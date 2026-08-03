# Replace website Android screenshots from new_shots_android and build
# Play Console phone assets at 1080x1920 (9:16).
#
# Usage (repo root):
#   powershell -ExecutionPolicy Bypass -File .\tools\update-android-screenshots.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent
$newDir = Join-Path $root 'website\assets\screens\new_shots_android'
$webDir = Join-Path $root 'website\assets\screens'
$playDir = Join-Path $root 'play-store\phone-screenshots'
New-Item -ItemType Directory -Force -Path $playDir | Out-Null

function Save-Jpeg {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [string]$Path,
    [long]$Quality = 88
  )
  $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq 'image/jpeg' }
  $eps = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $eps.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality,
    $Quality
  )
  $Bitmap.Save($Path, $codec, $eps)
}

function Convert-ToWebsiteJpeg {
  param(
    [string]$SourcePng,
    [string]$DestJpeg
  )
  $src = [System.Drawing.Image]::FromFile($SourcePng)
  try {
    $bmp = New-Object System.Drawing.Bitmap $src.Width, $src.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
      $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $g.DrawImage($src, 0, 0, $src.Width, $src.Height)
      Save-Jpeg -Bitmap $bmp -Path $DestJpeg
    } finally {
      $g.Dispose()
      $bmp.Dispose()
    }
  } finally {
    $src.Dispose()
  }
}

function Convert-ToPlayScreenshot {
  param(
    [string]$SourcePath,
    [string]$DestPng,
    [int]$OutW = 1080,
    [int]$OutH = 1920
  )
  $src = [System.Drawing.Image]::FromFile($SourcePath)
  try {
    # Scale to target width, then center-crop height to 9:16.
    $scale = $OutW / [double]$src.Width
    $scaledH = [int][math]::Round($src.Height * $scale)
    $tmp = New-Object System.Drawing.Bitmap $OutW, $scaledH
    $g1 = [System.Drawing.Graphics]::FromImage($tmp)
    try {
      $g1.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $g1.DrawImage($src, 0, 0, $OutW, $scaledH)
    } finally {
      $g1.Dispose()
    }

    $cropY = [math]::Max(0, [int][math]::Round(($scaledH - $OutH) / 2.0))
    if ($scaledH -lt $OutH) {
      # Letterbox if somehow shorter than 9:16.
      $out = New-Object System.Drawing.Bitmap $OutW, $OutH
      $g2 = [System.Drawing.Graphics]::FromImage($out)
      try {
        $g2.Clear([System.Drawing.Color]::White)
        $y = [int](($OutH - $scaledH) / 2)
        $g2.DrawImage($tmp, 0, $y, $OutW, $scaledH)
        $out.Save($DestPng, [System.Drawing.Imaging.ImageFormat]::Png)
      } finally {
        $g2.Dispose()
        $out.Dispose()
      }
    } else {
      $rect = New-Object System.Drawing.Rectangle 0, $cropY, $OutW, $OutH
      $out = $tmp.Clone($rect, $tmp.PixelFormat)
      try {
        $out.Save($DestPng, [System.Drawing.Imaging.ImageFormat]::Png)
      } finally {
        $out.Dispose()
      }
    }
    $tmp.Dispose()
  } finally {
    $src.Dispose()
  }
}

# Website replacements (filename in new_shots_android -> shotN.jpg).
# Intentionally NOT replacing: shot1 (alarm), shot28 (monitoring — no clean new shot),
# splash/onboarding/map-pin shots the user did not retake.
$websiteMap = [ordered]@{
  'Screenshot_20260730-211308.png' = 'shot9.jpg'   # Permissions
  'Screenshot_20260730-210603.png' = 'shot11.jpg'  # Home — Pick your stop
  'Screenshot_20260730-211140.png' = 'shot12.jpg'  # Station list
  'Screenshot_20260730-211155.png' = 'shot13.jpg'  # Choose transit & line
  'Screenshot_20260730-210709.png' = 'shot16.jpg'  # Ready / Start
  'Screenshot_20260730-210741.png' = 'shot20.jpg'  # My Trips
  'Screenshot_20260730-210758.png' = 'shot21.jpg'  # Settings hub
  'Screenshot_20260730-210941.png' = 'shot24.jpg'  # Wake alert settings
}

Write-Host 'Updating website Android JPGs...' -ForegroundColor Cyan
foreach ($entry in $websiteMap.GetEnumerator()) {
  $src = Join-Path $newDir $entry.Key
  $dst = Join-Path $webDir $entry.Value
  if (-not (Test-Path $src)) { throw "Missing source: $src" }
  Convert-ToWebsiteJpeg -SourcePng $src -DestJpeg $dst
  Write-Host "  $($entry.Value) <- $($entry.Key)"
}

# Play Console phone set (upload order). Mix new shots + kept classics.
$playMap = [ordered]@{
  '01-home-pick-stop.png'      = (Join-Path $newDir 'Screenshot_20260730-210603.png')
  '02-ready-start.png'         = (Join-Path $newDir 'Screenshot_20260730-210709.png')
  '03-pick-stop-stations.png'  = (Join-Path $newDir 'Screenshot_20260730-211140.png')
  '04-choose-transit-line.png' = (Join-Path $newDir 'Screenshot_20260730-211155.png')
  '05-monitoring.png'          = (Join-Path $webDir 'shot28.jpg')  # kept — no clean retake
  '06-wake-alert.png'          = (Join-Path $newDir 'Screenshot_20260730-211117.png')
  '07-my-trips.png'            = (Join-Path $newDir 'Screenshot_20260730-210741.png')
  '08-alarm.png'               = (Join-Path $webDir 'shot1.jpg')   # kept — unchanged
}

Write-Host 'Building Play Store phone screenshots (1080x1920)...' -ForegroundColor Cyan
foreach ($entry in $playMap.GetEnumerator()) {
  $dst = Join-Path $playDir $entry.Key
  Convert-ToPlayScreenshot -SourcePath $entry.Value -DestPng $dst
  Write-Host "  $($entry.Key)"
}

# Extra optional Play candidates (not in the primary 8).
$optionalDir = Join-Path $playDir 'optional'
New-Item -ItemType Directory -Force -Path $optionalDir | Out-Null
$optionalMap = [ordered]@{
  'settings.png'           = (Join-Path $newDir 'Screenshot_20260730-210758.png')
  'wake-alert-settings.png'= (Join-Path $newDir 'Screenshot_20260730-210941.png')
  'permissions.png'        = (Join-Path $newDir 'Screenshot_20260730-211308.png')
  'quick-picks.png'        = (Join-Path $newDir 'Screenshot_20260730-210646.png')
  'about.png'              = (Join-Path $newDir 'Screenshot_20260730-210900.png')
  'wear-os-settings.png'   = (Join-Path $newDir 'Screenshot_20260730-211013.png')
  'transit-line-setup.png' = (Join-Path $newDir 'Screenshot_20260730-211217.png')
}
foreach ($entry in $optionalMap.GetEnumerator()) {
  Convert-ToPlayScreenshot -SourcePath $entry.Value -DestPng (Join-Path $optionalDir $entry.Key)
  Write-Host "  optional/$($entry.Key)"
}

$readme = @'
# Phone screenshots for Google Play

Upload order (Phone → Store listing → Graphics):

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

All primary files are **1080 × 1920** (9:16) for Play Console.

`optional/` has extras if you want to swap (settings, permissions, quick picks, etc.).

Not used for store listing: field-test GPS-weak shot (`Screenshot_20260730-081345.png`).

Regenerate:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\update-android-screenshots.ps1
```
'@
Set-Content -Path (Join-Path $playDir 'README.md') -Value $readme -Encoding UTF8

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host "Website JPGs: $webDir"
Write-Host "Play assets:  $playDir"
