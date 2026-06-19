# Google Play Internal Testing Checklist

## Build
- [ ] Copy `android/key.properties.example` to `android/key.properties`
- [ ] Generate upload keystore (see `docs/PLAY_STORE_RELEASE.md`)
- [ ] Set `GOOGLE_MAPS_API_KEY` in `android/local.properties` or `.env`
- [ ] Run `flutter pub get`
- [ ] Run `flutter build appbundle --release`
- [ ] Confirm output: `build/app/outputs/bundle/release/app-release.aab`

## Version
- versionName: **1.0.0**
- versionCode: **1**
- applicationId: **app.dozealert**
- minSdk: **26** (Android 8.0+)

## Store Assets (play-store/)
- [ ] icon-512.png (512×512)
- [ ] feature-graphic-1024x500.png (1024×500)
- [ ] notification-icon.png (reference)
- [ ] SHORT_DESCRIPTION.txt
- [ ] FULL_DESCRIPTION.txt
- [ ] PRIVACY_POLICY_URL.txt (update before production)

## Release Notes
- [ ] RELEASE_NOTES.txt (paste into Play Console)

## Verified In App
- [x] Android 8+ (minSdk 26)
- [x] Release build configuration
- [x] Debug logs gated with AppLog (kDebugMode only)
- [x] Developer tools hidden in release (kDebugMode)
- [x] Location permission dialogs
- [x] Notification permission (POST_NOTIFICATIONS)
- [x] Background location permission flow
- [x] Battery optimization guidance
- [x] Foreground service notification while monitoring
- [x] Splash: DozeAlert + "Sleep peacefully. Arrive confidently."

## Play Console Upload
1. Create app in Google Play Console
2. Complete store listing with assets above
3. Set Privacy Policy URL
4. Upload `app-release.aab` to **Internal testing**
5. Add internal testers
6. Roll out release
