# AquaGrow Connect

The companion Android app for **AquaGrow**, a modular hydroponic pod that grows fresh herbs
and greens at home. The app shows each pod's live water readings, controls its pump, light
and pH doser, raises alerts before plants suffer, charts how each pod has been doing, and
issues a Harvest Passport QR for every crop.

Team Futurix · INTE 22283 Mobile Applications Development · University of Kelaniya

| | |
| --- | --- |
| Platform | Android (minSdk 24), Flutter, built in Android Studio |
| State and navigation | Riverpod 2, go_router |
| Backend | Supabase (Auth, Postgres with Row Level Security) |
| On-device storage | Hive (offline cache), flutter_secure_storage (Android Keystore) |
| Demo data | Built-in pod simulator: no hardware or network needed |
| Design | [Figma: AquaGrow, Refined Direction](https://www.figma.com/design/nuNDbA7UACR4QPQ2PVV4j3/AquaGrow) |

## Quick start (Android Studio)

1. Install **Flutter (stable)** and **Android Studio** with the **Flutter** and **Dart** plugins.
   Run `flutter doctor` and fix anything marked with a red cross.
2. Clone and set up:
   ```bash
   git clone https://github.com/sameera-ekanayaka/AquaGrow_Connect.git
   cd AquaGrow_Connect
   git config core.hooksPath tool/hooks
   flutter pub get
   ```
3. In Android Studio: **File > Open** and pick the `AquaGrow_Connect` folder.
4. Start an emulator (Device Manager) or plug in a phone with USB debugging on.
5. Choose the run configuration **AquaGrow (simulation)** and press **Run**.
6. Sign in with the **Use demo account** button. Explore Home, Crops, Insights and Care.
   To make things happen, open **Care > Pod simulator** and trigger a scenario.

### Using real Supabase or weather keys (optional)

```bash
cp env/example.json env/dev.json      # env/dev.json is git-ignored
```

Fill in `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `OPENWEATHER_API_KEY`, set `DATA_MODE` to `live`,
and run with the **AquaGrow (env file)** configuration
(or `flutter run --dart-define-from-file=env/dev.json`). Missing keys fall back to simulation.

## Common commands

| Task | Command |
| --- | --- |
| Run the app | `flutter run` |
| All tests | `flutter test` (or the **All tests** run configuration) |
| Static analysis | `flutter analyze` |
| Format | `dart format lib test` |
| Debug APK | `flutter build apk --debug` |
| Release APK | `flutter build apk --release` (needs `android/key.properties`, see `docs/tasks/sameera.md`) |

Every pull request runs commit-message checks, analysis, tests and a debug APK build on GitHub
Actions. The APK is attached to the CI run.

## Documentation

| File | Read it for |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Rules for AI coding agents working in this repo |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Branches, atomic commits, PRs, tests, definition of done |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers, folders, data modes, simulator, security, lecture map |
| [DESIGN.md](DESIGN.md) | Colours, type, spacing, components, screen rules |
| [docs/tasks/](docs/tasks/README.md) | Who builds what, with checklists and the timeline |
| [docs/DEMO.md](docs/DEMO.md) | The 7-minute demo script |

## Project structure

```
lib/
  main.dart, bootstrap.dart     Startup
  app/                          MaterialApp, router, bottom-nav shell, tab header
  core/                         Models, interfaces, theme, simulator, config, errors, logging
  data/                         Repository implementations + data_providers.dart
  shared/widgets/               Reusable UI kit from the Figma components
  features/<feature>/           One folder per feature, owned by one person
test/                           Mirrors lib/
android/                        Android Studio Gradle project
supabase/migrations/            Database schema and Row Level Security
docs/                           Architecture, tasks, demo
```

## Team

| Member | Area |
| --- | --- |
| Tharindu | Foundation, design system, app shell, settings, presentation |
| Osanda | IoT dashboard, controls, alerts and notifications, simulator panel |
| Sameera | Auth, Supabase, offline sync, security, release, code review |
| Imasha | Insights charts, weather and VPD, location, supplier map, sensors |
| Udeshika | Crops, growth stages, Harvest Passport, report |
