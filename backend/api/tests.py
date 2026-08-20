import tempfile
import uuid
from unittest.mock import patch

from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import SimpleTestCase, override_settings
from django.urls import reverse
from django.utils import timezone

from rest_framework import serializers
from rest_framework.test import APITestCase

from documents.models import Document

from .auth_serializers import RegisterSerializer, UserProfileSerializer


class PasswordValidationTests(SimpleTestCase):

    def test_registration_rejects_common_password(self):
        serializer = RegisterSerializer()

        with self.assertRaisesMessage(serializers.ValidationError, "too common"):
            serializer.validate({
                "username": "reviewer",
                "email": "reviewer@example.com",
                "password": "password"
            })

    def test_registration_accepts_strong_password(self):
        serializer = RegisterSerializer()

        data = serializer.validate({
            "username": "reviewer",
            "email": "reviewer@example.com",
            "password": "G7!vQ2#nL9@x"
        })

        self.assertEqual(data["username"], "reviewer")

    def test_profile_update_rejects_password_similar_to_username(self):
        user = User(
            username="researcher",
            email="researcher@example.com"
        )
        serializer = UserProfileSerializer(instance=user)

        with self.assertRaisesMessage(serializers.ValidationError, "too similar"):
            serializer.validate({
                "username": "researcher",
                "password": "researcher123"
            })


class ApiTestCase(APITestCase):

    password = "G7!vQ2#nL9@x"

    def setUp(self):
        self.user = User.objects.create_user(
            username="reviewer",
            email="reviewer@example.com",
            password=self.password
        )

    def authenticate(self):
        self.client.force_authenticate(user=self.user)

    def create_document(self, **overrides):
        values = {
            "owner": self.user,
            "filename": "sample.pdf",
            "uploaded_file": "documents/sample.pdf",
            "predicted_class": "HR",
            "confidence_score": 65,
            "status": "review",
            "human_review_required": True
        }
        values.update(overrides)

        with patch("documents.signals.process_document"):
            return Document.objects.create(**values)


class AuthenticationApiTests(ApiTestCase):

    def test_registration_login_and_profile_flow(self):
        registration = self.client.post(reverse("register"), {
            "username": "new_reviewer",
            "email": "new@example.com",
            "password": "T8!mR4#zP2@q"
        })
        self.assertEqual(registration.status_code, 201)

        login = self.client.post(reverse("token_obtain_pair"), {
            "username": "new_reviewer",
            "password": "T8!mR4#zP2@q"
        })
        self.assertEqual(login.status_code, 200)
        self.assertIn("access", login.data)
        self.assertIn("refresh", login.data)

        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {login.data['access']}"
        )
        profile = self.client.get(reverse("user-profile"))
        self.assertEqual(profile.status_code, 200)
        self.assertEqual(profile.data["username"], "new_reviewer")

    def test_registration_rejects_weak_password(self):
        response = self.client.post(reverse("register"), {
            "username": "new_reviewer",
            "password": "password"
        })

        self.assertEqual(response.status_code, 400)
        self.assertIn("password", response.data)


class ApiPermissionTests(ApiTestCase):

    def test_document_and_analytics_endpoints_require_authentication(self):
        protected_urls = [
            reverse("document-list"),
            reverse("document-detail", kwargs={"id": uuid.uuid4()}),
            reverse("review-queue"),
            reverse("stats"),
            reverse("department-stats"),
            reverse("accuracy-stats"),
            reverse("confusion-matrix")
        ]

        for url in protected_urls:
            with self.subTest(url=url):
                response = self.client.get(url)
                self.assertEqual(response.status_code, 401)

    def test_mutating_endpoints_require_authentication(self):
        upload = self.client.post(reverse("document-upload"), {})
        review = self.client.post(
            reverse("document-review", kwargs={"id": uuid.uuid4()}),
            {"action": "approve"}
        )
        analyze = self.client.post(reverse("ai-analyze"), {"text": "test"})

        self.assertEqual(upload.status_code, 401)
        self.assertEqual(review.status_code, 401)
        self.assertEqual(analyze.status_code, 401)


class UserDocumentIsolationTests(ApiTestCase):

    def setUp(self):
        super().setUp()
        self.other_user = User.objects.create_user(
            username="other_reviewer",
            password=self.password
        )
        self.own_document = self.create_document()
        self.other_document = self.create_document(owner=self.other_user)
        self.authenticate()

    def test_history_queue_and_dashboard_only_include_own_documents(self):
        history = self.client.get(reverse("document-list"))
        queue = self.client.get(reverse("review-queue"))
        stats = self.client.get(reverse("stats"))

        self.assertEqual([item["id"] for item in history.data], [str(self.own_document.id)])
        self.assertEqual([item["id"] for item in queue.data], [str(self.own_document.id)])
        self.assertEqual(stats.data["total_documents"], 1)

    def test_user_cannot_view_or_review_another_users_document(self):
        detail = self.client.get(
            reverse("document-detail", kwargs={"id": self.other_document.id})
        )
        review = self.client.post(
            reverse("document-review", kwargs={"id": self.other_document.id}),
            {"action": "approve"},
            format="json"
        )

        self.assertEqual(detail.status_code, 404)
        self.assertEqual(review.status_code, 404)


class UploadApiTests(ApiTestCase):

    @override_settings(MEDIA_ROOT=tempfile.gettempdir())
    @patch("documents.signals.process_document")
    def test_authenticated_user_can_upload_document(self, process_document):
        self.authenticate()
        uploaded_file = SimpleUploadedFile(
            "report.pdf",
            b"%PDF-1.4 test content",
            content_type="application/pdf"
        )

        response = self.client.post(
            reverse("document-upload"),
            {"filename": "report.pdf", "uploaded_file": uploaded_file},
            format="multipart"
        )

        self.assertEqual(response.status_code, 201)
        document = Document.objects.get(id=response.data["id"])
        self.assertEqual(document.filename, "report.pdf")
        self.assertEqual(document.owner, self.user)
        process_document.assert_called_once_with(document)


class ReviewApiTests(ApiTestCase):

    def setUp(self):
        super().setUp()
        self.authenticate()

    def test_approve_uses_prediction_and_records_reviewer(self):
        document = self.create_document(predicted_class="Finance")

        response = self.client.post(
            reverse("document-review", kwargs={"id": document.id}),
            {"action": "approve", "review_notes": "Looks correct"},
            format="json"
        )

        self.assertEqual(response.status_code, 200)
        document.refresh_from_db()
        self.assertEqual(document.final_class, "Finance")
        self.assertEqual(document.status, "approved")
        self.assertFalse(document.human_corrected)
        self.assertFalse(document.human_review_required)
        self.assertEqual(document.reviewed_by, self.user.username)
        self.assertIsNotNone(document.reviewed_at)

    def test_change_requires_a_valid_department(self):
        document = self.create_document()
        url = reverse("document-review", kwargs={"id": document.id})

        missing = self.client.post(url, {"action": "change"}, format="json")
        invalid = self.client.post(
            url,
            {"action": "change", "final_class": "Unknown"},
            format="json"
        )

        self.assertEqual(missing.status_code, 400)
        self.assertEqual(invalid.status_code, 400)

    def test_reject_clears_final_class(self):
        document = self.create_document()

        response = self.client.post(
            reverse("document-review", kwargs={"id": document.id}),
            {"action": "reject"},
            format="json"
        )

        self.assertEqual(response.status_code, 200)
        document.refresh_from_db()
        self.assertEqual(document.status, "rejected")
        self.assertEqual(document.final_class, "")
        self.assertFalse(document.human_review_required)


class AnalyticsApiTests(ApiTestCase):

    def setUp(self):
        super().setUp()
        self.authenticate()

    def test_statistics_department_and_confusion_endpoints(self):
        self.create_document(
            predicted_class="HR",
            final_class="HR",
            status="approved",
            human_review_required=False
        )
        self.create_document(
            predicted_class="IT",
            final_class="Legal",
            status="approved",
            human_review_required=False,
            human_corrected=True,
            reviewed_at=timezone.now(),
            reviewed_by=self.user.username
        )
        self.create_document(
            status="rejected",
            human_review_required=False,
            reviewed_at=timezone.now(),
            reviewed_by=self.user.username
        )
        self.create_document(status="pending", human_review_required=False)

        stats = self.client.get(reverse("stats"))
        departments = self.client.get(reverse("department-stats"))
        confusion = self.client.get(reverse("confusion-matrix"))
        accuracy = self.client.get(reverse("accuracy-stats"))

        self.assertEqual(stats.status_code, 200)
        self.assertEqual(stats.data["total_documents"], 4)
        self.assertEqual(stats.data["approved"], 2)
        self.assertEqual(stats.data["rejected"], 1)
        self.assertEqual(stats.data["pending"], 1)
        self.assertEqual(stats.data["processed_documents"], 3)
        self.assertEqual(stats.data["reviewed_documents"], 2)
        self.assertEqual(stats.data["auto_approved_documents"], 1)
        self.assertEqual(stats.data["human_intervention_rate"], 66.67)
        self.assertEqual(stats.data["auto_approval_rate"], 33.33)
        self.assertEqual(departments.data["HR"], 1)
        self.assertEqual(departments.data["Legal"], 1)
        self.assertEqual(confusion.data["IT"]["Legal"], 1)
        self.assertEqual(accuracy.data["total_reviewed"], 2)
        self.assertEqual(accuracy.data["accuracy"], 50.0)
