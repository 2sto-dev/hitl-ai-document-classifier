import uuid

from django.db import models


class Document(models.Model):

    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("approved", "Approved"),
        ("review", "Review"),
        ("rejected", "Rejected"),
    ]

    DEPARTMENT_CHOICES = [
        ("HR", "HR"),
        ("Finance", "Finance"),
        ("IT", "IT"),
        ("Legal", "Legal"),
        ("Operations", "Operations"),
        ("Procurement", "Procurement"),
    ]

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    filename = models.CharField(
        max_length=255
    )

    uploaded_file = models.FileField(
        upload_to="documents/"
    )

    extracted_text = models.TextField(
        blank=True
    )

    summary = models.TextField(
        blank=True
    )

    keywords = models.JSONField(
        default=list,
        blank=True
    )

    suggested_department = models.CharField(
        max_length=50,
        blank=True
    )

    predicted_class = models.CharField(
        max_length=50,
        blank=True
    )

    confidence_score = models.FloatField(
        default=0
    )

    final_class = models.CharField(
        max_length=50,
        choices=DEPARTMENT_CHOICES,
        blank=True
    )

    human_corrected = models.BooleanField(
        default=False
    )

    human_review_required = models.BooleanField(
        default=False
    )

    review_notes = models.TextField(
        blank=True
    )

    reviewed_by = models.CharField(
        max_length=100,
        blank=True
    )

    reviewed_at = models.DateTimeField(
        null=True,
        blank=True
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="pending"
    )

    uploaded_at = models.DateTimeField(
        auto_now_add=True
    )

    updated_at = models.DateTimeField(
        auto_now=True
    )

    def __str__(self):
        return self.filename