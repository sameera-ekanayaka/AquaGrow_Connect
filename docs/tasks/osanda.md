# Osanda: UI/UX lead (Home, shared widgets, controls, onboarding)

You own how the app looks and feels. You build the screens examiners notice first (Home, the
shared crop widgets, onboarding) and you review every screen PR so the whole app matches Figma.

## Read first

1. `AGENTS.md`, `CONTRIBUTING.md`, `DESIGN.md`, `docs/ARCHITECTURE.md`
2. Figma file "AquaGrow": page "01 — Refined Direction" (components, Home, My Pods) and
   "Page 1" (splash, onboarding)
3. `lib/core/theme/app_tokens.dart`, `lib/shared/widgets/` (the UI kit you will extend)
4. `lib/data/data_providers.dart` (every provider you need already exists)
5. `lib/features/dashboard/presentation/home_screen.dart` (your starting point)

## You own (edit freely)

- `lib/shared/widgets/` (you may change existing widgets too; keep their tests passing)
- `lib/features/dashboard/`, `lib/features/controls/` (create it), `lib/features/simulator/`,
  `lib/features/onboarding/` (create it)
- `assets/images/`
- `test/shared/`, `test/features/dashboard/`, `test/features/controls/`, `test/features/onboarding/`

**Do not edit:** `lib/core/` (ask Tharindu, except `lib/core/theme/` where you may adjust token
values to match Figma), `lib/data/`, `lib/app/` (ask Tharindu for routes), `pubspec.yaml`,
other members' feature folders. Your old branch `feature/m1-telemetry-simulator` is replaced by
`PodSimulator`. Do not merge it.

## Tasks

### 0. FIRST, before anyone else starts: Verify the foundation on a real device

The foundation (PR #4, branch `chore/foundation`) passes CI (analyze, tests, APK build), but it
was written on a laptop without Flutter, so nobody has run it on a device yet. You check it,
so the other four start from a base that works.

```bash
git fetch origin
git switch chore/foundation
flutter pub get
flutter analyze            # expect: no errors, no warnings
flutter test               # expect: all tests pass
```

Then in Android Studio run **AquaGrow (simulation)** on an emulator AND, if you can, a real phone:

1. The login screen appears. Tap the demo account button and sign in. Home shows **Your garden**.
2. Home shows **Pod Alpha · Kitchen** with a **Live** badge and 4 tiles (pH, Nutrients (EC), Water temp,
   Water level) whose values change every 2 seconds.
3. The bottom bar switches between Home, Crops (two pods), Insights and Care.
4. Care > **Pod simulator** > **pH crash**, then back to Home: the pH tile shows 4.8 in red.
5. Care > Pod simulator > **Pod offline** on Pod Beta: no crash. **Healthy pod** brings it back.
6. Rotate the phone on Home: the layout still fits, no overflow stripes.
7. Turn on flight mode: the offline banner appears; turn it off: it goes away.
8. Profile > Sign out asks for confirmation, then returns to login.

If something fails, fix it on a branch `fix/osanda-foundation-<what>` made from `chore/foundation`,
open a PR into `chore/foundation`, and tell Tharindu. When all 8 steps pass, comment on PR #4:
`Verified on <emulator/phone model>, Android <version>: all 8 checks pass.` and tell the group
in WhatsApp. Sameera then merges PR #4 and everyone starts.

### 1. MUST, by Sunday 11 AM: Shared crop widgets (`feature/osanda-crop-widgets`)

- [x] Done: `CropTile`, `CropHero`, `PodCard` and `CropPhoto` from the minimal Figma file (PR #9).

Udeshika (My Pods) and your own Home screen need these. Build them in `lib/shared/widgets/`
from the Figma components, export them in `widgets.dart`, and add a widget test for each:

- `CropTile({title, detail, imageAsset})`: 166 wide, photo 112 high, radius 20, title
  `titleMedium`, detail `bodySmall`. Without `imageAsset`, a `subtle` box with an eco icon.
- `CropHero({name, badgeLabel, caption, imageAsset})`: photo card radius 24, about 286 high,
  `StatusBadge` top-left, near-black summary box (radius 20) at the bottom with white
  `titleLarge` name and `bodySmall` caption.
- `PodCard({cropName, location, stageLabel, harvestLine, imageAsset, onTap})`: Figma "Pod card":
  photo with a stage badge, then name, `Kitchen · Pod Alpha`, stage in text colour, harvest line.

Post in WhatsApp as soon as it is merged. If you will miss 11 AM, tell Udeshika so the pod card
gets built inside `lib/features/crops/` instead.

### 2. MUST: Home screen to Figma (`feature/osanda-home`)

- [x] Done: `PodSelector` + "Choose a pod" sheet, `priorityTaskFor` + `PriorityTaskCard` (refill with confirm), `CropHero`, "Updated 12s ago", Your plants, offline state.

Match "Home / Opaque / Refined", top to bottom:

1. `TabHeader` (exists).
2. **Pod selector card**: `Pod Alpha · Kitchen` + `StatusBadge('Live · 12s ago', brand)` or `Offline`.
   Tap opens a bottom sheet listing pods; picking one sets `selectedPodIdProvider`.
3. **Priority task card** (warning surface, radius 20): the single most urgent problem from the
   latest reading (critical before warning; water level before pH before temp before EC). Example:
   `Water needs attention` / `Refill Pod Alpha today.` / button `Mark as refilled`
   (confirm dialog, then `controlRepositoryProvider.markRefilled`). Hidden when all is normal.
   Put the "most urgent problem" logic in `lib/features/dashboard/domain/priority_task.dart` and unit test it.
4. **Crop hero** (`CropHero`): `Day 8 · Growing`, crop name, `Harvest est. in 20 days`.
5. **Growing conditions**: `SectionHeader(caption: 'Updated 12s ago')` + the tiles grid (exists).
6. **Your plants**: `CropTile`s for the other pods' crops; `View crops` goes to `AppRoutes.crops`.

Offline pod: `Offline` badge, controls disabled. Loading and error states via `AsyncValueView`.

### 3. MUST: Pod controls UI (`feature/osanda-controls`)

- [x] Done: `PodControlsCard` on Home (pump, light, brightness, pH down) with confirm, busy, dosing and offline states (PR #23). The per-command fingerprint check was replaced by the optional app lock in Settings.

`lib/features/controls/presentation/pod_controls_card.dart`, on Home under the readings.

- Pump switch, grow light switch, brightness slider (0 to 100, applies on release), `pH down` button.
- State from `actuatorStateProvider(podId)`. Commands through `controlRepositoryProvider`.
- **Every command asks first** with `showConfirmDialog`. Turning the pump off is `destructive: true`.
- While a command runs: small progress indicator, control disabled.
- `pH down` shows the `PhDoseResult`: applied (SnackBar `pH lowered`), noEffect (warning text
  `No change. Check the pH-down bottle (2 of 5).`), locked (critical text `Dosing locked for safety`).
- Pod offline: controls disabled with the reason shown. Catch `DeviceFailure` and show its message.
- If Sameera's `biometricGuardProvider` exists, call it before sending (Should have).

Test: tapping the pump switch opens the dialog; Cancel changes nothing; Confirm turns it off.

### 4. ALWAYS: UX review of screen PRs

Review every PR that changes a screen (Crops, Insights, auth, alerts, settings) against
`DESIGN.md` and Figma before Sameera merges: tokens only, 48 dp targets, four states, light and
dark mode, no overflow at 360 px wide. Comment with specific fixes. Keep a short heuristics table
(Nielsen's 10 heuristics, one row each, where the app meets it) in `docs/UX_REVIEW.md` for the
report (lecture 6).

### 5. SHOULD: Splash and onboarding (`feature/osanda-onboarding`)

Figma "Splash Screen" and "Onboarding Screen": logo splash, then 3 slides
(Grow fresh food at home / Know your plants live / Get alerted before it's too late) shown once,
remembered in Hive `app_preferences`. Ask Tharindu to add the route and the first-launch redirect.

- [x] Done: `SplashScreen`, `OnboardingScreen` (3 slides, Skip, dots, Get started) and `OnboardingStore` (`onboarding_seen` in `app_preferences`). Route and first-launch redirect requested from Tharindu.

### 6. SHOULD: Simulator panel polish (`feature/osanda-simulator-ui`)

Show the selected pod's live pH, water level and temperature at the top of the panel so the
presenter sees the change happen. Group scenarios as Water, Nutrients, Device.

- [x] Done: live pH, water level and water temp tiles at the top of the panel, scenarios grouped as Water, Nutrients and Device, and a reset-to-healthy button.

### 8. MUST (Monday, by 10 PM): Release APK (handed over from Tharindu's task 8, PR #50)

Build after #51 (alerts polish) and #52 (Inter font) are merged. On the laptop with Android
Studio and the demo phone, follow `docs/RELEASE.md`:

- Create the upload keystore **outside the repo** and write `android/key.properties` (git-ignored).
  Never commit either, and never put the password in a commit, PR or chat.
- `flutter build apk --release` (simulation mode, as `docs/DEMO.md` expects), check the signature,
  `adb install -r` on the demo phone.
- Run the whole of `docs/DEMO.md` once on the installed APK and tick the checklist at the end of
  `docs/RELEASE.md`. Sameera can help with `android/` signing questions.

- [ ] Done: signed release APK installed on the demo phone and the full demo run passes.

## Demo lines you present (about 1.5 minutes)

"This is Home, built from our Figma design. Pod Alpha is live. I'll crash the pH from the
simulator... the tile turns red and the task card tells me what to do. Now I'll turn the pump
off: the app asks me first, because that is risky."

## Lectures you cover

L5 (Material, navigation, dialogs, bottom sheet), L6 (Figma, heuristics, UX review),
L4 (MVVM view layer), ILO6 (IoT controls).
