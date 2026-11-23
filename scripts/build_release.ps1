[CmdletBinding()]
param(
    [string]$Version,
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
    [switch]$SkipAnalyze
)

$ErrorActionPreference = "Stop"

function Stop-Build([string]$Message) {
    Write-Error $Message
    exit 1
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$PubspecPath = Join-Path $ProjectRoot "pubspec.yaml"
if (-not (Test-Path $PubspecPath)) {
    Stop-Build "pubspec.yaml not found. Run this script from a valid Flutter project."
}

if (-not $Version) {
    $Pubspec = Get-Content $PubspecPath -Raw
    $VersionMatch = [regex]::Match($Pubspec, '(?m)^version:\s*["'']?([^''"\r\n#]+)')
    if (-not $VersionMatch.Success) {
        Stop-Build "Could not read version from pubspec.yaml. Pass -Version explicitly."
    }
    $Version = $VersionMatch.Groups[1].Value.Trim()
}

$SafeVersion = $Version -replace '[^A-Za-z0-9._-]', '_'
$SafeDate = $Date -replace '[^A-Za-z0-9._-]', '_'
$OutputRoot = Join-Path $ProjectRoot "out"
$ReleaseName = "${SafeVersion}_${SafeDate}"
$ReleasePath = Join-Path $OutputRoot $ReleaseName
$BuildPath = Join-Path $ProjectRoot "build\windows\x64\runner\Release"

Write-Host ""
Write-Host "MEDIALOG N3 DESKTOP - WINDOWS RELEASE" -ForegroundColor Cyan
Write-Host "Version : $Version"
Write-Host "Date    : $Date"
Write-Host "Output  : $ReleasePath"
Write-Host ""

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Stop-Build "Flutter was not found in PATH. Install Flutter and reopen PowerShell."
}

if (-not (Test-Path (Join-Path $ProjectRoot "windows"))) {
    Write-Host "Windows desktop runner not found. Generating Windows platform files..." -ForegroundColor Yellow
    flutter create --platforms=windows .
    if ($LASTEXITCODE -ne 0) { Stop-Build "flutter create failed." }
}

Write-Host "[1/4] Resolving dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { Stop-Build "flutter pub get failed." }

if (-not $SkipAnalyze) {
    Write-Host "[2/4] Running static analysis..." -ForegroundColor Cyan
    flutter analyze
    if ($LASTEXITCODE -ne 0) { Stop-Build "flutter analyze failed. Fix analyzer errors or rerun with -SkipAnalyze." }
} else {
    Write-Host "[2/4] Static analysis skipped." -ForegroundColor Yellow
}

Write-Host "[3/4] Building Windows release..." -ForegroundColor Cyan
flutter build windows --release
if ($LASTEXITCODE -ne 0) { Stop-Build "Flutter Windows release build failed." }

if (-not (Test-Path $BuildPath)) {
    Stop-Build "Build output not found: $BuildPath"
}

Write-Host "[4/4] Copying release files..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
if (Test-Path $ReleasePath) {
    Remove-Item $ReleasePath -Recurse -Force
}
New-Item -ItemType Directory -Path $ReleasePath -Force | Out-Null
Copy-Item (Join-Path $BuildPath "*") $ReleasePath -Recurse -Force

$BuildInfo = @"
MEDIALOG N3 INTEGRATION DESKTOP
Version: $Version
Build date: $Date
Target: Windows x64
Configuration: Release

This package is a UI prototype. It contains no production integration with Medialog SQL,
N3.Health, FRMO/FRMR, CryptoPro, or live medical data sources.
"@
Set-Content -Path (Join-Path $ReleasePath "BUILD_INFO.txt") -Value $BuildInfo -Encoding UTF8

Write-Host ""
Write-Host "Release completed successfully." -ForegroundColor Green
Write-Host "Folder: $ReleasePath" -ForegroundColor Green
Write-Host "Executable: $ReleasePath\medialog_n3_integration_desktop.exe"
