# AssignHub - Frontend Integration Guide

This guide provides frontend developers with detailed documentation for authenticating and integrating with the AssignHub Django REST API.

---

## 1. Authentication & JWT Flow

AssignHub uses JWT (JSON Web Tokens) for security. 
* All protected endpoints expect an `Authorization` header containing the access token as a bearer token:
  ```http
  Authorization: Bearer <access_token>
  ```
* Access tokens are short-lived (15 minutes). When an access token expires, request a new one using the long-lived refresh token (7 days).

### Authentication State Machine:
1. **Register**: Student registers via `/api/accounts/register/`. The student is created with `is_approved = False`.
2. **Login**: Student/Admin logs in via `/api/accounts/login/` and gets `access` and `refresh` tokens.
3. **Pending Approval**: If a student is unapproved, they can log in but will receive `403 Forbidden` on assignments and submissions endpoints.
4. **Approve**: An admin approves the student. Now the student has full access.

---

## 2. API Endpoint Directory

| Endpoint | Method | Auth Required | Role Required | Description |
| :--- | :---: | :---: | :---: | :--- |
| `/api/accounts/register/` | `POST` | No | Public | Register a new student account |
| `/api/accounts/login/` | `POST` | No | Public | Obtain JWT Access & Refresh tokens |
| `/api/accounts/token/refresh/` | `POST` | No | Public | Refresh expired access token |
| `/api/accounts/students/` | `GET` | Yes | Admin | List all registered students |
| `/api/accounts/students/pending/` | `GET` | Yes | Admin | List all pending student approvals |
| `/api/accounts/students/<id>/approve/` | `POST` | Yes | Admin | Approve a pending student |
| `/api/accounts/students/<id>/reject/` | `POST` | Yes | Admin | Reject & deactivate a student |
| `/api/assignments/` | `GET` | Yes | Approved student or Admin | List all assignments (descending order) |
| `/api/assignments/` | `POST` | Yes | Admin | Create a new assignment |
| `/api/assignments/<id>/` | `GET` | Yes | Approved student or Admin | Retrieve single assignment details |
| `/api/assignments/<id>/` | `PUT`/`PATCH` | Yes | Admin | Update an assignment |
| `/api/assignments/<id>/` | `DELETE` | Yes | Admin | Delete an assignment |
| `/api/submissions/` | `GET` | Yes | Approved student or Admin | List submissions (Student: own; Admin: all) |
| `/api/submissions/` | `POST` | Yes | Approved student | Submit solution for an assignment |
| `/api/submissions/pending/` | `GET` | Yes | Approved student or Admin | Track pending submissions |
| `/api/dashboard/analytics/` | `GET` | Yes | Admin | Get administrative dashboard metrics |

---

## 3. Request & Response Examples

### 3.1 Student Registration
* **Endpoint**: `/api/accounts/register/`
* **Method**: `POST`
* **Request Payload**:
  ```json
  {
    "username": "johndoe",
    "email": "johndoe@example.com",
    "password": "SecurePassword123!",
    "password2": "SecurePassword123!",
    "first_name": "John",
    "last_name": "Doe",
    "roll_number": "CS2026_042"
  }
  ```
* **Response (201 Created)**:
  ```json
  {
    "id": 12,
    "username": "johndoe",
    "email": "johndoe@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "roll_number": "CS2026_042"
  }
  ```

### 3.2 User Login
* **Endpoint**: `/api/accounts/login/`
* **Method**: `POST`
* **Request Payload**:
  ```json
  {
    "username": "johndoe",
    "password": "SecurePassword123!"
  }
  ```
* **Response (200 OK)**:
  ```json
  {
    "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "role": "student",
    "is_approved": false,
    "roll_number": "CS2026_042"
  }
  ```

### 3.3 Token Refresh
* **Endpoint**: `/api/accounts/token/refresh/`
* **Method**: `POST`
* **Request Payload**:
  ```json
  {
    "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```
* **Response (200 OK)**:
  ```json
  {
    "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```

### 3.4 Student Approval (Admin Only)
* **Endpoint**: `/api/accounts/students/12/approve/`
* **Method**: `POST`
* **Response (200 OK)**:
  ```json
  {
    "detail": "Student johndoe approved successfully."
  }
  ```

### 3.5 Submit Assignment (Approved Student Only)
* **Endpoint**: `/api/submissions/`
* **Method**: `POST`
* **Request Payload**:
  ```json
  {
    "assignment": 2,
    "text_submission": "Here is my code implementation for Django models.",
    "file_url": "https://nlmofhlhbsnqftoiyoqh.supabase.co/storage/v1/object/public/submissions/sub_johndoe_2.pdf"
  }
  ```
* **Response (201 Created)**:
  ```json
  {
    "id": 21,
    "assignment": 2,
    "student": 12,
    "file_url": "https://nlmofhlhbsnqftoiyoqh.supabase.co/storage/v1/object/public/submissions/sub_johndoe_2.pdf",
    "text_submission": "Here is my code implementation for Django models.",
    "submitted_at": "2026-06-22T04:47:33Z",
    "status": "pending",
    "is_late": false
  }
  ```

### 3.6 Dashboard Metrics (Admin Only)
* **Endpoint**: `/api/dashboard/analytics/`
* **Method**: `GET`
* **Response (200 OK)**:
  ```json
  {
    "total_students": 10,
    "pending_approvals": 5,
    "total_assignments": 10,
    "total_submissions": 20,
    "completion_percentage": 40.0,
    "late_submissions": 8
  }
  ```

---

## 4. Error Handling & Formats

API errors utilize standard HTTP status codes:
* **400 Bad Request**: Invalid inputs or failed validation (e.g. password mismatch or duplicate roll number).
  ```json
  {
    "roll_number": ["custom user with this roll number already exists."]
  }
  ```
* **401 Unauthorized**: Missing or expired access token.
  ```json
  {
    "detail": "Given token not valid for any token type",
    "code": "token_not_valid",
    "messages": [
      {
        "token_class": "AccessToken",
        "token_type": "access",
        "message": "Token is invalid or expired"
      }
    ]
  }
  ```
* **403 Forbidden**: Token valid but user lacks required role/approval (e.g. unapproved student listing assignments).
  ```json
  {
    "detail": "You do not have permission to perform this action."
  }
  ```
* **404 Not Found**: Resource (assignment, student, submission) does not exist.
  ```json
  {
    "detail": "Not found."
  }
  ```

---

## 5. JSON Schemas for Key Endpoints

### Student Registration JSON Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "StudentRegistration",
  "type": "object",
  "properties": {
    "username": { "type": "string", "minLength": 3, "maxLength": 150 },
    "email": { "type": "string", "format": "email" },
    "password": { "type": "string", "minLength": 8 },
    "password2": { "type": "string", "minLength": 8 },
    "first_name": { "type": "string", "maxLength": 150 },
    "last_name": { "type": "string", "maxLength": 150 },
    "roll_number": { "type": "string", "maxLength": 32 }
  },
  "required": ["username", "email", "password", "password2", "roll_number"]
}
```

### Assignment Creation JSON Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AssignmentCreation",
  "type": "object",
  "properties": {
    "title": { "type": "string", "maxLength": 255 },
    "description": { "type": "string" },
    "pdf_url": { "type": "string", "format": "uri" },
    "external_link": { "type": "string", "format": "uri" },
    "deadline": { "type": "string", "format": "date-time" }
  },
  "required": ["title", "description", "deadline"]
}
```
