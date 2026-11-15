# AGENTS.md: instructions for AI coding agents

You are helping one member of a five-person student team build **AquaGrow Connect**, a
Flutter Android app (built in Android Studio) for the AquaGrow hydroponic pod. The demo is
on **Tuesday 17 November 2026**. Feature freeze is **Sunday 15 November, 9 PM**.

Follow every rule in this file. When a rule here conflicts with your own habits, this file wins.

---

## STEP 1: Find out who you are working for

The user's first message says their name, for example: *"I am Osanda. Read AGENTS.md and do my tasks."*

| Name | Task file |
| --- | --- |
| Tharindu | `docs/tasks/tharindu.md` |
| Osanda | `docs/tasks/osanda.md` |
| Sameera | `docs/tasks/sameera.md` |
| Imasha | `docs/tasks/imasha.md` |
| Udeshika | `docs/tasks/udeshika.md` |

If the user did not give a name, **ask for it before doing anything else.** Never do work
from another member's task file.

## STEP 2: Read, in this order, before writing any code

1. That member's task file (above). It lists the folders they own and their tasks in priority order.
2. `CONTRIBUTING.md`: branches, commits, PRs, tests, definition of done.
3. `docs/ARCHITECTURE.md`: layers, folders, providers, navigation, security.
4. `DESIGN.md`: colours, type, spacing, components, screen rules.
5. The existing code the task names (start with `lib/data/data_providers.dart` and the screen you will change).

Then tell the user, in 3 to 5 lines: which task you will do first, which branch you will
create, and which files you expect to touch. Wait for a yes if anything is unclear.

## STEP 3: Work in this loop, one task at a time

```
git switch main && git pull
git switch -c feature/<name>-<task>            # e.g. feature/osanda-alert-engine
repeat for each small step:
    write the code AND its test
    dart format lib test
    flutter analyze                             # must show no errors or warnings
    flutter test                                # must be all green
    git add <only the files for this step>
    git commit                                  # one small, atomic, conventional commit
git push -u origin feature/<name>-<task>
open a PR into main using the template; tick the task's checkbox in the same PR
merge only when CI's "Commit messages" and "Analyze and test" checks are green, and only
    if the user says to (merge order: Sameera, then any teammate after ~30 min, then the
    author when blocked or near a deadline; see CONTRIBUTING.md section 4)
```

Then move to the next task on a new branch from the updated `main`.

If you cannot run `flutter`, say so plainly and do not claim the code was tested.

---

## Hard rules (never break these)

### Ownership

- Edit ONLY the folders listed under "You own" in the member's task file.
- Never edit: `lib/core/**`, `lib/app/**`, `lib/data/data_providers.dart`, `pubspec.yaml`,
  `android/**`, `supabase/**`, or another member's feature folder, **unless the task file says
  that member owns it.** If you need a change there, stop and write the exact request for the
  user to send to the owner (for example, a new route for Tharindu).
- You may ADD new widgets to `lib/shared/widgets/` (not change existing ones) and add tests anywhere under `test/`.

### Commits

- Conventional Commits: `type(scope): summary`, for example `feat(alerts): raise alert when pH leaves range`.
- Small and atomic: one logical change per commit, app still builds after each one. Never one big end-of-day commit.
- **Never mention any AI tool, model, assistant or agent in a commit message, PR title or PR
  description, and never add an AI `Co-authored-by` trailer.** Write as the student engineer.
  The `commit-msg` hook (`git config core.hooksPath tool/hooks`) and CI reject violations.
- Never commit to `main`. Never force-push to `main`. Never rewrite other people's commits.
- Never commit secrets, `env/*.json` (except `env/example.json`), keystores or `key.properties`.

### Code

- Architecture: screens read Riverpod providers; providers read repositories through interfaces
  in `lib/core/interfaces/`. Screens never call Supabase, Hive, HTTP or the simulator directly
  (the simulator panel is the only exception).
- Shared data comes from `lib/data/data_providers.dart`. Do not create a second copy of a repository or simulator.
- Imports: `package:aquagrow_mobile/...` only. No relative imports in `lib/`.
- No `print`: use `AppLogger('<feature>')`.
- No hex colours, raw font sizes or raw padding numbers in features: use `context.ag`,
  `Theme.of(context).textTheme`, `AgSpace`, `AgRadius` (see `DESIGN.md`).
- Every list and chart handles loading, error, empty and data (`AsyncValueView`).
- Every risky action (pump, light, dosing, logout, delete, harvest) uses `showConfirmDialog`.
- Lists use `ListView.builder`. Layouts adapt with `LayoutBuilder` (2 columns under 600 px, 4 above).
- Pure logic goes in `domain/` with no Flutter imports, and gets unit tests.
- Every public class and method gets a short `///` doc comment.
- Do not add packages. If one is truly needed, stop and ask the user to request it from Sameera or Tharindu.

### Tests

- Tests never use the network, a real clock, real timers or real plugins.
- For widget tests use `testApp()` from `test/helpers/test_app.dart`, and a
  `PodSimulator(clock: () => DateTime(2026, 11, 15, 10))` that you `tick()` by hand.
- Never delete or weaken an existing test to make CI pass. Fix the code instead.

---

## Project facts you will need

- Package name: `aquagrow_mobile`. Android application id: `com.futurix.aquagrow`. minSdk 24.
- State: Riverpod 2 (`flutter_riverpod`). Navigation: `go_router` (`lib/app/router/`). Paths in `AppRoutes`.
- Data mode: `simulation` by default (no network needed). `live` uses Supabase when keys are in `env/dev.json`.
- Demo pods: `pod-alpha` (Pod Alpha, Kitchen, Genovese Basil) and `pod-beta` (Pod Beta, Dining room, Baby Spinach).
- Metrics and safe ranges: `SensorMetric` (`ph`, `ec`, `waterTemp`, `waterLevel`) with `statusOf`, `format`, `targetLabel`.
- Scenarios for the demo: `SimScenario` (`acidSpike`, `lowWater`, `heatwave`, `doserEmpty`, `sensorOffline`, ...).
- Run in Android Studio with the **AquaGrow (simulation)** run configuration, or `flutter run`.

## Useful providers (`lib/data/data_providers.dart`)

| Provider | Gives you |
| --- | --- |
| `podsProvider` | `AsyncValue<List<Pod>>`, live |
| `selectedPodIdProvider` / `selectedPodProvider` | The pod the user is looking at |
| `latestReadingProvider(podId)` | `AsyncValue<SensorReading>`, live |
| `actuatorStateProvider(podId)` | Pump, light, doser state, live |
| `telemetryRepositoryProvider` | `.history(podId, from:, to:)` for charts |
| `controlRepositoryProvider` | `.setPump`, `.setLight`, `.dosePhDown`, `.markRefilled` |
| `alertRepositoryProvider` / `alertsProvider` / `unreadAlertCountProvider` | Alerts |
| `appConfigProvider` | Keys and data mode |
| `preferencesStoreProvider` | Small device settings in Hive `app_preferences` (`getBool`, `setString`, ...) |
| `localDataEraserProvider` | `.eraseAll()`: deletes local readings, queue and preferences (Settings > Privacy) |
| `podSimulatorProvider` | The simulator (simulator panel only) |

## When you are unsure

Stop and ask the user one clear question. Do not guess about ownership, packages, or shared files.
