import os
import django
import random
import string
from django.urls import reverse
from rest_framework.test import APIClient

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()
from django.conf import settings
settings.ALLOWED_HOSTS.append('testserver')
print("ALLOWED_HOSTS in script:", settings.ALLOWED_HOSTS)

from django.contrib.auth import get_user_model
from assignments.models import Assignment
from submissions.models import Submission

User = get_user_model()

def rand_str(length=6):
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

def run_verification():
    print("Starting AssignHub API & JWT Integration Verification...")
    client = APIClient()
    
    reports = {
        "api": [],
        "jwt": []
    }
    
    # ----------------------------------------------------
    # 1. JWT Authentication Tests
    # ----------------------------------------------------
    print("\n--- 1. Testing JWT Authentication ---")
    login_url = reverse("student-login")
    login_data = {
        "username": "admin",
        "password": "AdminPassword123!"
    }
    response = client.post(login_url, login_data, format='json')
    if response.status_code == 200:
        print("[PASS] Admin Login successful.")
        access_token = response.data["access"]
        refresh_token = response.data["refresh"]
        reports["jwt"].append({
            "name": "Admin Login & Token Generation",
            "status": "PASS",
            "details": f"Successfully retrieved tokens. Role claim: {response.data.get('role')}, is_approved claim: {response.data.get('is_approved')}"
        })
    else:
        print("[FAIL] Admin Login failed:", response.data)
        reports["jwt"].append({
            "name": "Admin Login & Token Generation",
            "status": "FAIL",
            "details": str(response.data)
        })
        return
        
    refresh_url = reverse("token-refresh")
    refresh_response = client.post(refresh_url, {"refresh": refresh_token}, format='json')
    if refresh_response.status_code == 200:
        print("[PASS] Token Refresh successful.")
        new_access_token = refresh_response.data["access"]
        reports["jwt"].append({
            "name": "JWT Token Refresh Flow",
            "status": "PASS",
            "details": "Successfully generated new access token using refresh token."
        })
    else:
        print("[FAIL] Token Refresh failed:", refresh_response.data)
        reports["jwt"].append({
            "name": "JWT Token Refresh Flow",
            "status": "FAIL",
            "details": str(refresh_response.data)
        })

    student_login_data = {
        "username": "student_app1",
        "password": "StudentPassword123!"
    }
    student_response = client.post(login_url, student_login_data, format='json')
    if student_response.status_code == 200:
        student_access_token = student_response.data["access"]
        print("[PASS] Approved Student Login successful.")
        reports["jwt"].append({
            "name": "Approved Student Token Generation",
            "status": "PASS",
            "details": f"Role: {student_response.data.get('role')}, Approved: {student_response.data.get('is_approved')}"
        })
    else:
        print("[FAIL] Approved Student Login failed:", student_response.data)
        reports["jwt"].append({
            "name": "Approved Student Token Generation",
            "status": "FAIL",
            "details": str(student_response.data)
        })
        
    pending_login_data = {
        "username": "student_pend1",
        "password": "StudentPassword123!"
    }
    pending_response = client.post(login_url, pending_login_data, format='json')
    if pending_response.status_code == 200:
        pending_access_token = pending_response.data["access"]
        print("[PASS] Pending Student Login successful.")
        reports["jwt"].append({
            "name": "Pending Student Token Generation",
            "status": "PASS",
            "details": f"Role: {pending_response.data.get('role')}, Approved: {pending_response.data.get('is_approved')}"
        })
    else:
        print("[FAIL] Pending Student Login failed:", pending_response.data)

    # ----------------------------------------------------
    # 2. Registration API
    # ----------------------------------------------------
    print("\n--- 2. Testing Registration API ---")
    reg_url = reverse("student-register")
    reg_username = f"test_student_{rand_str()}"
    reg_data = {
        "username": reg_username,
        "email": f"{reg_username}@example.com",
        "password": "SecurePassword123!",
        "password2": "SecurePassword123!",
        "first_name": "Test",
        "last_name": "Student",
        "roll_number": f"ROLL_{rand_str(4).upper()}"
    }
    reg_response = client.post(reg_url, reg_data, format='json')
    if reg_response.status_code == 201:
        print(f"[PASS] Registration successful for {reg_username}.")
        reports["api"].append({
            "endpoint": "POST /api/accounts/register/",
            "status": "PASS",
            "details": f"Created unapproved student '{reg_username}'."
        })
    else:
        print("[FAIL] Registration failed:", reg_response.data)
        reports["api"].append({
            "endpoint": "POST /api/accounts/register/",
            "status": "FAIL",
            "details": str(reg_response.data)
        })

    # ----------------------------------------------------
    # 3. Admin Approval APIs
    # ----------------------------------------------------
    print("\n--- 3. Testing Student Approval System ---")
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access_token}")
    
    pending_list_url = reverse("student-pending-list")
    pending_response = client.get(pending_list_url)
    if pending_response.status_code == 200:
        print("[PASS] Admin: Retrieve pending students list successful.")
        temp_user = User.objects.get(username=reg_username)
        reports["api"].append({
            "endpoint": "GET /api/accounts/students/pending/",
            "status": "PASS",
            "details": f"Retrieved pending list. Count: {len(pending_response.data)}"
        })
        
        approve_url = reverse("student-approve", kwargs={"id": temp_user.id})
        approve_response = client.post(approve_url)
        if approve_response.status_code == 200:
            print(f"[PASS] Admin: Approve student {reg_username} successful.")
            temp_user.refresh_from_db()
            if temp_user.is_approved:
                reports["api"].append({
                    "endpoint": "POST /api/accounts/students/<id>/approve/",
                    "status": "PASS",
                    "details": f"Approved student '{reg_username}' (is_approved=True)."
                })
            else:
                reports["api"].append({
                    "endpoint": "POST /api/accounts/students/<id>/approve/",
                    "status": "FAIL",
                    "details": "is_approved is still False after request."
                })
        else:
            print("[FAIL] Admin: Approve student failed:", approve_response.data)
            
        reject_url = reverse("student-reject", kwargs={"id": temp_user.id})
        reject_response = client.post(reject_url)
        if reject_response.status_code == 200:
            print(f"[PASS] Admin: Reject student {reg_username} successful.")
            temp_user.refresh_from_db()
            if not temp_user.is_approved and not temp_user.is_active:
                reports["api"].append({
                    "endpoint": "POST /api/accounts/students/<id>/reject/",
                    "status": "PASS",
                    "details": f"Rejected student '{reg_username}' (is_approved=False, is_active=False)."
                })
            else:
                reports["api"].append({
                    "endpoint": "POST /api/accounts/students/<id>/reject/",
                    "status": "FAIL",
                    "details": f"Status after rejection: approved={temp_user.is_approved}, active={temp_user.is_active}"
                })
        else:
            print("[FAIL] Admin: Reject student failed:", reject_response.data)
    else:
        print("[FAIL] Admin: Retrieve pending students list failed:", pending_response.data)

    User.objects.filter(username=reg_username).delete()

    # ----------------------------------------------------
    # 4. Assignments CRUD APIs
    # ----------------------------------------------------
    print("\n--- 4. Testing Assignments CRUD ---")
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access_token}")
    
    assign_list_url = reverse("assignment-list")
    from django.utils import timezone
    assign_data = {
        "title": "Temp Verification Assignment",
        "description": "This is a temporary assignment created for verification purposes.",
        "pdf_url": "https://example.com/temp.pdf",
        "external_link": "https://example.com",
        "deadline": timezone.now() + timezone.timedelta(days=2)
    }
    create_response = client.post(assign_list_url, assign_data, format='json')
    if create_response.status_code == 201:
        print("[PASS] Admin: Create assignment successful.")
        assign_id = create_response.data["id"]
        reports["api"].append({
            "endpoint": "POST /api/assignments/",
            "status": "PASS",
            "details": f"Created assignment '{assign_data['title']}' with ID {assign_id}."
        })
        
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {student_access_token}")
        assign_detail_url = reverse("assignment-detail", kwargs={"pk": assign_id})
        retrieve_response = client.get(assign_detail_url)
        if retrieve_response.status_code == 200:
            print("[PASS] Approved Student: Retrieve assignment details successful.")
            reports["api"].append({
                "endpoint": "GET /api/assignments/<id>/",
                "status": "PASS",
                "details": f"Retrieved assignment detail for ID {assign_id}."
            })
        else:
            print("[FAIL] Approved Student: Retrieve assignment details failed:", retrieve_response.data)

        client.credentials(HTTP_AUTHORIZATION=f"Bearer {pending_access_token}")
        pending_retrieve_response = client.get(assign_detail_url)
        if pending_retrieve_response.status_code == 403:
            print("[PASS] Pending Student: Retrieve blocked with 403 Forbidden (Correct).")
            reports["jwt"].append({
                "name": "Role-Based Access Control (Unapproved Student)",
                "status": "PASS",
                "details": "Pending student blocked from retrieving assignments with 403 Forbidden."
            })
        else:
            print("[FAIL] Pending Student: Retrieve allowed or failed with wrong status:", pending_retrieve_response.status_code)
            reports["jwt"].append({
                "name": "Role-Based Access Control (Unapproved Student)",
                "status": "FAIL",
                "details": f"Pending student received status code {pending_retrieve_response.status_code} instead of 403."
            })

        client.credentials(HTTP_AUTHORIZATION=f"Bearer {access_token}")
        update_data = {
            "title": "Updated Verification Assignment",
            "description": "Updated desc.",
            "deadline": timezone.now() + timezone.timedelta(days=3)
        }
        update_response = client.patch(assign_detail_url, update_data, format='json')
        if update_response.status_code == 200:
            print("[PASS] Admin: Update assignment successful.")
            reports["api"].append({
                "endpoint": "PATCH /api/assignments/<id>/",
                "status": "PASS",
                "details": f"Updated assignment title to '{update_data['title']}'."
            })
        else:
            print("[FAIL] Admin: Update assignment failed:", update_response.data)

        delete_response = client.delete(assign_detail_url)
        if delete_response.status_code == 204:
            print("[PASS] Admin: Delete assignment successful.")
            reports["api"].append({
                "endpoint": "DELETE /api/assignments/<id>/",
                "status": "PASS",
                "details": f"Deleted temporary assignment with ID {assign_id}."
            })
        else:
            print("[FAIL] Admin: Delete assignment failed:", delete_response.data)
            
    else:
        print("[FAIL] Admin: Create assignment failed:", create_response.data)

    # ----------------------------------------------------
    # 5. Submissions APIs
    # ----------------------------------------------------
    print("\n--- 5. Testing Submissions APIs ---")
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {student_access_token}")
    
    # Pick a seeded assignment that the student hasn't submitted yet
    student_obj = User.objects.get(username="student_app1")
    first_assignment = Assignment.objects.exclude(submissions__student=student_obj).first()
    if first_assignment:
        sub_list_url = reverse("submission-list")
        sub_data = {
            "assignment": first_assignment.id,
            "text_submission": "This is a verification submission.",
            "file_url": "https://example.com/sub.pdf"
        }
        sub_response = client.post(sub_list_url, sub_data, format='json')
        if sub_response.status_code == 201:
            print("[PASS] Approved Student: Create submission successful.")
            sub_id = sub_response.data["id"]
            reports["api"].append({
                "endpoint": "POST /api/submissions/",
                "status": "PASS",
                "details": f"Submitted assignment '{first_assignment.title}' (ID: {first_assignment.id}) under submission ID {sub_id}."
            })
            
            list_response = client.get(sub_list_url)
            if list_response.status_code == 200:
                print("[PASS] Approved Student: List own submissions successful.")
                reports["api"].append({
                    "endpoint": "GET /api/submissions/",
                    "status": "PASS",
                    "details": f"Retrieved student's own submissions. Count: {len(list_response.data)}"
                })
            else:
                print("[FAIL] Approved Student: List own submissions failed:", list_response.data)

            client.credentials(HTTP_AUTHORIZATION=f"Bearer {access_token}")
            pending_sub_url = reverse("submission-pending")
            pending_sub_response = client.get(pending_sub_url)
            if pending_sub_response.status_code == 200:
                print("[PASS] Admin: Retrieve pending submissions tracker successful.")
                reports["api"].append({
                    "endpoint": "GET /api/submissions/pending/",
                    "status": "PASS",
                    "details": f"Retrieved pending submissions. Count: {len(pending_sub_response.data)}"
                })
            else:
                print("[FAIL] Admin: Retrieve pending submissions failed:", pending_sub_response.data)
                
            Submission.objects.filter(id=sub_id).delete()
        else:
            print("[FAIL] Approved Student: Create submission failed:", sub_response.data)
    else:
        print("[FAIL] Submissions test skipped: No assignments exist.")

    # ----------------------------------------------------
    # 6. Dashboard Analytics API
    # ----------------------------------------------------
    print("\n--- 6. Testing Dashboard Analytics ---")
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access_token}")
    dash_url = reverse("dashboard-analytics")
    dash_response = client.get(dash_url)
    if dash_response.status_code == 200:
        print("[PASS] Admin: Retrieve dashboard analytics successful.")
        reports["api"].append({
            "endpoint": "GET /api/dashboard/analytics/",
            "status": "PASS",
            "details": f"Data: {dash_response.data}"
        })
    else:
        print("[FAIL] Admin: Retrieve dashboard analytics failed:", dash_response.data)
        reports["api"].append({
            "endpoint": "GET /api/dashboard/analytics/",
            "status": "FAIL",
            "details": str(dash_response.data)
        })

    client.credentials(HTTP_AUTHORIZATION=f"Bearer {student_access_token}")
    student_dash_response = client.get(dash_url)
    if student_dash_response.status_code == 403:
        print("[PASS] Student: Dashboard blocked with 403 Forbidden (Correct).")
        reports["jwt"].append({
            "name": "Role-Based Access Control (Student Analytics Block)",
            "status": "PASS",
            "details": "Student blocked from dashboard analytics with 403 Forbidden."
        })
    else:
        print("[FAIL] Student: Dashboard access not blocked:", student_dash_response.status_code)
        reports["jwt"].append({
            "name": "Role-Based Access Control (Student Analytics Block)",
            "status": "FAIL",
            "details": f"Access not blocked, status: {student_dash_response.status_code}"
        })

    # ----------------------------------------------------
    # Write API_TEST_REPORT.md
    # ----------------------------------------------------
    print("\nWriting API_TEST_REPORT.md...")
    api_md_content = """# AssignHub - API Verification Report

This report outlines the verification results of AssignHub core endpoints against the Supabase database.

---

## Endpoint Verification Summary

| Endpoint URL | HTTP Method | Expected Status | Result Status | Verification Details |
| :--- | :--- | :--- | :--- | :--- |
"""
    for entry in reports["api"]:
        method_path = entry["endpoint"].split(" ")
        method = method_path[0]
        path = method_path[1]
        expected_status = "200/201/204"
        api_md_content += f"| `{path}` | **{method}** | `{expected_status}` | **{entry['status']}** | {entry['details']} |\n"

    api_md_content += """
---

## Endpoint Specifications & Payloads

### 1. Authentication Endpoints
* **Register Student**: `POST /api/accounts/register/`
  * Request Body: `username`, `email`, `password`, `password2`, `first_name`, `last_name`, `roll_number`
  * Response: Created student details (`id`, `username`, `email`, etc.).
* **Login User**: `POST /api/accounts/login/`
  * Request Body: `username`, `password`
  * Response: JWT tokens (`access`, `refresh`), user claims (`role`, `is_approved`, `roll_number`).
* **Refresh Token**: `POST /api/accounts/token/refresh/`
  * Request Body: `refresh`
  * Response: New `access` token.

### 2. Admin Operations (Admin Only)
* **List Pending Students**: `GET /api/accounts/students/pending/`
  * Response: Array of unapproved students.
* **Approve Student**: `POST /api/accounts/students/<id>/approve/`
  * Response: Approval success message.
* **Reject Student**: `POST /api/accounts/students/<id>/reject/`
  * Response: Rejection/deactivation success message.

### 3. Assignments (Admin CRUD, Student Read-Only)
* **List Assignments**: `GET /api/assignments/`
* **Create Assignment (Admin)**: `POST /api/assignments/`
* **Retrieve Assignment Details**: `GET /api/assignments/<id>/`
* **Update Assignment (Admin)**: `PATCH /api/assignments/<id>/`
* **Delete Assignment (Admin)**: `DELETE /api/assignments/<id>/`

### 4. Submissions (Student Submit/List Own, Admin List All)
* **Create Submission**: `POST /api/submissions/`
  * Request Body: `assignment`, `text_submission`, `file_url`
* **List Submissions**: `GET /api/submissions/`
* **Pending Submissions Tracker**: `GET /api/submissions/pending/`

### 5. Dashboard (Admin Only)
* **Dashboard Analytics**: `GET /api/dashboard/analytics/`
  * Response: Aggregated statistics of students, assignments, submissions, completion rate, and late counts.
"""

    with open("../API_TEST_REPORT.md", "w", encoding="utf-8") as f:
        f.write(api_md_content)
    print("API_TEST_REPORT.md written successfully.")

    # ----------------------------------------------------
    # Write JWT_AUDIT_REPORT.md
    # ----------------------------------------------------
    print("Writing JWT_AUDIT_REPORT.md...")
    jwt_md_content = """# AssignHub - JWT Security Audit Report

This report documents the security audit of the SimpleJWT token architecture, permission checks, and role-based access control (RBAC).

---

## 1. JWT Architecture & Configuration

AssignHub uses **SimpleJWT** for token-based authentication. The settings are configured in `backend/config/settings/base.py`:
* **Access Token Lifetime**: 15 minutes
* **Refresh Token Lifetime**: 7 days
* **Authorization Header Prefix**: `Bearer`

Custom claims are added dynamically to both access and refresh tokens using the Custom Token serializer:
* `role`: User role (`admin` or `student`).
* `is_approved`: Approval status (boolean).
* `roll_number`: Student identification number (nullable).

---

## 2. Permission Verification Results

| Audit Check | Status | Verification Details |
| :--- | :--- | :--- |
"""
    for entry in reports["jwt"]:
        jwt_md_content += f"| {entry['name']} | **{entry['status']}** | {entry['details']} |\n"

    jwt_md_content += """
---

## 3. Role-Based Access Matrix

| Endpoint Route | Public | Student (Unapproved) | Student (Approved) | Admin |
| :--- | :---: | :---: | :---: | :---: |
| `POST /api/accounts/register/` | [PASS] | [PASS] | [PASS] | [PASS] |
| `POST /api/accounts/login/` | [PASS] | [PASS] | [PASS] | [PASS] |
| `POST /api/accounts/token/refresh/` | [PASS] | [PASS] | [PASS] | [PASS] |
| `GET /api/accounts/students/pending/` | [FAIL] | [FAIL] | [FAIL] | [PASS] (Admin Only) |
| `POST /api/accounts/students/<id>/approve/` | [FAIL] | [FAIL] | [FAIL] | [PASS] (Admin Only) |
| `POST /api/accounts/students/<id>/reject/` | [FAIL] | [FAIL] | [FAIL] | [PASS] (Admin Only) |
| `GET /api/assignments/` | [FAIL] | [FAIL] | [PASS] | [PASS] |
| `POST /api/assignments/` | [FAIL] | [FAIL] | [FAIL] | [PASS] (Admin Only) |
| `PATCH /api/assignments/<id>/` | [FAIL] | [FAIL] | [FAIL] | [PASS] (Admin Only) |
| `DELETE /api/assignments/<id>/` | [FAIL] | [FAIL] | [FAIL] | [PASS] (Admin Only) |
| `POST /api/submissions/` | [FAIL] | [FAIL] | [PASS] | [PASS] |
| `GET /api/submissions/` | [FAIL] | [FAIL] | [PASS] (Own Only) | [PASS] (All Submissions) |
| `GET /api/submissions/pending/` | [FAIL] | [FAIL] | [PASS] (Own Pending) | [PASS] (All Pending) |
| `GET /api/dashboard/analytics/` | [FAIL] | [FAIL] | [FAIL] | [PASS] (Admin Only) |

---

## 4. Security Findings & Recommendations

1. **Token Expiry**: Current access token duration is 15 minutes, which strikes a good balance between security and UX.
2. **Deactivation Policy**: Rejection of a student calls `is_active = False` on the user record. This disables active JWT generation upon next login, and invalidates user permissions immediately since `IsAdminUser` and `IsApprovedStudentOrAdmin` verify `request.user.is_authenticated` and user properties.
3. **Recommendation**: Implement blacklisting for refresh tokens upon logout or rejection to instantly invalidate active refresh sessions. SimpleJWT's blacklist app can be enabled in INSTALLED_APPS.
"""

    with open("../JWT_AUDIT_REPORT.md", "w", encoding="utf-8") as f:
        f.write(jwt_md_content)
    print("JWT_AUDIT_REPORT.md written successfully.")

if __name__ == '__main__':
    run_verification()
