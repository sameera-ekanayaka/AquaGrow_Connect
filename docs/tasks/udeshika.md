# Udeshika: Crops, growth stages and Harvest Passport

You own the plants themselves: what is growing in each pod, how far along it is, and the
Harvest Passport QR that proves where food came from. You also own the report.

## Read first

1. `AGENTS.md`, `CONTRIBUTING.md`, `DESIGN.md`, `docs/ARCHITECTURE.md`
2. `lib/core/models/crop_batch.dart` and `pod.dart` (stage, day number, days left already work)
3. `lib/data/data_providers.dart` (`podsProvider`, `telemetryRepositoryProvider`)
4. Your starting screens: `lib/features/crops/presentation/`
5. Figma screens "My Pods" (`Refined Direction` page)

## You own (edit freely)

- `lib/features/crops/`
- `test/features/crops/`
- New photos in `assets/images/crops/` (PNG or WebP under 300 KB)
- `docs/REPORT.md` (create it)

**Do not edit:** other features, `lib/core/`, `lib/app/` (ask Tharindu for routes), `pubspec.yaml`.

## Tasks

### 1. MUST: My Pods list to Figma (`feature/udeshika-my-pods`)

Replace the simple rows in `crops_screen.dart` with the Figma **Pod card**:
photo on top (`batch.imageAsset`, or a soft `subtle` box with an eco icon when null), a
`StatusBadge` with the stage over the photo, then crop name (`titleLarge`), `Kitchen · Pod Alpha`
(`bodySmall`), stage in green-brand text, and `Day 8 · Harvest est. in 20 days`.

- Keep `ListView.builder`. 1 column on phones, 2 columns at 600 px and wider (`LayoutBuilder`).
- Tap opens `AppRoutes.cropDetail(pod.id)`.
- Under the cards: the selected pod's readings summary row is NOT needed here (that is Home).
- Add a `+ Add a pod` filled button at the end that shows a "Coming soon" dialog (no real pairing).

Tests: widget test that two pods render two cards with their crop names, using `testApp()`.

### 2. MUST: Crop detail (`feature/udeshika-crop-detail`)

`crop_detail_screen.dart`:

- Hero photo with the name and stage badge.
- **Stage timeline**: Seedling, Growing, Ready to harvest as three steps, current one highlighted.
- Progress bar + `Day 8 of 28 · 20 days left`.
- **Recipe targets** for this crop (pH range, EC, water temp, light hours) from a recipe list in
  `lib/features/crops/domain/crop_recipes.dart` (copy the five seed recipes from
  `supabase/migrations/001_initial_schema.sql`, plus Genovese Basil and Baby Spinach).
- **Today's average** pH and EC for this pod from `telemetryRepositoryProvider.history(...)` (last 24 h).
- A `Harvest` button, enabled only when the stage is `readyToHarvest` (for the demo, also allow it
  from `growing` with a dialog "Harvest early?"). It asks with `showConfirmDialog`, then opens the passport.

Tests: `crop_recipes_test.dart` (every recipe has min pH < max pH and positive days).

### 3. MUST: Harvest Passport QR (`feature/udeshika-passport`)

- `lib/features/crops/domain/harvest_passport.dart` (pure Dart): crop, variety, pod, planted date,
  harvest date, days grown, average pH and EC over the batch, **water saved** estimate
  (`litres = daysGrown * 1.8`, explain the assumption in a doc comment: soil growing uses about 2 L per
  plant per day versus 0.2 L hydroponic), and a `hash` = SHA-256 (package `crypto`) of the
  canonical JSON of those fields.
- `HarvestPassportScreen`: a card with the facts and a `QrImageView` (package `qr_flutter`) whose data is
  the JSON plus the hash. Show the first 8 characters of the hash under the code.
- Route: ask Tharindu to add `/crops/:podId/passport`.

Tests: same input gives the same hash; changing any field changes the hash; water saved maths.

Done when: harvesting Pod Alpha opens a passport whose QR scans (any phone camera) to readable JSON.

### 4. SHOULD: Start a new batch (`feature/udeshika-new-batch`)

A form (crop from the recipe list, pod, planting date) with validation, stored in a local
`batchOverridesProvider` so the pod shows the new crop. No backend needed.

### 5. MUST (Monday): Report (`docs/udeshika-report`)

`docs/REPORT.md` sections: problem and users, platform choice (why Flutter + Android Studio),
architecture (link `docs/ARCHITECTURE.md`), lecture coverage table, security, testing results,
iOS comparison (Flutter vs SwiftUI, one paragraph), future work (AI plant doctor, ESP32 camera,
BLE pairing), individual contribution table. Tharindu helps with the platform and iOS parts.

## Demo lines you present (about 1 minute)

"My Pods shows each crop and its stage. Basil is on day 8 of 28. When it is ready, I harvest it and
the app creates a Harvest Passport. Scan this QR with any phone: crop, dates, water saved, and a
SHA-256 hash so it can't be faked."

## Lectures you cover

L5 (lists, cards, navigation to detail), L6 (Figma fidelity), L9 (data integrity with hashing),
L3 and L11 in the report.
