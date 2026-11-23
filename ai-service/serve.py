"""Local, data-only inference. The PHP application owns authorization and ranking."""
import json
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer

from common import normalize

ROOT = Path(__file__).resolve().parent
VERSION = "1+2"
LABELS = frozenset(("bed", "coffee_table", "desk", "dining_table", "other", "sofa", "wardrobe"))


class LinearTextModel:
    def __init__(self, path):
        data = json.loads(path.read_text(encoding="utf8"))
        vocab = data["vocabulary"]
        self.classes = data["classes"]
        self.coefficients = np.asarray(data["coef"], dtype=float)
        self.intercepts = np.asarray(data["intercept"], dtype=float)
        idf = np.asarray(data["idf"], dtype=float)
        if (set(self.classes) != LABELS or len(self.classes) != len(LABELS)
                or sorted(vocab.values()) != list(range(len(vocab)))
                or idf.shape != (len(vocab),) or not np.all(np.isfinite(idf))
                or self.coefficients.shape != (len(LABELS), len(vocab))
                or self.intercepts.shape != (len(LABELS),)
                or not all(np.isfinite(x).all() for x in (self.intercepts, self.coefficients))):
            raise ValueError("Invalid model artifact")
        self.vector = TfidfVectorizer(ngram_range=(1, 2), sublinear_tf=True,
                                      stop_words="english", vocabulary=vocab)
        self.vector.idf_ = idf

    def score(self, text):
        x = self.vector.transform([text])
        if not x.nnz:
            return []
        scores = np.asarray(x @ self.coefficients.T).ravel() + self.intercepts
        return [{"intent": self.classes[i], "score": float(scores[i])}
                for i in np.argsort(scores)[::-1]]


primary = LinearTextModel(ROOT / "artifacts/model.json")
specialist = LinearTextModel(ROOT / "artifacts/model-v2.json")


def accepted(scores, margin):
    return bool(scores and scores[0]["intent"] != "other" and
                scores[0]["score"] - scores[1]["score"] >= margin)


def classify(text):
    scores = primary.score(text)
    if accepted(scores, 0.3):
        return scores[0]["intent"], scores, "logistic"
    alternative = specialist.score(text)
    if accepted(alternative, 0.6) and alternative[0]["score"] > 0:
        return alternative[0]["intent"], alternative, "linear_svm"
    return None, scores, "abstained"


def predict(text):
    if not isinstance(text, str) or not 3 <= len(text.strip()) <= 1500:
        raise ValueError("Description must contain 3 to 1500 characters.")
    text = normalize(text)
    intent, scores, stage = classify(text)
    # Explicit alternatives can be independently classified. Abstain on conflicting types.
    parts = re.split(r"\b(?:or|and)\b", text, maxsplit=3)
    if len(parts) > 1:
        options = {classify(part)[0] for part in parts} - {None}
        if len(options) > 1:
            intent, stage = None, "ambiguous"
    return {"status": "ok" if intent else "unknown", "intent": intent,
            "scores": scores, "model_version": VERSION, "stage": stage}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # Never log descriptions or raw requests.

    def send_json(self, status, data):
        encoded = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(encoded)

    def do_GET(self):
        if self.path == "/health":
            self.send_json(200, {"status": "ready", "version": VERSION})
        else:
            self.send_json(404, {"error": "Not found"})

    def do_POST(self):
        if self.headers.get("Origin"):
            return self.send_json(403, {"error": "Internal service only"})
        if self.path != "/predict":
            return self.send_json(404, {"error": "Not found"})
        self.connection.settimeout(3)
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 1 <= length <= 8000:
                return self.send_json(413, {"error": "Invalid request size"})
            if self.headers.get_content_type() != "application/json":
                return self.send_json(415, {"error": "JSON required"})
            data = json.loads(self.rfile.read(length))
            if not isinstance(data, dict) or set(data) != {"text"}:
                raise ValueError("Invalid fields")
            self.send_json(200, predict(data["text"]))
        except (ValueError, TimeoutError, RecursionError):
            self.send_json(400, {"error": "Invalid description"})


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 8765), Handler).serve_forever()
