# Running AquaGrow on iOS

The app runs on the iOS Simulator and on a real iPhone, in simulation mode or
live mode (`--dart-define-from-file=env/dev.json`). Bundle id
`com.futurix.aquagrow`, iOS 15 or later.

## One-time Mac setup

1. Install Xcode, then select it (asks for your Mac password):

   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   sudo xcodebuild -runFirstLaunch
   ```

2. Install CocoaPods and an iOS simulator runtime (no password needed):

   ```bash
   brew install cocoapods
   xcodebuild -downloadPlatform iOS
   ```

   The runtime is about 8 GB; keep at least 20 GB free.

3. If `flutter build ios` says "The sandbox is not in sync with the
   Podfile.lock", run `cd ios && pod install` once.

## iOS Simulator

```bash
flutter run -d "iPhone 18 Pro" --dart-define-from-file=env/dev.json
```

Face ID: Simulator > Features > Face ID > Enrolled, then "Matching Face" when
the app asks.

## Your own iPhone (free Apple ID)

1. Xcode > Settings > Accounts: add **your** Apple ID.
2. `open ios/Runner.xcworkspace` > Runner > Signing & Capabilities: tick
   *Automatically manage signing*, Team = *Your Name (Personal Team)*.
   This writes your team id into `project.pbxproj`: **do not commit it**.
3. iPhone: Settings > Privacy & Security > Developer Mode on (restarts).
4. Plug the phone in, unlock it, and install a **release** build, which opens
   from the home screen (a debug build only starts from Flutter or Xcode):

   ```bash
   flutter build ios --release --dart-define-from-file=env/dev.json
   xcrun devicectl device install app --device <UDID> build/ios/Release-iphoneos/Runner.app
   ```

   `flutter devices` shows the UDID. Xcode 27 writes the app to
   `build/ios/Release-iphoneos/`, which `flutter run --release` does not find
   yet, so install it with `devicectl` as above.
5. First launch: Settings > General > VPN & Device Management > your Apple ID >
   Trust.

A free Apple ID signs the app for **7 days**; after that, build and install
again. At most 3 sideloaded apps at a time.
