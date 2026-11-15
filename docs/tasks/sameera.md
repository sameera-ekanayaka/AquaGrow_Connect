# Sameera: auth, Supabase, offline sync, security and release

You make the app trustworthy: real accounts, data that survives going offline, secure
storage, and the signed APK we install for the demo. You also review and merge every PR.

## Read first

1. `AGENTS.md`, `CONTRIBUTING.md`, `DESIGN.md`, `docs/ARCHITECTURE.md`
2. `lib/data/data_providers.dart` (where live repositories plug in)
3. `lib/core/interfaces/` (the contracts your Supabase classes implement)
4. Your existing code: `lib/features/auth/`, `lib/features/storage/`, `supabase/migrations/`

## You own (edit freely)

- `lib/features/auth/`, `lib/features/storage/`, `lib/features/sync/` (create it)
- `lib/data/supabase/` (create it), `lib/core/network/`, `lib/core/security/`
- `android/`, `supabase/`
- `test/features/auth/`, `test/features/sync/`, `test/data/supabase/`
- You may edit the `DataMode.live` branches in `lib/data/data_providers.dart`.
- You may edit `pubspec.yaml` (tell the group when you do).

## Tasks

### 0. ALWAYS: Review and merge PRs

Check each PR against its template checklist and `CONTRIBUTING.md`. Merge only with green CI.
You are the first choice to merge, not the only one: if you are busy for more than about
30 minutes, another teammate may merge, and authors may self-merge when blocked or near a
deadline (see CONTRIBUTING.md section 4). Review self-merged PRs afterwards.
Prefer "Rebase and merge" so the small commits stay. Ask for changes when a PR edits
someone else's folder without agreement.

### 1. MUST: Auth screens to the new design (`feature/sameera-auth-ui`)

- [x] Done: login, register and profile on the Figma theme, forgot password, `AuthFailure` messages.

- Restyle `login_screen.dart`, `register_screen.dart`, `profile_screen.dart` with the Figma theme
  (`DESIGN.md`): white background, near-black filled button, Inter type, `AgSpace`/`AgRadius` tokens.
  Remove every use of `AppColors` and `GoogleFonts` from these files.
- Use `Validators.email` and `Validators.password` in the forms.
- Keep the one-tap **Use demo account** button for the viva.
- Add a **Forgot password** flow (`resetPassword`) with a clear success message.
- Show `AppFailure` messages, not raw exceptions: map Supabase `AuthException` to `AuthFailure`
  inside `AuthRepository`.

Tests: widget test that an invalid email shows the error text and does not call `signIn`.

### 2. MUST: Offline cache and sync (`feature/sameera-sync`)

- [x] Done: `SyncService` (cache, Hive queue, batches of 50), Supabase uploader, migration 002, Profile "Last synced", `SyncListener`. `SyncListener` is in `AppShell` (#19).

- `lib/features/sync/application/sync_service.dart`:
  - caches every reading from `telemetryRepositoryProvider` into `LocalCacheService` (72-hour window, exists),
  - while `isOfflineProvider` is true, queues readings to upload,
  - when the connection returns, uploads the queue to Supabase `telemetry_logs` (if Supabase is configured)
    in batches of 50, then clears it. Without Supabase, it logs `would upload N readings` and clears.
- Show `Last synced 2 min ago` in the profile screen and a short SnackBar `Back online · 37 readings synced`.
- Conflict rule (write it in the doc comment): readings are append-only, so the server keeps every row;
  duplicates are ignored by reading id.

Tests: queue grows while offline, flushes on reconnect, never exceeds `AppConstants.maxOfflineQueueItems`.

Done when: turn on flight mode, wait 20 s, turn it off: the SnackBar shows readings synced.

### 3. MUST: Release APK (Monday, `chore/sameera-release`)

- [x] Moved to Tharindu (task 8 in `docs/tasks/tharindu.md`). Steps written in `docs/RELEASE.md`.

- Create an upload keystore (outside the repo), write `android/key.properties` (git-ignored).
- `flutter build apk --release`, install on the demo phone, run the whole demo once on it.
- Write the steps in `docs/RELEASE.md` without any passwords.

### 4. SHOULD: Biometric guard (`feature/sameera-biometric`)

- [x] Done: `BiometricGuard.confirm` + `biometricGuardProvider`, FragmentActivity and AppCompat launch theme.

`lib/core/security/biometric_guard.dart` + `biometricGuardProvider`:
`Future<bool> confirm(String reason)` using `local_auth`. Returns true when the device has no
biometrics (so the demo never blocks). Osanda calls it before pump and light commands.

### 5. SHOULD: Live Supabase repositories (`feature/sameera-supabase-repos`)

- [x] Done: `SupabasePodRepository`, `SupabaseTelemetryRepository` (realtime + Hive fallback), live branches wired, migration 004, `supabase/seed/demo_account.sql`.

`lib/data/supabase/supabase_pod_repository.dart` (`devices` table) and
`supabase_telemetry_repository.dart` (`telemetry_logs`, realtime channel for new rows, Hive fallback).
Return them from the `DataMode.live` branches in `data_providers.dart`. Add a migration
`002_*.sql` only if you need new tables, with RLS policies like `001`.

### 6. SHOULD: Remove legacy code

- [x] Done: removed `biophilic_theme.dart`, `app_colors.dart`, `mock_sensor_repository.dart` and `i_sensor_repository.dart` (#45).

When no screen imports them any more, delete `lib/core/constants/app_colors.dart`,
`lib/core/theme/biophilic_theme.dart`, `lib/core/mocks/mock_sensor_repository.dart` and
`lib/core/interfaces/i_sensor_repository.dart` in one `refactor` commit. Check with the group first.

## Demo lines you present (about 2 minutes)

"Accounts use Supabase Auth, tokens live in the Android Keystore, and Row Level Security means
I can only read my own pods." Later: "I'll switch on flight mode... the app keeps working from
the cache. Back online, and the queued readings sync."

## Lectures you cover

L1 (offline, reconnect), L2 (permissions, manifest), L9 (Supabase, Hive, secure storage, RLS),
CLO5 security, deployment (signed APK).
