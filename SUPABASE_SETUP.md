# Supabase Integration & Setup Guide

This guide explains how to configure your Supabase PostgreSQL Database and Supabase Storage buckets for AssignHub.

---

## 1. Database Connection

Supabase has transitioned free tier database direct connection hosts (`db.[project-ref].supabase.co`) to **IPv6-only**. 

### Connection Methods

#### A. Direct Connection (IPv6 Supported Networks Only)
If your network/server supports IPv6, you can connect directly using the credentials in your `.env` file:
*   **Host**: `db.nlmofhlhbsnqftoiyoqh.supabase.co`
*   **Port**: `5432`
*   **Database**: `postgres`
*   **User**: `postgres`

#### B. Connection Pooler (IPv4 Networks / Default Local Development)
If you are on an IPv4-only network (most local development setups), you must use the Supabase Connection Pooler (Supavisor) which resolves to IPv4 addresses.

1.  **Retrieve Pooler Credentials**:
    *   Navigate to your **Supabase Dashboard > Project Settings > Database**.
    *   Find the **Connection Pooler** section.
2.  **Configuration**:
    *   **Host**: `aws-0-[region].pooler.supabase.com` (e.g., `aws-0-ap-southeast-1.pooler.supabase.com` for Singapore)
    *   **Port**: `6543` (Transaction mode) or `5432` (Session mode)
    *   **User**: `postgres.[project-ref]` (e.g., `postgres.nlmofhlhbsnqftoiyoqh`)
    *   **Password**: Your project database password

Ensure your `.env` is updated with the pooler credentials if direct IPv6 connection fails.

---

## 2. Supabase Storage Setup

AssignHub uploads PDFs (for assignments) and submission files (for student work) directly to Supabase Storage. You must create the following buckets in your Supabase dashboard:

### Buckets to Create
1.  **`assignments`** — For admin-created assignment details.
2.  **`submissions`** — For student submission files.

### Creation Steps
1.  Navigate to **Storage** in the left sidebar of your Supabase Dashboard.
2.  Click **New Bucket**.
3.  Name it `assignments`.
4.  Toggle **Public Bucket** to **ON** (so students can download PDFs via public URLs).
5.  Repeat steps 2-4 to create a public bucket named `submissions`.

### Row Level Security (RLS) Policies
By default, public buckets allow public reading but restrict write/upload operations. To allow the Django backend to upload files using the service key or anon key, you need to configure policies:

#### For `assignments` Bucket
1.  Go to **Storage > Policies**.
2.  Under `assignments` bucket, click **New Policy**.
3.  Choose **For full customization** (or select a template for uploads).
4.  Set the policy name: `Allow uploads for authenticated keys`.
5.  Select **Allowed operations**: `INSERT` and `SELECT`.
6.  For target roles, select `authenticated` and `anon` (if using anon keys). Or leave empty to apply to all keys.
7.  Click **Save Policy**.

#### For `submissions` Bucket
1.  Under `submissions` bucket, click **New Policy**.
2.  Set policy name: `Allow student uploads`.
3.  Select **Allowed operations**: `INSERT` and `SELECT`.
4.  Click **Save Policy**.

---

## 3. Local Verification

To run database migrations locally on SQLite during testing, simply execute:
```bash
python manage.py test
```
To run the server against the live database, run:
```bash
python manage.py runserver
```
*(Note: Ensure your current IP is allowed in the Supabase Dashboard under Database > Network Restrictions if you get connection refusals)*.
