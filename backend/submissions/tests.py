from django.contrib.auth import get_user_model
from django.utils import timezone
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from assignments.models import Assignment
from submissions.models import Submission

User = get_user_model()


class SubmissionTests(APITestCase):

    def setUp(self):
        self.admin = User.objects.create_user(
            username="admin",
            email="admin@example.com",
            password="AdminPassword123!",
            role="admin",
            is_staff=True,
        )
        self.approved_student_1 = User.objects.create_user(
            username="approved1",
            email="app1@example.com",
            password="StudentPassword123!",
            role="student",
            is_approved=True,
        )
        self.approved_student_2 = User.objects.create_user(
            username="approved2",
            email="app2@example.com",
            password="StudentPassword123!",
            role="student",
            is_approved=True,
        )
        self.unapproved_student = User.objects.create_user(
            username="unapproved",
            email="unapp@example.com",
            password="StudentPassword123!",
            role="student",
            is_approved=False,
        )

        # Create two assignments (one active, one expired)
        self.active_assignment = Assignment.objects.create(
            title="Active Assignment",
            description="Due in 2 days",
            deadline=timezone.now() + timezone.timedelta(days=2),
            created_by=self.admin,
        )
        self.expired_assignment = Assignment.objects.create(
            title="Expired Assignment",
            description="Due 2 days ago",
            deadline=timezone.now() - timezone.timedelta(days=2),
            created_by=self.admin,
        )

    def test_student_submission_flow(self):
        self.client.force_authenticate(user=self.approved_student_1)

        # Unapproved student submit (should fail)
        self.client.force_authenticate(user=self.unapproved_student)
        response = self.client.post(
            reverse("submission-list"),
            {
                "assignment": self.active_assignment.id,
                "text_submission": "My solution",
            },
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Approved student submit on active assignment (should succeed, not late)
        self.client.force_authenticate(user=self.approved_student_1)
        response = self.client.post(
            reverse("submission-list"),
            {
                "assignment": self.active_assignment.id,
                "text_submission": "My solution",
            },
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Submission.objects.count(), 1)
        submission = Submission.objects.first()
        self.assertEqual(submission.student, self.approved_student_1)
        self.assertFalse(submission.is_late)
        self.assertEqual(submission.status, "pending")

        # Duplicate submit by same student (should fail)
        response = self.client.post(
            reverse("submission-list"),
            {
                "assignment": self.active_assignment.id,
                "text_submission": "Another solution",
            },
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_late_submission_calculation(self):
        self.client.force_authenticate(user=self.approved_student_1)

        response = self.client.post(
            reverse("submission-list"),
            {
                "assignment": self.expired_assignment.id,
                "text_submission": "Late submission solution",
            },
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        submission = Submission.objects.get(assignment=self.expired_assignment)
        self.assertTrue(submission.is_late)
        self.assertEqual(submission.status, "late")

    def test_submission_visibility_rules(self):
        # Create a submission for student 1
        sub1 = Submission.objects.create(
            assignment=self.active_assignment,
            student=self.approved_student_1,
            text_submission="Student 1 work",
        )
        # Create a submission for student 2
        sub2 = Submission.objects.create(
            assignment=self.active_assignment,
            student=self.approved_student_2,
            text_submission="Student 2 work",
        )

        # Student 1 fetches list: should only see sub1
        self.client.force_authenticate(user=self.approved_student_1)
        response = self.client.get(reverse("submission-list"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["id"], sub1.id)

        # Admin fetches list: should see both
        self.client.force_authenticate(user=self.admin)
        response = self.client.get(reverse("submission-list"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)

    def test_pending_submissions_endpoint(self):
        # Create a submission for student 1 (pending)
        sub1 = Submission.objects.create(
            assignment=self.active_assignment,
            student=self.approved_student_1,
            text_submission="Pending work",
            status="pending",
        )
        # Create a graded submission for student 2
        sub2 = Submission.objects.create(
            assignment=self.active_assignment,
            student=self.approved_student_2,
            text_submission="Graded work",
            status="graded",
        )

        # Fetch pending (Admin): should only return sub1
        self.client.force_authenticate(user=self.admin)
        response = self.client.get(reverse("submission-pending"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["id"], sub1.id)
