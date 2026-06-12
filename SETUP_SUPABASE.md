# eFordo — Supabase Setup Guide

## Overview

This guide covers the complete Supabase setup for the eFordo project.

### Architecture

```
Flutter App  ──HTTP──>  NestJS Backend  ──SDK──>  Supabase
                             │
                        ┌────┴────┐
                        │         │
                   Auth API    Database
                (sign up/in)  (PostgreSQL)
```

- **Flutter** communicates only with the NestJS backend via `API_BASE_URL`
- **NestJS backend** uses the Supabase JS SDK with the **anon key** for client operations
- **Service Role Key** is used only for server-to-server privileged operations (e.g., admin functions)

---

## 1. Supabase Project

### Create Project

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Sign in (or create an account)
3. Click **New project**
4. Fill in:
   - **Name**: `eFordo`
   - **Database Password**: Generate a strong password and save it securely
   - **Region**: Choose the closest to your users (e.g., `Singapore (ap-southeast-1)`)
5. Click **Create new project** (takes ~1-2 minutes)

### Get Your Project Credentials

After creation, go to **Project Settings > API**:

| Credential | Where | Location in Settings |
|---|---|---|
| **Project URL** | `SUPABASE_URL` | Settings > API > Project URL |
| **Project ID** | (part of URL) | `urpvkixomcutouphdgmw` from `https://urpvkixomcutouphdgmw.supabase.co` |
| **Region** | (chosen during creation) | Settings > General > Region |
| **Anon Key** 📋 | `SUPABASE_ANON_KEY` | Settings > API > anon/public key |
| **Service Role Key** 🔒 | `SUPABASE_SERVICE_ROLE_KEY` | Settings > API > service_role key (click Reveal) |

> ⚠️ **Security**: Never expose the Service Role Key to clients. It bypasses all RLS.

---

## 2. Auth Configuration

### Enable Email Auth

1. Go to **Authentication > Providers**
2. Click **Email**
3. Toggle **Enable Email sign-up** to ON
4. **Disable** "Confirm email" (for MVP — users won't need to verify email)
5. Click **Save**

> **To enable email confirmation later**: Go back to Authentication > Providers > Email and toggle "Confirm email" ON. Supabase will send verification emails automatically.

### Disable Unused Providers

Make sure these are OFF:
- ❌ Google
- ❌ GitHub
- ❌ Magic Links
- ❌ Phone Auth

### Configure Auth Settings

1. Go to **Authentication > Settings**
2. Under **General**:
   - **Site URL**: `http://localhost:3000` (update for production)
   - **Redirect URLs**: Add `http://localhost:3000/auth/callback`
3. Under **Security**:
   - **Enable Manual Linking**: OFF (default)
   - **Allow multiple accounts**: OFF (default)

---

## 3. Database Migrations

Run these SQL migrations in order using the **SQL Editor** at `https://app.supabase.com/project/urpvkixomcutouphdgmw/sql/new`.

### Migration 001: Profiles

Open the SQL Editor and paste the contents of:

```
backend/api/supabase/migrations/001_profiles.sql
```

This creates:
- `public.profiles` table (id, supabase_user_id, username, email, display_name)
- RLS policies for SELECT/UPDATE on own profile
- Case-insensitive indexes on username and email
- `updated_at` auto-update trigger

### Migration 002: Workspaces & Projects

Paste the contents of:

```
backend/api/supabase/migrations/002_workspaces_projects.sql
```

This creates:
- `public.workspaces` table with CASCADE delete from auth.users
- `public.projects` table with CASCADE delete from workspaces
- RLS policies for full CRUD ownership
- Status CHECK constraint (`active`, `on_hold`, `completed`)
- Indexes on all query-relevant columns

### Migration 003: Storage Buckets

Paste the contents of:

```
backend/api/supabase/migrations/003_storage_buckets.sql
```

This creates:
- `avatars` bucket (public read, authenticated upload, 2MB limit)
- `attachments` bucket (private, user-only access, 10MB limit)
- RLS policies for both buckets

---

## 4. Storage Buckets

Alternatively to the SQL migration, you can create buckets via the dashboard:

1. Go to **Storage** in the Supabase dashboard
2. Click **New Bucket**
3. Create two buckets:

| Bucket | Name | Public | File Size Limit | Allowed Types |
|---|---|---|---|---|
| Avatars | `avatars` | ✅ Public | 2 MB | png, jpeg, webp, gif |
| Attachments | `attachments` | ❌ Private | 10 MB | png, jpeg, pdf, doc, docx, txt, zip |

The RLS policies from `003_storage_buckets.sql` enforce:
- **Avatars**: Anyone can view, only the owning user can upload/update/delete
- **Attachments**: Only the owning user can view/upload/update/delete

File organization: `{bucket}/{user_id}/{filename}` (e.g., `avatars/abc-123/photo.png`)

---

## 5. Backend Environment

### Verify `.env`

The file `backend/api/.env` should contain:

```env
# Server
PORT=3000

# Supabase
SUPABASE_URL=https://urpvkixomcutouphdgmw.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Updated `.env.example`

The updated reference file is at `backend/api/.env.example`:

```env
# Server
PORT=3000

# Supabase
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

### Key Usage Principles

| Key | Where Used | Purpose |
|---|---|---|
| **Anon Key** | `SupabaseService` (client) | Authenticated user operations — respects RLS |
| **Service Role Key** | Admin/batch operations | Bypasses RLS — for server-side only |
| **Anon Key** (never in frontend) | — | Flutter talks to NestJS, not directly to Supabase |

#### When to use each key:

- **Anon key**: All user-facing operations (register, login, CRUD workspaces/projects, upload files). Every request goes through NestJS controllers which set the auth context.
- **Service role key**: Admin operations (user management, bulk data processing, system migrations). Never exposed to the client.

---

## 6. Frontend Configuration

### Update `.env`

The file `frontend/flutter_app/.env` should contain:

```env
API_BASE_URL=http://localhost:3000
```

Update `API_BASE_URL` to your deployed backend URL when moving to production.

> ⚠️ **Important**: The Flutter app does NOT connect directly to Supabase. It only communicates with the NestJS backend. This means:
> - No Supabase keys in the frontend
> - No direct database queries from the Flutter app
> - All business logic runs server-side

---

## 7. Migration Strategy

### Folder Structure

```
backend/api/supabase/
├── migrations/
│   ├── 001_profiles.sql
│   ├── 002_workspaces_projects.sql
│   └── 003_storage_buckets.sql
├── seeds/
│   └── (empty for now — add sample data later)
└── README.md
```

### Versioning Convention

- Use sequential numeric prefixes: `001_`, `002_`, `003_`, etc.
- Never modify a migration file after it's been applied to any environment
- Create a NEW migration file for schema changes
- Name files descriptively after the feature: `001_profiles.sql`, `002_workspaces_projects.sql`

### Applying Migrations

**Development**: Run each file manually in the Supabase SQL Editor.

**Production**: Use one of:
1. **Supabase CLI** (recommended): `supabase db push` with local migrations
2. **Manual**: Apply migrations in order via the SQL Editor
3. **CI/CD**: Automate via GitHub Actions using the Service Role Key

### Schema Evolution

When you need to change the schema:

1. Create `004_new_feature.sql`
2. Apply it in the SQL Editor
3. Update the NestJS code to match
4. Commit both the migration and the code changes together

---

## 8. Security Recommendations

### ✅ DO
- Keep the **Service Role Key** in `.env` only — never commit it
- Always use RLS for user data isolation
- Validate all inputs in NestJS DTOs (class-validator)
- Use `whitelist: true` on NestJS ValidationPipe
- Delete unused Storage bucket policies
- Monitor auth logs in Supabase Dashboard > Authentication > Logs

### ❌ DON'T
- Do NOT expose Supabase keys to the Flutter app
- Do NOT use the Service Role Key in client-facing code
- Do NOT disable RLS on user data tables
- Do NOT skip input validation on the backend
- Do NOT modify applied migrations — create new ones

---

## 9. Verification Checklist

### Auth
- [ ] Email sign-up is enabled in Auth > Providers
- [ ] Email confirmation is disabled (MVP)
- [ ] Google/GitHub/Magic Links/Phone are disabled

### Database
- [ ] Migration 001 applied — `profiles` table exists
- [ ] Migration 002 applied — `workspaces` and `projects` tables exist
- [ ] All RLS policies active on all three tables
- [ ] Indexes created on all foreign keys and query columns
- [ ] `updated_at` triggers working

### Storage
- [ ] `avatars` bucket created (public)
- [ ] `attachments` bucket created (private)
- [ ] RLS policies applied to both buckets
- [ ] File size limits configured

### Backend
- [ ] `.env` has real `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
- [ ] `nest build` passes cleanly
- [ ] `curl http://localhost:3000/health` returns 200

### Frontend
- [ ] `.env` has `API_BASE_URL=http://localhost:3000`
- [ ] No Supabase keys in Flutter code
- [ ] Flutter app starts successfully

---

## Quick Start

```bash
# 1. Apply SQL migrations (in Supabase SQL Editor in order)
# 2. Start the backend
cd backend/api && npx nest start

# 3. Start the frontend
cd frontend/flutter_app && flutter run -d chrome

# 4. Verify health
curl http://localhost:3000/health
#> {"status":"ok","timestamp":"..."}
```

---

> **Next**: After setup is complete, register a test user via the Flutter app or directly via the NestJS API:
> ```bash
> curl -X POST http://localhost:3000/auth/register \
>   -H "Content-Type: application/json" \
>   -d '{"username":"testuser","email":"test@example.com","password":"password123"}'
> ```
