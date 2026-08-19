from django.test import SimpleTestCase
from unittest.mock import Mock, patch

from .classifier import needs_human_review
from .pdf_extractor import OCRUnavailableError, extract_text, preprocess_text
from .services import process_document


class DocumentProcessingTests(SimpleTestCase):

    @patch("ai_engine.pdf_extractor._run_ocr", return_value="Scanned invoice total 1250 EUR")
    @patch("ai_engine.pdf_extractor._needs_ocr", return_value=True)
    @patch("ai_engine.pdf_extractor._extract_with_fitz", return_value="")
    def test_scanned_pdf_uses_ocr(self, _fitz, _needs_ocr, run_ocr):
        text = extract_text("scanned.pdf")

        self.assertEqual(text, "Scanned invoice total 1250 EUR")
        run_ocr.assert_called_once_with("scanned.pdf")

    @patch(
        "ai_engine.pdf_extractor._run_ocr",
        side_effect=OCRUnavailableError("OCR is unavailable"),
    )
    @patch("ai_engine.pdf_extractor._needs_ocr", return_value=True)
    @patch("ai_engine.pdf_extractor._extract_with_fitz", return_value="")
    def test_scanned_pdf_falls_back_when_ocr_is_missing(
        self,
        _fitz,
        _needs_ocr,
        _run_ocr,
    ):
        self.assertEqual(extract_text("scanned.pdf"), "")

    @patch(
        "ai_engine.pdf_extractor._run_ocr",
        side_effect=RuntimeError("OCR failed"),
    )
    @patch("ai_engine.pdf_extractor._needs_ocr", return_value=True)
    @patch(
        "ai_engine.pdf_extractor._extract_with_fitz",
        return_value="Useful native text",
    )
    def test_mixed_pdf_keeps_native_text_when_ocr_fails(
        self,
        _fitz,
        _needs_ocr,
        _run_ocr,
    ):
        self.assertEqual(extract_text("mixed.pdf"), "Useful native text")

    def test_preprocessing_normalizes_text_and_can_mask_pii(self):
        text = "Invoice\tfor  employee@example.com\n\n\nPhone: 555-123-4567"

        cleaned = preprocess_text(text, mask_pii=True)

        self.assertNotIn("  ", cleaned)
        self.assertNotIn("employee@example.com", cleaned)
        self.assertNotIn("555-123-4567", cleaned)
        self.assertIn("[REDACTED_EMAIL]", cleaned)

    def test_review_threshold_routes_low_confidence_documents(self):
        self.assertTrue(needs_human_review(None))
        self.assertTrue(needs_human_review(69.99))
        self.assertFalse(needs_human_review(70))
        self.assertFalse(needs_human_review(95))

    @patch("ai_engine.services.extract_text", return_value="employee salary contract")
    @patch("ai_engine.services.analyze_document")
    @patch("ai_engine.services.classify_document")
    def test_processing_persists_human_review_route(self, classify, analyze, _extract):
        classify.return_value = {
            "predicted_class": "HR",
            "confidence": 69.99,
        }
        analyze.return_value = {
            "summary": "Ollama summary",
            "keywords": ["employee", "salary"],
            "department": "HR",
        }
        document = Mock()
        document.uploaded_file.path = "report.pdf"

        process_document(document)

        self.assertEqual(document.decision_route, "human_review")
        self.assertEqual(document.decision_threshold, 70.0)
        self.assertTrue(document.human_review_required)
        self.assertEqual(document.summary, "Ollama summary")
        self.assertEqual(document.keywords, ["employee", "salary"])

    @patch("ai_engine.services.extract_text", return_value="employee salary contract")
    @patch("ai_engine.services.analyze_document")
    @patch("ai_engine.services.classify_document")
    def test_processing_persists_auto_approved_route(self, classify, analyze, _extract):
        classify.return_value = {
            "predicted_class": "HR",
            "confidence": 70.0,
        }
        analyze.side_effect = RuntimeError("Ollama unavailable")
        document = Mock()
        document.uploaded_file.path = "report.pdf"

        process_document(document)

        self.assertEqual(document.decision_route, "auto_approved")
        self.assertEqual(document.decision_threshold, 70.0)
        self.assertFalse(document.human_review_required)
        self.assertTrue(document.summary)
