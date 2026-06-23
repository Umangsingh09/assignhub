# AssignHub Backend

AssignHub is a robust, production-grade learning management backend built using Django, Django REST Framework (DRF), and PostgreSQL/Supabase. It features an automated student registration and approval system, role-based access control, assignment tracking, student submissions with late detection, dashboard analytics, and Supabase cloud storage integration.

---

## Technical Stack

- **Core Framework**: Django 6.0 & Django REST Framework (DRF)
- **Database**: PostgreSQL (configured for Supabase in production/Docker, SQLite in local development fallback)
- **Authentication**: JWT authentication using SimpleJWT
- **Cloud Storage**: Supabase Storage REST API Integration (via `requests`)
- **DevOps**: Docker, Docker Compose, GitHub Actions CI Pipeline

---

## Quick Setup Guide

### Local Development

1. **Clone and navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Set up Virtual Environment**:
   ```bash
   python -m venv venv
   # On Windows:
   .\venv\Scripts\activate
   # On Linux/macOS:
   source venv/bin/activate
   ```

3. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up Environment Variables**:
   Create a `.env` file in the `backend/` directory by copying `.env.example`:
   ```bash
   cp .env.example .env
   ```
   Fill in the `SUPABASE_URL` and `SUPABASE_KEY` (service role key) and PostgreSQL credentials as necessary.

5. **Run Migrations & Start Development Server**:
   ```bash
   python manage.py migrate
   python manage.py runserver
   ```
   The backend will be available at `http://127.0.0.1:8000/`.

6. **Create a Superuser (Admin)**:
   ```bash
   python manage.py createsuperuser
   ```

---

## Docker Deployment

You can spin up the application along with a PostgreSQL database locally using Docker Compose.

From the workspace root:
```bash
# Build and start services
docker-compose up --build -d

# Check logs
docker-compose logs -f web

# Run migrations inside the docker container (runs automatically, but can run manually)
docker-compose exec web python manage.py migrate

# Create a superuser inside the docker container
docker-compose exec web python manage.py createsuperuser
```

---

## API Documentation

### Authentication & Profiles

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/accounts/register/` | Register as a student (starts as unapproved) | Public |
| `POST` | `/api/accounts/login/` | Obtain JWT Access and Refresh Tokens | Public |
| `POST` | `/api/accounts/token/refresh/` | Refresh expired JWT Access Token | Public |
| `GET` | `/api/accounts/students/pending/` | List all unapproved student accounts | Admin Only |
| `POST` | `/api/accounts/students/<id>/approve/` | Approve student account (activates student) | Admin Only |
| `POST` | `/api/accounts/students/<id>/reject/` | Reject student account (deactivates student) | Admin Only |

### Assignments Management

*Note: Unapproved student accounts are completely blocked from accessing these endpoints.*

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/assignments/` | List all assignments | Approved Student & Admin |
| `POST` | `/api/assignments/` | Create a new assignment | Admin Only |
| `GET` | `/api/assignments/<id>/` | Retrieve assignment details | Approved Student & Admin |
| `PUT`/`PATCH` | `/api/assignments/<id>/` | Modify assignment details | Admin Only |
| `DELETE` | `/api/assignments/<id>/` | Delete an assignment | Admin Only |

### Submissions Management

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/submissions/` | Submit assignment (checks deadlines & duplication) | Approved Student Only |
| `GET` | `/api/submissions/` | List submissions (Student sees own, Admin sees all) | Approved Student & Admin |
| `GET` | `/api/submissions/pending/` | View pending (ungraded) submissions | Approved Student & Admin |

### Dashboard Analytics

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/dashboard/analytics/` | View metrics (student count, approvals, late subs, completion rate) | Admin Only |

---

## Postman Integration

A Postman collection is supplied in the project root: `AssignHub.postman_collection.json`.
1. Open Postman.
2. Click **Import** and select the file.
3. Configure the environment variables (`base_url`, `token`, `refresh_token`). Logins will automatically save access tokens to the environment context.

---

## Running Tests

Verify code changes using Django's built-in testing commands:
```bash
python manage.py test
```
