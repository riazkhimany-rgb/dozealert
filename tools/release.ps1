# Full release pipeline: clean, verify, build, optional git push & GitHub Release
#
# Examples (run from project root):
#   .\tools\release.ps1                          # APK for website (default)
#
# If PowerShell blocks scripts ("running scripts is disabled"):
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#   -- or one run without changing policy:
#   powershell -ExecutionPolicy Bypass -File .\tools\release.ps1 -CommitMessage "Release 1.0.1" -Push -CreateGitHubRelease
#
#   .\tools\release.ps1 -Target aab                # Google Play bundle
#   .\tools\release.ps1 -Target both               # APK + AAB
#   .\tools\release.ps1 -SkipClean                 # Faster rebuild
#   .\tools\release.ps1 -CommitMessage "Release 1.0.1" -Push
#   .\tools\release.ps1 -CreateGitHubRelease       # After build, upload APK to GitHub Releases
#
# Prerequisites:
#   - Flutter SDK on PATH
#   - android/key.properties for signed release builds (see docs/PLAY_STORE_RELEASE.md)
#   - GOOGLE_MAPS_API_KEY in android/local.properties (maps in release builds)
#   - gh CLI logged in (only for -CreateGitHubRelease)

[CmdletBinding()]
param(
    [ValidateSet('apk', 'aab', 'both')]
    [string]$Target = 'apk',

    [switch]$SkipClean,
    [switch]$SkipTests,
    [switch]$SkipBranding,
    [switch]$Push,
    [string]$CommitMessage,
    [switch]$CreateGitHubRelease,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot

function Invoke-Step {
    param(
        [string]$Label,
        [scriptblock]$Action
    )
    Write-Host ""
    Write-Host "==> $Label" -ForegroundColor Cyan
    if ($DryRun) {
        Write-Host "    (dry run - skipped)" -ForegroundColor DarkGray
        return
    }
    & $Action
    # PowerShell pipelines (e.g. flutter --version | Select-Object) can leave LASTEXITCODE at -1
    # even when the command succeeded; only treat positive exit codes as failure.
    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -gt 0) {
        throw "Step failed: $Label (exit $LASTEXITCODE)"
    }
}

function Get-VersionInfo {
    $line = (Select-String -Path 'pubspec.yaml' -Pattern '^version:').Line
    if ($line -match 'version:\s*([\d.]+)\+(\d+)') {
        return @{
            Name = $Matches[1]
            Code = $Matches[2]
            Tag  = "v$($Matches[1])"
        }
    }
    return @{ Name = '1.0.0'; Code = '1'; Tag = 'v1.0.0' }
}

function Test-ReleaseSigning {
    $keyProps = Join-Path $projectRoot 'android/key.properties'
    if (-not (Test-Path $keyProps)) {
        Write-Host ""
        Write-Host "WARNING: android/key.properties not found." -ForegroundColor Yellow
        Write-Host "  Release builds will use the debug keystore." -ForegroundColor Yellow
        Write-Host "  See docs/PLAY_STORE_RELEASE.md to configure signing." -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Copy-ApkToWebsite {
    param([hashtable]$Version)

    $apkSource = 'build/app/outputs/flutter-apk/app-release.apk'
    if (-not (Test-Path $apkSource)) {
        throw "APK not found at $apkSource"
    }

    $downloadsDir = Join-Path $projectRoot 'website/downloads'
    New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null

    $versioned = "dozealert-$($Version.Name).apk"
    Copy-Item $apkSource (Join-Path $downloadsDir $versioned) -Force
    Copy-Item $apkSource (Join-Path $downloadsDir 'dozealert-latest.apk') -Force

    Update-WebsiteVersion -Version $Version

    Write-Host ""
    Write-Host "APK copied to website/downloads/:" -ForegroundColor Green
    Write-Host "  $versioned"
    Write-Host "  dozealert-latest.apk"
}

function Update-WebsiteVersion {
    param([hashtable]$Version)

    $versionJsonPath = Join-Path $projectRoot 'website/app-version.json'
    $versionLabel = "$($Version.Name)+$($Version.Code)"
    @"
{"version":"$($Version.Name)","build":$($Version.Code),"label":"$versionLabel"}
"@ | Set-Content -Path $versionJsonPath -Encoding utf8

    $indexPath = Join-Path $projectRoot 'website/index.html'
    if (Test-Path $indexPath) {
        $indexHtml = Get-Content $indexPath -Raw
        $indexHtml = [regex]::Replace(
            $indexHtml,
            '(<span id="app-version">)[^<]*(</span>)',
            "`${1}$versionLabel`${2}"
        )
        Set-Content -Path $indexPath -Value $indexHtml -Encoding utf8 -NoNewline
    }

    Write-Host "  Website version set to $versionLabel" -ForegroundColor Green
}

function Invoke-GitRelease {
    param(
        [string]$Message,
        [switch]$DoPush
    )

    $secretPatterns = @(
        'key.properties',
        'android/key.properties',
        '.env'
    )

    foreach ($pattern in $secretPatterns) {
        $full = Join-Path $projectRoot $pattern
        if (Test-Path $full) {
            git reset --quiet HEAD -- $pattern 2>$null
            if (git check-ignore -q $pattern 2>$null) { continue }
            Write-Host "  Skipping secret/untracked file from commit: $pattern" -ForegroundColor Yellow
        }
    }

    git add -A
    foreach ($pattern in $secretPatterns) {
        if (Test-Path (Join-Path $projectRoot $pattern)) {
            git reset HEAD -- $pattern 2>$null
        }
    }

    $status = git status --porcelain
    if ([string]::IsNullOrWhiteSpace($status)) {
        Write-Host "  Nothing to commit." -ForegroundColor DarkGray
    } else {
        git commit -m $Message
        Write-Host "  Committed: $Message" -ForegroundColor Green
    }

    if ($DoPush) {
        $branch = git rev-parse --abbrev-ref HEAD
        git push -u origin $branch
        Write-Host "  Pushed branch: $branch" -ForegroundColor Green
    }
}

function Invoke-GithubRelease {
    param(
        [hashtable]$Version
    )

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'GitHub CLI (gh) not found. Install from https://cli.github.com/'
    }

    $apk = Join-Path $projectRoot "website/downloads/dozealert-$($Version.Name).apk"
    if (-not (Test-Path $apk)) {
        throw "Release APK not found: $apk (build with -Target apk first)"
    }

    $tag = $Version.Tag
    $title = "DozeAlert $($Version.Name)"
    $notes = @"
Release $($Version.Name) (build $($Version.Code)).

Download the APK below or from https://dozealert.app
"@

    gh release view $tag 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Release $tag already exists - uploading asset only." -ForegroundColor Yellow
        gh release upload $tag $apk --clobber
    } else {
        gh release create $tag $apk `
            --title $title `
            --notes $notes
    }

    Write-Host "  GitHub Release: $tag" -ForegroundColor Green
}

try {
    $version = Get-VersionInfo
    Write-Host "DozeAlert release pipeline - $($version.Name)+$($version.Code) - target: $Target" -ForegroundColor White

    Invoke-Step 'Check Flutter' {
        if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
            throw 'Flutter not found on PATH. Install Flutter and add it to PATH.'
        }
        $versionLine = (flutter --version 2>&1 | Select-Object -First 1)
        Write-Host $versionLine
    }
    Test-ReleaseSigning | Out-Null

    if (-not $SkipClean) {
        Invoke-Step 'flutter clean' { flutter clean }
    }

    Invoke-Step 'flutter pub get' { flutter pub get }

    if (-not $SkipBranding) {
        Invoke-Step 'Regenerate launcher icons' { dart run flutter_launcher_icons }
        Invoke-Step 'Regenerate native splash' { dart run flutter_native_splash:create }
    }

    Invoke-Step 'flutter analyze' { flutter analyze }

    if (-not $SkipTests) {
        Invoke-Step 'flutter test' { flutter test }
    }

    if ($Target -eq 'apk' -or $Target -eq 'both') {
        Invoke-Step 'flutter build apk --release' { flutter build apk --release }
        if (-not $DryRun) {
            Copy-ApkToWebsite -Version $version
        }
    }

    if ($Target -eq 'aab' -or $Target -eq 'both') {
        Invoke-Step 'flutter build appbundle --release' { flutter build appbundle --release }
        $bundle = 'build/app/outputs/bundle/release/app-release.aab'
        if (-not $DryRun -and (Test-Path $bundle)) {
            Write-Host "  AAB: $bundle" -ForegroundColor Green
        }
    }

    if ($CommitMessage) {
        Invoke-Step 'Git commit' {
            Invoke-GitRelease -Message $CommitMessage -DoPush:$Push
        }
    } elseif ($Push) {
        Invoke-Step 'Git push' {
            $branch = git rev-parse --abbrev-ref HEAD
            git push -u origin $branch
        }
    }

    if ($CreateGitHubRelease) {
        Invoke-Step 'GitHub Release' {
            Invoke-GithubRelease -Version $version
        }
    }

    Write-Host ""
    Write-Host "Release pipeline finished." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    if ($Target -eq 'apk' -or $Target -eq 'both') {
        Write-Host "  - Upload website/ to dozealert.app (include website/downloads/*.apk)"
    }
    if ($Target -eq 'aab' -or $Target -eq 'both') {
        Write-Host "  - Upload build/app/outputs/bundle/release/app-release.aab to Google Play Console"
    }
    if (-not $CreateGitHubRelease -and ($Target -eq 'apk' -or $Target -eq 'both')) {
        Write-Host "  - Optional: re-run with -CreateGitHubRelease to publish APK on GitHub Releases"
    }
    if (-not $CommitMessage -and -not $Push) {
        Write-Host "  - Optional: re-run with -CommitMessage 'your message' -Push to publish source to GitHub"
    }
}
finally {
    Pop-Location
}
