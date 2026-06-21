from django.conf import settings
from django.db import models

from assignments.models import Assignment


class Submission(models.Model):
    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("graded", "Graded"),
        ("late", "Late"),
    ]

    assignment = models.ForeignKey(
        Assignment, on_delete=models.CASCADE, related_name="submissions"
    )
    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="submissions",
    )
    file_url = models.URLField(blank=True, null=True)
    text_submission = models.TextField(blank=True, null=True)
    submitted_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(
        max_length=16, choices=STATUS_CHOICES, default="pending"
    )
    is_late = models.BooleanField(default=False)

    def save(self, *args, **kwargs):
        # Determine if the submission is late upon creation
        if not self.id and self.assignment:
            from django.utils import timezone
            # Set submitted_at value for comparison if not already set (auto_now_add handles DB side)
            now = timezone.now()
            if now > self.assignment.deadline:
                self.is_late = True
                self.status = "late"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Submission by {self.student.username} for {self.assignment.title}"
