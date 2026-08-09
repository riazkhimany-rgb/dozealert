# Wear OS screenshots for Google Play

Play Console requires:

- **1:1 aspect ratio**, minimum **384 x 384** pixels
- **App UI only** — no emulator gray bezel / device frame
- **Solid background** (black is fine), not transparent

## Current listing set (`play-store/wear-screenshots/`)

Upload these to **Play Console → Wear OS screenshots** (numeric order):

| Play file | Source | Screen |
|-----------|--------|--------|
| `01-idle.png` | prior capture | Set up on phone |
| `02-ready.png` | `watch_shot1.png` | **Ready** + **scrollbar** (Derry Rd / Start trip) |
| `03-monitoring.png` | prior capture | Monitoring / distance left |
| `04-alarm.png` | prior capture | Wake-up alarm |
| `05-splash.png` | `watch_shot2.png` | **Branded splash** (sleepy-pin on black) |

`02-ready` and `05-splash` prove the two Wear App Quality fixes that blocked production.

JPEG mirrors for the same upload set also live in `website/play-console/wear/` (`02-ready.jpg`, `05-splash.jpg`).

## Regenerate from website captures

```powershell
cd D:\Dev\Projects\dozealert
.\tools\prepare-wear-play-screenshot.ps1 -InputPath website\assets\screens\watch_shot1.png -OutputPath play-store\wear-screenshots\02-ready.png
.\tools\prepare-wear-play-screenshot.ps1 -InputPath website\assets\screens\watch_shot2.png -OutputPath play-store\wear-screenshots\05-splash.png
```

Website display copies:

- `website/assets/screens/w_shot_ready_scroll.png`
- `website/assets/screens/w_shot_splash.png`

## Quick generate (no emulator, synthetic UI)

```powershell
cd D:\Dev\Projects\dozealert
.\tools\generate-wear-screenshots.ps1
```

## Capture from Wear emulator (pixel-perfect)

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

## Best capture (avoids bezel)

**Android Studio → Running Devices → camera icon → "Play Store Compatible"** (if shown).

Or raw ADB (then run the script above):

```powershell
adb -s emulator-5554 exec-out screencap -p > wear-raw.png
```
