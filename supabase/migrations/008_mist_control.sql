-- ==============================================================================
-- 008: Ultrasonic mist control (feature/osanda-demo-fixes)
-- ==============================================================================
-- The app writes the wanted mist state; the pod or the 3D simulator obeys it.
ALTER TABLE public.devices
    ADD COLUMN IF NOT EXISTS mist_on BOOLEAN NOT NULL DEFAULT TRUE;
