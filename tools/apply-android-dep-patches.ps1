# Patch Flutter Android deps so Play Console static checks pass.
# Safe to re-run (idempotent). Call after `flutter pub get`.
#
# flutter_local_notifications: BitmapFactory.decode* without Options
# (Play: "missing BitmapFactory.Options parameter")

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-LfText([string]$Path) {
    return ([System.IO.File]::ReadAllText($Path) -replace "`r`n", "`n").TrimEnd() + "`n"
}

$patchDir = Join-Path $PSScriptRoot 'patches'
$pubCache = Join-Path $env:LOCALAPPDATA 'Pub\Cache\hosted\pub.dev'

if (-not (Test-Path $pubCache)) {
    Write-Host "Pub cache not found at $pubCache - skip dep patches." -ForegroundColor Yellow
    return
}

$helpers = Read-LfText (Join-Path $patchDir 'flutter_local_notifications_BitmapFactoryHelpers.java.fragment')
$newBitmapMethod = Read-LfText (Join-Path $patchDir 'flutter_local_notifications_getBitmapFromSource.java.fragment')
$newIconFile = (Read-LfText (Join-Path $patchDir 'flutter_local_notifications_iconFile.java.fragment')).TrimEnd()
$assetOld = (Read-LfText (Join-Path $patchDir 'flutter_local_notifications_iconAsset_old.java.fragment')).TrimEnd()
$assetNew = (Read-LfText (Join-Path $patchDir 'flutter_local_notifications_iconAsset_new.java.fragment')).TrimEnd()

$pluginDirs = Get-ChildItem $pubCache -Directory -Filter 'flutter_local_notifications-*' |
    Where-Object { $_.Name -match '^flutter_local_notifications-\d' }

if (-not $pluginDirs) {
    Write-Host 'flutter_local_notifications not in pub cache - skip.' -ForegroundColor Yellow
    return
}

$marker = 'decodeSampledBitmapFile'
$bitmapNeedle = 'private static Bitmap getBitmapFromSource'
$iconFileOld = 'icon = IconCompat.createWithBitmap(BitmapFactory.decodeFile((String) data));'

$patched = 0
foreach ($dir in $pluginDirs) {
    $java = Join-Path $dir.FullName 'android\src\main\java\com\dexterous\flutterlocalnotifications\FlutterLocalNotificationsPlugin.java'
    if (-not (Test-Path $java)) { continue }

    $text = [System.IO.File]::ReadAllText($java) -replace "`r`n", "`n"

    if ($text.Contains($marker)) {
        Write-Host "Already patched: $($dir.Name)" -ForegroundColor DarkGray
        continue
    }

    if (-not $text.Contains($bitmapNeedle)) {
        Write-Host "Skip $($dir.Name): getBitmapFromSource not found." -ForegroundColor Yellow
        continue
    }

    $pattern = '(?s)  private static Bitmap getBitmapFromSource\(\s*Context context, Object data, BitmapSource bitmapSource\) \{.*?\n  \}\n'
    $replacement = $newBitmapMethod + "`n" + $helpers + "`n"
    $newText = [regex]::Replace($text, $pattern, $replacement, 1)
    if ($newText -eq $text) {
        Write-Host "Skip $($dir.Name): getBitmapFromSource regex did not match." -ForegroundColor Yellow
        continue
    }
    $text = $newText

    if ($text.Contains($iconFileOld)) {
        $text = $text.Replace($iconFileOld, $newIconFile)
    }

    if ($text.Contains($assetOld)) {
        $text = $text.Replace($assetOld, $assetNew)
    }

    [System.IO.File]::WriteAllText($java, $text)
    Write-Host "Patched BitmapFactory Options into $($dir.Name)" -ForegroundColor Green
    $patched++
}

if ($patched -eq 0) {
    Write-Host 'No new flutter_local_notifications patches applied.' -ForegroundColor DarkGray
}
