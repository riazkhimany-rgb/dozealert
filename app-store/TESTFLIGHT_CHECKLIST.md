# TestFlight and App Store submit checklist

Use with [docs/IOS_SETUP.md](../docs/IOS_SETUP.md) Phase 4. Bundle ID: `app.dozealert`. Version comes from `pubspec.yaml` (e.g. `1.1.0+62` → version `1.1.0`, build `62`). Bump on Windows with `.\tools\bump-version.ps1` in the **same commit** as the shippable fix.

## Before you start

- [ ] Apple Developer Program membership active  
- [ ] App record created in App Store Connect (bundle ID `app.dozealert`)  
- [ ] Google Cloud: Maps SDK for iOS enabled; key restricted with iOS bundle ID `app.dozealert`  
- [ ] RentAMac: repo pulled; `.env` and `ios/Flutter/Secrets.xcconfig` present  
- [ ] Listing copy ready in this folder (`DESCRIPTION.txt`, `SUBTITLE.txt`, etc.)  
- [ ] App Privacy answers ready in `APP_PRIVACY_NUTRITION_LABELS.md`  

## Build and upload (RentAMac)

- [ ] `git pull` on `feature/simplified-trip-ux` (or the release branch)  
- [ ] Confirm `grep '^version:' pubspec.yaml` shows the build you intend to upload  
- [ ] **Required:** `./tools/ios-refresh-build-number.sh` (or `flutter build ios --config-only …`) so `ios/Flutter/Generated.xcconfig` matches pubspec — Xcode will otherwise Archive the **previous** build number  
- [ ] `grep FLUTTER_BUILD ios/Flutter/Generated.xcconfig` shows the new number  
- [ ] `cd ios && pod install && cd ..`  
- [ ] Open `ios/Runner.xcworkspace` in Xcode (not the `.xcodeproj`)  
- [ ] Signing & Capabilities → Team selected → Automatic signing  
- [ ] Product → Destination → **Any iOS Device (arm64)** (or a connected iPhone)  
- [ ] Product → **Archive**  
- [ ] Organizer → Distribute App → App Store Connect → Upload  
- [ ] Wait until the build appears under TestFlight (processing can take several minutes)  

Alternative: `flutter build ipa` then upload the IPA via Transporter or Xcode Organizer.

## App Store Connect metadata

- [ ] Privacy Policy URL: `https://dozealert.app/privacy`  
- [ ] App Privacy questionnaire completed from `APP_PRIVACY_NUTRITION_LABELS.md`  
- [ ] Name: DozeAlert; Subtitle from `SUBTITLE.txt`  
- [ ] Description / Keywords / What’s New pasted from this folder  
- [ ] Category: Travel; Age: 4+; No ads; No sign-in required  
- [ ] Screenshots uploaded (see `SCREENSHOTS.md`)  
- [ ] Support URL / marketing URL if you have them (support: support@dozealert.app)  

## Apple Watch (companion)

Ship with builds that include the Watch app (see [docs/IOS_SETUP.md](../docs/IOS_SETUP.md) → Apple Watch companion).

- [ ] Watch + Widgets targets signed with the same Team as Runner; App Group `group.app.dozealert` enabled  
- [ ] Watch App Icon present (1024×1024) before Archive  
- [ ] Internal TestFlight install includes Watch app (iPhone Watch app → install DozeAlert)  
- [ ] Simulator smoke (optional on RentAMac): trip remote buttons + alarm screen  
- [ ] **Physical Watch release gate:** locked phone + Watch updates; alarm haptic; dismiss; complication on face  
- [ ] Listing: note “Works with Apple Watch”; upload Watch screenshots per `WATCH_SCREENSHOTS.md`  

## TestFlight

- [ ] **Internal testing:** add yourself / team; install via TestFlight; run the alarm matrix in `docs/IOS_SETUP.md`  
- [ ] **External testing (optional):** create a group, submit build for Beta App Review if required  
- [ ] Fix crashes / Always-location / alarm issues before production submit  

## Submit for App Review

- [ ] Select the processed build on the iOS version page  
- [ ] Answer export compliance (should be auto-cleared via Info.plist `ITSAppUsesNonExemptEncryption = false`)  
- [ ] Note for Review (optional): “No login. Grant Location → Always and Notifications to test trip monitoring. Use a short map-pin trip to verify the wake alarm.”  
- [ ] Submit for Review  

## After approval

- [ ] Release manually or automatically per your Connect setting  
- [ ] Smoke-test the live App Store build on a physical iPhone  
