from pathlib import Path
from ai_engine.classifier import classify_document

base = Path('dataset')
counts = {dept.name: sum(1 for p in dept.iterdir() if p.suffix.lower() == '.pdf') for dept in base.iterdir() if dept.is_dir()}
print('counts =', counts)
print('total =', sum(counts.values()))
samples = [
    'Employment contract and employee details for onboarding',
    'IT access request form for new employee account',
    'Employee leave request and payroll details',
    'Contract termination and benefits summary',
]
for text in samples:
    print(repr(text), '->', classify_document(text))
