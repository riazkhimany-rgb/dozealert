# Build signed release App Bundle for Google Play
# Prerequisites: android/key.properties configured (see docs/PLAY_STORE_RELEASE.md)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location (Split-Path $PSScriptRoot -Parent)

flutter clean
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter build appbundle --release

$bundle = "build/app/outputs/bundle/release/app-release.aab"
$mapping = "build/app/outputs/mapping/release/mapping.txt"
if (Test-Path $bundle) {
    Write-Host ""
    Write-Host "Success: $bundle" -ForegroundColor Green
    if (Test-Path $mapping) {
        Write-Host "Deobfuscation file: $mapping" -ForegroundColor Green
        Write-Host "Upload mapping.txt in Play Console -> App bundle explorer -> Downloads"
    }
    Write-Host "Upload to Google Play Console -> Internal testing"
} else {
    Write-Error "Build failed: $bundle not found"
}

Pop-Location
