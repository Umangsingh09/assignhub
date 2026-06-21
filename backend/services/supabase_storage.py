import mimetypes
import os
import requests


class SupabaseStorageService:

    @staticmethod
    def upload_file(bucket_name: str, file_obj, file_path: str) -> str:
        """
        Uploads a file to Supabase Storage bucket and returns its public URL.
        :param bucket_name: Name of the bucket (e.g., 'assignments', 'submissions')
        :param file_obj: File-like object or bytes containing file data
        :param file_path: Path in bucket (e.g., 'assignments/django_basics.pdf')
        :return: Public URL string of the uploaded file
        """
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_key = os.getenv("SUPABASE_KEY")

        if not supabase_url or not supabase_key:
            raise ValueError(
                "SUPABASE_URL or SUPABASE_KEY environment variables are not configured."
            )

        # Sanitize URLs
        supabase_url = supabase_url.rstrip("/")
        file_path = file_path.lstrip("/")

        # Endpoint for uploading: POST /storage/v1/object/{bucket}/{path}
        upload_url = f"{supabase_url}/storage/v1/object/{bucket_name}/{file_path}"

        # Guess file MIME type
        mime_type, _ = mimetypes.guess_type(file_path)
        if not mime_type:
            mime_type = "application/octet-stream"

        headers = {
            "Authorization": f"Bearer {supabase_key}",
            "ApiKey": supabase_key,
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
                f"{supabase_url}/storage/v1/object/public/{bucket_name}/{file_path}"
            )
            return public_url
        else:
            raise Exception(
                f"Failed to upload file to Supabase Storage: {response.status_code} - {response.text}"
            )
