# Team tasks

Each person has one task file. It lists exactly what to build, which folders you own,
and how to know you are finished. Work top to bottom: items are in priority order.

| Person | Role | Task file | Owns |
| --- | --- | --- | --- |
| Tharindu | Foundation, design system, app shell, settings, slides | [tharindu.md](tharindu.md) | `lib/app/`, `lib/core/theme/`, `lib/shared/`, `lib/features/settings/`, `lib/features/onboarding/` |
| Osanda | IoT dashboard, controls, alerts, notifications, simulator panel | [osanda.md](osanda.md) | `lib/features/dashboard/`, `lib/features/controls/`, `lib/features/alerts/`, `lib/features/simulator/` |
| Sameera | Auth, Supabase, offline sync, security, release APK, PR reviews | [sameera.md](sameera.md) | `lib/features/auth/`, `lib/features/sync/`, `lib/features/storage/`, `lib/data/supabase/`, `lib/core/network/`, `lib/core/security/`, `android/`, `supabase/` |
| Imasha | Insights charts, weather and VPD, location, supplier map, shake | [imasha.md](imasha.md) | `lib/features/insights/`, `lib/features/location/`, `lib/features/care/` |
| Udeshika | Crops, growth stages, Harvest Passport QR, report | [udeshika.md](udeshika.md) | `lib/features/crops/` |

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
