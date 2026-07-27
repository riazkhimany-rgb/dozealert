# Sync website cache-bust query params and version JSON from pubspec.yaml build number.
# Run after bumping version in pubspec.yaml (e.g. before deploy or release build).
# Prefer: .\tools\bump-version.ps1 (bumps pubspec then calls this).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
$versionLine = (Select-String -Path (Join-Path $projectRoot 'pubspec.yaml') -Pattern '^version:').Line
if ($versionLine -match 'version:\s*([\d.]+)\+(\d+)') {
    $versionName = $Matches[1]
    $versionCode = $Matches[2]
} else {
    throw 'Could not parse version from pubspec.yaml'
}

$versionLabel = "$versionName+$versionCode"
$websiteRoot = Join-Path $projectRoot 'website'
$utf8Bom = New-Object System.Text.UTF8Encoding $true

function Write-Utf8BomFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content,
        [switch]$EnsureTrailingNewline
    )
    $text = $Content
    if ($EnsureTrailingNewline -and -not $text.EndsWith("`n")) {
        $text += "`n"
    }
    [System.IO.File]::WriteAllText($Path, $text, $utf8Bom)
}

$appVersionJson = (@{
    version = $versionName
    build   = [int]$versionCode
    label   = $versionLabel
} | ConvertTo-Json -Compress)
Write-Utf8BomFile (Join-Path $websiteRoot 'app-version.json') $appVersionJson -EnsureTrailingNewline

# Must match android/wear/build.gradle.kts wearVersionExtra (default 25).
$wearExtra = 25
$wearGradle = Join-Path $projectRoot 'android/wear/build.gradle.kts'
if (Test-Path $wearGradle) {
    $wearText = Get-Content $wearGradle -Raw
    if ($wearText -match 'wearVersionExtra\s*=\s*(\d+)') {
        $wearExtra = [int]$Matches[1]
    }
}
$wearBuild = 100000 + [int]$versionCode + $wearExtra
$wearVersionJson = (@{
    version    = $versionName
    build      = $wearBuild
    phoneBuild = [int]$versionCode
    label      = "$versionName+$wearBuild"
} | ConvertTo-Json -Compress)
Write-Utf8BomFile (Join-Path $websiteRoot 'wear-version.json') $wearVersionJson -EnsureTrailingNewline

Get-ChildItem -Path $websiteRoot -Filter 'index.asp' -Recurse -File | ForEach-Object {
    $html = [System.IO.File]::ReadAllText($_.FullName)
    # Preserve leading BOM if present.
    $hadBom = $html.Length -gt 0 -and [int][char]$html[0] -eq 0xFEFF
    if ($hadBom) {
        $html = $html.Substring(1)
    }

    $html = [regex]::Replace($html, 'brand\.css\?v=\d+', "brand.css?v=$versionCode")
    $html = [regex]::Replace($html, 'brand\.js\?v=\d+', "brand.js?v=$versionCode")
    $html = [regex]::Replace(
        $html,
        'icon-512\.png(?:\?v=\d+)?',
        "icon-512.png?v=$versionCode"
    )
    if ($_.DirectoryName -eq $websiteRoot) {
        $html = [regex]::Replace(
            $html,
            '(<span id="app-version">)[^<]*(</span>)',
            "`${1}$versionLabel`${2}"
        )
        $html = [regex]::Replace(
            $html,
            '(<span id="wear-version">)[^<]*(</span>)',
            "`${1}$versionName+$wearBuild`${2}"
        )
    }

    if ($hadBom) {
        $html = ([char]0xFEFF) + $html
    }
    Write-Utf8BomFile $_.FullName $html
}

Write-Host "Website synced to $versionLabel (asset cache bust ?v=$versionCode; wear $versionName+$wearBuild)" -ForegroundColor Green
