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
4. `ios/Runner/Info.plist` includes Always location strings, photo/camera/motion purpose strings (required by linked plugins even if unused), `UIBackgroundModes` (`location`, `audio`), and `GMSApiKey=$(GOOGLE_MAPS_API_KEY)`

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

## What Phase 1–4 do / do not do

**Done in repo:** identity, Info.plist, Maps key plumbing, iOS Always + notification permission flows, Wear/activity UI hidden on iOS, background GPS via Geolocator `AppleSettings`, iOS alarm notification/audio hardening, App Store listing package under [`app-store/`](../app-store/), export compliance key in Info.plist.

**Still needs you on a Mac + Apple account:** create the App Store Connect app, sign/archive/upload, screenshots, TestFlight, and App Review. Real lock-screen proof needs a physical iPhone.

## Phase 4 — TestFlight / App Store (RentAMac)

Store listing copy, privacy questionnaire answers, and checklists live in [`app-store/`](../app-store/). Do not rewrite Play Store docs for iOS.

### 1. Prerequisites

1. Apple Developer Program membership active  
2. Google Cloud: **Maps SDK for iOS** on the same key; iOS bundle ID restriction `app.dozealert`  
3. RentAMac with Xcode; DeskIn (or similar) if you are remoting in  

### 2. Create the App Store Connect app (browser)

1. Open [App Store Connect](https://appstoreconnect.apple.com) → **My Apps** → **+** → **New App**  
2. Platforms: **iOS**  
3. Name: **DozeAlert**  
4. Primary language: English  
5. Bundle ID: select **app.dozealert** (create the identifier under Certificates, Identifiers & Profiles first if it is missing)  
6. SKU: e.g. `dozealert-ios`  
7. User Access: Full Access (unless you need limited)

### 3. Prepare the Mac project

In Terminal (adjust the path if your clone lives elsewhere):

```bash
cd ~/dozealert
git pull
# Ensure .env exists with GOOGLE_MAPS_API_KEY=...
# Ensure ios/Flutter/Secrets.xcconfig exists (copy from Secrets.xcconfig.example and set GOOGLE_MAPS_API_KEY, or sync from Windows)
flutter pub get
cd ios && pod install && cd ..
```

### 4. Signing in Xcode

1. Open **`ios/Runner.xcworkspace`** (double-click in Finder — not `Runner.xcodeproj`)  
2. In the left sidebar, select the blue **Runner** project  
3. Select the **Runner** target → **Signing & Capabilities**  
4. Check **Automatically manage signing**  
5. **Team:** choose your Apple Developer team  
6. Confirm Bundle Identifier is `app.dozealert`  

Xcode will create/download a Distribution certificate and provisioning profile when you archive for the App Store the first time.

### 5. Archive and upload

1. In the Xcode toolbar, set the run destination to **Any iOS Device (arm64)** (not a Simulator)  
2. Menu: **Product** → **Archive**  
3. When Organizer opens: **Distribute App** → **App Store Connect** → **Upload**  
4. Keep defaults unless you know you need something else; finish the wizard  
5. In App Store Connect → **TestFlight**, wait until the build finishes processing  

Alternative from Terminal:

```bash
flutter build ipa
```

Then upload the IPA with **Transporter** or Xcode Organizer.

Version/build come from `pubspec.yaml` (`1.1.0+55` → marketing version `1.1.0`, build `55`). If Connect already has that build number, bump the `+` number in `pubspec.yaml` and rebuild.

### 6. Listing and App Privacy

Paste from [`app-store/`](../app-store/):

| Connect field | File |
|---------------|------|
| Subtitle | `SUBTITLE.txt` |
| Promotional Text | `PROMOTIONAL_TEXT.txt` |
| Description | `DESCRIPTION.txt` |
| Keywords | `KEYWORDS.txt` |
| What’s New | `WHATS_NEW.txt` |
| Privacy Policy URL | `PRIVACY_POLICY_URL.txt` |
| App Privacy | `APP_PRIVACY_NUTRITION_LABELS.md` |

Category: **Travel**. Age rating: **4+**. No ads. No account / sign-in required.

Screenshots: follow [`app-store/SCREENSHOTS.md`](../app-store/SCREENSHOTS.md).

### 7. TestFlight then submit

Follow [`app-store/TESTFLIGHT_CHECKLIST.md`](../app-store/TESTFLIGHT_CHECKLIST.md):

1. **Internal** TestFlight — install on your iPhone; run the alarm matrix below  
2. Optional **External** TestFlight  
3. Attach the build to the App Store version → **Submit for Review**  

Review note suggestion: “No login. Grant Location → Always and Notifications to test trip monitoring. Use a short map-pin trip to verify the wake alarm.”

Export compliance should be satisfied by `ITSAppUsesNonExemptEncryption = false` in Info.plist (HTTPS / standard encryption only).

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
