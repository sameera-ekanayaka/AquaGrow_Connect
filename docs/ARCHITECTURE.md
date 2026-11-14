# Architecture

AquaGrow Connect is a Flutter app for Android, built in Android Studio. It is the
companion app for the AquaGrow modular hydroponic pod. It uses **MVVM with a repository
layer**: screens (Views) watch Riverpod providers (ViewModels), and providers read
repositories (Model). Screens never talk to Supabase, Hive or the simulator directly.

## 1. Layers and the one rule

```
 ┌───────────────────────────────────────────────────────────────┐
 │  lib/features/<feature>/presentation   Screens + widgets (View)│
 │  lib/features/<feature>/application    Providers/controllers  │
 │                                        (ViewModel)             │
 └──────────────────────────┬────────────────────────────────────┘
                            │ ref.watch(...)
 ┌──────────────────────────▼────────────────────────────────────┐
 │  lib/data/data_providers.dart   Composition root: picks the   │
 │                                 data source by DataMode        │
 └──────────────────────────┬────────────────────────────────────┘
                            │ implements
 ┌──────────────────────────▼────────────────────────────────────┐
 │  lib/core/interfaces    Contracts (IPodRepository, ...)        │
 │  lib/core/models        Plain data classes (Pod, SensorReading)│
 └──────────────────────────▲────────────────────────────────────┘
                            │
 ┌──────────────────────────┴────────────────────────────────────┐
 │  lib/data/simulation    Simulator-backed repositories (demo)   │
 │  lib/data/supabase      Supabase-backed repositories (live)    │
 │  lib/core/simulation    PodSimulator: the virtual pod hardware │
 └───────────────────────────────────────────────────────────────┘
```

**Dependencies point down only.** `core` imports nothing from `data`, `features` or `app`.
`features` never import another feature's files. Shared things live in `core` or `shared`.

## 2. Folder map

| Folder | What lives there | Who edits it |
| --- | --- | --- |
| `lib/main.dart`, `lib/bootstrap.dart` | Startup: config, Hive, Supabase, error logging | Foundation (Tharindu) |
| `lib/app/` | `app.dart` (MaterialApp), `router/` (go_router, auth redirect), `shell/` (bottom nav, tab header, offline banner) | Tharindu |
| `lib/core/config/` | `AppConfig`, `DataMode` from `--dart-define` | Frozen |
| `lib/core/models/` | `Pod`, `CropBatch`, `SensorReading`, `SensorMetric`, `ActuatorState`, `PodAlert`, ... | Frozen (ask the group) |
| `lib/core/interfaces/` | Repository contracts | Frozen (ask the group) |
| `lib/core/simulation/` | `PodSimulator`, `SimScenario` | Frozen (ask Tharindu) |
| `lib/core/theme/` | `AgColors`, `AgSpace`, `AgRadius`, `AppTheme` from Figma | Tharindu (Osanda may tune token values to match Figma) |
| `lib/core/errors/`, `logging/`, `utils/` | `AppFailure`, `AppLogger`, `Validators` | Frozen |
| `lib/data/` | Repository implementations and `data_providers.dart` | Sameera (live), Tharindu (sim) |
| `lib/shared/widgets/` | UI kit: `SensorTile`, `StatusBadge`, `SectionHeader`, state views, `showConfirmDialog`, crop widgets | Osanda (others may ADD new widgets) |
| `lib/features/<name>/` | One folder per feature, owned by one person | See [docs/tasks](tasks/) |
| `test/` | Mirrors `lib/`. One test file per source file that has logic | Everyone |
| `android/` | Gradle project, manifest, permissions, signing | Sameera |
| `supabase/migrations/` | SQL schema and RLS policies | Sameera |

Legacy files from the first sprint (`core/constants/app_colors.dart`,
`core/theme/biophilic_theme.dart`, `core/mocks/`, `core/interfaces/i_sensor_repository.dart`)
are still used by the auth and location screens. Their owners move those screens to the
new theme and delete the legacy files as part of their tasks. Do not use them in new code.

## 3. Inside a feature

```
lib/features/crops/
  domain/          Pure Dart logic, no Flutter imports (calculations, rules). Easy to unit test.
  application/     Riverpod providers and controllers (the ViewModel).
  presentation/    Screens (*_screen.dart) and widgets/ used only by this feature.
```

Create `domain/` and `application/` only when you need them. A screen that just shows a
provider's data can live in `presentation/` alone.

## 4. Data modes

`AppConfig.dataMode` decides where data comes from. It is set at build time:

| Mode | How to get it | Data source |
| --- | --- | --- |
| `simulation` (default) | Run with no env file, or `DATA_MODE=simulation` | `PodSimulator`. No network needed. Used for the demo. |
| `live` | `env/dev.json` with `DATA_MODE=live` and Supabase keys | Supabase (auth, devices, telemetry). Falls back to simulation if keys are missing. |

Only `lib/data/data_providers.dart` reads the mode. Everything else just reads providers.

## 5. The pod simulator

`PodSimulator` (`lib/core/simulation/pod_simulator.dart`) stands in for the ESP32 pod:

- Two demo pods, **Pod Alpha** (Kitchen, Genovese Basil) and **Pod Beta** (Dining room, Baby Spinach).
- Every 2 seconds each pod's pH, EC, water temperature and water level drift toward a target with small noise.
- Controls change the physics: pump off warms the water, pH-down lowers pH by 0.15, refilling sets water to 100%.
- `SimScenario`s (pH crash, low water, heatwave, empty doser, offline, ...) are triggered from the
  **Pod simulator** screen (Care tab) during the demo.
- `history()` returns a believable, repeatable week of hourly readings for charts.
- In tests, pass a fixed `clock` and call `tick()` by hand. Never `start()` it in a test.

## 6. State management rules (Riverpod 2)

- Read shared data only through `lib/data/data_providers.dart`:
  `podsProvider`, `selectedPodIdProvider`, `selectedPodProvider`, `latestReadingProvider(podId)`,
  `actuatorStateProvider(podId)`, `alertsProvider`, `unreadAlertCountProvider`, and the repository providers.
- Put a feature's own providers in `lib/features/<feature>/application/<feature>_providers.dart`.
- Use `StreamProvider` for live data, `FutureProvider` for one-off loads, and
  `StateNotifierProvider` or `AsyncNotifierProvider` for screens with actions.
- Render every `AsyncValue` with `AsyncValueView` so loading, error, empty and data are all handled.
- Keep form text in a `TextEditingController` owned by a `ConsumerStatefulWidget`, so rotation keeps it.

## 7. Navigation

go_router, configured in `lib/app/router/app_router.dart`. Paths live in `AppRoutes`.

- The four tabs are `StatefulShellRoute` branches, so each tab keeps its own stack.
- `context.go(...)` switches location, `context.push(...)` opens a screen with a back arrow.
- The auth redirect keeps signed-out users on login and register only.
- To add a screen: add the path to `AppRoutes`, add a `GoRoute`, then navigate. Ask Tharindu to review router changes.

## 8. Errors and logging

- Repositories catch exceptions and throw an `AppFailure` subtype with a safe, friendly message.
- `AsyncValueView` shows `AppFailure.message`. Never show `e.toString()` to users.
- Log with `const _log = AppLogger('feature-name');`. Never `print`. Logs appear in Android Studio Logcat.

## 9. Security (lecture 9, OWASP Mobile Top 10)

| Risk | What we do |
| --- | --- |
| Secrets in code | Keys come from `env/dev.json` via `--dart-define-from-file`. The file is git-ignored. |
| Insecure storage | Tokens only in `flutter_secure_storage` (Android Keystore). Never in Hive or SharedPreferences. |
| Data access | Supabase Row Level Security: users read and write only their own devices (`supabase/migrations`). |
| Network | HTTPS only. Cleartext blocked in `network_security_config.xml`. |
| Risky actions | Pump, light, dosing and logout need a confirm dialog. Biometric unlock before controls (Should have). |
| Backups | `android:allowBackup="false"` so app data is not copied to cloud backups. |
| Input | Every form uses `Validators`, with numeric ranges for pH and EC. |
| Permissions | Ask for location and notifications only when the feature is opened, with a reason shown first. |

## 10. Lecture coverage map

| Lecture | Where it shows in the code |
| --- | --- |
| L1 Mobile networks | `OfflineBanner` + `isOfflineProvider`, Hive cache, sync on reconnect |
| L2 Mobile OS | Runtime permissions (location, notifications), `AndroidManifest.xml`, minSdk 24 |
| L3 Platforms | Flutter on Android, built in Android Studio (report) |
| L4 Architecture | MVVM + repositories + composition root, Activity = `MainActivity`, lifecycle |
| L5 UI and navigation | Material 3, bottom `NavigationBar`, AppBar, dialogs, `ListView.builder` |
| L6 UI/UX flow | Figma design tokens in `AppTheme`, 48 dp touch targets, contrast |
| L7 Web APIs | OpenWeatherMap REST + JSON (`core/services/weather_service.dart`) |
| L8 Location and sensors | `geolocator`, supplier map, `sensors_plus` shake to refresh |
| L9 Databases | Supabase Postgres + RLS, Hive offline cache, secure storage |
| L10 Testing | `test/` unit and widget tests, CI on every PR, Logcat logging |
| L11 iOS | Same codebase could target iOS (report only) |
