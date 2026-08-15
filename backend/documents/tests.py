from django.test import SimpleTestCase

from .models import Document


class DocumentModelTests(SimpleTestCase):

    def test_new_document_has_pending_review_defaults(self):
        document = Document(
            filename="report.pdf",
            uploaded_file="documents/report.pdf"
        )

        self.assertEqual(document.status, "pending")
        self.assertEqual(document.confidence_score, 0)
        self.assertEqual(document.keywords, [])
        self.assertFalse(document.human_review_required)
        self.assertFalse(document.human_corrected)
        self.assertEqual(document.decision_threshold, 70.0)

    def test_string_representation_uses_filename(self):
        document = Document(filename="report.pdf")

        self.assertEqual(str(document), "report.pdf")
