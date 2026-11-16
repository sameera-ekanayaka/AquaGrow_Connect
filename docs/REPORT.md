# AquaGrow Connect: Project Report

## 1. Problem and users

Growing fresh herbs and leafy greens at home is hard to get right. Plants need the correct water pH, nutrient strength (EC), water temperature, water level and light. Beginners often do not know when something is wrong until the plants are already damaged.

AquaGrow is a modular hydroponic pod that measures these values with sensors. AquaGrow Connect is the companion Android app. It shows live readings, raises alerts when a value leaves its safe range, lets the user control the pump and light, and tracks each crop from seedling to harvest.

Target users are home growers, students and busy families who want fresh food at home without needing expert knowledge.

## 2. Platform choice: Flutter and Android Studio

We built AquaGrow Connect with Flutter (Dart) in Android Studio, targeting Android.

- One codebase and fast hot reload suit a five-person student team.
- A rich widget library let us match the Figma designs closely.
- Strong packages for what we need: Riverpod, go_router, charts, QR codes, sensors and notifications.
- Widget and unit tests run without a phone, so CI checks every pull request.
- Android Studio gives us the emulator, the Flutter and Dart plugins, and USB debugging on a real phone for the demo.

## 3. Architecture

The app is built in layers (see `docs/ARCHITECTURE.md`):

- **Screens** only read Riverpod providers.
- **Providers** read repositories through interfaces in `lib/core/interfaces/`.
- **Repositories** have two versions: a simulation (default, no network) and a live one using Supabase.
- **Domain code** (for example recipes and the Harvest Passport) is pure Dart with unit tests.
- Navigation uses go_router, with four tabs: Home, Crops, Insights and Care.

## 4. Lecture coverage

| Lecture | Topic | Where it appears in the app |
| --- | --- | --- |
| L3 | Platform and tools | Flutter and Android Studio setup, CI on GitHub |
| L5 | Lists, cards and navigation | My Pods list, pod cards, go_router to crop detail |
| L6 | Figma fidelity | My Pods, crop detail and Harvest Passport follow the Figma screens |
| L8 | Device hardware | Location, shake to refresh, biometric unlock, local notifications |
| L9 | Data integrity | SHA-256 hash in the Harvest Passport QR |
| L11 | Testing and release | About 420 automated tests, release APK steps in `docs/RELEASE.md` |

## 5. Security

- Biometric check before risky pod commands (pump, light, dosing).
- Confirm dialogs before every risky action, such as harvest, delete and logout.
- Secrets and keys stay in `env/*.json`, which is never committed.
- Sensitive values are kept with `flutter_secure_storage`.
- The Harvest Passport has a SHA-256 hash, so changed data gives a different hash.

## 6. Testing results

- About 420 automated tests pass on `main`, and CI runs on every pull request.
- The two CI checks are "Commit messages" and "Analyze and test".
- My own tests cover crop recipes, the crop detail screen, the My Pods list and the Harvest Passport (same input gives the same hash, any change gives a new hash, water saved maths).
- We also tested manually on a real Android phone in simulation mode.

## 7. iOS comparison: Flutter and SwiftUI

Flutter draws its own widgets from one Dart codebase, so the same screens can run on Android and iOS. SwiftUI is native to Apple devices only and gives the best iOS look and access to new Apple features, but a second app would need a separate codebase and skills. For a small student team with an Android demo, Flutter was faster. An iOS version would need a Mac, Xcode and platform changes such as notifications and biometrics.

## 8. Future work

- AI plant doctor: spot plant problems from a photo.
- ESP32 camera in the pod for growth photos.
- Bluetooth (BLE) pairing to add a new pod.
- A start-a-new-batch form for planting a new crop.

