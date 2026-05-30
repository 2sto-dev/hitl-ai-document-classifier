from ai_engine.qwen_service import analyze_document

sample_text = """
EMPLOYMENT AGREEMENT

Company: TechNova Solutions SRL

Employee Name: John Smith

Position: Software Developer

Department: Human Resources

Salary: 12000 RON
"""

result = analyze_document(sample_text)

print(result)