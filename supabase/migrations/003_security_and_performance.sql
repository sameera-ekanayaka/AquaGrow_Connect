-- ==============================================================================
-- 003: Fixes from the Supabase security and performance advisors
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Security 1: the sign-up trigger function had a mutable search_path, and as a
-- SECURITY DEFINER function in the public schema anyone could call it through
-- /rest/v1/rpc/handle_new_user. Pin the search_path and allow only the trigger.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'role', 'owner')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------------------
-- Performance 1: evaluate auth.uid() once per query, not once per row, by
-- wrapping it in (select ...). Same rules as before; FOR ALL policies now also
-- spell out WITH CHECK so inserts and updates follow the same owner rule.
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can access their own profile" ON public.profiles;
CREATE POLICY "Users can access their own profile"
    ON public.profiles FOR ALL
    USING ((select auth.uid()) = id)
    WITH CHECK ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Owners can manage devices" ON public.devices;
CREATE POLICY "Owners can manage devices"
    ON public.devices FOR ALL
    USING ((select auth.uid()) = owner_id)
    WITH CHECK ((select auth.uid()) = owner_id);

DROP POLICY IF EXISTS "Users can query telemetry of their devices" ON public.telemetry_logs;
CREATE POLICY "Users can query telemetry of their devices"
    ON public.telemetry_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.devices
            WHERE devices.id = telemetry_logs.device_id
              AND devices.owner_id = (select auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can add telemetry to their devices" ON public.telemetry_logs;
CREATE POLICY "Users can add telemetry to their devices"
    ON public.telemetry_logs FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.devices
            WHERE devices.id = telemetry_logs.device_id
              AND devices.owner_id = (select auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can manage batches on their devices" ON public.crop_batches;
CREATE POLICY "Users can manage batches on their devices"
    ON public.crop_batches FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.devices
            WHERE devices.id = crop_batches.device_id
              AND devices.owner_id = (select auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.devices
            WHERE devices.id = crop_batches.device_id
              AND devices.owner_id = (select auth.uid())
        )
    );

-- ------------------------------------------------------------------------------
-- Performance 2: index the foreign keys that RLS checks and joins use.
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_devices_owner ON public.devices (owner_id);
CREATE INDEX IF NOT EXISTS idx_crop_batches_device ON public.crop_batches (device_id);
CREATE INDEX IF NOT EXISTS idx_crop_batches_recipe ON public.crop_batches (recipe_id);
CREATE INDEX IF NOT EXISTS idx_harvest_logs_batch ON public.harvest_logs (batch_id);
