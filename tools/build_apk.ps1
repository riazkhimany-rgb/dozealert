# Build release APK for direct download (sideload / website)
# Uses release signing when android/key.properties exists; otherwise debug signing.
# See docs/APK_RELEASE.md
#
# By default builds arm64 only (faster / smaller). Pass -FatApk for all ABIs.

[CmdletBinding()]
param(
    [switch]$FatApk
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot

try {
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
    & (Join-Path $PSScriptRoot 'apply-android-dep-patches.ps1')

    $apkArgs = @('build', 'apk', '--release')
    if (-not $FatApk) {
        $apkArgs += @('--target-platform', 'android-arm64')
        Write-Host "  APK ABI: android-arm64 (pass -FatApk for universal)" -ForegroundColor DarkGray
    }

    & flutter @apkArgs
    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -gt 0) {
        throw "flutter build apk failed (exit $LASTEXITCODE)"
    }

    $apkSource = "build/app/outputs/flutter-apk/app-release.apk"
    if (-not (Test-Path $apkSource)) {
        throw "Build failed: $apkSource not found"
    }

    $downloadsDir = Join-Path $projectRoot "website/downloads"
    New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null

    $versionedName = "dozealert-$versionName.apk"
    $latestName = "dozealert-latest.apk"

    Copy-Item $apkSource (Join-Path $downloadsDir $versionedName) -Force
    Copy-Item $apkSource (Join-Path $downloadsDir $latestName) -Force

    & (Join-Path $PSScriptRoot 'sync-website-versions.ps1')

    Write-Host ""
    Write-Host "Success:" -ForegroundColor Green
    Write-Host "  $downloadsDir\$versionedName"
    Write-Host "  $downloadsDir\$latestName"
    Write-Host ""
    Write-Host "Deploy the website/ folder to your host, then share:" -ForegroundColor Yellow
    Write-Host "  https://your-domain.com/downloads/dozealert-latest.apk"
}
finally {
    Pop-Location
}
