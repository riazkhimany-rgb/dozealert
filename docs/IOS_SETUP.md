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

**Done in repo:** identity, Info.plist, Maps key plumbing, iOS Always + notification permission flows, Wear/activity UI hidden on iOS, background GPS via Geolocator `AppleSettings`, iOS locked-reliability stack (heartbeat notification, geofence backup, custom notification sound, pre-alert, `beginBackgroundTask`, audio session arming), App Store listing package under [`app-store/`](../app-store/), export compliance key in Info.plist.

**Still needs you on a Mac + Apple account:** create the App Store Connect app, sign/archive/upload, screenshots, TestFlight, and App Review. Real lock-screen proof needs a physical iPhone.

### Locked-phone alarms (iOS)

- Approach alerts post the local notification **first** (system sound), then start the looping `alarm.mp3` tone (always on iOS, so locked wakes are not TTS-only).
- Unlocking with an active alert restarts tone / TTS / vibration (`reinforceAlarmIfActive`).
- Monitoring uses `ActivityType.otherNavigation` so transit trips are less likely to pause GPS than car-only navigation mode.
- Stale stop counts on the lock screen are expected while Flutter is suspended; Core Location should still wake the app for updates. If distance freezes for many minutes while locked, confirm **Location → Always** and the blue status-bar location indicator during the trip.

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
- Arrival / pre-alert notifications use **time-sensitive** interruption and a bundled custom sound (`alarm_notification.wav`). Critical Alerts are **not** enabled (Apple entitlement + review); escalate only if locked Focus/Silent still mutes wakes after this stack.
- Alarm/TTS use `playback` audio session (ignores the Ring/Silent switch for app audio). Trip start also arms the audio session once.
- While monitoring: a quiet **trip heartbeat** notification updates distance/stops (throttled) so locked GPS wakes are observable.
- **Geofence backup:** approach + destination `CLCircularRegion`s arm on trip start and clear on stop; region entry can fire pre-alert / main wake if the continuous stream was deferred.
- Alarm start wraps a short native `beginBackgroundTask` so looping audio can begin after a location wake.
- Unlock / resume still calls `reinforceAlarmIfActive()` so a silent lock-screen wake can recover outputs.
- `UIBackgroundModes` includes `location` + `audio`.

### Locked-phone test matrix (physical iPhone 12 preferred)

After installing a build that includes the locked-reliability stack:

1. Always location + notifications granted; Focus Off; Silent switch Off  
2. Same with Silent switch On (looping tone should still play via `playback`)  
3. Locked 10+ minutes before approach — notification tone and/or looping alarm without unlocking  
4. Transit wake-by-stops and map-pin distance  
5. Confirm geofence alone can wake if continuous GPS updates look stale on unlock  
6. Unlock mid-alarm still reinforces tone / TTS / vibration  
7. Low Power Mode — monitoring + alarm still work  

**Acceptable:** Home stop/distance labels look briefly stale until unlock, if the **wake itself** was audible.

**Escalation:** If Focus still mutes notification sound after the above passes, apply for Apple **Critical Alerts** entitlement and retest.

## Android safety

- Do not change `android/` manifests, Gradle Maps injection, Wear, or FGS for iOS work
- Shared Dart changes must be additive (`Platform.isIOS` branches); leave existing `Platform.isAndroid` bodies intact
