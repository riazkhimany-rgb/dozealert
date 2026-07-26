# App Store screenshots

Capture on RentAMac (Simulator or physical iPhone). Store final PNGs under `app-store/screenshots/` locally if you want — do not commit large binaries unless you intentionally add them.

## Required display sizes (iPhone)

Upload at least one set Apple currently requires for your primary device class. As of recent App Store Connect UI:

| Display | Typical Simulator | Pixel size (portrait) |
|---------|-------------------|------------------------|
| 6.7" (required for many new apps) | iPhone 15 Pro Max / 16 Plus class | 1290 × 2796 (or current ASC hint) |
| 6.1" | iPhone 15 / 16 | 1179 × 2556 (or current ASC hint) |

Always follow the size hints shown in App Store Connect for your version — Apple changes accepted dimensions over time.

Optional: 5.5" legacy set if Connect still offers it.

## Suggested shots (3–5)

1. Home / trip ready — destination set, Start visible  
2. Transit stop picker or line picker  
3. Active monitoring — distance / stop progress  
4. Map pin destination (non-transit)  
5. Settings / wake distance (optional)

Avoid Wear OS or Android-only screens. Prefer light, real product UI — no fake marketing overlays on the device chrome.

## How to capture (Simulator)

1. Open Simulator (e.g. iPhone 16 Plus).  
2. From Terminal in the repo: `flutter run -d <simulator-id>`  
3. Set up sample destinations / a short demo trip.  
4. In Simulator menu: **File → Save Screen** (or **Device → Screenshot** depending on Xcode version).  
5. Rename files clearly, e.g. `01-home.png`, and upload in App Store Connect → App Store → iOS version → Screenshots.

## App icon

Marketing / App Store icon comes from the Xcode asset catalog (`ios/Runner/Assets.xcassets/AppIcon.appiconset`, including 1024×1024). No separate Play Store feature graphic is required for iOS.
