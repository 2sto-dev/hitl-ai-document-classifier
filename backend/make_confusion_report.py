import os
import re
from pathlib import Path

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import confusion_matrix, classification_report
from sklearn.model_selection import train_test_split
from sklearn.svm import LinearSVC

from ai_engine.pdf_extractor import extract_text

DATASET_PATH = Path("dataset")

texts = []
labels = []
files = []

for department in sorted(os.listdir(DATASET_PATH)):
    department_path = DATASET_PATH / department
    if not department_path.is_dir():
        continue

    for filename in sorted(os.listdir(department_path)):
        if not filename.lower().endswith(".pdf"):
            continue

        file_path = department_path / filename
        text = extract_text(str(file_path))
        text = re.sub(r"\s+", " ", text).strip().lower()

        if not text:
            continue

        texts.append(text)
        labels.append(department)
        files.append((department, filename))

vectorizer = TfidfVectorizer(
    max_features=7000,
    ngram_range=(1, 3),
    stop_words="english",
    max_df=0.90,
    min_df=2,
    sublinear_tf=True,
)

X = vectorizer.fit_transform(texts)
X_train, X_test, y_train, y_test, files_train, files_test = train_test_split(
    X,
    labels,
    files,
    test_size=0.2,
    random_state=42,
    stratify=labels,
)

model = LinearSVC(class_weight="balanced", random_state=42)
model.fit(X_train, y_train)
predictions = model.predict(X_test)

labels_order = sorted(set(labels))
cm = confusion_matrix(y_test, predictions, labels=labels_order)

print("CONFUSION REPORT")
print("=" * 80)
print("Confusion Matrix:")
print(cm)
print("\nLabels:", labels_order)
print("\nClassification Report:\n")
print(classification_report(y_test, predictions, labels=labels_order, digits=4))

print("\nMisclassified Examples:")
print("-" * 80)

for true_label, predicted_label, (dept, filename) in zip(y_test, predictions, files_test):
    if true_label != predicted_label:
        file_index = files.index((dept, filename))
        sample_text = texts[file_index]
        sample_tokens = [token for token in re.findall(r"\b[a-z]{2,}\b", sample_text) if len(token) > 2]

        if len(sample_tokens) == 0:
            continue

        feature_names = vectorizer.get_feature_names_out()
        sample_vector = vectorizer.transform([sample_text])
        nonzero = sample_vector.nonzero()[1]
        token_scores = []

        for idx in nonzero:
            feature_name = feature_names[idx]
            if feature_name in sample_tokens:
                token_scores.append((feature_name, sample_vector[0, idx]))

        token_scores.sort(key=lambda item: item[1], reverse=True)
        top_terms = [term for term, _ in token_scores[:10]]

        print(f"{true_label} -> {predicted_label}: {filename}")
        print(f"  top terms: {', '.join(top_terms)}")
