import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import psycopg2

# Resolve paths and load .env
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env", override=True)

DB_NAME = os.getenv("DB_NAME", "postgres")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_HOST = os.getenv("DB_HOST", "db.nlmofhlhbsnqftoiyoqh.supabase.co")
DB_PORT = os.getenv("DB_PORT", "5432")

PROJECT_REF = "nlmofhlhbsnqftoiyoqh"
REGION = "ap-southeast-1"  # Singapore
POOLER_HOST = f"aws-0-{REGION}.pooler.supabase.com"

print("=" * 60)
print("SUPABASE POSTGRESQL CONNECTION DIAGNOSTICS")
print("=" * 60)
print(f"Loaded config from .env:")
print(f"  - DB_HOST: {DB_HOST}")
print(f"  - DB_PORT: {DB_PORT}")
print(f"  - DB_NAME: {DB_NAME}")
print(f"  - DB_USER: {DB_USER}")
print(f"  - Password set: {'Yes' if DB_PASSWORD else 'No'}")
print("-" * 60)

# Test 1: Direct Connection (IPv6)
print("TEST 1: Testing Direct Connection (IPv6)...")
try:
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT,
        connect_timeout=3
    )
    print("-> Success! Connected directly via IPv6.")
    conn.close()
except Exception as e:
    print(f"-> Direct Connection Failed.")
    print(f"   Reason: {e}")
    if "Name or service not known" in str(e) or "gaierror" in str(type(e)):
        print("   [Diagnosis] DNS resolution failed. Your local network/DNS server does not support IPv6-only domains.")
    elif "Network is unreachable" in str(e):
        print("   [Diagnosis] Your local internet connection does not have an active IPv6 routing path.")

print("-" * 60)

# Test 2: Pooled Connection (IPv4)
print("TEST 2: Testing Connection Pooler (IPv4)...")
pooled_user = f"postgres.{PROJECT_REF}"
print(f"  - Attempting host: {POOLER_HOST}")
print(f"  - Attempting user: {pooled_user}")
print(f"  - Attempting port: 5432 (Session Mode)")

try:
    conn = psycopg2.connect(
        host=POOLER_HOST,
        database=DB_NAME,
        user=pooled_user,
        password=DB_PASSWORD,
        port="5432",
        sslmode="require",
        connect_timeout=5
    )
    print("-> Success! Connected via Supabase Connection Pooler.")
    conn.close()
except Exception as e:
    print("-> Pooled Connection Failed.")
    print(f"   Reason: {e}")
    if "tenant/user" in str(e) and "not found" in str(e):
        print("\n   [ACTION REQUIRED] Connection pooler is currently DISABLED in your Supabase dashboard.")
        print("   Please follow these steps to enable it:")
        print("     1. Log in to https://supabase.com")
        print("     2. Navigate to: Project Settings > Database")
        print("     3. Scroll down to Connection Pooler and toggle it ON.")
        print("     4. Ensure the port matches (5432 for Session Mode, 6543 for Transaction Mode).")
    elif "password authentication failed" in str(e):
        print("\n   [ACTION REQUIRED] Database password authentication failed.")
        print("   Please verify the DB_PASSWORD value in your .env file matches your database password.")
print("=" * 60)
