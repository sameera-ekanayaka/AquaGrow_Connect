-- ==============================================================================
-- Demo data for one account (live mode)
-- ==============================================================================
-- There is no real ESP32 yet, so a new account has no pods and no readings.
-- Run this once in the Supabase SQL editor AFTER the account has signed up in
-- the app. It gives that account the same two pods as the simulator, with
-- crops and a week of hourly readings for the charts. Safe to run again: it
-- does nothing if the account already has pods.
--
-- Change the email on the next line if needed.
-- ------------------------------------------------------------------------------
DO $$
DECLARE
    demo_email CONSTANT TEXT := 'grower@aquagrow.io';
    owner UUID;
    alpha UUID;
    beta UUID;
BEGIN
    SELECT id INTO owner FROM public.profiles WHERE email = demo_email;
    IF owner IS NULL THEN
        RAISE EXCEPTION 'No profile for %. Sign up in the app first.', demo_email;
    END IF;
    IF EXISTS (SELECT 1 FROM public.devices WHERE owner_id = owner) THEN
        RAISE NOTICE '% already has pods, nothing to do.', demo_email;
        RETURN;
    END IF;

    INSERT INTO public.devices (owner_id, device_name, room, serial_number, system_type, is_online, last_seen_at)
    VALUES (owner, 'Pod Alpha', 'Kitchen', 'AQG-DEMO-ALPHA-' || left(owner::text, 8), 'NFT', TRUE, NOW())
    RETURNING id INTO alpha;

    INSERT INTO public.devices (owner_id, device_name, room, serial_number, system_type, is_online, last_seen_at)
    VALUES (owner, 'Pod Beta', 'Dining room', 'AQG-DEMO-BETA-' || left(owner::text, 8), 'DWC', TRUE, NOW())
    RETURNING id INTO beta;

    INSERT INTO public.crop_batches (device_id, recipe_id, custom_crop_name, planted_date, status)
    VALUES
        (alpha, (SELECT id FROM public.crop_recipes WHERE crop_name = 'Italian Basil' LIMIT 1),
         'Genovese Basil', CURRENT_DATE - 8, 'ACTIVE'),
        (beta, NULL, 'Baby Spinach', CURRENT_DATE - 4, 'ACTIVE');

    -- A week of hourly readings with a gentle day/night cycle.
    INSERT INTO public.telemetry_logs
        (reading_id, device_id, ph, tds_ppm, ec_ms, water_temp_c, ambient_temp_c, humidity_pct, water_level_pct, recorded_at)
    SELECT
        'seed-' || d.tag || '-' || to_char(t, 'YYYYMMDDHH24'),
        d.id,
        round((d.ph + 0.15 * sin(extract(epoch FROM t) / 13751.0))::numeric, 2),
        round((d.ec * 500 + 40 * sin(extract(epoch FROM t) / 9000.0))::numeric, 1),
        round((d.ec + 0.1 * sin(extract(epoch FROM t) / 13751.0))::numeric, 2),
        round((d.temp + 1.5 * sin(extract(epoch FROM t) / 13751.0))::numeric, 2),
        round((27 + 3 * sin(extract(epoch FROM t) / 13751.0))::numeric, 2),
        round((70 - 8 * sin(extract(epoch FROM t) / 13751.0))::numeric, 2),
        round((95 - 25 * ((extract(epoch FROM t - (NOW() - INTERVAL '7 days'))) / 604800.0))::numeric, 2),
        t
    FROM (VALUES
            (alpha, 'alpha', 6.1, 1.6, 21.5),
            (beta,  'beta',  6.3, 1.4, 20.5)
         ) AS d(id, tag, ph, ec, temp),
         generate_series(date_trunc('hour', NOW() - INTERVAL '7 days'), date_trunc('hour', NOW()), INTERVAL '1 hour') AS t;

    RAISE NOTICE 'Demo pods and readings created for %.', demo_email;
END $$;
