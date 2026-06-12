-- eFordo Profiles Table
-- Run this SQL in your Supabase SQL Editor (https://app.supabase.com/project/_/sql)

-- 1. Create the profiles table
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

-- 3. Create policies
-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = supabase_user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = supabase_user_id);

-- Service role can insert profiles (for registration)
CREATE POLICY "Service role can insert profiles"
    ON public.profiles
    FOR INSERT
    WITH CHECK (true);

-- 4. Create indexes for case-insensitive lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_lower
    ON public.profiles (LOWER(username));

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_email_lower
    ON public.profiles (LOWER(email));

-- 5. Create auto-update trigger for updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
