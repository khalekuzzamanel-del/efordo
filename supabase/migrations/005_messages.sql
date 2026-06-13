-- eFordo Migration 005: Messages
-- Run in Supabase SQL Editor: https://app.supabase.com/project/urpvkixomcutouphdgmw/sql

-- 1. Messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message_type TEXT NOT NULL DEFAULT 'TEXT' CHECK (message_type IN ('TEXT', 'IMAGE', 'SYSTEM', 'DETECTION', 'VOICE')),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Enable Row Level Security
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies
-- Users can SELECT messages only from rooms they belong to
DROP POLICY IF EXISTS "messages_select_member" ON public.messages;
CREATE POLICY "messages_select_member" ON public.messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.room_members
            WHERE room_members.room_id = messages.room_id
            AND room_members.user_id = auth.uid()
        )
    );

-- Users can INSERT messages only into rooms they belong to
DROP POLICY IF EXISTS "messages_insert_member" ON public.messages;
CREATE POLICY "messages_insert_member" ON public.messages
    FOR INSERT
    WITH CHECK (
        sender_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.room_members
            WHERE room_members.room_id = messages.room_id
            AND room_members.user_id = auth.uid()
        )
    );

-- 4. Indexes
CREATE INDEX IF NOT EXISTS idx_messages_room_id ON public.messages(room_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_room_id_created_at ON public.messages(room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_message_type ON public.messages(message_type);

-- 5. Enable Realtime for messages table
-- This allows Flutter to subscribe to new messages in real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
