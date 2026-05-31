import os
import fitz
import joblib

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score,
    classification_report
)


DATASET_PATH = "dataset"

texts = []
labels = []


def extract_pdf_text(pdf_path):

    doc = fitz.open(pdf_path)

    text = ""

    for page in doc:
        text += page.get_text()

    return text


print("Loading dataset...\n")


for department in os.listdir(DATASET_PATH):

    department_path = os.path.join(
        DATASET_PATH,
        department
    )

    if not os.path.isdir(department_path):
        continue

    print(f"Department: {department}")

    for filename in os.listdir(
        department_path
    ):

        if not filename.lower().endswith(
            ".pdf"
        ):
            continue

        file_path = os.path.join(
            department_path,
            filename
        )

        try:

            text = extract_pdf_text(
                file_path
            )

            if not text.strip():

                print(
                    f"Empty PDF: {filename}"
                )

                continue

            texts.append(text)

            labels.append(
                department
            )

            print(
                f"Loaded: {filename}"
            )

        except Exception as e:

            print(
                f"FAILED: {filename}"
            )

            print(e)


print("\n======================")
print(
    f"Documents loaded: {len(texts)}"
)
print("======================\n")


vectorizer = TfidfVectorizer(
    max_features=5000,
    ngram_range=(1, 2)
)

X = vectorizer.fit_transform(
    texts
)

X_train, X_test, y_train, y_test = train_test_split(
    X,
    labels,
    test_size=0.2,
    random_state=42,
    stratify=labels
)

model = LogisticRegression(
    max_iter=3000
)

model.fit(
    X_train,
    y_train
)

predictions = model.predict(
    X_test
)

print("\n======================")
print("MODEL EVALUATION")
print("======================\n")

accuracy = accuracy_score(
    y_test,
    predictions
)

print(
    f"Accuracy: {accuracy:.4f}"
)

print("\nClassification Report:\n")

print(
    classification_report(
        y_test,
        predictions
    )
)

os.makedirs(
    "models",
    exist_ok=True
)

joblib.dump(
    vectorizer,
    "models/vectorizer.pkl"
)

joblib.dump(
    model,
    "models/classifier.pkl"
)

print("\n======================")
print("MODEL SAVED")
print("======================")

print(
    "models/vectorizer.pkl"
)

print(
    "models/classifier.pkl"
)