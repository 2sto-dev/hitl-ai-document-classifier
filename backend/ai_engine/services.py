from .pdf_extractor import extract_text


def process_document(document):

    text = extract_text(
        document.uploaded_file.path
    )

    document.extracted_text = text

    document.save(
        update_fields=["extracted_text"]
    )

    return document