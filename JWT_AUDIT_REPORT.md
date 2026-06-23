# AssignHub - JWT Security Audit Report

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
| Admin Login & Token Generation | **PASS** | Successfully retrieved tokens. Role claim: admin, is_approved claim: True |
| JWT Token Refresh Flow | **PASS** | Successfully generated new access token using refresh token. |
| Approved Student Token Generation | **PASS** | Role: student, Approved: True |
| Pending Student Token Generation | **PASS** | Role: student, Approved: False |
| Role-Based Access Control (Unapproved Student) | **PASS** | Pending student blocked from retrieving assignments with 403 Forbidden. |
| Role-Based Access Control (Student Analytics Block) | **PASS** | Student blocked from dashboard analytics with 403 Forbidden. |

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
