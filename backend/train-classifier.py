import os
from pathlib import Path
import joblib

from ai_engine.pdf_extractor import clean_text, extract_text as extract_pdf_text

from sklearn.calibration import CalibratedClassifierCV
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.model_selection import (
    GridSearchCV,
    StratifiedKFold,
    cross_val_score,
    train_test_split,
)
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
)


DATASET_PATH = "dataset"

BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "models"

texts = []
labels = []


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

        # These files are byte-identical to the HR performance-review set.
        # Keeping both labels makes the training target contradictory.
        if (
            department == "Finance"
            and filename.lower().startswith("performance_review_")
        ):
            print(f"Skipped mislabeled duplicate: {filename}")
            continue

        file_path = os.path.join(
            department_path,
            filename
        )

        try:

            text = extract_pdf_text(
                file_path
            )

            text = clean_text(text)
            text = text.lower()

            if not text:

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


# Improve vectorization: remove common English stopwords, use trigrams,
# and ignore very rare/very common tokens
vectorizer = TfidfVectorizer(
    max_features=7000,
    ngram_range=(1, 3),
    stop_words='english',
    max_df=0.90,
    min_df=2,
    sublinear_tf=True,
)

# lowercase texts to reduce sparsity
texts = [t.lower() for t in texts]

X = vectorizer.fit_transform(texts)

X_train, X_test, y_train, y_test = train_test_split(
    X,
    labels,
    test_size=0.2,
    random_state=42,
    stratify=labels,
)

cv = StratifiedKFold(
    n_splits=5,
    shuffle=True,
    random_state=42,
)

base_model = LinearSVC(
    class_weight='balanced',
    random_state=42,
)

calibrated_base = CalibratedClassifierCV(
    estimator=base_model,
    method='sigmoid',
    cv=5,
)

cv_scores = cross_val_score(
    calibrated_base,
    X,
    labels,
    cv=cv,
    scoring='f1_macro',
    n_jobs=-1,
)

print("\n======================")
print("MODEL EVALUATION")
print("======================\n")

print("Cross-validation F1 (macro):")
print(cv_scores)
print(
    f"Mean CV F1 (macro): {cv_scores.mean():.4f} +/- {cv_scores.std():.4f}"
)

param_grid = {
    'estimator__C': [0.25, 0.5, 1.0, 2.0, 4.0],
}

grid_search = GridSearchCV(
    estimator=CalibratedClassifierCV(
        estimator=LinearSVC(class_weight='balanced', random_state=42),
        method='sigmoid',
        cv=5,
    ),
    param_grid=param_grid,
    cv=cv,
    scoring='f1_macro',
    n_jobs=-1,
)

grid_search.fit(X_train, y_train)

model = grid_search.best_estimator_
model.fit(X_train, y_train)
predictions = model.predict(X_test)

if not hasattr(model, 'predict_proba'):
    raise RuntimeError('Trained model does not expose predict_proba()')

accuracy = accuracy_score(
    y_test,
    predictions,
)

print("\nBest parameters:")
print(grid_search.best_params_)
print(f"Best CV F1 (macro): {grid_search.best_score_:.4f}")
print(f"Holdout accuracy: {accuracy:.4f}")

print("\nClassification Report:\n")
print(
    classification_report(
        y_test,
        predictions,
    )
)

print("\nConfusion Matrix:\n")
print(confusion_matrix(y_test, predictions))

MODEL_DIR.mkdir(parents=True, exist_ok=True)

joblib.dump(
    vectorizer,
    str(MODEL_DIR / "vectorizer.pkl")
)

joblib.dump(
    model,
    str(MODEL_DIR / "classifier.pkl")
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
