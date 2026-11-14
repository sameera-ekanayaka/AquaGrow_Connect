# Imasha: Insights, weather, location and sensors

You turn readings into understanding: charts of how each pod has been doing, local weather
and VPD advice, the supplier map, and phone sensors.

## Read first

1. `AGENTS.md`, `CONTRIBUTING.md`, `DESIGN.md`, `docs/ARCHITECTURE.md`
2. `lib/data/data_providers.dart` (`telemetryRepositoryProvider.history(...)`, `selectedPodProvider`)
3. `lib/core/models/sensor_metric.dart` (labels, units, target ranges)
4. Your existing code: `lib/features/location/`, `lib/core/services/`

## You own (edit freely)

- `lib/features/insights/`, `lib/features/location/`, `lib/features/care/`
- `lib/core/services/weather_service.dart`, `geo_service.dart`, `vpd_calculator.dart` (you wrote them)
- `test/features/insights/`, `test/features/location/`, and your existing `test/member3_weather_vpd_test.dart`

**Do not edit:** other features, `lib/app/` (ask Tharindu for routes), `pubspec.yaml`.

## Tasks

### 1. [x] MUST: History charts (`feature/imasha-charts`)

On the Insights tab, replacing the "Charts are on the way" placeholder.

- `lib/features/insights/application/history_providers.dart`:
  - `historyRangeProvider` (`24 hours` or `7 days`), `historyMetricProvider` (`SensorMetric`),
  - `historyProvider` = `telemetryRepositoryProvider.history(selectedPodId, from, to)`.
- `lib/features/insights/domain/history_stats.dart` (pure Dart): min, max, average, and
  **stability** = percent of readings inside the metric's target range.
- Chart with `fl_chart` `LineChart`: the line in `context.ag.text`, the target range as a
  `brandSurface` band, x-axis times, y-axis with the unit. `SegmentedButton` for the range,
  chips for pH / EC / Water temp / Water level.
- Stat row under the chart: `Avg 6.1 · Min 5.8 · Max 6.4 · 96% in range`.
- Loading, error and empty states with `AsyncValueView`.

Tests: `history_stats_test.dart` (known lists give known min/max/avg/stability), plus a widget test
that switching to `7 days` asks for a 7-day range.

### 2. MUST: Weather and VPD in Insights (`feature/imasha-weather-ui`)

- Move the weather summary and VPD gauge cards from `microclimate_screen.dart` onto the Insights tab,
  under the chart, restyled to the Figma theme (no `AppColors`, no `GoogleFonts` in your files).
- Feed VPD from the selected pod's latest `ambientTempC` and `humidityPct`
  (`latestReadingProvider`) instead of the manual sliders.
- Keep `MicroclimateScreen` reachable for the full detail, or remove it and its route (ask Tharindu).
- The weather API key comes from `ref.watch(appConfigProvider).openWeatherApiKey`; with no key, use the mock service.

### 3. MUST: Location permission flow (`feature/imasha-location`)

- Before asking for location, show a short dialog: why (local weather and nearby suppliers).
- Handle: granted, denied (explain and offer Try again), permanently denied (button opens app settings),
  GPS off. Fall back to Colombo with a visible note.

Tests: geo service fallback when denied (with a fake).

### 4. MUST: Supplier map in Care (`feature/imasha-suppliers`)

Restyle `hydro_map_screen.dart` and `supplier_pin_modal.dart` to the Figma theme. List suppliers
nearest first with distance (`ListView.builder`), with search and category chips (exists, just restyle).

### 5. SHOULD: Shake to refresh (`feature/imasha-shake`)

`lib/features/insights/application/shake_detector.dart` with `sensors_plus` accelerometer:
a shake (g-force above 2.7, at most once per second) refreshes the Insights data and shows
`Refreshed`. Put the threshold maths in a pure function and unit test it.

### 6. STRETCH: Care reminders

A simple list in Care: "Clean the filter (weekly)", "Top up nutrients (every 10 days)", with
next-due dates and a tick to complete.

## Demo lines you present (about 1 minute)

"Insights shows the last 24 hours: pH stayed 96% in range. Local weather from OpenWeatherMap
feeds a VPD gauge that says whether the room is good for leafy greens. In Care, suppliers near
me, sorted by distance. And a shake refreshes everything."

## Lectures you cover

L7 (REST and JSON), L8 (GPS, maps, accelerometer), L2 (runtime permissions), L5 (charts, chips, lists).
