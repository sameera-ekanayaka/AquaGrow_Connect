# Osanda: IoT dashboard, controls and alerts

You make the pod feel alive: live readings on Home, controls that change the pod, and
alerts when something goes wrong. Your part is the centre of the demo.

## Read first

1. `AGENTS.md`, `CONTRIBUTING.md`, `DESIGN.md`, `docs/ARCHITECTURE.md`
2. `lib/core/simulation/pod_simulator.dart` (how the pod behaves)
3. `lib/data/data_providers.dart` (every provider you need already exists)
4. `lib/features/dashboard/presentation/home_screen.dart` (your starting point)

## You own (edit freely)

- `lib/features/dashboard/`
- `lib/features/controls/` (create it)
- `lib/features/alerts/`
- `lib/features/simulator/`
- `test/features/dashboard/`, `test/features/controls/`, `test/features/alerts/`

**Do not edit:** `lib/core/`, `lib/data/`, `lib/app/` (ask Tharindu to add routes), `pubspec.yaml`.
Your old branch `feature/m1-telemetry-simulator` is replaced by `PodSimulator`. Do not merge it.

## Tasks

### 1. MUST: Alert engine (`feature/osanda-alert-engine`)

Create `lib/features/alerts/application/alert_engine.dart`.

- Listens to `telemetryRepositoryProvider.watchReadings(podId)` for every pod in `podsProvider`.
- For each `SensorMetric`, works out `metric.statusOf(metric.valueOf(reading))`.
- Raises a `PodAlert` through `alertRepositoryProvider.add(...)` when a metric **moves into**
  warning or critical (edge-triggered, not on every reading).
- Cooldown: at most one alert per pod + metric + severity every 5 minutes.
- Titles and messages are human: `pH is too low` / `Pod Alpha reads pH 4.8. Add pH-up or change the water.`
  Write one message per metric and direction (low and high).
- Start the engine once from a provider (`alertEngineProvider`) that Home watches, so it runs while the app is open.
- Put the pure decision logic (status change + cooldown) in `lib/features/alerts/domain/alert_rules.dart`
  with no Flutter imports, and pass the clock in.

Tests (`test/features/alerts/domain/alert_rules_test.dart`): normal to critical raises one alert;
staying critical raises no more; cooldown blocks repeats within 5 minutes; recovery then a
new drop raises again. Use a fixed clock.

Done when: Care > Pod simulator > **pH crash**, then the Home bell shows 1 and Alerts lists `pH is too low`.

### 2. MUST: Local notifications (`feature/osanda-notifications`)

- `lib/features/alerts/application/notification_service.dart` using `flutter_local_notifications`.
- Android channel `pod_alerts`, high importance. App icon `@mipmap/ic_launcher`.
- Ask for the notification permission (Android 13+) the first time Home opens, after a short
  explanation dialog ("Get notified when your plants need you").
- Show a notification for every **critical** alert from the engine. Tapping it opens `/alerts`.
- Wrap the plugin behind a small interface so tests can use a fake.

Done when: with the app in the background, a pH crash shows a system notification.

### 3. MUST: Home screen to Figma (`feature/osanda-home`)

Match the Figma "Home / Opaque / Refined" screen, top to bottom:

1. `TabHeader` (exists).
2. **Pod selector card**: `Pod Alpha · Kitchen` + `StatusBadge('Live · 12s ago', brand)` or `Offline`.
   Tap opens a bottom sheet listing pods; picking one sets `selectedPodIdProvider`.
3. **Priority task card** (warning surface, radius 20): the single most urgent problem from the
   latest reading (critical before warning; water level before pH before temp before EC). Example:
   `Water needs attention` / `Refill Pod Alpha today.` / button `Mark as refilled`
   (confirm dialog, then `controlRepositoryProvider.markRefilled`). Hide the card when all is normal.
   Put the "most urgent problem" logic in `lib/features/dashboard/domain/priority_task.dart` and test it.
4. **Crop hero**: photo, `Day 8 · Growing` badge, dark summary box with crop name and
   `Harvest est. in 20 days`. Use the shared `CropHero` widget if Tharindu has merged it; otherwise
   build it in `dashboard/presentation/widgets/` and tell Tharindu.
5. **Growing conditions**: `SectionHeader(caption: 'Updated 12s ago')` + the existing tiles grid.
6. **Your plants**: tiles for the other pods' crops, `View crops` goes to `AppRoutes.crops`.

Rules: offline pod shows the `Offline` badge and greys the tiles' captions; loading and error states use `AsyncValueView`.

### 4. MUST: Pod controls (`feature/osanda-controls`)

`lib/features/controls/presentation/pod_controls_card.dart`, shown on Home under the readings.

- Pump switch, grow light switch, brightness slider (0 to 100, applies on release), `pH down` button.
- Read state from `actuatorStateProvider(podId)`. Send commands through `controlRepositoryProvider`.
- **Every command asks first** with `showConfirmDialog`. Turning the pump off is `destructive: true`.
- While a command runs, show a small progress indicator and disable the control.
- `pH down` shows the `PhDoseResult`: applied (SnackBar `pH lowered`), noEffect (warning text
  `No change. Check the pH-down bottle (2 of 5).`), locked (critical text `Dosing locked for safety`).
- If the pod is offline, controls are disabled with the reason shown. Catch `DeviceFailure` and show its message.
- If Sameera's `biometricGuardProvider` exists, call it before sending (Should have).

Tests: a widget test that tapping the pump switch opens the dialog, Cancel changes nothing, Confirm turns it off.

### 5. SHOULD: Alerts screen polish (`feature/osanda-alerts-ui`)

Group into `Today` and `Earlier`, severity colour bar on the left, swipe to mark read,
and keep alerts across restarts with a Hive-backed `IAlertRepository` in `lib/features/alerts/data/`
(ask Tharindu to switch the provider).

### 6. SHOULD: Simulator panel polish (`feature/osanda-simulator-ui`)

Show the selected pod's live pH, water level and temperature at the top of the panel so the
presenter sees the change happen. Group scenarios as Water, Nutrients, Device.

## Demo lines you present (about 1.5 minutes)

"Here is Pod Alpha live. I'll crash the pH from the simulator... the tile turns red, a
notification arrives, and the alert is in the list. Now I'll turn the pump off: the app
asks me first, because that is risky."

## Lectures you cover

L4 (MVVM, Service = alert engine + notifications), L5 (Material, dialogs, bottom sheet, lists),
L8 (IoT sensing via the simulator), ILO6 (IoT).
