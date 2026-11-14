# Tharindu: foundation, alerts and notifications, settings, presentation

You built the foundation. Now you keep the shared code healthy, build the alert engine and
notifications on top of the simulator, add settings and the privacy note, and lead the slides.

## Read first

1. `AGENTS.md`, `CONTRIBUTING.md`, `DESIGN.md`, `docs/ARCHITECTURE.md`
2. `lib/core/simulation/pod_simulator.dart`, `lib/core/models/sensor_metric.dart`, `pod_alert.dart`
3. `lib/data/data_providers.dart` (alert repository, telemetry, pods)

## You own (edit freely)

- `lib/app/` (router, shell, header), `lib/core/` (models, interfaces, theme, simulator, config)
- `lib/data/simulation/`, `lib/data/data_providers.dart` (non-live parts)
- `lib/features/alerts/`, `lib/features/settings/` (create it)
- `test/app/`, `test/core/`, `test/data/`, `test/helpers/`, `test/features/alerts/`, `test/features/settings/`
- `docs/` (except other members' task files), `.github/`, `.run/`, `tool/`

Osanda owns `lib/shared/widgets/` and the screens' look; ask him before changing shared widgets.

## Tasks

### 0. ALWAYS: Route requests and a healthy `main`

Teammates ask for routes. Add the path to `AppRoutes` and a `GoRoute` in `app_router.dart` in a
small `feat(router): ...` PR within an hour. If CI goes red on `main`, fixing it beats every
other task. Keep `ARCHITECTURE.md`, `DESIGN.md` and `AGENTS.md` true when shared code changes.

### 1. MUST: Alert engine (`feature/tharindu-alert-engine`)

Create `lib/features/alerts/application/alert_engine.dart`.

- Listens to `telemetryRepositoryProvider.watchReadings(podId)` for every pod in `podsProvider`.
- For each `SensorMetric`, works out `metric.statusOf(metric.valueOf(reading))`.
- Raises a `PodAlert` through `alertRepositoryProvider.add(...)` when a metric **moves into**
  warning or critical (edge-triggered, not on every reading).
- Cooldown: at most one alert per pod + metric + severity every 5 minutes.
- Human titles and messages per metric and direction, for example `pH is too low` /
  `Pod Alpha reads pH 4.8. Add pH-up or change the water.`
- Started once by `alertEngineProvider`, watched by `AppShell`, so it runs while the app is open.
- Pure decision logic (status change + cooldown) in `lib/features/alerts/domain/alert_rules.dart`,
  no Flutter imports, clock passed in.

Tests (`test/features/alerts/domain/alert_rules_test.dart`): normal to critical raises one alert;
staying critical raises no more; cooldown blocks repeats within 5 minutes; recovery then a new
drop raises again.

Done when: Care > Pod simulator > **pH crash**, then the Home bell shows 1 and Alerts lists `pH is too low`.

### 2. MUST: Local notifications (`feature/tharindu-notifications`)

- `lib/features/alerts/application/notification_service.dart` with `flutter_local_notifications`,
  behind a small interface so tests can use a fake.
- Android channel `pod_alerts`, high importance, icon `@mipmap/ic_launcher`.
- Ask for the notification permission (Android 13+) on first launch after sign-in, after a short
  dialog explaining why ("Get notified when your plants need you").
- Notify for every **critical** alert. Tapping it opens `/alerts`.

Done when: with the app in the background, a pH crash shows a system notification.

### 3. SHOULD: Alerts screen polish (`feature/tharindu-alerts-ui`)

Group into `Today` and `Earlier`, severity colour bar, swipe to mark read. Ask Osanda for a quick
UX review. Optionally keep alerts across restarts with a Hive-backed `IAlertRepository`.

### 4. MUST: Settings and privacy (`feature/tharindu-settings`)

`lib/features/settings/presentation/settings_screen.dart`, route `/settings`, a "Settings" tile in Care:

- Theme: Light / Dark / System (`themeModeProvider`), remembered in Hive `app_preferences`.
- Data mode shown read-only (`Simulation` or `Live`), and the app version.
- **Privacy note** (lecture 9): what is stored, where, and a `Delete my local data` button
  (confirm dialog, clears the Hive boxes).
- About: team names and the module code.

### 5. SHOULD: Bundle the Inter font (`feature/tharindu-inter-font`)

Add Inter Regular, Medium, SemiBold and Bold (`.ttf`, OFL licence) to `assets/fonts/`, declare the
family in `pubspec.yaml`, set `fontFamily: 'Inter'` in `AppTheme`, update DESIGN.md.

### 6. MUST: Demo-flow widget test (`test/app/demo_flow_test.dart`)

One widget test that walks the demo: sign in, Home shows pods, simulator pH crash, alert appears,
open Crops, open Insights. Uses `testApp()` and `sim.tick()`.

### 7. MUST (Monday): Slides and demo script

Slides: problem, Figma flow, architecture diagram, lecture coverage, security, testing, demo,
future work. Rehearse `docs/DEMO.md` twice. Record a backup screen video.

## Demo lines you present (about 1.5 minutes)

Opening: the problem, the pod, the Figma design, why Flutter in Android Studio. Closing: the MVVM
architecture, the alert engine as a background service, tests and CI, iOS comparison, future work.

## Lectures you cover

L3 (platform choice), L4 (architecture, services), L10 (tests, CI), L11 (iOS), security (privacy note).
