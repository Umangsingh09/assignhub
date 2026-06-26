# 📚 AssignHub

> A secure, role-based assignment management platform built for educational institutions, coaching centers, and hiring assessments.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Django](https://img.shields.io/badge/Django-4.2-green)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-success)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## 🚀 Overview

AssignHub is a modern assignment management system that provides **admin-controlled access** to assignments.

Unlike traditional LMS platforms, students **cannot access assignments immediately after registration**. Every student must first be approved by the administrator before accessing the platform.

This makes AssignHub ideal for:

- 🏫 Colleges
- 📖 Coaching Institutes
- 👨‍🏫 Private Tutors
- 💼 Hiring & Assessment Platforms

---

# ✨ Features

## 👨‍💼 Admin

- Secure JWT Login
- Student Approval/Rejection
- Upload Assignments
- PDF/File Support
- Assignment Deadlines
- View Student Submissions
- Dashboard Analytics
- Completion Tracking
- Late Submission Tracking

---

## 👨‍🎓 Student

- Register Account
- Wait for Admin Approval
- Secure Login
- View Assignments
- Download Assignment PDFs
- Upload Assignment Submission
- Submission History

---

## 🔒 Security

- JWT Authentication
- Role-Based Access Control (RBAC)
- Protected APIs
- Secure Password Storage
- Supabase PostgreSQL
- Supabase Storage Integration

---

# 🛠 Tech Stack

### Frontend

- Flutter
- Riverpod
- Dio
- Go Router
- Flutter Secure Storage

### Backend

- Django
- Django REST Framework
- Simple JWT
- PostgreSQL
- Supabase Storage

### Database

- Supabase PostgreSQL

### Storage

- Supabase Storage

---

# 📂 Project Structure

```
assignhub/

│
├── backend/
│   ├── accounts/
│   ├── assignments/
│   ├── submissions/
│   ├── config/
│   └── services/
│
├── frontend_flutter/
│
├── README.md
└── docker-compose.yml
```

---

# ⚙️ Installation

## Clone Repository

```bash
git clone https://github.com/Umangsingh09/assignhub.git
```

```
cd assignhub
```

---

## Backend Setup

```
cd backend
```

Create Virtual Environment

```
python -m venv venv
```

Activate

Windows

```
venv\Scripts\activate
```

Install Dependencies

```
pip install -r requirements.txt
```

Run Migrations

```
python manage.py migrate
```

Start Server

```
python manage.py runserver
```

---

## Flutter Frontend

```
cd frontend_flutter
```

Install Packages

```
flutter pub get
```

Run

```
flutter run
```

---

# 🔑 Environment Variables

Create a `.env` file inside the backend folder.

Example:

```
SECRET_KEY=your_secret_key

DEBUG=True

DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your_password
DB_HOST=your_host
DB_PORT=5432

SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_key
```

---

# 📊 Core Workflow

```
Student Register
        │
        ▼
Pending Approval
        │
        ▼
Admin Approves
        │
        ▼
Student Login
        │
        ▼
View Assignments
        │
        ▼
Submit Assignment
        │
        ▼
Admin Reviews Submission
```

---

# 📸 Screens

- Login
- Register
- Pending Approval
- Admin Dashboard
- Student Dashboard
- Assignment Upload
- Assignment Submission
- Analytics Dashboard

---

# 🚀 Future Improvements

- Push Notifications
- Email Notifications
- AI Assignment Evaluation
- Plagiarism Detection
- Calendar Integration
- Real-time Chat
- Dark/Light Themes
- Attendance Module

---

# 👥 Team

**Umang Raj**  Backend Developer • Project Lead
**Hariom Singh** backend
**Aditya Kumar** database
**Raja Kumar**   frontend



---

# 🏆 Hackathon Project

Built for **DevFusion 3.0 - Developers Hackathon**

---

# 📄 License

This project is released under the MIT License.
