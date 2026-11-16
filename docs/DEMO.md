# Demo script (about 7 minutes)

Run on the demo phone with the **release APK**, in simulation mode, light theme.
Before starting: app freshly opened, signed out, both pods on **Healthy pod**, notifications allowed,
phone volume on, screen mirroring tested. Keep the backup video ready.

| # | Who | Time | Do | Say (proves) |
| --- | --- | --- | --- | --- |
| 1 | Tharindu | 1:00 | Slides: problem, pod, Figma flow, why Flutter in Android Studio | L3 platforms, L6 UI/UX |
| 2 | Sameera | 1:00 | Sign in with the demo account. Show profile. | Supabase Auth, Keystore tokens, RLS (L9, security) |
| 3 | Osanda | 1:30 | Home live readings. Care > Pod simulator > **pH crash**. Back to Home: red pH tile, notification, alert in the list. Turn the pump off: confirm dialog. | IoT (ILO6), L4 services, L5 dialogs |
| 4 | Udeshika | 1:00 | Crops > Pod Alpha detail: stage timeline, days left. Harvest, then show the Passport QR and scan it with another phone. | L5 lists and detail, data integrity |
| 5 | Imasha | 1:00 | Insights: 24 h chart, stability, and trend warning chip when pH is falling. Weather and VPD. Care > suppliers sorted by distance. Shake to refresh. | L7 REST, L8 location and sensors |
| 6 | Sameera | 0:45 | Flight mode on: app still works, offline banner. Off: "readings synced". | L1 networks, L9 sync |
| 7 | Tharindu | 0:45 | Slides: architecture, tests and CI, Flutter vs SwiftUI, future work | L4, L10, L11 |

## If something fails live

- Readings frozen: Care > Pod simulator > turn **Live readings** on.
- Wrong state: apply **Healthy pod** to both pods and continue.
- App crash: reopen. If it fails twice, switch to the backup video for that step.
