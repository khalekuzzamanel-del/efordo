# Supabase Migrations

This directory contains all eFordo database migrations.

## Structure

├── migrations/    # Versioned SQL migration files (apply in order)
├── seeds/         # Optional seed data

## Applying Migrations

1. Go to Supabase Dashboard > SQL Editor
2. Create a new query
3. Paste the contents of each migration file in order
4. Run them sequentially (001 → 002 → 003)

## Convention

- Files are named: `NNN_descriptive_name.sql`
- Never modify an applied migration — create a new one
- Always commit both the migration and code changes together

## Migrations

| File | Description |
|---|---|
| `001_profiles.sql` | Profiles table, RLS, indexes, triggers |
| `002_workspaces_projects.sql` | Workspaces & Projects tables, RLS, indexes |
| `003_storage_buckets.sql` | Storage buckets (avatars, attachments) + policies |
