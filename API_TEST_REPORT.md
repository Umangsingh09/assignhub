# AssignHub - API Verification Report

This report outlines the verification results of AssignHub core endpoints against the Supabase database.

---

## Endpoint Verification Summary

| Endpoint URL | HTTP Method | Expected Status | Result Status | Verification Details |
| :--- | :--- | :--- | :--- | :--- |
| `/api/accounts/register/` | **POST** | `200/201/204` | **PASS** | Created unapproved student 'test_student_635016'. |
| `/api/accounts/students/pending/` | **GET** | `200/201/204` | **PASS** | Retrieved pending list. Count: 6 |
| `/api/accounts/students/<id>/approve/` | **POST** | `200/201/204` | **PASS** | Approved student 'test_student_635016' (is_approved=True). |
| `/api/accounts/students/<id>/reject/` | **POST** | `200/201/204` | **PASS** | Rejected student 'test_student_635016' (is_approved=False, is_active=False). |
| `/api/assignments/` | **POST** | `200/201/204` | **PASS** | Created assignment 'Temp Verification Assignment' with ID 12. |
| `/api/assignments/<id>/` | **GET** | `200/201/204` | **PASS** | Retrieved assignment detail for ID 12. |
| `/api/assignments/<id>/` | **PATCH** | `200/201/204` | **PASS** | Updated assignment title to 'Updated Verification Assignment'. |
| `/api/assignments/<id>/` | **DELETE** | `200/201/204` | **PASS** | Deleted temporary assignment with ID 12. |
| `/api/submissions/` | **POST** | `200/201/204` | **PASS** | Submitted assignment 'Supabase Storage Integration' (ID: 5) under submission ID 21. |
| `/api/submissions/` | **GET** | `200/201/204` | **PASS** | Retrieved student's own submissions. Count: 5 |
| `/api/submissions/pending/` | **GET** | `200/201/204` | **PASS** | Retrieved pending submissions. Count: 2 |
| `/api/dashboard/analytics/` | **GET** | `200/201/204` | **PASS** | Data: {'total_students': 10, 'pending_approvals': 5, 'total_assignments': 10, 'total_submissions': 20, 'completion_percentage': 40.0, 'late_submissions': 14} |

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
