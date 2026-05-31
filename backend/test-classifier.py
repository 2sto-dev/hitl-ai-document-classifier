from ai_engine.classifier import classify_document

sample_text = """
EMPLOYMENT AGREEMENT

Employee: John Smith

Position: Software Engineer

Salary: 12000 RON

Benefits:
- Medical insurance
- Meal vouchers

Start date: 01.06.2026
"""

result = classify_document(sample_text)

print(result)