# Capture DozeAlert Wear OS screenshots from a running watch emulator/device.
#
# Requires debug Wear APK installed (includes ScreenshotActivity mock states).
#
# Usage:
#   .\tools\capture-wear-screenshots.ps1
#   .\tools\capture-wear-screenshots.ps1 -Device emulator-5554

[CmdletBinding()]
param(
    [string]$Device = "",

    [string]$OutputDir = (Join-Path (Split-Path $PSScriptRoot -Parent) "play-store\wear-screenshots")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-WearDevice {
    param([string]$Preferred)

    if ($Preferred) {
        return $Preferred
    }

    $lines = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\tdevice$' }
    foreach ($line in $lines) {
        $serial = ($line -split '\t')[0]
        $chars = (adb -s $serial shell getprop ro.build.characteristics 2>$null).Trim()
        if ($chars -match 'watch') {
            return $serial
        }
    }

    throw 'No Wear OS emulator/device found. Start a Wear AVD and rerun.'
}

function Invoke-WearScreenshot {
    param(
        [string]$Serial,
        [string]$Scenario,
        [string]$RawPath,
        [string]$PlayPath
    )

    adb -s $Serial shell am start -W -n "app.dozealert/.ScreenshotActivity" --es scenario $Scenario | Out-Null
    Start-Sleep -Seconds 2
    adb -s $Serial exec-out screencap -p | Set-Content -Path $RawPath -Encoding Byte
    & (Join-Path $PSScriptRoot 'prepare-wear-play-screenshot.ps1') -InputPath $RawPath -OutputPath $PlayPath
}

$serial = Get-WearDevice -Preferred $Device
Write-Host "Using Wear device: $serial" -ForegroundColor Cyan

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$tempDir = Join-Path $env:TEMP "dozealert-wear-capture"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
}

$shots = @(
    @{ Scenario = 'idle';       File = '01-idle.png' },
    @{ Scenario = 'ready';      File = '02-ready.png' },
    @{ Scenario = 'monitoring'; File = '03-monitoring.png' },
    @{ Scenario = 'alarm';      File = '04-alarm.png' }
)

foreach ($shot in $shots) {
    $raw = Join-Path $tempDir $shot.File
    $out = Join-Path $OutputDir $shot.File
    Write-Host "Capturing $($shot.File) ($($shot.Scenario))..." -ForegroundColor Cyan
    Invoke-WearScreenshot -Serial $serial -Scenario $shot.Scenario -RawPath $raw -PlayPath $out
}

Write-Host ""
Write-Host "Wear screenshots saved to:" -ForegroundColor Green
Write-Host "  $OutputDir"
