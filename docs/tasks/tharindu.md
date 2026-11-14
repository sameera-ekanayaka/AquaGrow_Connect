# Tharindu: foundation, design system, app shell and presentation

You built the foundation (this PR). Now you keep the shared parts healthy, build the shared
crop widgets everyone needs, settings and onboarding, and lead the slides.

## Read first

1. `AGENTS.md`, `CONTRIBUTING.md`, `DESIGN.md`, `docs/ARCHITECTURE.md`
2. Figma page "01 — Refined Direction" (components) and "Page 1" (splash, onboarding)

## You own (edit freely)

- `lib/app/` (router, shell, header), `lib/core/theme/`, `lib/shared/`
- `lib/features/settings/`, `lib/features/onboarding/` (create them)
- `lib/core/simulation/`, `lib/data/simulation/`, `lib/data/data_providers.dart` (non-live parts)
- `test/app/`, `test/shared/`, `test/core/`, `test/helpers/`
- `docs/` (except task files owned by others), `.github/`, `.run/`, `tool/`

## Tasks

### 0. ALWAYS: Route requests

Teammates ask you to add routes. Add the path to `AppRoutes` and a `GoRoute` in
`app_router.dart` in a small `feat(router): ...` PR. Turn these around within an hour.

### 1. MUST, first thing Sunday: Shared crop widgets (`feature/tharindu-crop-widgets`)

Osanda (Home) and Udeshika (My Pods) both need these. Build them in `lib/shared/widgets/` from
the Figma components, export them in `widgets.dart`, and add widget tests:

- `CropTile(title:, detail:, imageAsset:)`: 166-wide card, photo 112 high, radius 20.
- `CropHero(name:, badge:, caption:, imageAsset:)`: photo card radius 24, badge top-left,
  near-black summary box at the bottom with white text.
- `PodCard(...)`: photo, stage badge, name, `room · pod`, stage text, harvest line.

Tell the group in WhatsApp as soon as it is merged.

### 2. MUST: Settings screen (`feature/tharindu-settings`)

`lib/features/settings/presentation/settings_screen.dart`, route `/settings`, linked from Care
("Profile and settings" opens Profile; add a separate "Settings" tile):

- Theme: Light / Dark / System (`themeModeProvider`), remembered in Hive `app_preferences`.
- Data mode shown read-only (`Simulation` or `Live`), and the app version.
- **Privacy note** (lecture 9): what is stored, where, and a `Delete my local data` button
  (confirm dialog, clears Hive boxes).
- About: team names and the module code.

### 3. SHOULD: Splash and onboarding (`feature/tharindu-onboarding`)

Figma "Splash Screen" and "Onboarding Screen": logo splash, then 3 slides
(Grow fresh food at home / Know your plants live / Get alerted before it's too late) shown once,
remembered in Hive. Add a redirect rule for first launch, with a unit test.

### 4. MUST: Demo-flow widget test (`test/app/demo_flow_test.dart`)

One widget test that walks the demo: sign in, Home shows pods, simulator pH crash, alert appears,
open Crops, open Insights. Uses `testApp()` and `sim.tick()`.

### 5. MUST (Monday): Slides and demo script

Slides: problem, Figma flow, architecture diagram, lecture coverage, security, testing, demo,
future work. Rehearse the 7-minute script in `docs/DEMO.md` twice. Record a backup screen video.

### 6. ALWAYS: Keep `main` healthy

If CI goes red on `main`, fixing it beats every other task. Keep `DESIGN.md`, `ARCHITECTURE.md`
and `AGENTS.md` true when shared code changes.

## Demo lines you present (about 1.5 minutes)

Opening: the problem, the pod, the Figma design, why Flutter in Android Studio. Closing: the
architecture, tests and CI, iOS comparison, future work.

## Lectures you cover

L3 (platform choice), L4 (architecture), L5 and L6 (navigation, Material, Figma), L10 (tests, CI), L11 (iOS).
