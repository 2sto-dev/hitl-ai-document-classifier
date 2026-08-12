from pathlib import Path
from collections import Counter
from ai_engine.pdf_extractor import extract_text
from ai_engine.classifier import classify_document

base = Path('dataset')
miscounts = Counter()
count = 0
sample_errors = []
for dept in sorted(base.iterdir()):
    if not dept.is_dir():
        continue
    for pdf in sorted(dept.iterdir()):
        if pdf.suffix.lower() != '.pdf':
            continue
        count += 1
        text = extract_text(str(pdf))
        res = classify_document(text)
        predicted = res['department']
        if predicted != dept.name:
            miscounts[(dept.name, predicted)] += 1
            if len(sample_errors) < 20:
                sample_errors.append((dept.name, predicted, res['confidence'], pdf.name, repr(text[:240])))

print('total docs scanned=', count)
print('miscounts=')
for k,v in sorted(miscounts.items(), key=lambda x:(x[0][0], x[0][1])):
    print(f'  actual={k[0]:12} predicted={k[1]:12} count={v}')
print('samples:')
for actual, predicted, conf, name, snippet in sample_errors:
    print('---')
    print('actual=', actual, 'predicted=', predicted, 'conf=', conf, 'file=', name)
    print(snippet)
