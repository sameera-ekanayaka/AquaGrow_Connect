# AquaGrow 3D pod simulator

A browser digital twin of the AquaGrow pod for the live-mode demo. It plays the
part of the ESP32: it streams readings to Supabase and acts on the commands the
app sends.

## Run it

```bash
python3 -m http.server 8791 --bind 127.0.0.1 --directory tool/pod_simulator_3d
```

Open <http://localhost:8791>, then **Supabase Live Sync**: enter the project URL
(just `https://<ref>.supabase.co`), the anon key, and the same account the app
uses. The browser remembers the URL, key and email; the password is never
saved (the signed-in session is reused). **Forget** clears it.

Needs migrations 001 to 007 on that project.

## What it does once connected

- Shows your pods from `devices`, each with its growing crop from
  `crop_batches`. Herbs show basil leaves, greens show spinach leaves, an empty
  pod shows only the net cups. Plants grow with the crop's day.
- Sends a reading for every online pod every 4 s (`telemetry_logs`). Water
  drifts a little, warms up while the pump is off and slowly evaporates.
- Acts on app commands through realtime: pump, light, brightness,
  pH-down (pH drops 0.3) and refill (tank to 100%).
- Pump, light and brightness changed here are written back, so the app's
  controls match.
- Planting, harvesting or adding a pod in the app reloads the pods.

## Demo scenarios

Healthy pod, pH crash (4.8), pH drift high (7.6, fix with pH down in the app),
low water (fix with Mark as refilled), heatwave, nutrient low, sensor offline.
