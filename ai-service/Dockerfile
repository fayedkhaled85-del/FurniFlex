FROM python:3.14.0-slim-bookworm
WORKDIR /srv/advisor
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY common.py serve.py ./
COPY artifacts ./artifacts
CMD ["python","-B","serve.py"]
