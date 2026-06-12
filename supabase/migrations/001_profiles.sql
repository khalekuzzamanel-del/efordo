-- eFordo Migration 001: Profiles
-- Run in Supabase SQL Editor: https://app.supabase.com/project/urpvkixomcutouphdgmw/sql

-- 1. Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supabase_user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies (idempotent: drop before create)
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT USING (auth.uid() = supabase_user_id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE USING (auth.uid() = supabase_user_id);

-- Service role can insert profiles (called during registration)
-- NestJS backend uses the service_role key (adminClient) for this operation
DROP POLICY IF EXISTS "profiles_insert_service" ON public.profiles;
CREATE POLICY "profiles_insert_service" ON public.profiles
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- 4. Indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_lower
    ON public.profiles (LOWER(username));

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_email_lower
    ON public.profiles (LOWER(email));

CREATE INDEX IF NOT EXISTS idx_profiles_supabase_user_id
    ON public.profiles (supabase_user_id);

-- 5. Updated_at trigger
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
