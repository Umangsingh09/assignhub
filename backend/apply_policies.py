import os
from pathlib import Path
from dotenv import load_dotenv
import psycopg2

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env", override=True)

def apply_policies():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        port=os.getenv("DB_PORT")
    )
    conn.autocommit = True
    cursor = conn.cursor()
    
    print("Applying RLS policies for storage.objects...")
    
    sql_commands = [
        # Assignments policies
        """
        DROP POLICY IF EXISTS "Allow uploads for authenticated keys" ON storage.objects;
        """,
        """
        CREATE POLICY "Allow uploads for authenticated keys" ON storage.objects 
        FOR INSERT TO anon, authenticated 
        WITH CHECK (bucket_id = 'assignments');
        """,
        """
        DROP POLICY IF EXISTS "Allow public select on assignments" ON storage.objects;
        """,
        """
        CREATE POLICY "Allow public select on assignments" ON storage.objects 
        FOR SELECT TO anon, authenticated, public 
        USING (bucket_id = 'assignments');
        """,
        
        # Submissions policies
        """
        DROP POLICY IF EXISTS "Allow student uploads" ON storage.objects;
        """,
        """
        CREATE POLICY "Allow student uploads" ON storage.objects 
        FOR INSERT TO anon, authenticated 
        WITH CHECK (bucket_id = 'submissions');
        """,
        """
        DROP POLICY IF EXISTS "Allow public select on submissions" ON storage.objects;
        """,
        """
        CREATE POLICY "Allow public select on submissions" ON storage.objects 
        FOR SELECT TO anon, authenticated, public 
        USING (bucket_id = 'submissions');
        """
    ]
    
    for cmd in sql_commands:
        try:
            cursor.execute(cmd)
            print(f"Executed: {cmd.strip().splitlines()[0]}")
        except Exception as e:
            print(f"Error executing command: {cmd.strip()}")
            print(f"Reason: {e}")
            
    cursor.close()
    conn.close()
    print("RLS policies applied successfully.")

if __name__ == '__main__':
    apply_policies()
