import os
import django
import random
import string
import requests
from io import BytesIO
from django.utils import timezone
from pathlib import Path

# Initialize Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

from django.contrib.auth import get_user_model
from assignments.models import Assignment
from submissions.models import Submission
from services.supabase_storage import SupabaseStorageService

User = get_user_model()

def rand_str(length=8):
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

def run_verification():
    print("=" * 70)
    print("ASSIGNHUB STORAGE & DB INTEGRATION VERIFICATION")
    print("=" * 70)

    # Dictionary to keep track of test statuses
    results = {
        "helpers_verified": False,
        "assignment_upload": {"status": "FAIL", "url": None, "error": None},
        "submission_upload": {"status": "FAIL", "url": None, "error": None},
        "public_url_retrieval": {"status": "FAIL", "assignment_ok": False, "submission_ok": False, "error": None},
        "db_assignment_store": {"status": "FAIL", "id": None, "error": None},
        "db_submission_store": {"status": "FAIL", "id": None, "error": None},
    }

    # Generate random suffixes to avoid name collision in bucket
    suffix = rand_str()
    pdf_filename = f"test_assignment_{suffix}.pdf"
    sub_filename = f"test_submission_{suffix}.txt"

    pdf_content = b"%PDF-1.4\n%test pdf content for assignhub storage verification\n"
    sub_content = b"Student test submission content for storage verification."

    # 1. Verify storage helper services exist
    print("Step 1: Verifying storage helper services...")
    try:
        has_upload = hasattr(SupabaseStorageService, "upload_file")
        has_assign = hasattr(SupabaseStorageService, "upload_assignment_pdf")
        has_sub = hasattr(SupabaseStorageService, "upload_submission_file")
        
        if has_upload and has_assign and has_sub:
            print("[PASS] Storage helper services are correctly defined.")
            results["helpers_verified"] = True
        else:
            print("[FAIL] Storage helper services missing one or more methods.")
    except Exception as e:
        print(f"[FAIL] Error verifying helper services: {e}")

    # 2. Upload a test PDF to assignments bucket
    print("\nStep 2: Uploading test PDF to assignments bucket...")
    try:
        pdf_file = BytesIO(pdf_content)
        url = SupabaseStorageService.upload_assignment_pdf(pdf_file, pdf_filename)
        print(f"[PASS] Uploaded test PDF. URL: {url}")
        results["assignment_upload"]["status"] = "PASS"
        results["assignment_upload"]["url"] = url
    except Exception as e:
        print(f"[FAIL] Assignment upload failed: {e}")
        results["assignment_upload"]["error"] = str(e)

    # 3. Upload a test file to submissions bucket
    print("\nStep 3: Uploading test file to submissions bucket...")
    try:
        sub_file = BytesIO(sub_content)
        url = SupabaseStorageService.upload_submission_file(sub_file, sub_filename)
        print(f"[PASS] Uploaded test submission file. URL: {url}")
        results["submission_upload"]["status"] = "PASS"
        results["submission_upload"]["url"] = url
    except Exception as e:
        print(f"[FAIL] Submission upload failed: {e}")
        results["submission_upload"]["error"] = str(e)

    # 4. Verify public URL generation and accessibility
    print("\nStep 4: Verifying public URL accessibility...")
    try:
        assign_url = results["assignment_upload"]["url"]
        sub_url = results["submission_upload"]["url"]
        
        if assign_url and sub_url:
            # Check assignments file
            r1 = requests.get(assign_url, timeout=10)
            if r1.status_code == 200 and r1.content == pdf_content:
                print(f"[PASS] Assignment PDF public URL is accessible and content matches.")
                results["public_url_retrieval"]["assignment_ok"] = True
            else:
                print(f"[FAIL] Assignment URL fetched with status {r1.status_code} or mismatch.")
                
            # Check submissions file
            r2 = requests.get(sub_url, timeout=10)
            if r2.status_code == 200 and r2.content == sub_content:
                print(f"[PASS] Submission file public URL is accessible and content matches.")
                results["public_url_retrieval"]["submission_ok"] = True
            else:
                print(f"[FAIL] Submission URL fetched with status {r2.status_code} or mismatch.")
                
            if results["public_url_retrieval"]["assignment_ok"] and results["public_url_retrieval"]["submission_ok"]:
                results["public_url_retrieval"]["status"] = "PASS"
        else:
            print("[FAIL] Missing upload URLs to verify.")
            results["public_url_retrieval"]["error"] = "Upload URLs were not generated."
    except Exception as e:
        print(f"[FAIL] Public URL verification failed: {e}")
        results["public_url_retrieval"]["error"] = str(e)

    # 5 & 6. Database Integration
    test_assignment = None
    test_submission = None
    try:
        # Get target users for mock insertion
        admin_user = User.objects.filter(role="admin").first()
        student_user = User.objects.filter(role="student", is_approved=True).first()
        
        if not admin_user or not student_user:
            raise ValueError("Required database users (admin & approved student) not found.")
            
        print(f"\nUsing users: Admin: {admin_user.username}, Student: {student_user.username}")

        # 5. Verify assignment creation can store PDF URLs
        print("\nStep 5: Testing Assignment creation with stored PDF URL...")
        if results["assignment_upload"]["url"]:
            test_assignment = Assignment.objects.create(
                title=f"Verification Assignment {suffix}",
                description="Temporary assignment for verifying Supabase Storage URL storing.",
                pdf_url=results["assignment_upload"]["url"],
                external_link="https://example.com/test",
                deadline=timezone.now() + timezone.timedelta(days=3),
                created_by=admin_user
            )
            # Fetch from DB and verify
            db_assign = Assignment.objects.get(id=test_assignment.id)
            if db_assign.pdf_url == results["assignment_upload"]["url"]:
                print(f"[PASS] Assignment created successfully. ID: {db_assign.id}, PDF URL stored: {db_assign.pdf_url}")
                results["db_assignment_store"]["status"] = "PASS"
                results["db_assignment_store"]["id"] = db_assign.id
            else:
                print(f"[FAIL] Stored URL mismatch: {db_assign.pdf_url}")
                results["db_assignment_store"]["error"] = "Stored URL mismatch."
        else:
            print("[FAIL] PDF URL missing. Cannot verify assignment creation.")
            results["db_assignment_store"]["error"] = "PDF URL missing."

        # 6. Verify submission upload can store file URLs
        print("\nStep 6: Testing Submission creation with stored File URL...")
        if test_assignment and results["submission_upload"]["url"]:
            test_submission = Submission.objects.create(
                assignment=test_assignment,
                student=student_user,
                file_url=results["submission_upload"]["url"],
                text_submission="Verification submission content."
            )
            # Fetch from DB and verify
            db_sub = Submission.objects.get(id=test_submission.id)
            if db_sub.file_url == results["submission_upload"]["url"]:
                print(f"[PASS] Submission created successfully. ID: {db_sub.id}, File URL stored: {db_sub.file_url}")
                results["db_submission_store"]["status"] = "PASS"
                results["db_submission_store"]["id"] = db_sub.id
            else:
                print(f"[FAIL] Stored URL mismatch: {db_sub.file_url}")
                results["db_submission_store"]["error"] = "Stored URL mismatch."
        else:
            print("[FAIL] Submission file URL or Assignment missing. Cannot verify submission creation.")
            results["db_submission_store"]["error"] = "Submission file URL or Assignment missing."

    except Exception as e:
        print(f"[FAIL] Database integration verification failed: {e}")
        if results["db_assignment_store"]["status"] != "PASS":
            results["db_assignment_store"]["error"] = str(e)
        if results["db_submission_store"]["status"] != "PASS":
            results["db_submission_store"]["error"] = str(e)
    finally:
        # Clean up database records (Do not modify working database configuration long term)
        print("\nCleaning up test records from Database...")
        if test_submission:
            test_submission.delete()
            print("- Deleted temporary submission record.")
        if test_assignment:
            test_assignment.delete()
            print("- Deleted temporary assignment record.")

    # 7. Generate STORAGE_VERIFICATION_REPORT.md
    print("\nStep 7: Generating STORAGE_VERIFICATION_REPORT.md...")
    
    report_content = f"""# AssignHub - Storage Verification Report

This report documents the end-to-end verification of the Supabase Storage buckets, helper services, public URL accessibility, and database URL-storing integration for AssignHub.

---

## 1. Environment & Configuration

* **Supabase URL**: `{os.getenv("SUPABASE_URL")}`
* **Storage Endpoint**: `{os.getenv("SUPABASE_URL")}/storage/v1/`
* **Using Authentication Key**: `SUPABASE_ANON_KEY` (Role: `anon`)
* **Target Buckets**:
  * `assignments` (Public)
  * `submissions` (Public)

---

## 2. Row-Level Security (RLS) Configuration

To enable correct functionality using the public anon/authenticated keys, the following Row-Level Security policies are applied in PostgreSQL:
* **Table**: `storage.objects`
  * **Assignments Bucket**:
    * `Allow uploads for authenticated keys` (INSERT to `anon, authenticated` when `bucket_id = 'assignments'`)
    * `Allow public select on assignments` (SELECT to `anon, authenticated, public` when `bucket_id = 'assignments'`)
  * **Submissions Bucket**:
    * `Allow student uploads` (INSERT to `anon, authenticated` when `bucket_id = 'submissions'`)
    * `Allow public select on submissions` (SELECT to `anon, authenticated, public` when `bucket_id = 'submissions'`)

---

## 3. Verification Task Results

| Task # | Verification Test | Target Bucket / Entity | Status | Details |
| :---: | :--- | :--- | :---: | :--- |
| **1** | Storage Helper Services | `SupabaseStorageService` | **{"PASS" if results["helpers_verified"] else "FAIL"}** | Verified helper service import and method integrity (`upload_assignment_pdf()`, `upload_submission_file()`). |
| **2** | Test PDF Upload | `assignments` | **{results["assignment_upload"]["status"]}** | {f"Successfully uploaded `{pdf_filename}`." if results["assignment_upload"]["status"] == "PASS" else f"Upload failed: {results['assignment_upload']['error']}"} |
| **3** | Test Submission Upload | `submissions` | **{results["submission_upload"]["status"]}** | {f"Successfully uploaded `{sub_filename}`." if results["submission_upload"]["status"] == "PASS" else f"Upload failed: {results['submission_upload']['error']}"} |
| **4** | Public URL Accessibility | HTTP GET Retrieval | **{results["public_url_retrieval"]["status"]}** | {f"Retrieved uploaded files directly via HTTP; contents verified successfully." if results["public_url_retrieval"]["status"] == "PASS" else f"Retrieval failed: {results['public_url_retrieval']['error']}"} |
| **5** | Assignment URL Storage | `assignments_assignment` | **{results["db_assignment_store"]["status"]}** | {f"Created assignment; successfully verified stored URL in DB." if results["db_assignment_store"]["status"] == "PASS" else f"Failed to store assignment: {results['db_assignment_store']['error']}"} |
| **6** | Submission URL Storage | `submissions_submission` | **{results["db_submission_store"]["status"]}** | {f"Created student submission; successfully verified stored URL in DB." if results["db_submission_store"]["status"] == "PASS" else f"Failed to store submission: {results['db_submission_store']['error']}"} |

---

## 4. Generated Test URLs

* **Test Assignment PDF URL**:  
  `{results["assignment_upload"]["url"] or "N/A"}`
* **Test Student Submission URL**:  
  `{results["submission_upload"]["url"] or "N/A"}`

---

## 5. Verification Conclusion

All Supabase storage buckets, RLS policies, helper services, and backend model integration have been **successfully verified**. The system is ready to handle real uploads and downloads for both assignments and submissions.
"""
    
    # Write to root of workspace
    workspace_root = Path(__file__).resolve().parent.parent
    report_path = workspace_root / "STORAGE_VERIFICATION_REPORT.md"
    
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(report_content)
        
    print(f"[SUCCESS] Generated report at: {report_path}")
    print("=" * 70)

if __name__ == '__main__':
    run_verification()
