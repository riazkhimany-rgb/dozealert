# DozeAlert

**Sleep peacefully. Arrive confidently.**

DozeAlert wakes travelers before they reach their destination using smart location-based alarms.

## Brand

| Role | Color | Hex |
| --- | --- | --- |
| Midnight Blue | Background / primary dark | `#0D1B2A` |
| Cyan Accent | Highlights / secondary | `#4CC9F0` |
| White | Text / pin body | `#FFFFFF` |

Assets live in `assets/branding/`:

- `dozealert_logo.svg` — master vector logo
- `icon_foreground.png` / `icon_background.png` — adaptive launcher icon layers
- `splash_logo.png` — splash & in-app branding

## Features

- **Location alarms** — wake before your stop using distance or transit stops
- **Background monitoring** — track your trip while you rest (foreground notification on Android)
- **Transit mode** — GTFS stop-by-stop progress on supported Ontario/GTA lines
- **Favorite locations & trip history** — quick picks for Home, Work, and saved stops
- **Map picker** — choose any destination on Google Maps
- **First-time setup guide** — permissions, alarm test, and optional agency setup
- **Wake-up radius** — adjustable alert distance (250 m to 2 km)
- **Missed-trip detection** — records trips where the alarm was not dismissed in time
- **Wear OS companion** — trip status, start/stop, alarm dismiss, tile, and complication on a paired watch (phone runs monitoring)

## Tech Stack

- Flutter (Material 3)
- Provider state management
- SharedPreferences (local settings, favorites, trip history)
- Google Maps (`google_maps_flutter`) & Google Places search
- Geolocator, foreground service, and permission handling

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / Xcode for mobile builds
- Google Maps API key for map features

### Setup

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter run
```

### Google Maps API key (Android)

Add to `android/local.properties`:

```properties
GOOGLE_MAPS_API_KEY=your_key_here
```

Set `GMSApiKey` in `ios/Runner/Info.plist` for iOS.

## Google Play (Internal Testing)

See [docs/PLAY_STORE_RELEASE.md](docs/PLAY_STORE_RELEASE.md) for signing, building, and uploading.

### Wear OS companion

The phone app syncs trip state to a paired watch over the Wearable Data Layer. The watch shows status, start/stop controls, alarm dismiss, a **tile**, and a **complication**. Monitoring, GPS, and permissions stay on the phone.

Build the Wear bundle (same signing key and package name `app.dozealert`, separate version code):

```powershell
cd android
.\gradlew :wear:bundleRelease
```

Output: `build/wear/outputs/bundle/release/wear-release.aab`

Upload that AAB to the **Wear OS** release track in Play Console (not the phone track). Enable the Wear form factor under **Advanced settings** first.

Install on a dev watch:

```powershell
cd android
.\gradlew :wear:installDebug
```

Pair the watch with the phone, install both apps, set a destination on the phone, then open DozeAlert on the watch.

## Direct APK download (website)

For sideloading and a public download page, see [docs/APK_RELEASE.md](docs/APK_RELEASE.md).

### One-command release (recommended)

From the project root in PowerShell:

```powershell
# If you see "running scripts is disabled on this system", either run once with Bypass:
powershell -ExecutionPolicy Bypass -File .\tools\release.ps1

# Or allow scripts for your user account (one-time setup):
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Clean, analyze, test, build APK, copy to website/downloads/
.\tools\release.ps1

# Same + commit, push to GitHub, and create a GitHub Release with the APK
.\tools\release.ps1 -CommitMessage "Release 1.0.1" -Push -CreateGitHubRelease

# Google Play App Bundle instead of (or in addition to) APK
.\tools\release.ps1 -Target aab
.\tools\release.ps1 -Target both -CommitMessage "Release 1.0.1" -Push
```

| Flag | Purpose |
| --- | --- |
| `-Target apk` | Website APK (default) |
| `-Target aab` | Google Play `.aab` |
| `-Target both` | APK + AAB |
| `-SkipClean` | Skip `flutter clean` (faster rebuild) |
| `-SkipTests` | Skip `flutter test` |
| `-CommitMessage "..."` | Stage safe files, commit (never `key.properties` / `.env`) |
| `-Push` | Push current branch to `origin` |
| `-CreateGitHubRelease` | `gh release create` with APK asset (needs [GitHub CLI](https://cli.github.com/)) |

**Before your first signed release:** configure `android/key.properties` — see [docs/PLAY_STORE_RELEASE.md](docs/PLAY_STORE_RELEASE.md).

### Build APK only (no tests / clean)

```powershell
.\tools\build_apk.ps1
```

Host the `website/` folder on any static site; users install via the APK link and “Allow unknown apps” steps on the page.

Store assets and listing copy are in `play-store/`. Release notes: `RELEASE_NOTES.txt`.

```powershell
# Play Store bundle only (includes clean + branding assets)
.\tools\release.ps1 -Target aab
# or legacy script:
.\tools\build_release.ps1
```


## Project Structure

```
lib/
  models/       # Domain models
  services/     # Storage & platform services
  providers/    # ChangeNotifier state
  screens/      # UI screens
  widgets/      # Reusable components
  utils/        # Theme & branding
assets/branding/  # Icons & splash artwork
docs/             # Store assets & design briefs
```

## Store & Legal

- Play Store assets: `play-store/`
- Release guide: `docs/PLAY_STORE_RELEASE.md`
- Privacy policy: `privacy_policy.md`

## Contact

[support@dozealert.app](mailto:support@dozealert.app)

## Tagline

Sleep peacefully. Arrive confidently.
