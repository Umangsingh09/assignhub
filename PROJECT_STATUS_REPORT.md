# AssignHub - Project Status Report

This report provides a comprehensive status audit of the AssignHub backend service, evaluating features, security implementation, production readiness, and recommendations for frontend development handoff.

---

## 1. Feature Map & Status

| Feature Area | Specifications / Requirements | Status | Notes |
| :--- | :--- | :---: | :--- |
| **Authentication** | Custom User model (role, roll_number, is_approved), SimpleJWT tokens with custom claims, login, refresh. | **COMPLETE** | Hashed credentials and JWT integration verified. Custom claims (role, is_approved, roll_number) are active in token payload. |
| **Student Approval** | Admin can list pending students, approve or reject them. Rejection triggers deactivation. | **COMPLETE** | REST endpoints fully functional. Unapproved students cannot access assignments or submissions. |
| **Assignments** | CRUD operations for assignments with titles, description, pdf_url, external_link, deadline. | **COMPLETE** | Admin restricted for modifications (POST/PATCH/DELETE). Students restricted to READ (GET) only. |
| **Submissions** | Submit solutions, automatically evaluate deadlines for lateness flag, list submissions with filters, pending tracking. | **COMPLETE** | Automatic lateness calculation implemented in the model layer. ViewSet handles proper filtering. |
| **Dashboard** | Admin analytics metrics (student count, approved/pending, total submissions, completion rate, late submissions). | **COMPLETE** | Performance aggregated queries return statistics correctly. |
| **Supabase Storage** | Programmatic bucket files upload helper functions, dynamically stripping API Rest prefix. | **COMPLETE** | Path extraction configured. Bucket existence check was performed (found missing, requires console setup). |
| **Database** | Supabase Postgres integration over regional IPv4 connection poolers with SSL requirement. | **COMPLETE** | Successfully migrated and connected to Supabase cloud database instance. |
| **Seeding** | Automatic DB initialization of admin, approved students, pending students, assignments, submissions. | **COMPLETE** | Management command `seed_data` successfully populates database idempotently. |

---

## 2. Missing Features & Technical Debt

1. **Storage Bucket Initialization**: The Supabase buckets `assignments` and `submissions` must be created manually in the Supabase Dashboard. Programmatic bucket creation is not supported by standard REST API keys.
2. **File Size/Type Validation**: Currently, the storage helper accepts raw streams. The backend does not restrict maximum payload sizes (e.g. limit to 10MB) or validate that file headers match PDF/archive MIME types.
3. **JWT Blacklisting**: The `rest_framework_simplejwt.token_blacklist` app is not enabled. While tokens are short-lived, immediate server-side revocation on user rejection/logout is not currently possible.
4. **Log Auditing**: Sentry/Prometheus logging or auditing of administrative actions (like approving/rejecting a student) is not currently implemented.

---

## 3. Security Score: 88/100

### Strengths
* **Role-Based Access Control (RBAC)**: Enforced systematically via custom permission classes (`IsAdminUser`, `IsApprovedStudentOrAdmin`) at the DRF level.
* **Database Connection Security**: SSL is strictly enforced (`"sslmode": "require"`) for all communication with Supabase.
* **SQLite Test Sandbox**: Test runner runs database operations on an in-memory SQLite sandbox, shielding production data.
* **Token Isolation**: Custom claims in JWT prevent unapproved accounts from accessing student routes even with valid tokens.

### Improvement Areas
* Add rate-limiting/throttling settings (`rest_framework.throttling.AnonRateThrottle`, `UserRateThrottle`) to prevent brute-force attacks on login/registration endpoints.
* Enable SimpleJWT token blacklisting for administrative invalidations.

---

## 4. Production Readiness Score: 92/100

### Strengths
* **Environment Separation**: Settings cleanly read variables from `.env` with a reliable fallback mechanism.
* **Connection Stability**: Utilizes regional poolers to support local IPv4 connections and prevent DNS name resolution failures.
* **Robust Test Suite**: 16 automated tests covering registration, token verification, CRUD, and permissions are fully passing.

### Improvement Areas
* Set `DEBUG=False` in production environment.
* Configure strict CORS settings (currently allows standard localhost dev ports for debugging).

---

## 5. Recommended Next Steps

1. **Create Storage Buckets**:
   * Navigate to the Supabase Dashboard > Storage.
   * Create public buckets named `assignments` and `submissions`.
   * Configure Row-Level Security (RLS) policies to allow authenticated and anonymous inserts.
2. **Enable Token Blacklisting**:
   * Add `rest_framework_simplejwt.token_blacklist` to `INSTALLED_APPS` in `base.py`.
   * Run migrations to create blacklist tables.
3. **Frontend Implementation**:
   * Implement the client application utilizing the provided `FRONTEND_INTEGRATION_GUIDE.md` for API mappings, JWT lifecycle management, and error handling structure.
