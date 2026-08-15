from pathlib import Path
import joblib

BASE_DIR = Path(__file__).resolve().parent.parent
MODEL_DIR = BASE_DIR / "models"

vectorizer = joblib.load(
    MODEL_DIR / "vectorizer.pkl"
)

model = joblib.load(
    MODEL_DIR / "classifier.pkl"
)


def _normalize_class_name(label):
    return str(label).strip()


def classify_document(text):

    X = vectorizer.transform(
        [text]
    )

    probabilities = model.predict_proba(
        X
    )[0]

    best_idx = int(probabilities.argmax())
    second_idx = int(probabilities.argsort()[-2])

    predicted_class = _normalize_class_name(model.classes_[best_idx])
    confidence = float(probabilities[best_idx])
    second_class = _normalize_class_name(model.classes_[second_idx])
    second_confidence = float(probabilities[second_idx])
    confidence_margin = float(confidence - second_confidence)

    return {
        "predicted_class": predicted_class,
        "confidence": round(confidence * 100, 2),
        "second_class": second_class,
        "second_confidence": round(second_confidence * 100, 2),
        "confidence_margin": round(confidence_margin, 6),
    }


def needs_human_review(confidence, *, auto_accept_threshold=70.0):
    """
    Determine if a document needs human review based on confidence score.
    
    Args:
        confidence: Confidence score (0-100 percentage scale)
        auto_accept_threshold: Confidence threshold for automatic approval (default: 70%)
    
    Returns:
        False if confidence >= threshold (auto-approve)
        True if confidence < threshold (route to human review)
    """
    if confidence is None:
        return True

    return confidence < auto_accept_threshold