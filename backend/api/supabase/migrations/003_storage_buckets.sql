-- eFordo Migration 003: Storage Buckets
-- Run in Supabase SQL Editor: https://app.supabase.com/project/urpvkixomcutouphdgmw/sql
-- Alternatively, create buckets via Dashboard > Storage > New Bucket

-- 1. Create avatars bucket
INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,           -- public read access
    false,
    2097152,        -- 2 MB limit
    ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/gif']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- 2. Create attachments bucket
INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
VALUES (
    'attachments',
    'attachments',
    false,          -- private, access controlled via RLS
    false,
    10485760,       -- 10 MB limit
    ARRAY[
        'image/png', 'image/jpeg', 'image/webp', 'image/gif',
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'text/plain',
        'application/zip'
    ]::text[]
)
ON CONFLICT (id) DO NOTHING;

-- 3. Avatars bucket RLS Policies (idempotent)
DROP POLICY IF EXISTS "avatars_select_public" ON storage.objects;
CREATE POLICY "avatars_select_public" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_insert_own" ON storage.objects;
CREATE POLICY "avatars_insert_own" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "avatars_update_own" ON storage.objects;
CREATE POLICY "avatars_update_own" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "avatars_delete_own" ON storage.objects;
CREATE POLICY "avatars_delete_own" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- 4. Attachments bucket RLS Policies (idempotent)
DROP POLICY IF EXISTS "attachments_select_own" ON storage.objects;
CREATE POLICY "attachments_select_own" ON storage.objects
    FOR SELECT
    USING (
        bucket_id = 'attachments'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "attachments_insert_own" ON storage.objects;
CREATE POLICY "attachments_insert_own" ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'attachments'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "attachments_update_own" ON storage.objects;
CREATE POLICY "attachments_update_own" ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'attachments'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "attachments_delete_own" ON storage.objects;
CREATE POLICY "attachments_delete_own" ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'attachments'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
