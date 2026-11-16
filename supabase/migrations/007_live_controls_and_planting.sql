-- ==============================================================================
-- 007: Live pod controls, planting and the two missing recipes
--      (feature/osanda-live-flow)
-- ==============================================================================

-- 1. Pod controls. The app writes the wanted state on the device row; the pod
--    (or the 3D simulator) reads it through realtime and acts on it.
--    Requests are timestamps, so the same request can be sent twice.
ALTER TABLE public.devices
    ADD COLUMN IF NOT EXISTS pump_on BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS light_on BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS light_brightness INT NOT NULL DEFAULT 80
        CHECK (light_brightness BETWEEN 0 AND 100),
    ADD COLUMN IF NOT EXISTS ph_dose_requested_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS refill_requested_at TIMESTAMP WITH TIME ZONE;

-- 2. Planting and harvesting change crop_batches: the app and the 3D
--    simulator listen for that too. Row Level Security still applies.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public' AND tablename = 'crop_batches'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.crop_batches;
    END IF;
END $$;

-- 3. Recipes are already readable by every signed-in user: 001 created
--    "Authenticated users can read crop recipes". No second policy needed.

-- 4. The app offers 7 crops; 001 seeded 5. Add the other two.
INSERT INTO public.crop_recipes
    (crop_name, variety, stage_name, min_ph, max_ph, target_ec,
     target_water_temp_c, light_hours_per_day, pump_interval_min, duration_days)
SELECT v.*
FROM (VALUES
    ('Genovese Basil', 'Genovese', 'Vegetative', 5.8, 6.4, 1.6, 22.0, 18, 15, 28),
    ('Baby Spinach', 'Savoy', 'Vegetative', 5.5, 6.5, 1.8, 18.0, 14, 15, 30)
) AS v(crop_name, variety, stage_name, min_ph, max_ph, target_ec,
       target_water_temp_c, light_hours_per_day, pump_interval_min, duration_days)
WHERE NOT EXISTS (
    SELECT 1 FROM public.crop_recipes r WHERE r.crop_name = v.crop_name
);
