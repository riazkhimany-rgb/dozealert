# Wear OS screenshots for Google Play

Play Console requires:

- **1:1 aspect ratio**, minimum **384 x 384** pixels
- **App UI only** — no emulator gray bezel / device frame
- **Solid background** (black is fine), not transparent

## From website captures (current listing assets)

Real Wear app UI captures live in `website/assets/screens/watch_shot*.png`.
Convert them to Play-ready **512×512** opaque PNGs:

```powershell
cd D:\Dev\Projects\dozealert
.\tools\prepare-wear-play-screenshot.ps1 -InputPath website\assets\screens\watch_shot4.png -OutputPath play-store\wear-screenshots\01-idle.png
.\tools\prepare-wear-play-screenshot.ps1 -InputPath website\assets\screens\watch_shot2.png -OutputPath play-store\wear-screenshots\02-ready.png
.\tools\prepare-wear-play-screenshot.ps1 -InputPath website\assets\screens\watch_shot1.png -OutputPath play-store\wear-screenshots\03-monitoring.png
.\tools\prepare-wear-play-screenshot.ps1 -InputPath website\assets\screens\watch_shot3.png -OutputPath play-store\wear-screenshots\04-alarm.png
```

| Play file | Source | Screen |
|-----------|--------|--------|
| `01-idle.png` | `watch_shot4.png` | Set up on phone |
| `02-ready.png` | `watch_shot2.png` | Ready to rest, **Start trip** |
| `03-monitoring.png` | `watch_shot1.png` | **17.4 km left**, Clarkson GO |
| `04-alarm.png` | `watch_shot3.png` | Wake-up alarm |

## Quick generate (no emulator, synthetic UI)

Renders Play-ready **512×512** PNGs from scripted mock UI:

```powershell
cd D:\Dev\Projects\dozealert
.\tools\generate-wear-screenshots.ps1
```

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
