# iOS setup (DozeAlert)

Phone-only Flutter iOS enablement. Android build/config is unchanged; keep iOS identity and secrets under `ios/`.

## Prerequisites

- Apple Developer Program membership (for TestFlight / App Store)
- A Mac (or cloud Mac) with Xcode for `flutter build ios`, signing, and device runs
- Same Google Maps key as Android (`GOOGLE_MAPS_API_KEY` in repo-root `.env`)

### Google Cloud (same key)

On the existing Maps API key used by Android:

1. Enable **Maps SDK for iOS** (and Places if you use Places on iOS)
2. Add an iOS app restriction for bundle ID `app.dozealert` (keep the Android package restriction)

Do **not** create a second key for iOS.

## Phase 1 checklist (can do on Windows)

1. Confirm `.env` contains `GOOGLE_MAPS_API_KEY=...`
2. Sync the key into the iOS runner (gitignored):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/sync_ios_maps_key.ps1
```

This writes `ios/Flutter/Secrets.xcconfig`. Android still reads `.env` via Gradle.

3. Bundle ID is `app.dozealert` in `ios/Runner.xcodeproj/project.pbxproj`
4. `ios/Runner/Info.plist` includes Always location strings, `UIBackgroundModes` (`location`, `audio`), and `GMSApiKey=$(GOOGLE_MAPS_API_KEY)`

## Build on a Mac

```bash
cd /path/to/dozealert
# Ensure Secrets.xcconfig exists (run the PowerShell sync on Windows first, or recreate on Mac)
flutter pub get
cd ios && pod install && cd ..
flutter build ios --no-codesign   # compile check
# Or open ios/Runner.xcworkspace in Xcode for signing + device/simulator
```

Signing, certificates, and provisioning are configured in Xcode / App Store Connect after you join the Apple Developer Program.

## What Phase 1 does / does not do

**Done in repo:** identity, Info.plist, Maps key plumbing, iOS Always + notification permission flows, Wear/activity UI hidden on iOS.

**Still needs Mac + later phases:** continuous background GPS AppleSettings (Phase 2), alarm reliability on locked/silent (Phase 3), TestFlight / App Store (Phase 4).

## Android safety

- Do not change `android/` manifests, Gradle Maps injection, Wear, or FGS for iOS work
- Shared Dart changes must be additive (`Platform.isIOS` branches); leave existing `Platform.isAndroid` bodies intact
