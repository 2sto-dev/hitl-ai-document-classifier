from ai_engine.pdf_extractor import extract_text

text = extract_text(
    "media/documents/employee_contraact.pdf"
)

print(text)