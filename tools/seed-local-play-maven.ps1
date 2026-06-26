# Seeds android/local-play-maven for Gradle when Java cannot reach Google Maven (SSL).
# Run from repo root: powershell -ExecutionPolicy Bypass -File .\tools\seed-local-play-maven.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
$mavenRoot = Join-Path $projectRoot 'android/local-play-maven'

function Install-LocalMavenArtifact {
    param(
        [string]$GroupId,
        [string]$ArtifactId,
        [string]$Version,
        [string]$Extension,
        [string]$RepositoryBase = 'https://dl.google.com/dl/android/maven2'
    )

    $groupPath = $GroupId.Replace('.', '/')
    $fileName = "$ArtifactId-$Version.$Extension"
    $targetDir = Join-Path $mavenRoot "$groupPath/$ArtifactId/$Version"
    $targetFile = Join-Path $targetDir $fileName
    $url = "$RepositoryBase/$groupPath/$ArtifactId/$Version/$fileName"

    if (Test-Path $targetFile) {
        Write-Host "  skip $fileName"
        return
    }

    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    Invoke-WebRequest -Uri $url -OutFile $targetFile
    Write-Host "  saved $fileName"
}

Write-Host "Seeding local Play Maven repo at android/local-play-maven ..."
New-Item -ItemType Directory -Force -Path $mavenRoot | Out-Null

$artifacts = @(
    @('com.google.android.play', 'app-update-ktx', '2.1.0'),
    @('com.google.android.play', 'app-update', '2.1.0'),
    @('com.google.android.play', 'core-common', '2.0.3'),
    @('com.google.android.gms', 'play-services-basement', '18.1.0'),
    @('com.google.android.gms', 'play-services-tasks', '18.0.2'),
    @('androidx.core', 'core', '1.1.0'),
    @('androidx.fragment', 'fragment', '1.1.0')
)

foreach ($artifact in $artifacts) {
    Install-LocalMavenArtifact -GroupId $artifact[0] -ArtifactId $artifact[1] -Version $artifact[2] -Extension 'pom'
    Install-LocalMavenArtifact -GroupId $artifact[0] -ArtifactId $artifact[1] -Version $artifact[2] -Extension 'aar'
}

$mavenCentral = 'https://repo.maven.apache.org/maven2'
$kotlinArtifacts = @(
    @('org.jetbrains.kotlin', 'kotlin-stdlib-common', '1.8.20'),
    @('org.jetbrains.kotlin', 'kotlin-stdlib', '1.8.20'),
    @('org.jetbrains.kotlin', 'kotlin-stdlib-jdk7', '1.8.20'),
    @('org.jetbrains.kotlin', 'kotlin-stdlib-jdk8', '1.8.20'),
    @('org.jetbrains.kotlin', 'kotlin-stdlib-common', '2.2.10'),
    @('org.jetbrains.kotlin', 'kotlin-stdlib', '2.2.10'),
    @('org.jetbrains.kotlin', 'kotlin-stdlib-jdk7', '2.2.10'),
    @('org.jetbrains.kotlin', 'kotlin-stdlib-jdk8', '2.2.10')
)

foreach ($artifact in $kotlinArtifacts) {
    Install-LocalMavenArtifact -GroupId $artifact[0] -ArtifactId $artifact[1] -Version $artifact[2] -Extension 'pom' -RepositoryBase $mavenCentral
    try {
        Install-LocalMavenArtifact -GroupId $artifact[0] -ArtifactId $artifact[1] -Version $artifact[2] -Extension 'jar' -RepositoryBase $mavenCentral
    } catch {
        Write-Host "  skip jar $($artifact[1])-$($artifact[2])"
    }
}

Write-Host "Done."
