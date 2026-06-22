import os
from io import BytesIO
from services.supabase_storage import SupabaseStorageService
from dotenv import load_dotenv

# Ensure env vars are loaded
load_dotenv(".env")

def test_storage():
    print("Verifying Supabase Storage integration...")
    dummy_pdf = BytesIO(b"%PDF-1.4 dummy pdf content for verification")
    file_name = "test_verification_file.pdf"
    
    reports = []
    
    # Test 1: Upload to assignments bucket
    print("Testing upload_assignment_pdf()...")
    try:
        url = SupabaseStorageService.upload_assignment_pdf(dummy_pdf, file_name)
        print(f"[PASS] Upload successful. Public URL: {url}")
        reports.append({
            "name": "upload_assignment_pdf()",
            "status": "PASS",
            "details": f"Successfully uploaded dummy file. Public URL: {url}"
        })
    except Exception as e:
        print(f"[FAIL] Upload to assignments bucket failed: {e}")
        reports.append({
            "name": "upload_assignment_pdf()",
            "status": "FAIL",
            "details": str(e)
        })

    # Test 2: Upload to submissions bucket
    dummy_sub = BytesIO(b"dummy student submission content")
    print("Testing upload_submission_file()...")
    try:
        url = SupabaseStorageService.upload_submission_file(dummy_sub, file_name)
        print(f"[PASS] Upload successful. Public URL: {url}")
        reports.append({
            "name": "upload_submission_file()",
            "status": "PASS",
            "details": f"Successfully uploaded dummy submission. Public URL: {url}"
        })
    except Exception as e:
        print(f"[FAIL] Upload to submissions bucket failed: {e}")
        reports.append({
            "name": "upload_submission_file()",
            "status": "FAIL",
            "details": str(e)
        })

    # Write STORAGE_REPORT.md
    print("Generating STORAGE_REPORT.md...")
    md_content = f"""# AssignHub - Supabase Storage Verification Report

This report documents the verification of Supabase Storage buckets and backend upload helpers.

---

## 1. Storage Configuration

* **Supabase URL**: `{os.getenv("SUPABASE_URL")}`
* **Storage Endpoint**: `{os.getenv("SUPABASE_URL")}/storage/v1/`
* **Using Key**: {"SUPABASE_KEY" if os.getenv("SUPABASE_KEY") else "SUPABASE_ANON_KEY (Fallback)"}

---

## 2. Bucket Verification Results

| Helper Function | Target Bucket | Verification Status | Details / Public Link |
| :--- | :--- | :--- | :--- |
"""
    for r in reports:
        bucket = "assignments" if "assignment" in r["name"] else "submissions"
        md_content += f"| `{r['name']}` | `{bucket}` | **{r['status']}** | {r['details']} |\n"

    md_content += """
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
"""
    with open("../STORAGE_REPORT.md", "w", encoding="utf-8") as f:
        f.write(md_content)
    print("STORAGE_REPORT.md generated successfully.")

if __name__ == '__main__':
    test_storage()
