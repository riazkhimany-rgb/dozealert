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
    Push-Location $projectRoot
    flutter pub get | Out-Null
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
