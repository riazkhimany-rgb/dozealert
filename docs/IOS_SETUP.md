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

**Done in repo:** identity, Info.plist, Maps key plumbing, iOS Always + notification permission flows, Wear/activity UI hidden on iOS, background GPS via Geolocator `AppleSettings`, iOS locked-reliability stack (real looping alarm tone, trip keep-alive audio session, native geofence wake, heartbeat notification, custom notification sound, pre-alert, stale-stop fallback, persisted trip log), App Store listing package under [`app-store/`](../app-store/), export compliance key in Info.plist.

**Still needs you on a Mac + Apple account:** create the App Store Connect app, sign/archive/upload, screenshots, TestFlight, and App Review. Real lock-screen proof needs a physical iPhone.

### Locked-phone alarms (iOS)

- Approach alerts post the local notification **first**, then start the looping `alarm.wav` tone (always on iOS, so locked wakes are not TTS-only).
- Unlocking with an active alert restarts tone / TTS / vibration (`reinforceAlarmIfActive`).
- Monitoring uses `ActivityType.otherNavigation` so transit trips are less likely to pause GPS than car-only navigation mode.
- A trip keep-alive audio session now keeps the process resident, so stop counts should stay current while locked. If distance still freezes for many minutes, confirm **Location → Always** and the blue status-bar location indicator during the trip.

See [Alarm reliability notes](#alarm-reliability-notes-ios) for the full stack and the retest matrix.

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

### What the build-58 field test proved

Three independent faults, all now fixed:

1. **The Ring/Silent switch mutes every notification sound.** No amount of interruption-level tuning changes that; only the app's own `playback`-category audio (or the Critical Alerts entitlement) survives the switch. The custom `alarm_notification.wav` was correct but irrelevant while locked and silenced.
2. **There was no alarm tone.** `assets/sounds/alarm.mp3` and `android/app/src/main/res/raw/alarm.mp3` were both 4-byte stubs, so the "always loop the tone on iOS" path had always been a no-op. Rounds where the phone stayed unlocked only sounded because `flutter_tts` uses `playback`.
3. **The app was suspended while locked.** Stop counts froze, the wake fired only on unlock, and the geofence backup could not help because `invokeMethod("onRegionEntered")` needs a live Dart isolate.

Two smaller bugs found alongside: `defaultToSpeaker` and `allowBluetooth` are `playAndRecord`-only options, and passing them with the `playback` category makes the whole session configuration throw — so the alarm session and the TTS session were both failing to configure.

### Current stack

- **Real audio.** `assets/sounds/alarm.wav` is a 4 s loop-safe two-tone alarm (44.1 kHz mono PCM), mirrored to `android/app/src/main/res/raw/alarm.wav` and `ios/Runner/alarm_notification.wav` for the notification sound.
- **Trip keep-alive.** `ios/Runner/keepalive.wav` loops near-silently through a `playback` session for the whole trip (`startKeepAlive` / `stopKeepAlive`). This keeps the process resident so stop counts refresh while locked, and keeps the audio route hot so the alarm starts instantly and loudly. It stops the moment the trip ends.
- **Native wake.** Trip start writes destination and wake copy to `UserDefaults`; on `didEnterRegion` for the destination ring, `AppDelegate` posts the notification and starts the looping tone **in Swift**, with no Dart round trip. Dart adopts the wake on its next run (`consumeNativeWake`) and hands the tone over only once its own loop is playing, so there is no gap and no double audio.
- **Geofence backup.** Approach + destination `CLCircularRegion`s arm on trip start and clear on stop.
- **Stale-stop fallback.** If stop counting freezes for 90 s (no fixes, or the route matcher cannot advance) while straight-line distance is already inside the wake radius, the distance wake fires anyway. Covers weak GPS on a hotspot with no SIM.
- **Critical Alerts.** Requested at permission time with a fallback to a standard request; arrival notifications use `InterruptionLevel.critical` with a critical sound only when the entitlement is actually granted, otherwise `timeSensitive`. See below — the entitlement is not wired into signing yet.
- **Trip heartbeat.** A quiet, throttled notification shows distance/stops so locked GPS wakes stay observable.
- **Trip log.** Settings → Developer → **Locked-trip log** persists GPS gaps, stop-count changes, geofence entries, pre-alerts, wake source, and whether the tone actually started. Copy it out after a field test instead of relying on recollection.
- Alarm start wraps a short native `beginBackgroundTask`; unlock/resume still calls `reinforceAlarmIfActive()`.
- `UIBackgroundModes` includes `location` + `audio`.

### Enabling Critical Alerts (after Apple approval)

`ios/Runner/Runner.entitlements` exists but is **deliberately not referenced by any build configuration** — signing fails if the provisioning profile lacks the key.

1. Submit the request at <https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/>
2. Once granted, regenerate the provisioning profile, then in Xcode set the Runner target's **Code Signing Entitlements** to `Runner/Runner.entitlements` (or add `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` to each Runner build configuration)
3. No Dart change is needed: `AlarmService.refreshCriticalAlertStatus()` detects the grant at runtime and escalates the interruption level automatically

Separately, **Time Sensitive Notifications** is a free capability (no Apple approval) that is not enabled yet. Without it iOS quietly downgrades our `timeSensitive` notifications to `active`, so they cannot break through Focus. Enable it in Xcode under Signing & Capabilities when you next touch signing — it will create/extend the entitlements file, so do it at the same time as the Critical Alerts wiring to avoid a signing round trip.

### Locked-phone retest matrix (physical iPhone 12)

Run the same route as the failing test, then read the trip log.

1. **Silent switch ON, locked 10+ minutes** — the looping tone must play through the switch. This is the headline case.
2. **Silent switch ON, locked, wake-by-stops** — the stop count must still be current when you unlock.
3. **Hotspot off mid-trip** — GPS-only wake still fires (geofence or stale-stop fallback).
4. **Unlock mid-alarm** — outputs reinforce, single tone (not two), dismiss works.
5. **Low Power Mode** — monitoring and alarm still work.
6. Open **Developer → Locked-trip log** and check for `gps.gap` entries, whether `wake.fired` shows `source=native-geofence` or `source=stops`, and that `alarm.tone.playing` appears (not `alarm.tone.failed`).

**Acceptable:** Home labels look briefly stale until unlock, provided the wake itself was audible.

**Known trade-off:** the keep-alive track means measurable battery drain during a trip, and App Review occasionally challenges keep-alive audio. DozeAlert is genuinely an alarm app, `UIBackgroundModes` already declares `audio`, and playback stops when the trip ends.

## Android safety

- Do not change `android/` manifests, Gradle Maps injection, Wear, or FGS for iOS work
- Shared Dart changes must be additive (`Platform.isIOS` branches); leave existing `Platform.isAndroid` bodies intact
