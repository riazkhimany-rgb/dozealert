# Build the Wear OS companion AAB for Google Play.
#
# Usage (from project root):
#   .\tools\build-wear.ps1
#   .\tools\build-wear.ps1 -InstallDebug

[CmdletBinding()]
param(
    [switch]$InstallDebug
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location (Join-Path $projectRoot 'android')

function Resolve-JavaHome {
    $candidates = @(
        'C:\Program Files\Android\Android Studio\jbr',
        'C:\Program Files\Android\Android Studio1\jbr',
        "$env:LOCALAPPDATA\Programs\Android Studio\jbr"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path (Join-Path $candidate 'bin\java.exe')) {
            return $candidate
        }
    }

    try {
        $flutterJdk = (flutter doctor -v 2>&1 |
            Select-String 'Java binary at:' |
            ForEach-Object { ($_ -replace '.*Java binary at:\s*', '').Trim() })
        if ($flutterJdk -and (Test-Path $flutterJdk)) {
            return Split-Path (Split-Path $flutterJdk -Parent) -Parent
        }
    } catch {
        # fall through
    }

    throw 'JAVA_HOME not found. Install Android Studio or set JAVA_HOME to your JDK folder.'
}

try {
    $env:JAVA_HOME = Resolve-JavaHome
    Write-Host "Using JAVA_HOME=$($env:JAVA_HOME)" -ForegroundColor Cyan

    # Sync Flutter version into local.properties for wear versionCode/versionName.
    # flutter pub get alone can leave a stale flutter.versionCode — write from pubspec.
    Push-Location $projectRoot
    flutter pub get | Out-Null
    $versionLine = (Select-String -Path (Join-Path $projectRoot 'pubspec.yaml') -Pattern '^version:').Line
    if ($versionLine -notmatch 'version:\s*([\d.]+)\+(\d+)') {
        throw "Could not parse version from pubspec.yaml"
    }
    $versionName = $Matches[1]
    $versionCode = $Matches[2]
    $localProps = Join-Path $projectRoot 'android\local.properties'
    if (-not (Test-Path $localProps)) {
        throw "Missing $localProps"
    }
    $updated = Get-Content $localProps | ForEach-Object {
        if ($_ -match '^flutter\.versionCode=') { "flutter.versionCode=$versionCode" }
        elseif ($_ -match '^flutter\.versionName=') { "flutter.versionName=$versionName" }
        else { $_ }
    }
    $updated | Set-Content $localProps -Encoding ascii
    $wearExtra = 25
    $wearGradle = Get-Content (Join-Path $projectRoot 'android\wear\build.gradle.kts') -Raw
    if ($wearGradle -match 'wearVersionExtra\s*=\s*(\d+)') {
        $wearExtra = [int]$Matches[1]
    }
    $wearCode = 100000 + [int]$versionCode + $wearExtra
    Write-Host "Wear versionName=$versionName versionCode=$wearCode (phone +$versionCode, extra $wearExtra)" -ForegroundColor Cyan
    Pop-Location

    if ($InstallDebug) {
        Write-Host 'Building and installing Wear debug APK...' -ForegroundColor Cyan
        .\gradlew :wear:installDebug
    } else {
        Write-Host 'Building Wear release AAB...' -ForegroundColor Cyan
        .\gradlew :wear:bundleRelease
        $bundle = Join-Path $projectRoot 'build\wear\outputs\bundle\release\wear-release.aab'
        if (Test-Path $bundle) {
            Write-Host ""
            Write-Host "Wear AAB ready:" -ForegroundColor Green
            Write-Host "  $bundle"
        }
    }
}
finally {
    Pop-Location
}
