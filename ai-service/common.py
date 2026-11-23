import re, html
def normalize(text):
    return re.sub(r"\s+", " ", html.unescape(re.sub("<[^>]+>", " ", text))).strip().lower()
def label(category):
    for fragment, name in [
        (" > Sofas", "sofa"),
        (" > Coffee Tables", "coffee_table"),
        (" > Beds & Bed Frames", "bed"),
        (" > Kitchen & Dining Room Tables", "dining_table"),
        (" > Desks", "desk"),
        (" > Secretary Desks", "desk"),
        (" > Armoires & Wardrobes", "wardrobe"),
    ]:
        if fragment in category and "Outdoor" not in category:
            return name
    return "other"
