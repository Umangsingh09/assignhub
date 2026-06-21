from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    ROLE_CHOICES = [
        ('admin', 'Admin'),
        ('student', 'Student'),
    ]

    role = models.CharField(max_length=16, choices=ROLE_CHOICES, default='student')
    roll_number = models.CharField(max_length=32, blank=True, null=True, unique=True)
    is_approved = models.BooleanField(default=False)

    def __str__(self):
        return self.email or self.username
