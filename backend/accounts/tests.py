from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class AccountsAuthTests(APITestCase):

    def test_student_registration(self):
        url = reverse("student-register")
        data = {
            "username": "student1",
            "email": "student1@example.com",
            "password": "SecurePassword123!",
            "password2": "SecurePassword123!",
            "first_name": "John",
            "last_name": "Doe",
            "roll_number": "ROLL001",
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(User.objects.count(), 1)
        user = User.objects.first()
        self.assertEqual(user.username, "student1")
        self.assertEqual(user.role, "student")
        self.assertFalse(user.is_approved)

    def test_student_registration_password_mismatch(self):
        url = reverse("student-register")
        data = {
            "username": "student2",
            "email": "student2@example.com",
            "password": "SecurePassword123!",
            "password2": "DifferentPassword123!",
            "roll_number": "ROLL002",
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("password", response.data)

    def test_student_login(self):
        # Create student user
        student = User.objects.create_user(
            username="student_login",
            email="login@example.com",
            password="Password123!",
            role="student",
            roll_number="ROLL_LOGIN",
        )
        url = reverse("student-login")
        response = self.client.post(
            url, {"username": "student_login", "password": "Password123!"}
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)


class StudentApprovalSystemTests(APITestCase):

    def setUp(self):
        self.admin_user = User.objects.create_user(
            username="admin_user",
            email="admin@example.com",
            password="AdminPassword123!",
            role="admin",
            is_staff=True,
        )
        self.student_user = User.objects.create_user(
            username="student_user",
            email="student@example.com",
            password="StudentPassword123!",
            role="student",
            roll_number="ROLL_STUDENT",
            is_approved=False,
        )

    def test_pending_list_admin_only(self):
        url = reverse("student-pending-list")

        # Unauthenticated request
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

        # Student request
        self.client.force_authenticate(user=self.student_user)
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Admin request
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["username"], "student_user")

    def test_approve_student_admin_only(self):
        url = reverse("student-approve", args=[self.student_user.id])

        # Student trying to approve
        self.client.force_authenticate(user=self.student_user)
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Admin approving
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.student_user.refresh_from_db()
        self.assertTrue(self.student_user.is_approved)
        self.assertTrue(self.student_user.is_active)

    def test_reject_student_admin_only(self):
        url = reverse("student-reject", args=[self.student_user.id])

        # Student trying to reject
        self.client.force_authenticate(user=self.student_user)
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Admin rejecting
        self.client.force_authenticate(user=self.admin_user)
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.student_user.refresh_from_db()
        self.assertFalse(self.student_user.is_approved)
        self.assertFalse(self.student_user.is_active)


class DashboardAnalyticsTests(APITestCase):

    def setUp(self):
        self.admin = User.objects.create_user(
            username="admin_dash",
            email="adash@example.com",
            password="AdminPassword123!",
            role="admin",
            is_staff=True,
        )
        self.student_approved = User.objects.create_user(
            username="student_approved",
            email="s_app@example.com",
            password="Password123!",
            role="student",
            is_approved=True,
        )
        self.student_pending = User.objects.create_user(
            username="student_pending",
            email="s_pend@example.com",
            password="Password123!",
            role="student",
            is_approved=False,
        )

    def test_dashboard_analytics_admin_only(self):
        url = reverse("dashboard-analytics")

        # Student request (denied)
        self.client.force_authenticate(user=self.student_approved)
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        # Admin request (success)
        self.client.force_authenticate(user=self.admin)
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["total_students"], 2)
        self.assertEqual(response.data["pending_approvals"], 1)
        self.assertEqual(response.data["total_assignments"], 0)
        self.assertEqual(response.data["total_submissions"], 0)
        self.assertEqual(response.data["completion_percentage"], 0.0)

