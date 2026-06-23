# AssignHub - Supabase Storage Verification Report

This report documents the verification of Supabase Storage buckets and backend upload helpers.

---

## 1. Storage Configuration

* **Supabase URL**: `https://nlmofhlhbsnqftoiyoqh.supabase.co`
* **Storage Endpoint**: `https://nlmofhlhbsnqftoiyoqh.supabase.co/storage/v1/`
* **Using Key**: SUPABASE_ANON_KEY (Fallback)

---

## 2. Bucket Verification Results

| Helper Function | Target Bucket | Verification Status | Details / Public Link |
| :--- | :--- | :--- | :--- |
| `upload_assignment_pdf()` | `assignments` | **PASS** | Successfully uploaded dummy file. Public URL: https://nlmofhlhbsnqftoiyoqh.supabase.co/storage/v1/object/public/assignments/test_verification_file.pdf |
| `upload_submission_file()` | `submissions` | **PASS** | Successfully uploaded dummy submission. Public URL: https://nlmofhlhbsnqftoiyoqh.supabase.co/storage/v1/object/public/submissions/test_verification_file.pdf |

---

## 3. Storage Security & RLS Policies Recommendations

For public read and restricted write operations (uploads from backend), ensure the following policies are configured in the Supabase Dashboard:

### Bucket: `assignments`
* **Visibility**: Public (so PDF files can be loaded by students)
* **Allowed Operations**: `INSERT`, `SELECT`
* **Allowed Roles**: `anon`, `authenticated` (required if uploading via anon or service keys)

### Bucket: `submissions`
* **Visibility**: Public
* **Allowed Operations**: `INSERT`, `SELECT`
* **Allowed Roles**: `anon`, `authenticated`
