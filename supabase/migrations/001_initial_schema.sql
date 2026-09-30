-- ==============================================================================
-- AquaGrow PostgreSQL Schema and Security Migration
-- Author: Member 2 (Database, Cloud and Security Architecture Lead)
-- Description: Core tables, foreign keys, performance indexes, triggers, and Row-Level Security (RLS)
-- ==============================================================================

-- Enable UUID extension for cryptographically strong primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. Profiles Table (Synchronized with Supabase auth.users)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'owner' CHECK (role IN ('owner', 'viewer', 'commercialGrower')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Trigger to automatically create a profile record when a user signs up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ------------------------------------------------------------------------------
-- 2. Hydroponic Devices Table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL DEFAULT 'AquaGrow Unit',
    serial_number TEXT UNIQUE NOT NULL,
    mac_address TEXT,
    system_type TEXT NOT NULL CHECK (system_type IN ('NFT', 'DWC')),
    firmware_version TEXT DEFAULT '1.0.0',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_online BOOLEAN DEFAULT FALSE,
    last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- 3. Telemetry Logs Table (High-frequency time-series data)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.telemetry_logs (
    id BIGSERIAL PRIMARY KEY,
    device_id UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
    ph NUMERIC(4, 2) NOT NULL,
    tds_ppm NUMERIC(6, 1) NOT NULL,
    ec_ms NUMERIC(4, 2) NOT NULL,
    water_temp_c NUMERIC(4, 2) NOT NULL,
    ambient_temp_c NUMERIC(4, 2),
    humidity_pct NUMERIC(4, 2),
    water_level_pct NUMERIC(5, 2) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Composite index optimized for rapid historical chart range queries and pagination
CREATE INDEX IF NOT EXISTS idx_telemetry_device_time 
    ON public.telemetry_logs (device_id, recorded_at DESC);

-- ------------------------------------------------------------------------------
-- 4. Crop DNA Recipes Table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crop_recipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_name TEXT NOT NULL,
    variety TEXT,
    stage_name TEXT NOT NULL DEFAULT 'Vegetative',
    min_ph NUMERIC(3, 1) NOT NULL,
    max_ph NUMERIC(3, 1) NOT NULL,
    target_ec NUMERIC(3, 1) NOT NULL,
    target_water_temp_c NUMERIC(3, 1) NOT NULL,
    light_hours_per_day INT NOT NULL DEFAULT 16,
    pump_interval_min INT NOT NULL DEFAULT 15,
    duration_days INT NOT NULL DEFAULT 30
);

-- ------------------------------------------------------------------------------
-- 5. Active Crop Batches Table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crop_batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES public.crop_recipes(id),
    custom_crop_name TEXT,
    planted_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_harvest_date DATE,
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'HARVESTED', 'FAILED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- 6. Harvest Logs and Traceability Passport Table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.harvest_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_id UUID NOT NULL REFERENCES public.crop_batches(id) ON DELETE CASCADE,
    yield_grams NUMERIC(7, 2) NOT NULL,
    water_saved_liters NUMERIC(6, 2) NOT NULL,
    avg_ph NUMERIC(4, 2),
    avg_ec NUMERIC(4, 2),
    qr_code_hash TEXT UNIQUE NOT NULL,
    harvest_notes TEXT,
    harvested_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ==============================================================================
-- ROW-LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.telemetry_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crop_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crop_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.harvest_logs ENABLE ROW LEVEL SECURITY;

-- 1. Profiles: Users can query and modify only their own profile
CREATE POLICY "Users can access their own profile"
    ON public.profiles FOR ALL
    USING (auth.uid() = id);

-- 2. Devices: Owners have full management rights over registered devices
CREATE POLICY "Owners can manage devices"
    ON public.devices FOR ALL
    USING (auth.uid() = owner_id);

-- 3. Telemetry: Users can query telemetry only for devices they own
CREATE POLICY "Users can query telemetry of their devices"
    ON public.telemetry_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.devices 
            WHERE devices.id = telemetry_logs.device_id 
              AND devices.owner_id = auth.uid()
        )
    );

-- 4. Crop Recipes: All authenticated users have read access to botanical recipes
CREATE POLICY "Authenticated users can read crop recipes"
    ON public.crop_recipes FOR SELECT
    TO authenticated
    USING (true);

-- 5. Crop Batches: Owners can manage cultivation batches on their devices
CREATE POLICY "Users can manage batches on their devices"
    ON public.crop_batches FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.devices 
            WHERE devices.id = crop_batches.device_id 
              AND devices.owner_id = auth.uid()
        )
    );

-- 6. Harvest Passport: Public read access for consumer QR verification
CREATE POLICY "Public can verify harvest passport QR"
    ON public.harvest_logs FOR SELECT
    USING (true);

-- ==============================================================================
-- SEED DATA: Master Crop DNA Recipes
-- ==============================================================================
INSERT INTO public.crop_recipes (crop_name, variety, stage_name, min_ph, max_ph, target_ec, target_water_temp_c, light_hours_per_day, pump_interval_min, duration_days)
VALUES
    ('Butterhead Lettuce', 'Bibb', 'Vegetative', 5.6, 6.2, 1.4, 20.0, 16, 15, 30),
    ('Italian Basil', 'Genovese', 'Vegetative', 5.8, 6.4, 1.6, 22.0, 18, 15, 28),
    ('Wild Rocket', 'Arugula', 'Vegetative', 6.0, 6.8, 1.5, 19.5, 14, 20, 25),
    ('Sweet Mint', 'Spearmint', 'Vegetative', 6.0, 6.5, 2.0, 21.0, 16, 15, 35),
    ('Pak Choi', 'Baby Green', 'Vegetative', 6.0, 7.0, 1.8, 20.5, 14, 15, 32)
ON CONFLICT DO NOTHING;
