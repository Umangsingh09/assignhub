const SUPABASE_URL = 'https://nlmofhlhbsnqftoiyoqh.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_HhdGVMuA7geSFRAFD8UEwg_F8x52S7A';

class SupabaseStorage {
    /**
     * Uploads a file directly from the browser to Supabase Storage.
     * @param {string} bucketName - The target bucket ('assignments' or 'submissions')
     * @param {File} file - The HTML File object to upload
     * @returns {Promise<string>} - The public URL of the uploaded file
     */
    static async uploadFile(bucketName, file) {
        // Generate a unique filename: timestamp_random_originalName
        const randHex = Math.random().toString(36).substring(2, 10);
        const timestamp = Date.now();
        const safeName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_');
        const fileName = `${timestamp}_${randHex}_${safeName}`;

        const uploadUrl = `${SUPABASE_URL}/storage/v1/object/${bucketName}/${fileName}`;
        
        const headers = {
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
            'ApiKey': SUPABASE_ANON_KEY,
            'Content-Type': file.type || 'application/octet-stream'
        };

        const response = await fetch(uploadUrl, {
            method: 'POST',
            headers: headers,
            body: file
        });

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(`Failed to upload to Supabase Storage: ${response.status} - ${errorText}`);
        }

        // Construct public URL
        const publicUrl = `${SUPABASE_URL}/storage/v1/object/public/${bucketName}/${fileName}`;
        return publicUrl;
    }
}
