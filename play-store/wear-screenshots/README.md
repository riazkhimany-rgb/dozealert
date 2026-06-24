# Wear OS screenshots for Google Play

Play Console requires:

- **1:1 aspect ratio**, minimum **384 x 384** pixels
- **App UI only** — no emulator gray bezel / device frame
- **Solid background** (black is fine), not transparent

## Quick generate (no emulator needed)

Renders Play-ready **512×512** PNGs matching the Wear app UI:

```powershell
cd D:\Dev\Projects\dozealert
.\tools\generate-wear-screenshots.ps1
```

Output:

| File | Screen |
|------|--------|
| `01-idle.png` | No destination yet |
| `02-ready.png` | Destination set (Bronte GO), **Start** |
| `03-monitoring.png` | Active trip, **2.3 km remaining**, **Stop** |
| `04-alarm.png` | Wake-up alarm at destination |

## Capture from Wear emulator (pixel-perfect)

After installing a debug Wear APK (includes `ScreenshotActivity` mock states):

```powershell
.\tools\build-wear.ps1 -InstallDebug
.\tools\capture-wear-screenshots.ps1
```

## Quick fix for a raw emulator screenshot

```powershell
cd D:\Dev\Projects\dozealert
.\tools\prepare-wear-play-screenshot.ps1 -InputPath .\wear-raw.png -OutputPath .\play-store\wear-screenshots\01-idle.png
```

This produces a **512x512** square PNG and replaces the emulator gray bezel with black.

Upload files from this folder to **Play Console → Wear OS screenshots**.

## Best capture (avoids bezel)

**Android Studio → Running Devices → camera icon → "Play Store Compatible"** (if shown).

Or raw ADB (then run the script above):

```powershell
adb -s emulator-5554 exec-out screencap -p > wear-raw.png
```

## Suggested shots

1. `01-idle.png` — destination set, Idle / Open on phone
2. `02-monitoring.png` — trip monitoring with km remaining
3. `03-tile.png` — DozeAlert tile (optional)
