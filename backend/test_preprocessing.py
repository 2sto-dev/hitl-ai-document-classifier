import unittest

from ai_engine.pdf_extractor import preprocess_text


class PreprocessTextTests(unittest.TestCase):
    def test_preprocess_text_normalizes_whitespace_and_preserves_business_terms(self):
        raw_text = "\u00a0Invoice\u000b for employee\n\nsalary review  with payment terms."

        cleaned = preprocess_text(raw_text)

        self.assertIn("invoice", cleaned.lower())
        self.assertIn("employee", cleaned.lower())
        self.assertIn("salary", cleaned.lower())
        self.assertIn("payment", cleaned.lower())
        self.assertNotIn("  ", cleaned)
        self.assertNotIn("\x0b", cleaned)

    def test_preprocess_text_can_mask_pii(self):
        text = "Contact John at john.doe@example.com or 555-123-4567 for the contract."

        masked = preprocess_text(text, mask_pii=True)

        self.assertNotIn("john.doe@example.com", masked)
        self.assertNotIn("555-123-4567", masked)
        self.assertTrue("[REDACTED_EMAIL]" in masked or "[REDACTED_PHONE]" in masked)

    def test_preprocess_text_can_remove_repeated_headers_and_footers(self):
        text = "Quarterly Review\nQuarterly Review\nQuarterly Review\nInvoice for supplier payment"

        cleaned = preprocess_text(text, remove_repeated_headers_footers=True)

        self.assertNotIn("Quarterly Review", cleaned)
        self.assertIn("Invoice for supplier payment", cleaned)


if __name__ == "__main__":
    unittest.main()
