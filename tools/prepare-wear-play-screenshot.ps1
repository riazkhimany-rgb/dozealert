# Convert a raw Wear emulator/device screenshot into a Play Console-compatible PNG.
#
# Play requirements (Wear OS):
#   - 1:1 aspect ratio, at least 384 x 384 px
#   - App UI only (no emulator device frame / gray bezel)
#   - Solid background (black is fine), not transparent
#
# Usage:
#   .\tools\prepare-wear-play-screenshot.ps1 -InputPath .\wear-raw.png
#   .\tools\prepare-wear-play-screenshot.ps1 -InputPath .\wear-raw.png -OutputPath .\play-store\wear-screenshots\01-idle.png
#
# Capture raw screenshot:
#   adb -s emulator-5554 exec-out screencap -p > wear-raw.png
#
# Android Studio: Running Devices -> camera -> "Play Store Compatible" (best)

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [string]$OutputPath,

    [ValidateRange(384, 2048)]
    [int]$Size = 512
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

function Test-BezelGray {
    param([System.Drawing.Color]$Color)

    if ($Color.A -lt 200) {
        return $false
    }

    $r = [int]$Color.R
    $g = [int]$Color.G
    $b = [int]$Color.B
    $max = [Math]::Max($r, [Math]::Max($g, $b))
    $min = [Math]::Min($r, [Math]::Min($g, $b))

    if (($max - $min) -gt 24) {
        return $false
    }

    $avg = ($r + $g + $b) / 3.0
    return ($avg -ge 45 -and $avg -le 150)
}

function Get-CenterSquareRect {
    param([System.Drawing.Bitmap]$Bitmap)

    $side = [Math]::Min($Bitmap.Width, $Bitmap.Height)
    $x = [int][Math]::Floor(($Bitmap.Width - $side) / 2.0)
    $y = [int][Math]::Floor(($Bitmap.Height - $side) / 2.0)
    return [System.Drawing.Rectangle]::new($x, $y, $side, $side)
}

function Remove-EmulatorBezel {
    param([System.Drawing.Bitmap]$Bitmap)

    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
        for ($x = 0; $x -lt $Bitmap.Width; $x++) {
            $pixel = $Bitmap.GetPixel($x, $y)
            if (Test-BezelGray -Color $pixel) {
                $Bitmap.SetPixel($x, $y, [System.Drawing.Color]::Black)
            }
        }
    }
}

function Save-PlayScreenshot {
    param(
        [System.Drawing.Bitmap]$Source,
        [System.Drawing.Rectangle]$CropRect,
        [int]$TargetSize,
        [string]$Destination
    )

    $cropped = New-Object System.Drawing.Bitmap $CropRect.Width, $CropRect.Height
    $cropGraphics = [System.Drawing.Graphics]::FromImage($cropped)
    $cropGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $cropGraphics.DrawImage(
        $Source,
        (New-Object System.Drawing.Rectangle 0, 0, $CropRect.Width, $CropRect.Height),
        $CropRect,
        [System.Drawing.GraphicsUnit]::Pixel
    )
    $cropGraphics.Dispose()

    Remove-EmulatorBezel -Bitmap $cropped

    $output = New-Object System.Drawing.Bitmap $TargetSize, $TargetSize
    $outputGraphics = [System.Drawing.Graphics]::FromImage($output)
    $outputGraphics.Clear([System.Drawing.Color]::Black)
    $outputGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $outputGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $outputGraphics.DrawImage($cropped, 0, 0, $TargetSize, $TargetSize)
    $outputGraphics.Dispose()
    $cropped.Dispose()

    $directory = Split-Path -Parent $Destination
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $output.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
    $output.Dispose()
}

$resolvedInput = Resolve-Path -LiteralPath $InputPath
if (-not $OutputPath) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedInput.Path)
    $OutputPath = Join-Path (Split-Path $PSScriptRoot -Parent) "play-store\wear-screenshots\$baseName-play.png"
}

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$bitmap = [System.Drawing.Bitmap]::FromFile($resolvedInput.Path)

try {
    $cropRect = Get-CenterSquareRect -Bitmap $bitmap
    Save-PlayScreenshot -Source $bitmap -CropRect $cropRect -TargetSize $Size -Destination $resolvedOutput

    Write-Host "Play-ready Wear screenshot:" -ForegroundColor Green
    Write-Host "  $resolvedOutput"
    Write-Host "  ${Size}x${Size} PNG, 1:1, emulator bezel replaced with black"
}
finally {
    $bitmap.Dispose()
}
