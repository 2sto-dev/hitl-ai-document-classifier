from pathlib import Path
from ai_engine.pdf_extractor import extract_text
from ai_engine.classifier import classify_document

path = Path('dataset/HR/employment_contract.pdf')
print('path exists:', path.exists())
if path.exists():
    text = extract_text(str(path))
    print('text length:', len(text))
    print('text snippet:', repr(text[:800]))
    print('classification:', classify_document(text))
