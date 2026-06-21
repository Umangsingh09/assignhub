from django.conf import settings
from django.db import models


class Assignment(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField()
    pdf_url = models.URLField(blank=True, null=True)
    external_link = models.URLField(blank=True, null=True)
    deadline = models.DateTimeField()
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="assignments",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title
