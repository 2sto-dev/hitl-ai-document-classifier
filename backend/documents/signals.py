from django.db.models.signals import post_save
from django.dispatch import receiver

from documents.models import Document
from ai_engine.services import process_document


@receiver(post_save, sender=Document)
def document_uploaded(sender, instance, created, **kwargs):

    if created:

        try:

            process_document(instance)

        except Exception as e:

            print(
                f"Processing error: {e}"
            )