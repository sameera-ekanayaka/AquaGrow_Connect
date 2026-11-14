# Team tasks

Each person has one task file. It lists exactly what to build, which folders you own,
and how to know you are finished. Work top to bottom: items are in priority order.

| Person | Role | Task file | Owns |
| --- | --- | --- | --- |
| Tharindu | Foundation, alert engine, notifications, settings, slides | [tharindu.md](tharindu.md) | `lib/app/`, `lib/core/`, `lib/data/simulation/`, `lib/features/alerts/`, `lib/features/settings/` |
| Osanda | UI/UX lead: shared widgets, Home, controls UI, onboarding, design review | [osanda.md](osanda.md) | `lib/shared/widgets/`, `lib/features/dashboard/`, `lib/features/controls/`, `lib/features/simulator/`, `lib/features/onboarding/` |
| Sameera | Auth, Supabase, offline sync, security, release APK, PR reviews | [sameera.md](sameera.md) | `lib/features/auth/`, `lib/features/sync/`, `lib/features/storage/`, `lib/data/supabase/`, `lib/core/network/`, `lib/core/security/`, `android/`, `supabase/` |
| Imasha | Insights charts, weather and VPD, location, supplier map, shake | [imasha.md](imasha.md) | `lib/features/insights/`, `lib/features/location/`, `lib/features/care/` |
| Udeshika | Crops, growth stages, Harvest Passport QR, report | [udeshika.md](udeshika.md) | `lib/features/crops/` |

## Start order

1. **Osanda** runs Task 0 in `osanda.md`: checks the foundation (PR #4) on an emulator and a phone.
2. **Sameera** merges PR #4 once Osanda confirms.
3. **Everyone** pulls `main` and starts their own task file.

Until PR #4 is merged, the others can install Flutter and Android Studio and read the docs.

## Timeline

| When | Gate |
| --- | --- |
| Sat 14 Nov, 11 PM | Foundation merged. Everyone runs the app with 4 tabs. |
| Sun 15 Nov, 9 PM | **Feature freeze.** All Must-have items merged. No new features after this. |
| Mon 16 Nov, 10 PM | Bugs fixed, tests green, release APK on a real phone, slides done, backup video recorded. |
| Tue 17 Nov | Presentation, demo and viva. |

## Priority labels in the task files

- **MUST**: the demo fails without it. Finish all MUST items before any SHOULD.
- **SHOULD**: do only after every MUST is merged.
- **STRETCH**: only if everything else is done and tested.

If you run out of time, stop at the end of a finished item. Never leave half-built code on `main`.
