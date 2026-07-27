# Bump phone build number in pubspec.yaml and sync website version files.
#
# Examples (from project root):
#   .\tools\bump-version.ps1              # 1.1.0+62 -> 1.1.0+63
#   .\tools\bump-version.ps1 -Build 70    # set build number explicitly
#   .\tools\bump-version.ps1 -Name 1.2.0  # set marketing version (keeps/+bumps build)
#
# Always run this (or release.ps1) before commit/push for TestFlight / Play / website.
# Do not ship a fix commit at the previous +N and bump in a follow-up — Mac pulls
# between those commits (or stale ios/Flutter/Generated.xcconfig) look like "still 61".

[CmdletBinding()]
param(
    [int]$Build = 0,
    [string]$Name = '',
    [switch]$SkipWebsite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
$pubspec = Get-Content $pubspecPath -Raw

if ($pubspec -notmatch '(?m)^version:\s*([\d.]+)\+(\d+)\s*$') {
    throw "Could not parse version from pubspec.yaml"
}

$currentName = $Matches[1]
$currentBuild = [int]$Matches[2]
$nextName = if ($Name) { $Name } else { $currentName }
$nextBuild = if ($Build -gt 0) { $Build } else { $currentBuild + 1 }

if ($nextBuild -le $currentBuild -and -not $Name) {
    throw "Refusing to set build $nextBuild (current is $currentBuild). Pass -Build with a higher number."
}

$nextLabel = "$nextName+$nextBuild"
$pubspec = [regex]::Replace(
    $pubspec,
    '(?m)^version:\s*[\d.]+\+\d+\s*$',
    "version: $nextLabel"
)
Set-Content -Path $pubspecPath -Value $pubspec -Encoding utf8 -NoNewline

Write-Host "pubspec.yaml -> $nextLabel (was $currentName+$currentBuild)" -ForegroundColor Green

if (-not $SkipWebsite) {
    & (Join-Path $PSScriptRoot 'sync-website-versions.ps1')
}

Write-Host ""
Write-Host "Next (Mac / TestFlight): after git pull, regenerate Xcode build number:" -ForegroundColor Cyan
Write-Host "  flutter pub get"
Write-Host "  flutter build ios --config-only --release --build-name=$nextName --build-number=$nextBuild"
Write-Host "  grep FLUTTER_BUILD ios/Flutter/Generated.xcconfig"
