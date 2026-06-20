# APK build & download website

Direct APK distribution for testers and users before (or alongside) Google Play.

## Build the APK

### Full pipeline (clean, test, build, optional GitHub)

```powershell
.\tools\release.ps1
```

See [README.md](../README.md#one-command-release-recommended) for flags (`-Push`, `-CreateGitHubRelease`, `-Target aab`, etc.).

### Quick APK only (no clean / tests)

```powershell
.\tools\build_apk.ps1
```

This runs `flutter build apk --release` and copies the output to:

- `website/downloads/dozealert-latest.apk`
- `website/downloads/dozealert-<version>.apk` (from `pubspec.yaml`, e.g. `dozealert-1.0.0.apk`)

### Manual commands

```powershell
flutter pub get
flutter build apk --release
```

Output file:

```
build/app/outputs/flutter-apk/app-release.apk
```

Copy it to `website/downloads/dozealert-latest.apk` for the website download link.

### Signing

- If `android/key.properties` exists (see [PLAY_STORE_RELEASE.md](PLAY_STORE_RELEASE.md)), the APK is **release-signed** with your upload keystore.
- If not, Flutter uses the **debug** keystore — fine for personal testing, not for wide distribution.

For production sideloading, configure release signing first.

### Split APKs vs single APK

By default, `flutter build apk --release` builds a **fat APK** (all ABIs). For a smaller file:

```powershell
flutter build apk --release --split-per-abi
```

That produces separate APKs under `build/app/outputs/flutter-apk/` (`app-armeabi-v7a-release.apk`, etc.). Pick one ABI or host all three on the website.

## Deploy the website

The landing page lives in `website/`:

```
website/
  index.html          # Download page
  assets/icon-512.png
  downloads/          # Put APK here (not committed to git)
    dozealert-latest.apk
```

### Option A — Static host (recommended)

Upload the entire `website/` folder to any static host:

- **GitHub Pages** — push `website/` contents to `gh-pages` branch or use `/docs` folder
- **Netlify / Vercel** — set publish directory to `website`
- **Cloudflare Pages**, **Firebase Hosting**, or your own web server

Ensure `downloads/dozealert-latest.apk` is uploaded with the site.

### Option B — GitHub Releases

1. Run `.\tools\build_apk.ps1`
2. Create a GitHub Release and attach `website/downloads/dozealert-1.0.0.apk`
3. Point the download button in `index.html` to the release asset URL

### Option C — Local preview

```powershell
cd website
python -m http.server 8080
```

Open `http://localhost:8080` (APK download works only if the file exists in `downloads/`).

## Update version on the page

After bumping `pubspec.yaml`:

1. Rebuild with `.\tools\build_apk.ps1`
2. Edit the version in `website/index.html` (search for `app-version` and the script at the bottom)

## Play Store vs APK

| | APK (this guide) | Play Store |
|---|------------------|------------|
| Build | `flutter build apk` | `flutter build appbundle` |
| User install | Sideload + unknown sources | Play Store |
| Script | `tools/build_apk.ps1` | `tools/build_release.ps1` |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `key.properties` missing | Use debug build for testing, or follow [PLAY_STORE_RELEASE.md](PLAY_STORE_RELEASE.md) |
| Download 404 | Run build script so `website/downloads/dozealert-latest.apk` exists |
| “App not installed” on device | Uninstall old build; ensure APK matches device ABI |
| Maps blank | Set `GOOGLE_MAPS_API_KEY` in `android/local.properties` before building |

## Contact

[support@dozealert.app](mailto:support@dozealert.app)
