# Phone screenshots for Google Play

Upload order (Phone â†’ Store listing â†’ Graphics):

| # | File | Source | Caption idea |
|---|------|--------|----------------|
| 1 | `01-home-pick-stop.png` | new | Never miss your stop again |
| 2 | `02-ready-start.png` | new | Set your stop, tap Start |
| 3 | `03-pick-stop-stations.png` | new | Pick any station on your line |
| 4 | `04-choose-transit-line.png` | new | Choose transit and line |
| 5 | `05-monitoring.png` | kept (`shot28`) | Watching your trip |
| 6 | `06-wake-alert.png` | new | Wake 1 stop before |
| 7 | `07-my-trips.png` | new | Saved stops and lines |
| 8 | `08-alarm.png` | kept (`shot1`) | GET READY wake alert |

All primary files are **1080 Ã— 1920** (9:16) for Play Console.

`optional/` has extras if you want to swap (settings, permissions, quick picks, etc.).

Not used for store listing: field-test GPS-weak shot (`Screenshot_20260730-081345.png`).

Regenerate:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\update-android-screenshots.ps1
```
