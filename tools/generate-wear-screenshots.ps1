# Generate DozeAlert Wear OS Play Store screenshots (512x512, round-watch layout).
# Matches TripScreen / AlarmActivity copy and Wear Material3 dark styling.
#
# Usage:
#   .\tools\generate-wear-screenshots.ps1

[CmdletBinding()]
param(
    [string]$OutputDir = "",
    [int]$Size = 512
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputDir) {
    $OutputDir = Join-Path (Split-Path $scriptRoot -Parent) "play-store\wear-screenshots"
}

Add-Type -AssemblyName System.Drawing

function New-Font {
    param(
        [string]$Family,
        [float]$Size,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
    )

    return New-Object System.Drawing.Font($Family, $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
}

function Measure-CenteredBlock {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Font[]]$Fonts,
        [string[]]$Lines,
        [float]$MaxWidth
    )

    $heights = New-Object System.Collections.Generic.List[float]
    $widths = New-Object System.Collections.Generic.List[float]

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $size = $Graphics.MeasureString($Lines[$i], $Fonts[$i], $MaxWidth)
        $heights.Add($size.Height)
        $widths.Add($size.Width)
    }

    $spacing = 10.0
    $totalHeight = ($heights | Measure-Object -Sum).Sum + ($spacing * ([Math]::Max(0, $Lines.Count - 1)))
    return @{
        Heights = $heights
        Widths = $widths
        TotalHeight = $totalHeight
        Spacing = $spacing
    }
}

function Draw-CenteredTextBlock {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Font[]]$Fonts,
        [System.Drawing.Brush[]]$Brushes,
        [string[]]$Lines,
        [float]$CenterX,
        [float]$StartY,
        [float]$MaxWidth,
        [hashtable]$Block
    )

    $y = $StartY
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $format = New-Object System.Drawing.StringFormat
        $format.Alignment = [System.Drawing.StringAlignment]::Center
        $format.LineAlignment = [System.Drawing.StringAlignment]::Near
        $format.Trimming = [System.Drawing.StringTrimming]::EllipsisCharacter
        $rectHeight = $Block.Heights[$i] + 4
        $rect = New-Object System.Drawing.RectangleF ($CenterX - ($MaxWidth / 2.0)), $y, $MaxWidth, $rectHeight
        $Graphics.DrawString($Lines[$i], $Fonts[$i], $Brushes[$i], $rect, $format)
        $y += $Block.Heights[$i] + $Block.Spacing
        $format.Dispose()
    }
}

function Draw-PillButton {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Label,
        [float]$CenterX,
        [float]$Top,
        [float]$Width,
        [float]$Height,
        [System.Drawing.Color]$Fill,
        [System.Drawing.Color]$Border,
        [System.Drawing.Font]$Font,
        [switch]$Outlined
    )

    $left = $CenterX - ($Width / 2.0)
    $rect = New-Object System.Drawing.RectangleF $left, $Top, $Width, $Height
    $radius = $Height / 2.0
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($left, $Top, $Height, $Height, 90, 180)
    $path.AddArc($left + $Width - $Height, $Top, $Height, $Height, 270, 180)
    $path.CloseFigure()

    if ($Outlined) {
        $Graphics.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(24, 255, 255, 255))), $path)
        $pen = New-Object System.Drawing.Pen $Border, 2
        $Graphics.DrawPath($pen, $path)
        $pen.Dispose()
    } else {
        $Graphics.FillPath((New-Object System.Drawing.SolidBrush $Fill), $path)
    }

    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $Graphics.DrawString($Label, $Font, [System.Drawing.Brushes]::White, $rect, $format)
    $format.Dispose()
    $path.Dispose()
}

function Save-WearScreenshot {
    param(
        [hashtable]$Screen,
        [string]$Destination,
        [int]$TargetSize
    )

    $bitmap = New-Object System.Drawing.Bitmap $TargetSize, $TargetSize
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.Clear([System.Drawing.Color]::Black)

    $fontFamily = 'Segoe UI'
    $titleFont = New-Font -Family $fontFamily -Size 22
    $statusFont = New-Font -Family $fontFamily -Size 30 -Style ([System.Drawing.FontStyle]::Bold)
    $bodyFont = New-Font -Family $fontFamily -Size 18
    $buttonFont = New-Font -Family $fontFamily -Size 18
    $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(210, 255, 255, 255))
    $buttonFill = [System.Drawing.Color]::FromArgb(255, 60, 64, 67)
    $buttonBorder = [System.Drawing.Color]::FromArgb(255, 120, 124, 127)

    $lines = @($Screen.AppTitle, $Screen.Status, $Screen.Detail)
    $fonts = @($titleFont, $statusFont, $bodyFont)
    $brushes = @($white, $white, $muted)

    if ($Screen.Subline) {
        $lines += $Screen.Subline
        $fonts += $bodyFont
        $brushes += $muted
    }

    $maxTextWidth = $TargetSize * 0.78
    $block = Measure-CenteredBlock -Graphics $graphics -Fonts $fonts -Lines $lines -MaxWidth $maxTextWidth

    $buttonHeight = 46.0
    $buttonWidth = $TargetSize * 0.72
    $buttonGap = 12.0
    $buttonCount = 0
    if ($Screen.PrimaryButton) { $buttonCount++ }
    if ($Screen.SecondaryButton) { $buttonCount++ }
    $buttonsHeight = if ($buttonCount -gt 0) { ($buttonCount * $buttonHeight) + (($buttonCount - 1) * $buttonGap) } else { 0 }
    if ($buttonsHeight -gt 0) {
        $contentHeight = $block.TotalHeight + 24 + $buttonsHeight
    } else {
        $contentHeight = $block.TotalHeight
    }
    $startY = ($TargetSize - $contentHeight) / 2.0

    Draw-CenteredTextBlock -Graphics $graphics -Fonts $fonts -Brushes $brushes -Lines $lines `
        -CenterX ($TargetSize / 2.0) -StartY $startY -MaxWidth $maxTextWidth -Block $block

    $buttonTop = $startY + $block.TotalHeight + 24
    if ($Screen.PrimaryButton) {
        Draw-PillButton -Graphics $graphics -Label $Screen.PrimaryButton -CenterX ($TargetSize / 2.0) `
            -Top $buttonTop -Width $buttonWidth -Height $buttonHeight -Fill $buttonFill -Border $buttonBorder -Font $buttonFont
        $buttonTop += $buttonHeight + $buttonGap
    }
    if ($Screen.SecondaryButton) {
        Draw-PillButton -Graphics $graphics -Label $Screen.SecondaryButton -CenterX ($TargetSize / 2.0) `
            -Top $buttonTop -Width $buttonWidth -Height $buttonHeight -Fill $buttonFill -Border $buttonBorder `
            -Font $buttonFont -Outlined
    }

    $directory = Split-Path -Parent $Destination
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $bitmap.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $bitmap.Dispose()
    $titleFont.Dispose()
    $statusFont.Dispose()
    $bodyFont.Dispose()
    $buttonFont.Dispose()
    $white.Dispose()
    $muted.Dispose()
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$screens = @(
    @{
        File = '01-idle.png'
        AppTitle = 'DozeAlert'
        Status = 'Idle'
        Detail = 'Set destination on phone'
        Subline = 'Waiting for phone…'
        PrimaryButton = $null
        SecondaryButton = 'Open on phone'
    },
    @{
        File = '02-ready.png'
        AppTitle = 'DozeAlert'
        Status = 'Idle'
        Detail = 'Bronte GO'
        Subline = $null
        PrimaryButton = 'Start'
        SecondaryButton = 'Open on phone'
    },
    @{
        File = '03-monitoring.png'
        AppTitle = 'DozeAlert'
        Status = 'Monitoring'
        Detail = '2.3 km remaining'
        Subline = $null
        PrimaryButton = 'Stop'
        SecondaryButton = 'Open on phone'
    },
    @{
        File = '04-alarm.png'
        AppTitle = $null
        Status = 'Wake up'
        Detail = 'Bronte GO'
        Subline = 'Alarm active'
        PrimaryButton = 'Dismiss alarm'
        SecondaryButton = $null
    }
)

foreach ($screen in $screens) {
    if ($screen.AppTitle -eq $null) {
        # Alarm screen: no app title line
        $path = Join-Path $OutputDir $screen.File
        $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
        $graphics.Clear([System.Drawing.Color]::Black)

        $statusFont = New-Font -Family 'Segoe UI' -Size 32 -Style ([System.Drawing.FontStyle]::Bold)
        $bodyFont = New-Font -Family 'Segoe UI' -Size 20
        $buttonFont = New-Font -Family 'Segoe UI' -Size 18
        $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
        $muted = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(210, 255, 255, 255))

        $lines = @($screen.Status, $screen.Detail, $screen.Subline)
        $fonts = @($statusFont, $bodyFont, $bodyFont)
        $brushes = @($white, $white, $muted)
        $maxTextWidth = $Size * 0.78
        $block = Measure-CenteredBlock -Graphics $graphics -Fonts $fonts -Lines $lines -MaxWidth $maxTextWidth

        $buttonHeight = 46.0
        $buttonWidth = $Size * 0.72
        $contentHeight = $block.TotalHeight + 24 + $buttonHeight
        $startY = ($Size - $contentHeight) / 2.0

        Draw-CenteredTextBlock -Graphics $graphics -Fonts $fonts -Brushes $brushes -Lines $lines `
            -CenterX ($Size / 2.0) -StartY $startY -MaxWidth $maxTextWidth -Block $block

        Draw-PillButton -Graphics $graphics -Label $screen.PrimaryButton -CenterX ($Size / 2.0) `
            -Top ($startY + $block.TotalHeight + 24) -Width $buttonWidth -Height $buttonHeight `
            -Fill ([System.Drawing.Color]::FromArgb(255, 60, 64, 67)) `
            -Border ([System.Drawing.Color]::FromArgb(255, 120, 124, 127)) -Font $buttonFont

        $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose()
        $bitmap.Dispose()
        $statusFont.Dispose()
        $bodyFont.Dispose()
        $buttonFont.Dispose()
        $white.Dispose()
        $muted.Dispose()
    } else {
        Save-WearScreenshot -Screen $screen -Destination (Join-Path $OutputDir $screen.File) -TargetSize $Size
    }

    Write-Host "Generated $(Join-Path $OutputDir $screen.File)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Wear screenshots ready in: $OutputDir" -ForegroundColor Cyan
