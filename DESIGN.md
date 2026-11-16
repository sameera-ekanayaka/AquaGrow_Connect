# Design system

Source of truth: Figma file **AquaGrow — Minimal UI**, page **Screens**
(<https://www.figma.com/design/C1QLO2lVYJ0zJbkdLYZYii/AquaGrow-%E2%80%94-Minimal-UI>).
The older file "AquaGrow" (page "01 — Refined Direction") is out of date: do not build from
it. The look is
**white and near-black with a lime accent, plant photography, and calm, clear hierarchy.**
Urgent care comes before streaks, and every reading shows its target.

All tokens are already in code. **Never type a hex colour, a raw font size or a raw
padding number in a feature.** Use the tokens below.

## 1. Colour (`context.ag.<role>`)

| Role | Light | Dark | Use for |
| --- | --- | --- | --- |
| `background` | `#FAFAFA` | `#0A0A0A` | Screen background |
| `surface` | `#FFFFFF` | `#161616` | Cards, sheets, nav bar |
| `subtle` | `#F5F5F5` | `#1F1F1F` | Quiet panels, round icon buttons |
| `border` | `#E5E7EB` | `#2A2A2A` | 1 px card borders |
| `text` | `#0A0A0A` | `#FAFAFA` | Main text, primary button fill |
| `textSecondary` | `#616161` | `#A3A3A3` | Labels, captions, inactive tabs |
| `onDark` | `#FFFFFF` | `#0A0A0A` | Text on the primary button |
| `brand` | `#A8E63D` | `#A8E63D` | "Live" badge, selected highlights |
| `brandSurface` | `#F1F9DC` | `#26330F` | Selected tab pill |
| `warning` | `#8A5300` | `#F5B04C` | Out-of-range value |
| `warningSurface` | `#FFF5E8` | `#2E2110` | "Needs attention" card |
| `critical` | `#B3261E` | `#F2B8B5` | Dangerous value, destructive button |
| `criticalSurface` | `#FDECEA` | `#3A1A18` | Critical alert card |

```dart
final c = context.ag;           // import core/theme/app_tokens.dart
Container(color: c.warningSurface, child: Text('Water needs attention', style: TextStyle(color: c.warning)));
```

## 2. Type (line height 1.4)

Figma uses **Plus Jakarta Sans**. It is bundled in `assets/fonts/` (Regular, Medium, SemiBold,
Bold, ExtraBold for titles; OFL licence in `OFL.txt`) and set once in `AppTheme`
(`fontFamily: 'PlusJakartaSans'`), so every
`textTheme` style uses it. Never set a font family in a feature, and never load fonts from the
internet at runtime: the demo phone may be offline.

| Figma style | Flutter | Size / weight | Example |
| --- | --- | --- | --- |
| Title | `textTheme.headlineMedium` | 28 / 700 | "Your garden" |
| Section | `textTheme.titleLarge` | 20 / 700 | "Growing conditions" |
| Strong | `textTheme.titleMedium` | 16 / 600 | Card titles, buttons |
| Body | `textTheme.bodyLarge` | 16 / 400 | Paragraphs |
| Label | `textTheme.labelLarge` | 14 / 600 | "Pod Alpha · Kitchen" |
| Meta | `textTheme.bodySmall` | 12 / 500, secondary colour | "Updated 1m ago", tile labels |
| Sensor value | `textTheme.displaySmall` | 28 / 700 | "6.2", "22°C" |

Text must scale with the phone's font size setting. Never wrap the app in a fixed `textScaler`.

## 3. Spacing and shape

| Token | Value | Use for |
| --- | --- | --- |
| `AgSpace.screen` | 20 | Padding around every screen |
| `AgSpace.s4 … s32` | 4, 8, 12, 16, 20, 24, 32 | Gaps. Cards use 12 inside; sections are 20 apart |
| `AgRadius.r16` | 16 | Buttons, inputs, small cards |
| `AgRadius.r20` | 20 | Sensor tiles, crop tiles, task card |
| `AgRadius.r24` | 24 | Crop hero, dialogs, nav bar |
| `AgRadius.pill` | 999 | Badges |
| `kMinTouchTarget` | 48 | Smallest tappable size |

## 4. Components (`lib/shared/widgets/widgets.dart`)

| Figma component | Flutter widget | Notes |
| --- | --- | --- |
| Badge | `StatusBadge(label:, tone:)` | Tones: neutral, brand (lime), warning, critical |
| Sensor | `SensorTile(label:, value:, caption:, status:)` | Status from `SensorMetric.statusOf(value)` |
| Button (dark) | `FilledButton` | Already themed: near-black, 48 high, radius 16 |
| Navigation | `AppShell` | Home, Crops, Insights, Care |
| (header) | `TabHeader(overline:, title:)` | Includes the alerts bell with unread count |
| (section title) | `SectionHeader(title:, caption:/actionLabel:)` | "Your plants · View crops" |
| Crop tile, Crop hero, Pod card | Build in your feature, then move to `shared/` if two features need it | Use `assets/images/crops/` |
| (states) | `AsyncValueView`, `LoadingView`, `ErrorView`, `EmptyView` | Every list and chart |
| (dialog) | `showConfirmDialog(...)` | Every risky action |

## 5. Screen rules (lectures 5 and 6, Material guidelines)

1. Every screen: `SafeArea`, padding `AgSpace.screen`, scrolls if content can overflow.
2. One primary (filled) button per screen at most.
3. Risky actions (pump off, pH dose, logout, delete, harvest) go through `showConfirmDialog`. SnackBars are only for "done" feedback.
4. Every list or chart shows loading, error, empty and data states (`AsyncValueView`).
5. Lists use `ListView.builder` (lecture 7: RecyclerView equivalent).
6. Layouts adapt with `LayoutBuilder`: 2 columns under 600 px wide, 4 above. Test portrait and landscape.
7. Touch targets at least 48 × 48. Icon-only buttons need a `tooltip` or `Semantics` label.
8. Colour is never the only signal: out-of-range values also change their caption text.
9. Light and dark themes must both look right. Check both before opening a PR.

## 6. Images

Crop photos are in `assets/images/crops/`: basil and spinach exported from Figma, the others
from Unsplash (free under the Unsplash License), cropped to 480 × 480 WebP. Every recipe maps
to a photo in `SupabaseRows.cropImage`. Add new ones there, as PNG or WebP under 300 KB.
