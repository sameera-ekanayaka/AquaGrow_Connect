-- ==============================================================================
-- 002: Telemetry upload from the app's offline queue
-- ==============================================================================
-- The app uploads readings it queued while offline (feature/sameera-sync).
--
-- 1. reading_id: the app's own id for each reading. It is unique, so a batch
--    that is uploaded twice (for example after a retry) is ignored instead of
--    creating duplicates. Readings are append-only: rows are never updated.
-- 2. An INSERT policy: 001 only let owners read telemetry, so every upload
--    was rejected by Row Level Security. Owners may now add readings for
--    their own devices only.
-- ------------------------------------------------------------------------------

ALTER TABLE public.telemetry_logs
    ADD COLUMN IF NOT EXISTS reading_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_telemetry_reading_id
    ON public.telemetry_logs (reading_id);

DROP POLICY IF EXISTS "Users can add telemetry to their devices"
    ON public.telemetry_logs;

CREATE POLICY "Users can add telemetry to their devices"
    ON public.telemetry_logs FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.devices
            WHERE devices.id = telemetry_logs.device_id
              AND devices.owner_id = auth.uid()
        )
    );
