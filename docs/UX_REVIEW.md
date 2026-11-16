# UX review

Owner: Osanda (UI/UX). Last updated: Sunday 15 November 2026, before the 9 PM freeze.

This file records the UX review of every merged screen, checked against `DESIGN.md`
and the Figma file "AquaGrow — Minimal UI". It is also the Nielsen heuristic
evaluation for the report.

## How the review was done

- Built `main` at `bbfc25f` and ran it on a Pixel 7 Pro emulator in simulation mode.
- Every screen was checked in light mode, in dark mode, and at 360 dp wide
  (`adb shell wm density 640` on the 1440 px screen).
- The code was searched for hard-coded colours, raw font sizes and raw spacing, lists
  without `ListView.builder`, missing `AsyncValueView` states and risky actions without
  `showConfirmDialog`.
- Severity uses Nielsen's 0 to 4 scale: 4 is a usability catastrophe, 3 is a major
  problem, 2 is minor, 1 is cosmetic.

## Checklist by screen

| Screen | PR | Tokens only | 48 dp targets | Four states | Light and dark | 360 dp |
| --- | --- | --- | --- | --- | --- | --- |
| Login, register | #11 | Yes | Yes | Yes | Yes | Yes |
| Profile | #11 | Yes | Yes | n/a | Yes | Yes |
| Home, pod controls | #22, #23, #28 | Yes | Yes | Yes | Yes | Yes |
| My Pods | #26 | Yes | Yes | Yes | Yes | Yes |
| Crop detail | #24 | Yes | Yes | Yes | Yes | "Seedling" breaks (8) |
| Harvest Passport | #29 | Yes (white behind the QR is on purpose) | Yes | Yes | Not checked | Not checked |
| Insights chart | #12 | Raw font sizes (15) | Yes | Yes | Yes | Yes |
| Weather and VPD cards | #13 | Raw sizes and spacing (3) | "Enable GPS" too small (6) | Weather error shows raw text (5) | Yes | **Overflows (1)** |
| Microclimate | #13 | 23 hard-coded colours (3) | Yes | Partly | Own dark checks (3) | Not checked |
| Supplier map | #18, #25 | Mostly | Yes | Yes | Yes | Yes |
| Care | n/a | Yes | Yes | n/a | Yes | Yes |
| Settings | #20 | Yes | Yes | n/a | Yes | Yes |
| Alerts | n/a | Yes | Yes | Yes | Yes | Yes |

## Findings

Numbers match the checklist above. Fix the 4s and 3s before the freeze.

| # | Severity | Screen | Problem | Fix | Owner |
| --- | --- | --- | --- | --- | --- |
| 1 | 4 | Insights: weather and VPD cards | At 360 dp wide both cards overflow (yellow and black stripes): the temperature row, the VPD title row with the "OPTIMAL" chip, and the "0.94 kPa · Ideal Vegetative Transpiration" row. | Wrap the long text in `Expanded` or `Flexible` and let it wrap to two lines (`vpd_gauge_card.dart`, `weather_summary_card.dart`). Check with a 360 dp widget test. | Imasha |
| 2 | 3 | Insights | Opening the tab fires two Android dialogs at once (location permission, then Location Accuracy) with no reason given first. | Show the "GPS unavailable, showing Colombo" banner first and only ask when the user taps "Use my location". | Imasha |
| 3 | 2 | Microclimate | 23 `AppColors` values, raw font sizes and spacing, and its own `isDark` checks, so it will drift from the theme. | Use `context.ag`, `textTheme` and `AgSpace`. | Imasha |
| 4 | 2 | VPD card | Jargon a home grower will not know: "Canopy Transpiration Physics", "Leaf Sat 3.78 kPa \| Air 2.84 kPa", "Stomata". | Plain words, for example "Air dryness for your plants" and "Good for leafy greens". Keep the kPa number. | Imasha |
| 5 | 3 | Weather card | The error state prints `error.toString()` straight to the user. | Show a friendly line ("Could not load the weather. Check your connection.") and log the error with `AppLogger`. | Imasha |
| 6 | 2 | Location banner | The "Enable GPS" button uses `Size.zero` and `shrinkWrap`, so it is well under 48 dp. | Remove both, or set `minimumSize: Size(0, kMinTouchTarget)`. | Imasha |
| 7 | 2 | Crop detail | The basil pH target says 5.8–6.4 while Home and Insights say 5.5–6.5, so it looks like a mistake. | Label it as the crop's ideal ("Best for basil: 5.8–6.4") or use the same range. | Udeshika |
| 8 | 2 | Crop detail | At 360 dp, "Seedling" under the first stage breaks into "Seedlin / g". | Give each stage label equal `Expanded` width with `softWrap: false`, or use a smaller label style. | Udeshika |
| 9 | 3 | Crop detail, supplier map | The lime brand colour is used as text ("30%", "Rockwool & Growing Media · Colombo", "Details"). On white this is about 1.5:1 contrast, below WCAG 4.5:1. | Keep lime for fills. Use `c.text` or `c.textSecondary` for that text. | Udeshika, Imasha |
| 10 | 2 | Supplier map, crop detail | Names do not match: Care says "Hydroponic suppliers" but the screen says "Hydro-Hub Supply Network". Headings use Title Case ("Crop Detail", "Recipe Targets", "Harvest Crop") while the rest of the app uses sentence case. | "Hydroponic suppliers", "Recipe targets", "Harvest crop", and the crop name as the title. | Imasha, Udeshika |
| 11 | 2 | Supplier map | The GPS bar reads "Fallback Default (Colombo): 6.9271°, 79.8612° ±25m". | "Showing suppliers near Colombo". | Imasha |
| 12 | 1 | Alerts | "Mark all read" shows even when there are no alerts. | Hide it, or disable it when the list is empty. | Tharindu |
| 13 | 2 | App start | A cold start shows the default Flutter logo. | Branded splash (Osanda, task 5). | Osanda |
| 14 | 1 | My Pods, Home | Pod Beta shows a placeholder instead of the spinach photo. | Set `imageAsset` for Pod Beta in the simulator (already requested). | Tharindu |
| 15 | 1 | Insights chart | Axis labels use `fontSize: 10`. | Use `textTheme.labelSmall`. | Imasha |

What already works well:

- Every data screen uses `AsyncValueView`: Home, My Pods, crop detail, Passport, the Insights chart and Alerts.
- Harvest, sign out, delete local data and every pod control ask first with `showConfirmDialog`.
- Dark mode holds up on every screen checked.
- The Settings privacy section explains each kind of data in plain words.

## Nielsen's 10 heuristics

| # | Heuristic | Where AquaGrow meets it | Gaps found | Rating |
| --- | --- | --- | --- | --- |
| 1 | Visibility of system status | "Live" or "Offline" badge on the pod picker. "Updated just now" on readings. Spinners on each control while a command is sent. "Last synced" on Profile. | None major. | Good |
| 2 | Match between system and the real world | Plain task messages ("Water needs attention", "Refill it today"). Metric names in words ("Nutrients (EC)"). | VPD jargon (4) and raw GPS coordinates (11). | Needs work |
| 3 | User control and freedom | Every risky action has a Cancel. Brightness only sends when the finger lifts, and Cancel puts the slider back. The pod picker is a dismissible sheet. | Location is asked for before the user chooses to use it (2). | Fair |
| 4 | Consistency and standards | One token set (`context.ag`, `AgSpace`), shared widgets (`SensorTile`, `StatusBadge`, `TabHeader`), Material 3 switches and sheets. | Title Case and naming mismatches (10), different pH targets (7), Microclimate's own colours (3). | Fair |
| 5 | Error prevention | Confirm dialogs on pump, light, dosing, harvest, sign out and delete. Fingerprint check before commands. Dosing locks after 5 pulses with no change. Controls are disabled when the pod is offline. | None. | Good |
| 6 | Recognition rather than recall | Every reading shows its target ("Target 5.5–6.5"). Status colour plus words. The priority card says what to do next. | None major. | Good |
| 7 | Flexibility and efficiency of use | "Mark refilled" straight from the Home task card. "Mark all read" on Alerts. Quick pod switching from the selector. Demo account on login. | Shake to refresh is not done yet (Imasha, SHOULD). | Fair |
| 8 | Aesthetic and minimalist design | Calm Home: one priority card, then the hero, readings and controls. Lime only for status and actions. | The VPD card is dense (two extra numbers, a long tip). Lime text has low contrast (9). | Fair |
| 9 | Help users recognise, diagnose and recover from errors | The offline pod explains itself ("Controls come back when Pod Alpha reconnects"). Dose notes say why ("Check the pH-down bottle, 2 of 5"). Retry on `AsyncValueView` errors. | The weather card prints the raw exception (5). | Fair |
| 10 | Help and documentation | Settings explains data and privacy. The empty alerts state says when alerts appear. Each control dialog explains what will happen. | No first-run guide yet (Osanda, task 5 onboarding). | Fair |

## Round 2: visual polish (Monday 16 November)

Checked on the signed release APK (Pixel 7 Pro emulator, light mode) against `DESIGN.md`.
The aim was one consistent look: the same accent, type, shapes and wording on every screen.

| # | Severity | Screen | Problem | Fix | Owner |
| --- | --- | --- | --- | --- | --- |
| 17 | 3 | Home | An out-of-range tile (water 25°C) only turns amber; the caption still says "Target 18–24°C". Colour is the only signal (DESIGN rule 8). | Caption says which way first, on its own line: "Too high", then "Target 18–24°C". | Osanda (fixed in this round) |
| 18 | 1 | My Pods | Every card says the stage twice: the photo badge and a "Growing" line under the name. | Keep the badge only. | Osanda (fixed in this round) |
| 19 | 2 | Location dialog | The only lime filled button in the app. Everywhere else the primary button is near-black. Also Title Case ("Allow Location Access"). | Use the themed `FilledButton` and "Allow location access". | Imasha |
| 20 | 2 | Weather and VPD cards | Wide letter spacing and capitals ("SCATTERED CLOUDS WITH MILD HUMI...") are cut off, and the spacing differs from every other screen. | Sentence case, normal spacing, let the condition wrap to two lines. | Imasha |
| 21 | 2 | VPD card | The title is cut off ("Vapor Pressure Deficit ..."). The scale uses tan and brown that are not in the token set. "RH" is jargon. | Title "Air dryness (VPD)". Use `warning`/`critical`/`brand` for the scale. "Humidity 69%". | Imasha |
| 22 | 2 | VPD card, weather icons | "OPTIMAL" and the small icons are lime on white (about 1.5:1). | Text in `c.text` on `brandSurface`; icons in `textSecondary`. | Imasha |
| 23 | 1 | Insights, My Pods, Care headers | Capitals with letter spacing above every tab title ("LOOK AFTER YOUR PODS"), while Home uses a sentence-case greeting. | Sentence case overline in `TabHeader`, the same as Home. | Tharindu |
| 24 | 1 | My Pods vs Home | "Harvest est. in 20 days" vs "Harvest in about 20 days". | One wording: "Harvest in about 20 days". | Udeshika |
| 25 | 1 | Care | Four separate cards with equal weight, so the demo-only Pod simulator looks as important as Settings. Care reminders put cards inside a card. | One grouped list with dividers; reminders as plain rows. | Imasha |

## Still to review

- Harvest Passport (#29) in dark mode and at 360 dp.
- The app lock screen (draft PR #58) in light, dark and landscape.
