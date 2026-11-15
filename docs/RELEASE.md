# Release APK

How to build the signed release APK for the demo phone. Takes about 15 minutes the first
time. Run everything on the laptop that has Android Studio, in **PowerShell**, from the
project folder.

> Never commit the keystore, `android/key.properties` or any password. `.gitignore`
> already blocks `*.jks`, `*.keystore` and `key.properties`.

## 1. Check the tools (once)

```powershell
flutter doctor
```

Fix anything red. "Android toolchain" and "Android Studio" must be green, and the phone
must show up under "Connected device" (USB debugging on, "Allow" accepted on the phone).

## 2. Create the upload keystore (once, outside the repo)

`keytool` ships with Android Studio:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\aquagrow-keys"
```

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v `
  -keystore "$env:USERPROFILE\aquagrow-keys\aquagrow-upload.jks" `
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Choose a password when asked and keep it in your password manager. Losing the keystore
means future updates cannot be installed over this version.

## 3. Point Gradle at it

Create `android/key.properties` (git-ignored) with your own password. Use forward slashes in
the path:

```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=C:/Users/YOUR_WINDOWS_USER/aquagrow-keys/aquagrow-upload.jks
```

`android/app/build.gradle.kts` reads this file. Without it, release builds fall back to the
debug key, so a missing file does not break the build, but the APK is then not release-signed.

## 4. Build

```powershell
git switch main
```

```powershell
git pull
```

```powershell
flutter clean
```

```powershell
flutter pub get
```

```powershell
flutter build apk --release
```

The APK is at `build\app\outputs\flutter-apk\app-release.apk`.

This build runs in **simulation mode** (no env file), which is what `docs/DEMO.md` uses.
For a live Supabase build instead, add `--dart-define-from-file=env/dev.json`.

## 5. Check it is signed with the upload key

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\<version>\apksigner.bat" verify --print-certs `
  build\app\outputs\flutter-apk\app-release.apk
```

Replace `<version>` with the folder name under `build-tools` (for example `35.0.0`). The
certificate must NOT say `CN=Android Debug`.

## 6. Install on the demo phone

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

If it fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (a debug build is already installed),
uninstall the old one first:

```powershell
adb uninstall com.futurix.aquagrow
```

## 7. Rehearse on the phone

Run the whole of `docs/DEMO.md` once on the installed APK:

- [ ] Sign in with **Use demo account**; Profile shows "Simulation · built-in pods".
- [ ] pH crash: red tile, notification, alert in the list.
- [ ] Pump off: confirm dialog, then the fingerprint or PIN prompt.
- [ ] Flight mode on: offline banner. Off: "Back online · N readings synced".
- [ ] Light theme set on the phone; screen mirroring tested.
- [ ] Backup video recorded.
