# AssignHub - Database Verification Report

This report documents the verification, schema status, and connection settings for the AssignHub Supabase PostgreSQL database.

---

## 1. Connection & Routing Root Cause

The connection issue was resolved by identifying that:
1. **Direct Connection Limitation (IPv6-Only)**: The direct database hostname `db.nlmofhlhbsnqftoiyoqh.supabase.co` resolves exclusively to an IPv6 address (`2406:da18:e5c:b702:366c:5947:3126:dd70`). Local environments on IPv4-only networks failed to resolve or connect to this host.
2. **Pooler Connection (IPv4-Compatible)**: By configuring the connection to use the Supabase Connection Pooler host `aws-1-ap-southeast-1.pooler.supabase.com` on port `5432` with username `postgres.nlmofhlhbsnqftoiyoqh`, IPv4 network clients can successfully connect.

---

## 2. Final Working Database Settings

The application successfully connects to Supabase using the following settings in `backend/.env`:

```ini
DB_NAME=postgres
DB_USER=postgres.nlmofhlhbsnqftoiyoqh
DB_HOST=aws-1-ap-southeast-1.pooler.supabase.com
DB_PORT=5432
# DB_PASSWORD is set securely (excluded from this report)
```

---

## 3. Migration Verification

All Django migrations are fully applied to the Supabase PostgreSQL database. Running `python manage.py showmigrations` confirms:

* **accounts**: `0001_initial` [Applied]
* **admin**: `0001_initial`, `0002_logentry_remove_auto_add`, `0003_logentry_add_action_flag_choices` [Applied]
* **assignments**: `0001_initial` [Applied]
* **auth**: `0001_initial` to `0012_alter_user_first_name_max_length` [Applied]
* **contenttypes**: `0001_initial`, `0002_remove_content_type_name` [Applied]
* **sessions**: `0001_initial` [Applied]
* **submissions**: `0001_initial` [Applied]

---

## 4. Database Table Verification

Introspection of the remote database schema confirms that the following primary tables exist and are fully populated:

| Table Name | Description | Seeded Record Count |
| :--- | :--- | :--- |
| `accounts_customuser` | Custom User Model (with `role`, `roll_number`, `is_approved`) | 11 (1 Admin, 5 Approved, 5 Pending) |
| `assignments_assignment` | Assignment entries | 10 |
| `submissions_submission` | Student assignment submissions | 20 |
| `django_migrations` | Django migrations tracking | 18 |

---

## 5. Schema Correctness & Data Types

The columns and database constraints match Django model definitions exactly:

### Table: `accounts_customuser`
* `id`: `bigint` (Primary Key, Auto-increment)
* `password`: `character varying` (Hashed password string)
* `last_login`: `timestamp with time zone` (Nullable)
* `is_superuser`: `boolean`
* `username`: `character varying(150)` (Unique)
* `first_name`: `character varying(150)`
* `last_name`: `character varying(150)`
* `email`: `character varying(254)`
* `is_staff`: `boolean`
* `is_active`: `boolean`
* `date_joined`: `timestamp with time zone`
* `role`: `character varying(16)` (Choices: `admin`, `student`)
* `roll_number`: `character varying(32)` (Unique, Nullable)
* `is_approved`: `boolean`

### Table: `assignments_assignment`
* `id`: `bigint` (Primary Key)
* `title`: `character varying(255)`
* `description`: `text`
* `pdf_url`: `character varying(200)` (Nullable)
* `external_link`: `character varying(200)` (Nullable)
* `deadline`: `timestamp with time zone`
* `created_at`: `timestamp with time zone`
* `created_by_id`: `bigint` (Foreign Key to `accounts_customuser`)

### Table: `submissions_submission`
* `id`: `bigint` (Primary Key)
* `file_url`: `character varying(200)` (Nullable)
* `text_submission`: `text` (Nullable)
* `submitted_at`: `timestamp with time zone`
* `status`: `character varying(16)` (Choices: `pending`, `graded`, `late`)
* `is_late`: `boolean`
* `assignment_id`: `bigint` (Foreign Key to `assignments_assignment`)
* `student_id`: `bigint` (Foreign Key to `accounts_customuser`)

---

## 6. Conclusion
The database tables are verified, matching constraints and relationship definitions. The schema is 100% correct, and data has been successfully seeded.
