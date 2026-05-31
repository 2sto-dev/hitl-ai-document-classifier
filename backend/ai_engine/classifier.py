import joblib


vectorizer = joblib.load(
    "models/vectorizer.pkl"
)

model = joblib.load(
    "models/classifier.pkl"
)


def classify_document(text):

    X = vectorizer.transform(
        [text]
    )

    prediction = model.predict(
        X
    )[0]

    probabilities = model.predict_proba(
        X
    )[0]

    confidence = round(
        float(max(probabilities) * 100),
        2
    )

    return {
        "department": str(prediction),
        "confidence": confidence
    }


def needs_human_review(
    confidence
):

    return confidence < 70