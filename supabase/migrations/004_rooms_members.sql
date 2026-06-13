-- eFordo Migration 004: Rooms & Room Members
-- Run in Supabase SQL Editor: https://app.supabase.com/project/urpvkixomcutouphdgmw/sql

-- 1. Helper: generate unique invite code
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    code_length INT := 8;
    result TEXT := '';
    i INT;
BEGIN
    FOR i IN 1..code_length LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::INT, 1);
    END LOOP;
    RETURN result;
END;
$$;

-- 2. Rooms table
CREATE TABLE IF NOT EXISTS public.rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    invite_code TEXT UNIQUE NOT NULL DEFAULT public.generate_invite_code(),
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Room members table
CREATE TABLE IF NOT EXISTS public.room_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'MEMBER' CHECK (role IN ('OWNER', 'ADMIN', 'MEMBER')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(room_id, user_id)
);

-- 4. Enable Row Level Security
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_members ENABLE ROW LEVEL SECURITY;

-- 5. Rooms RLS Policies
-- Users can SELECT rooms they are members of
DROP POLICY IF EXISTS "rooms_select_member" ON public.rooms;
CREATE POLICY "rooms_select_member" ON public.rooms
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.room_members
            WHERE room_members.room_id = rooms.id
            AND room_members.user_id = auth.uid()
        )
        AND rooms.is_deleted = FALSE
    );

-- Any authenticated user can create a room
DROP POLICY IF EXISTS "rooms_insert_authenticated" ON public.rooms;
CREATE POLICY "rooms_insert_authenticated" ON public.rooms
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- OWNER or ADMIN can update room
DROP POLICY IF EXISTS "rooms_update_owner_admin" ON public.rooms;
CREATE POLICY "rooms_update_owner_admin" ON public.rooms
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.room_members
            WHERE room_members.room_id = id
            AND room_members.user_id = auth.uid()
            AND room_members.role IN ('OWNER', 'ADMIN')
        )
    );

-- Only OWNER can soft-delete room
DROP POLICY IF EXISTS "rooms_delete_owner" ON public.rooms;
CREATE POLICY "rooms_delete_owner" ON public.rooms
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.room_members
            WHERE room_members.room_id = id
            AND room_members.user_id = auth.uid()
            AND room_members.role = 'OWNER'
        )
    );

-- 6. Room Members RLS Policies
-- Users can SELECT members of rooms they belong to
DROP POLICY IF EXISTS "room_members_select_own_room" ON public.room_members;
CREATE POLICY "room_members_select_own_room" ON public.room_members
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.room_members AS my_membership
            WHERE my_membership.room_id = room_members.room_id
            AND my_membership.user_id = auth.uid()
        )
    );

-- User can INSERT themselves when joining (used by backend service)
DROP POLICY IF EXISTS "room_members_insert_join" ON public.room_members;
CREATE POLICY "room_members_insert_join" ON public.room_members
    FOR INSERT
    WITH CHECK (
        -- User can join themselves, or OWNER/ADMIN can add others
        user_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.room_members AS actor
            WHERE actor.room_id = room_members.room_id
            AND actor.user_id = auth.uid()
            AND actor.role IN ('OWNER', 'ADMIN')
        )
    );

-- OWNER or ADMIN can remove members (cannot remove OWNER)
DROP POLICY IF EXISTS "room_members_delete_owner_admin" ON public.room_members;
CREATE POLICY "room_members_delete_owner_admin" ON public.room_members
    FOR DELETE
    USING (
        -- Cannot remove self if OWNER (must transfer ownership first)
        (room_members.user_id != auth.uid() OR room_members.role != 'OWNER')
        AND EXISTS (
            SELECT 1 FROM public.room_members AS actor
            WHERE actor.room_id = room_members.room_id
            AND actor.user_id = auth.uid()
            AND actor.role IN ('OWNER', 'ADMIN')
            -- ADMIN cannot remove OWNER
            AND (actor.role = 'OWNER' OR room_members.role != 'OWNER')
        )
    );

-- OWNER can update role (promote/demote)
DROP POLICY IF EXISTS "room_members_update_owner" ON public.room_members;
CREATE POLICY "room_members_update_owner" ON public.room_members
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.room_members AS actor
            WHERE actor.room_id = room_members.room_id
            AND actor.user_id = auth.uid()
            AND actor.role = 'OWNER'
        )
    );

-- 7. Indexes
CREATE INDEX IF NOT EXISTS idx_rooms_created_by ON public.rooms(created_by);
CREATE INDEX IF NOT EXISTS idx_rooms_invite_code ON public.rooms(invite_code);
CREATE INDEX IF NOT EXISTS idx_rooms_is_deleted ON public.rooms(is_deleted);
CREATE INDEX IF NOT EXISTS idx_room_members_room_id ON public.room_members(room_id);
CREATE INDEX IF NOT EXISTS idx_room_members_user_id ON public.room_members(user_id);
CREATE INDEX IF NOT EXISTS idx_room_members_role ON public.room_members(role);

-- 8. Updated_at trigger (reuses handle_updated_at from migration 001)
DROP TRIGGER IF EXISTS set_rooms_updated_at ON public.rooms;
CREATE TRIGGER set_rooms_updated_at
    BEFORE UPDATE ON public.rooms
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 9. Auto-assign OWNER role on room creation
CREATE OR REPLACE FUNCTION public.handle_new_room()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.room_members (room_id, user_id, role)
    VALUES (NEW.id, NEW.created_by, 'OWNER');
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_room_created ON public.rooms;
CREATE TRIGGER on_room_created
    AFTER INSERT ON public.rooms
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_room();
