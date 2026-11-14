-- ==============================================================================
-- 004: What the live repositories need (feature/sameera-supabase-repos)
-- ==============================================================================

-- 1. Every pod shows "Pod Alpha · Kitchen", so devices need a room.
ALTER TABLE public.devices
    ADD COLUMN IF NOT EXISTS room TEXT NOT NULL DEFAULT 'Home';

-- 2. Realtime: the app listens for new telemetry rows and device changes.
--    Row Level Security still applies, so each user only receives rows for
--    their own devices.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public' AND tablename = 'telemetry_logs'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.telemetry_logs;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public' AND tablename = 'devices'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.devices;
    END IF;
END $$;
