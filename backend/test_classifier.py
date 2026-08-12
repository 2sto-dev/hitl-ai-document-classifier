import unittest

from ai_engine.classifier import classify_document, needs_human_review


class ClassifierTests(unittest.TestCase):
    def test_classify_document_returns_probabilistic_confidence(self):
        result = classify_document(text="Employment agreement")

        self.assertIn("predicted_class", result)
        self.assertIn("confidence", result)
        self.assertIn("second_class", result)
        self.assertIn("second_confidence", result)
        self.assertIn("confidence_margin", result)
        self.assertGreaterEqual(result["confidence"], 0)
        self.assertLessEqual(result["confidence"], 100)

    def test_needs_human_review_uses_threshold(self):
        # Confidence >= 70% should auto-approve (return False)
        self.assertFalse(needs_human_review(75))
        self.assertFalse(needs_human_review(70))
        
        # Confidence < 70% should route to human review (return True)
        self.assertTrue(needs_human_review(69))
        self.assertTrue(needs_human_review(50))


if __name__ == "__main__":
    unittest.main()