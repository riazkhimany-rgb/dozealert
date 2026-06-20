# Regenerate launcher, splash, and website icons from the canonical splash artwork.
# Run from project root: .\tool\generate_branding_assets.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
$sourcePath = Join-Path $projectRoot 'assets/branding/splash_screen.png'
if (-not (Test-Path $sourcePath)) {
    throw "Missing source artwork: $sourcePath"
}

Add-Type -AssemblyName System.Drawing

function Test-BackgroundPixel {
    param([System.Drawing.Color]$Color)
    $dr = [Math]::Abs([int]$Color.R - 13)
    $dg = [Math]::Abs([int]$Color.G - 27)
    $db = [Math]::Abs([int]$Color.B - 42)
    return ($dr -lt 42 -and $dg -lt 42 -and $db -lt 42)
}

function Get-PinBounds {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$ScanHeight
    )

    $minX = $Bitmap.Width
    $maxX = 0
    $minY = $ScanHeight
    $maxContentY = 0

    $scanLeft = [int]($Bitmap.Width * 0.28)
    $scanRight = [int]($Bitmap.Width * 0.72)

    for ($y = 0; $y -lt $ScanHeight; $y++) {
        for ($x = $scanLeft; $x -lt $scanRight; $x++) {
            $pixel = $Bitmap.GetPixel($x, $y)
            if (-not (Test-BackgroundPixel $pixel)) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxContentY) { $maxContentY = $y }
            }
        }
    }

    if ($maxX -le $minX -or $maxContentY -le $minY) {
        throw 'Could not detect pin artwork in splash_screen.png'
    }

    $padX = [int](($maxX - $minX) * 0.16)
    $padY = [int](($maxContentY - $minY) * 0.14)
    $originX = [Math]::Max(0, $minX - $padX)
    $originY = [Math]::Max(0, $minY - $padY)
    $width = [Math]::Min($Bitmap.Width - $originX, ($maxX - $minX) + (2 * $padX))
    $height = [Math]::Min($ScanHeight - $originY, ($maxContentY - $minY) + (2 * $padY))

    return @{
        X      = $originX
        Y      = $originY
        Width  = $width
        Height = $height
    }
}

function New-CroppedBitmap {
    param(
        [System.Drawing.Bitmap]$Source,
        [hashtable]$Bounds
    )

    $crop = New-Object System.Drawing.Bitmap $Bounds.Width, $Bounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($crop)
    $graphics.DrawImage(
        $Source,
        (New-Object System.Drawing.Rectangle 0, 0, $Bounds.Width, $Bounds.Height),
        $Bounds.X,
        $Bounds.Y,
        $Bounds.Width,
        $Bounds.Height,
        [System.Drawing.GraphicsUnit]::Pixel
    )
    $graphics.Dispose()
    return $crop
}

function New-TransparentForeground {
    param([System.Drawing.Bitmap]$Cropped)

    $output = New-Object System.Drawing.Bitmap $Cropped.Width, $Cropped.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $Cropped.Height; $y++) {
        for ($x = 0; $x -lt $Cropped.Width; $x++) {
            $pixel = $Cropped.GetPixel($x, $y)
            if (Test-BackgroundPixel $pixel) {
                $output.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            } else {
                $output.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $pixel.R, $pixel.G, $pixel.B))
            }
        }
    }
    return $output
}

function New-SquareCanvas {
    param(
        [System.Drawing.Bitmap]$Foreground,
        [int]$Size,
        [System.Drawing.Color]$BackgroundColor,
        [double]$PaddingRatio = 0.1,
        [int]$CornerRadius = 0
    )

    $canvas = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear($BackgroundColor)

    if ($CornerRadius -gt 0) {
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $rect = New-Object System.Drawing.Rectangle 0, 0, $Size, $Size
        $d = $CornerRadius * 2
        $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
        $path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
        $path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
        $path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
        $path.CloseFigure()
        $graphics.SetClip($path)
        $graphics.Clear($BackgroundColor)
    }

    $maxDraw = [int]($Size * (1.0 - (2 * $PaddingRatio)))
    $scale = [Math]::Min(
        $maxDraw / $Foreground.Width,
        $maxDraw / $Foreground.Height
    )
    $drawWidth = [int]($Foreground.Width * $scale)
    $drawHeight = [int]($Foreground.Height * $scale)
    $offsetX = [int](($Size - $drawWidth) / 2)
    $offsetY = [int](($Size - $drawHeight) / 2)

    $graphics.DrawImage(
        $Foreground,
        (New-Object System.Drawing.Rectangle $offsetX, $offsetY, $drawWidth, $drawHeight)
    )
    $graphics.Dispose()
    return $canvas
}

function New-TransparentSquareForeground {
    param(
        [System.Drawing.Bitmap]$Foreground,
        [int]$Size = 1024,
        [double]$PaddingRatio = 0.08
    )

    $canvas = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $maxDraw = [int]($Size * (1.0 - (2 * $PaddingRatio)))
    $scale = [Math]::Min(
        $maxDraw / $Foreground.Width,
        $maxDraw / $Foreground.Height
    )
    $drawWidth = [int]($Foreground.Width * $scale)
    $drawHeight = [int]($Foreground.Height * $scale)
    $offsetX = [int](($Size - $drawWidth) / 2)
    $offsetY = [int](($Size - $drawHeight) / 2)

    $graphics.DrawImage(
        $Foreground,
        (New-Object System.Drawing.Rectangle $offsetX, $offsetY, $drawWidth, $drawHeight)
    )
    $graphics.Dispose()
    return $canvas
}

function Save-Png {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Path
    )

    $directory = Split-Path $Path -Parent
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function New-NotificationIcon {
    param(
        [System.Drawing.Bitmap]$Foreground,
        [int]$Size
    )

    $canvas = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $maxDraw = [int]($Size * 0.84)
    $scale = [Math]::Min(
        $maxDraw / $Foreground.Width,
        $maxDraw / $Foreground.Height
    )
    $drawWidth = [int]($Foreground.Width * $scale)
    $drawHeight = [int]($Foreground.Height * $scale)
    $offsetX = [int](($Size - $drawWidth) / 2)
    $offsetY = [int](($Size - $drawHeight) / 2)

    $attrs = New-Object System.Drawing.Imaging.ImageAttributes
    $matrix = New-Object System.Drawing.Imaging.ColorMatrix
    $matrix.Matrix00 = 0
    $matrix.Matrix11 = 0
    $matrix.Matrix22 = 0
    $matrix.Matrix33 = 1
    $matrix.Matrix40 = 1
    $matrix.Matrix41 = 1
    $matrix.Matrix42 = 1
    $attrs.SetColorMatrix($matrix)

    $graphics.DrawImage(
        $Foreground,
        (New-Object System.Drawing.Rectangle $offsetX, $offsetY, $drawWidth, $drawHeight),
        0,
        0,
        $Foreground.Width,
        $Foreground.Height,
        [System.Drawing.GraphicsUnit]::Pixel,
        $attrs
    )

    $graphics.Dispose()
    return $canvas
}

Write-Host 'Generating branding assets from splash_screen.png...' -ForegroundColor Cyan

$source = New-Object System.Drawing.Bitmap $sourcePath
$scanHeight = [int]($source.Height * 0.62)
$bounds = Get-PinBounds -Bitmap $source -ScanHeight $scanHeight
Write-Host "  Pin crop: $($bounds.Width)x$($bounds.Height) at ($($bounds.X), $($bounds.Y))" -ForegroundColor DarkGray

$cropped = New-CroppedBitmap -Source $source -Bounds $bounds
$foreground = New-TransparentForeground -Cropped $cropped
$backgroundColor = [System.Drawing.Color]::FromArgb(255, 13, 27, 42)

$brandingDir = Join-Path $projectRoot 'assets/branding'
$websiteDir = Join-Path $projectRoot 'website/assets'
$playStoreDir = Join-Path $projectRoot 'play-store'
$webDir = Join-Path $projectRoot 'web'

Save-Png -Bitmap $foreground -Path (Join-Path $brandingDir 'splash_logo.png')
Save-Png -Bitmap $foreground -Path (Join-Path $websiteDir 'logo.png')

$iconForeground = New-TransparentSquareForeground -Foreground $foreground -Size 1024 -PaddingRatio 0.08
Save-Png -Bitmap $iconForeground -Path (Join-Path $brandingDir 'icon_foreground.png')

$icon512 = New-SquareCanvas -Foreground $foreground -Size 512 -BackgroundColor $backgroundColor -PaddingRatio 0.08 -CornerRadius 96
Save-Png -Bitmap $icon512 -Path (Join-Path $websiteDir 'icon-512.png')
Save-Png -Bitmap $icon512 -Path (Join-Path $playStoreDir 'icon-512.png')

$web192 = New-SquareCanvas -Foreground $foreground -Size 192 -BackgroundColor $backgroundColor -PaddingRatio 0.08 -CornerRadius 36
$web512 = New-SquareCanvas -Foreground $foreground -Size 512 -BackgroundColor $backgroundColor -PaddingRatio 0.08 -CornerRadius 96
Save-Png -Bitmap $web192 -Path (Join-Path $webDir 'icons/Icon-192.png')
Save-Png -Bitmap $web512 -Path (Join-Path $webDir 'icons/Icon-512.png')
Save-Png -Bitmap $web192 -Path (Join-Path $webDir 'icons/Icon-maskable-192.png')
Save-Png -Bitmap $web512 -Path (Join-Path $webDir 'icons/Icon-maskable-512.png')
Save-Png -Bitmap $web192 -Path (Join-Path $webDir 'favicon.png')

foreach ($size in @(24, 36, 48, 72, 96)) {
    $folder = switch ($size) {
        24 { 'drawable-mdpi' }
        36 { 'drawable-hdpi' }
        48 { 'drawable-xhdpi' }
        72 { 'drawable-xxhdpi' }
        96 { 'drawable-xxxhdpi' }
    }
    $notification = New-NotificationIcon -Foreground $foreground -Size $size
    Save-Png -Bitmap $notification -Path (Join-Path $projectRoot "android/app/src/main/res/$folder/ic_stat_dozealert.png")
    $notification.Dispose()
}

$icon512.Dispose()
$iconForeground.Dispose()
$web192.Dispose()
$web512.Dispose()
$foreground.Dispose()
$cropped.Dispose()
$source.Dispose()

Write-Host 'Branding assets updated.' -ForegroundColor Green
Write-Host 'Next: dart run flutter_launcher_icons && dart run flutter_native_splash:create' -ForegroundColor DarkGray
Write-Host '  Native splash uses icon_foreground.png (square) for Android 12 launch animation.' -ForegroundColor DarkGray
