from django.contrib.auth import get_user_model
from django.utils import timezone
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from assignments.models import Assignment

User = get_user_model()


class AssignmentTests(APITestCase):

    def setUp(self):
        self.admin = User.objects.create_user(
            username="admin",
            email="admin@example.com",
            password="AdminPassword123!",
            role="admin",
            is_staff=True,
        )
        self.approved_student = User.objects.create_user(
            username="approved_std",
            email="app@example.com",
            password="StudentPassword123!",
            role="student",
            is_approved=True,
        )
        self.unapproved_student = User.objects.create_user(
            username="unapproved_std",
            email="unapp@example.com",
            password="StudentPassword123!",
            role="student",
            is_approved=False,
        )
        self.assignment = Assignment.objects.create(
            title="Django Assignment",
            description="Build a REST API",
            deadline=timezone.now() + timezone.timedelta(days=2),
            created_by=self.admin,
        )

    def test_unapproved_student_blocked(self):
        self.client.force_authenticate(user=self.unapproved_student)
        
        # Test List
        response = self.client.get(reverse("assignment-list"))
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Test Retrieve
        response = self.client.get(
            reverse("assignment-detail", args=[self.assignment.id])
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_approved_student_read_only(self):
        self.client.force_authenticate(user=self.approved_student)

        # Test List
        response = self.client.get(reverse("assignment-list"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

        # Test Retrieve
        response = self.client.get(
            reverse("assignment-detail", args=[self.assignment.id])
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Test Create (should be blocked)
        response = self.client.post(
            reverse("assignment-list"),
            {
                "title": "New Assignment",
                "description": "Fail expected",
                "deadline": timezone.now() + timezone.timedelta(days=1),
            },
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_full_crud(self):
        self.client.force_authenticate(user=self.admin)

        # Create
        new_deadline = timezone.now() + timezone.timedelta(days=5)
        response = self.client.post(
            reverse("assignment-list"),
            {
                "title": "React Assignment",
                "description": "Build UI components",
                "deadline": new_deadline.isoformat(),
            },
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Assignment.objects.count(), 2)
        self.assertEqual(response.data["created_by_username"], "admin")

        # Update
        update_url = reverse("assignment-detail", args=[self.assignment.id])
        response = self.client.patch(update_url, {"title": "Updated Django Title"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assignment.refresh_from_db()
        self.assertEqual(self.assignment.title, "Updated Django Title")

        # Delete
        response = self.client.delete(update_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Assignment.objects.count(), 1)


from unittest.mock import patch
from django.test import TestCase
from services.supabase_storage import SupabaseStorageService

class SupabaseStorageServiceTests(TestCase):

    @patch("services.supabase_storage.requests.post")
    def test_upload_file_success(self, mock_post):
        # Configure mock response
        mock_post.return_value.status_code = 200
        mock_post.return_value.text = "Success"

        # Set environment variables for testing
        with patch.dict(
            "os.environ",
            {
                "SUPABASE_URL": "https://testproject.supabase.co/rest/v1/",
                "SUPABASE_KEY": "testkey",
            },
        ):
            # Test direct file upload
            url = SupabaseStorageService.upload_file(
                "assignments", b"file content", "test.pdf"
            )
            self.assertEqual(
                url,
                "https://testproject.supabase.co/storage/v1/object/public/assignments/test.pdf",
            )

            # Verify mock_post call details
            mock_post.assert_called_once_with(
                "https://testproject.supabase.co/storage/v1/object/assignments/test.pdf",
                headers={
                    "Authorization": "Bearer testkey",
                    "ApiKey": "testkey",
                    "Content-Type": "application/pdf",
                },
                data=b"file content",
            )

    @patch("services.supabase_storage.requests.post")
    def test_upload_helpers(self, mock_post):
        mock_post.return_value.status_code = 200
        with patch.dict(
            "os.environ",
            {
                "SUPABASE_URL": "https://testproject.supabase.co/rest/v1/",
                "SUPABASE_KEY": "testkey",
            },
        ):
            url_pdf = SupabaseStorageService.upload_assignment_pdf(
                b"pdf data", "assignment1.pdf"
            )
            self.assertEqual(
                url_pdf,
                "https://testproject.supabase.co/storage/v1/object/public/assignments/assignment1.pdf",
            )

            url_sub = SupabaseStorageService.upload_submission_file(
                b"sub data", "sub1.zip"
            )
            self.assertEqual(
                url_sub,
                "https://testproject.supabase.co/storage/v1/object/public/submissions/sub1.zip",
            )

