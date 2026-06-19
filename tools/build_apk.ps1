# Build release APK for direct download (sideload / website)
# Uses release signing when android/key.properties exists; otherwise debug signing.
# See docs/APK_RELEASE.md

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot

$versionLine = (Select-String -Path "pubspec.yaml" -Pattern "^version:").Line
if ($versionLine -match "version:\s*([\d.]+)\+(\d+)") {
    $versionName = $Matches[1]
    $versionCode = $Matches[2]
} else {
    $versionName = "1.0.0"
    $versionCode = "1"
}

Write-Host "Building DozeAlert $versionName ($versionCode)..." -ForegroundColor Cyan

flutter pub get
flutter build apk --release

$apkSource = "build/app/outputs/flutter-apk/app-release.apk"
if (-not (Test-Path $apkSource)) {
    Pop-Location
    throw "Build failed: $apkSource not found"
}

$downloadsDir = Join-Path $projectRoot "website/downloads"
New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null

$versionedName = "dozealert-$versionName.apk"
$latestName = "dozealert-latest.apk"

Copy-Item $apkSource (Join-Path $downloadsDir $versionedName) -Force
Copy-Item $apkSource (Join-Path $downloadsDir $latestName) -Force

Write-Host ""
Write-Host "Success:" -ForegroundColor Green
Write-Host "  $downloadsDir\$versionedName"
Write-Host "  $downloadsDir\$latestName"
Write-Host ""
Write-Host "Deploy the website/ folder to your host, then share:" -ForegroundColor Yellow
Write-Host "  https://your-domain.com/downloads/dozealert-latest.apk"

Pop-Location
