# Sync website cache-bust query params and version JSON from pubspec.yaml build number.
# Run after bumping version in pubspec.yaml (e.g. before deploy or release build).

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

@{
    version = $versionName
    build   = [int]$versionCode
    label   = $versionLabel
} | ConvertTo-Json -Compress | Set-Content (Join-Path $websiteRoot 'app-version.json') -Encoding utf8

$wearVersionPath = Join-Path $websiteRoot 'wear-version.json'
if (Test-Path $wearVersionPath) {
    $wear = Get-Content $wearVersionPath -Raw | ConvertFrom-Json
    $wear.phoneBuild = [int]$versionCode
    $wear | ConvertTo-Json -Compress | Set-Content $wearVersionPath -Encoding utf8
}

Get-ChildItem -Path $websiteRoot -Filter 'index.html' -Recurse -File | ForEach-Object {
    $html = Get-Content $_.FullName -Raw
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
    }
    Set-Content -Path $_.FullName -Value $html -Encoding utf8 -NoNewline
}

Write-Host "Website synced to $versionLabel (asset cache bust ?v=$versionCode)" -ForegroundColor Green
