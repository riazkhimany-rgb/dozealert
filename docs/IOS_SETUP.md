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

## What Phase 1–3 do / do not do

**Done in repo:** identity, Info.plist, Maps key plumbing, iOS Always + notification permission flows, Wear/activity UI hidden on iOS, background GPS via Geolocator `AppleSettings`, iOS alarm notification/audio hardening.

**Still needs Mac + later phases:** TestFlight / App Store (Phase 4). Real lock-screen proof needs a physical iPhone.

## Alarm reliability notes (iOS)

- Trip start requests notification permission (alert + sound + badge).
- Arrival notifications use **time-sensitive** interruption (not Critical Alerts).
- Alarm/TTS use `playback` audio session (ignores the Ring/Silent switch for app audio).
- **Silent Mode / Focus limits:** notification *sounds* may still be muted by Focus or user settings; Critical Alerts (Apple entitlement) are deferred unless testing shows they are required.
- `UIBackgroundModes` includes `audio` so speech/alarm can continue when locked.

### Manual test matrix (physical iPhone preferred)

1. Trip running, app foreground — trigger approach alarm  
2. Trip running, app backgrounded 2+ minutes — alarm still fires  
3. Screen locked — alarm/TTS still audible  
4. Ring/Silent switch on Silent — app audio should still play; note notification sound behavior  
5. Low Power Mode — monitoring + alarm still work  

## Android safety

- Do not change `android/` manifests, Gradle Maps injection, Wear, or FGS for iOS work
- Shared Dart changes must be additive (`Platform.isIOS` branches); leave existing `Platform.isAndroid` bodies intact
