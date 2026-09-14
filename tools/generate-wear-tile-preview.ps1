# Generate the Wear OS tile preview drawable (WO-V10).
#
# The tile manager on the watch and in the phone companion shows this asset, and
# the Wear app quality guidelines expect it to depict the tile's actual content
# rather than a generic app icon. This mirrors DozeAlertTileService.buildTile():
# black canvas, grey CAPTION1 status over a cyan TITLE3 trip line.
#
# Usage (from project root):
#   .\tools\generate-wear-tile-preview.ps1
#
# If you capture the real tile from a watch instead, overwrite the same path.

[CmdletBinding()]
param(
    [string]$OutputPath = "",

    [int]$Size = 384,

    [string]$Status = "Watching",

    [string]$Line = "2 stops to go"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputPath) {
    $OutputPath = Join-Path (Split-Path $scriptRoot -Parent) `
        "android\wear\src\main\res\drawable-nodpi\tile_preview.png"
}

Add-Type -AssemblyName System.Drawing

# Matches DozeAlertTileService: 0xFF94A3B8 caption, 0xFF4CC9F0 line, black canvas.
$captionColor = [System.Drawing.Color]::FromArgb(255, 0x94, 0xA3, 0xB8)
$lineColor = [System.Drawing.Color]::FromArgb(255, 0x4C, 0xC9, 0xF0)

# Protolayout CAPTION1 is 16sp and TITLE3 is 20sp; the preview represents a
# 192dp screen at 2x, so scale both by two.
$captionPx = [float]($Size * 16.0 / 192.0)
$linePx = [float]($Size * 20.0 / 192.0)
$spacerPx = [float]($Size * 4.0 / 192.0)

$bitmap = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$captionFont = $null
$lineFont = $null
$captionBrush = $null
$lineBrush = $null
$format = $null

try {
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear([System.Drawing.Color]::Black)

    $captionFont = New-Object System.Drawing.Font(
        'Segoe UI', $captionPx, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $lineFont = New-Object System.Drawing.Font(
        'Segoe UI', $linePx, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $captionBrush = New-Object System.Drawing.SolidBrush $captionColor
    $lineBrush = New-Object System.Drawing.SolidBrush $lineColor

    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Near
    $format.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter

    $maxWidth = [float]($Size * 0.8)
    $captionSize = $graphics.MeasureString($Status, $captionFont, $maxWidth)
    $lineSize = $graphics.MeasureString($Line, $lineFont, $maxWidth)
    $totalHeight = $captionSize.Height + $spacerPx + $lineSize.Height
    $top = ($Size - $totalHeight) / 2.0
    $left = ($Size - $maxWidth) / 2.0

    $graphics.DrawString(
        $Status, $captionFont, $captionBrush,
        (New-Object System.Drawing.RectangleF $left, $top, $maxWidth, $captionSize.Height), $format)
    $graphics.DrawString(
        $Line, $lineFont, $lineBrush,
        (New-Object System.Drawing.RectangleF $left, ($top + $captionSize.Height + $spacerPx), $maxWidth, $lineSize.Height),
        $format)

    $directory = Split-Path -Parent $OutputPath
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Tile preview written:" -ForegroundColor Green
    Write-Host "  $OutputPath (${Size}x${Size})"
}
finally {
    if ($format) { $format.Dispose() }
    if ($lineBrush) { $lineBrush.Dispose() }
    if ($captionBrush) { $captionBrush.Dispose() }
    if ($lineFont) { $lineFont.Dispose() }
    if ($captionFont) { $captionFont.Dispose() }
    $graphics.Dispose()
    $bitmap.Dispose()
}
