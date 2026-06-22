import mimetypes
import os
import urllib.parse as urlparse
import requests


class SupabaseStorageService:

    @staticmethod
    def _get_base_url() -> str:
        supabase_url = os.getenv("SUPABASE_URL")
        if not supabase_url:
            raise ValueError("SUPABASE_URL environment variable is not configured.")

        # Extract scheme and host to strip any path suffix like '/rest/v1/'
        parsed_url = urlparse.urlparse(supabase_url)
        return f"{parsed_url.scheme}://{parsed_url.netloc}"

    @staticmethod
    def _get_api_key() -> str:
        key = os.getenv("SUPABASE_KEY") or os.getenv("SUPABASE_ANON_KEY")
        if not key:
            raise ValueError(
                "Neither SUPABASE_KEY nor SUPABASE_ANON_KEY environment variables are configured."
            )
        return key

    @classmethod
    def upload_file(cls, bucket_name: str, file_obj, file_path: str) -> str:
        """
        Uploads a file to Supabase Storage bucket and returns its public URL.
        :param bucket_name: Name of the bucket (e.g., 'assignments', 'submissions')
        :param file_obj: File-like object or bytes containing file data
        :param file_path: Path in bucket (e.g., 'django_basics.pdf')
        :return: Public URL string of the uploaded file
        """
        base_url = cls._get_base_url()
        api_key = cls._get_api_key()

        file_path = file_path.lstrip("/")

        # Endpoint for uploading: POST /storage/v1/object/{bucket}/{path}
        upload_url = f"{base_url}/storage/v1/object/{bucket_name}/{file_path}"

        # Guess file MIME type
        mime_type, _ = mimetypes.guess_type(file_path)
        if not mime_type:
            mime_type = "application/octet-stream"

        headers = {
            "Authorization": f"Bearer {api_key}",
            "ApiKey": api_key,
            "Content-Type": mime_type,
        }

        # Read file data
        if hasattr(file_obj, "read"):
            # Reset seek position if possible
            if hasattr(file_obj, "seek"):
                try:
                    file_obj.seek(0)
                except Exception:
                    pass
            file_data = file_obj.read()
        else:
            file_data = file_obj

        response = requests.post(upload_url, headers=headers, data=file_data)

        if response.status_code == 200:
            # Construct and return public URL
            public_url = (
                f"{base_url}/storage/v1/object/public/{bucket_name}/{file_path}"
            )
            return public_url
        else:
            raise Exception(
                f"Failed to upload file to Supabase Storage: {response.status_code} - {response.text}"
            )

    @classmethod
    def upload_assignment_pdf(cls, file_obj, file_name: str) -> str:
        """
        Helper to upload an assignment PDF file to the 'assignments' bucket.
        """
        return cls.upload_file("assignments", file_obj, file_name)

    @classmethod
    def upload_submission_file(cls, file_obj, file_name: str) -> str:
        """
        Helper to upload a student submission file to the 'submissions' bucket.
        """
        return cls.upload_file("submissions", file_obj, file_name)
