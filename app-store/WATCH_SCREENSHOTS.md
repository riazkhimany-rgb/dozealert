# Apple Watch screenshots (App Store)

Upload in App Store Connect → your iOS version → **Apple Watch** screenshots
(or Media Manager → Apple Watch).

Apple requires **one consistent size** across all localizations. Prefer the size
Connect marks as required for your app (often Series 11 **416 × 496**). Extra
folders below are ready if Connect asks for other slots.

## Upload folders (`screens/upload/`)

| Folder | Pixels | Connect models |
|--------|--------|----------------|
| `watch-422x514/` | 422 × 514 | Ultra 3 |
| `watch-410x502/` | 410 × 502 | Ultra 2 / Ultra |
| `watch-416x496/` | 416 × 496 | **Series 11 / Series 10** (recommended start) |
| `watch-396x484/` | 396 × 484 | Series 9 / 8 / 7 |
| `watch-368x448/` | 368 × 448 | Series 6 / 5 / 4 / SE |
| `watch-312x390/` | 312 × 390 | Series 3 |

Each folder has the same three shots, in upload order:

1. `01-ready-start-trip.png` — Ready + Start trip  
2. `02-watching.png` — Watching + Stop trip  
3. `03-idle-set-up-on-phone.png` — Idle / set up on phone  

## How to upload

1. Open the **Apple Watch** screenshot area in Connect.  
2. Start with **`upload/watch-416x496/`** (Series 11 size shown in Connect).  
3. Drag **01 → 02 → 03** in that order.  
4. If Connect still shows empty required slots for Ultra / Series 9 / etc., upload the matching folder the same way (same three files).  
5. Save.

Source captures: `screens/watch/` and `Simulator Screenshot - Apple Watch…`.

## Optional later captures

- GET READY full-screen alarm  
- Complication on a watch face  
- Watching with a realistic stop count / distance (Simulator GPS can show absurd km)
