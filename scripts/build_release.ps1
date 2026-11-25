[CmdletBinding()]
param(
    [string]$Version,
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
    [switch]$SkipAnalyze
)

$ErrorActionPreference = "Stop"

function Stop-Build([string]$Message) {
    Write-Host ""
    Write-Host "[ОШИБКА] $Message" -ForegroundColor Red
    exit 1
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$PubspecPath = Join-Path $ProjectRoot "pubspec.yaml"
if (-not (Test-Path -LiteralPath $PubspecPath)) {
    Stop-Build "Файл pubspec.yaml не найден. Запустите сценарий из каталога проекта Flutter."
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Pubspec = Get-Content -LiteralPath $PubspecPath -Raw
    $VersionMatch = [regex]::Match($Pubspec, '(?m)^version:\s*["'']?([^''"#\r\n]+)')
    if (-not $VersionMatch.Success) {
        Stop-Build "Не удалось прочитать версию из pubspec.yaml. Укажите её явно параметром -Version."
    }
    $Version = $VersionMatch.Groups[1].Value.Trim()
}

$SafeVersion = $Version -replace '[^A-Za-z0-9._-]', '_'
$SafeDate = $Date -replace '[^A-Za-z0-9._-]', '_'
$OutputRoot = Join-Path $ProjectRoot "out"
$ReleaseName = ""${SafeVersion}_${SafeDate}""
$ReleasePath = Join-Path $OutputRoot $ReleaseName
$BuildPath = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
$ExecutableName = "medialog_n3_integration_desktop.exe"
$ExecutablePath = Join-Path $ReleasePath $ExecutableName

Write-Host ""
Write-Host "MEDIALOG N3 DESKTOP - СБОРКА ДЛЯ WINDOWS" -ForegroundColor Cyan
Write-Host "Версия  : $Version"
Write-Host "Дата    : $Date"
Write-Host "Каталог : $ReleasePath"
Write-Host ""

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Stop-Build "Flutter не найден в PATH. Установите Flutter и перезапустите PowerShell."
}

$WindowsPath = Join-Path $ProjectRoot "windows"
if (-not (Test-Path -LiteralPath $WindowsPath)) {
    Write-Host "Среда запуска Windows не найдена. Создаём файлы платформы Windows..." -ForegroundColor Yellow
    flutter create --platforms=windows .
    if ($LASTEXITCODE -ne 0) {
        Stop-Build "Не удалось создать файлы платформы Windows."
    }
}

Write-Host "[1/4] Загрузка зависимостей..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Stop-Build "Не удалось загрузить зависимости Flutter."
}

if (-not $SkipAnalyze) {
    Write-Host "[2/4] Статический анализ кода..." -ForegroundColor Cyan
    flutter analyze
    if ($LASTEXITCODE -ne 0) {
        Stop-Build "Статический анализ завершился с ошибками. Исправьте их или повторите запуск с параметром -SkipAnalyze."
    }
}
else {
    Write-Host "[2/4] Статический анализ пропущен." -ForegroundColor Yellow
}

Write-Host "[3/4] Сборка приложения для Windows..." -ForegroundColor Cyan
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Stop-Build "Не удалось собрать приложение для Windows."
}

if (-not (Test-Path -LiteralPath $BuildPath -PathType Container)) {
    Stop-Build "Каталог с результатами сборки не найден: $BuildPath"
}

$BuiltExecutable = Join-Path $BuildPath $ExecutableName
if (-not (Test-Path -LiteralPath $BuiltExecutable -PathType Leaf)) {
    Stop-Build "После сборки не найден исполняемый файл: $BuiltExecutable"
}

Write-Host "[4/4] Копирование файлов приложения..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

if (Test-Path -LiteralPath $ReleasePath) {
    Remove-Item -LiteralPath $ReleasePath -Recurse -Force
}

New-Item -ItemType Directory -Path $ReleasePath -Force | Out-Null
Copy-Item -Path (Join-Path $BuildPath "*") -Destination $ReleasePath -Recurse -Force

if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
    Stop-Build "Исполняемый файл не был скопирован в каталог релиза: $ExecutablePath"
}

$BuildInfo = @"
MEDIALOG N3 INTEGRATION DESKTOP
Version: $Version
Build date: $Date
Target platform: Windows x64
Configuration: Release

Этот пакет является визуальным прототипом. В нём нет промышленной интеграции с Медиалог SQL,
N3.Health, ФРМО/ФРМР, CryptoPro и реальными источниками медицинских данных.
"@

$BuildInfoPath = Join-Path $ReleasePath "BUILD_INFO.txt"
Set-Content -LiteralPath $BuildInfoPath -Value $BuildInfo -Encoding UTF8

Write-Host ""
Write-Host "Сборка успешно завершена." -ForegroundColor Green
Write-Host "Каталог: $ReleasePath" -ForegroundColor Green
Write-Host "Исполняемый файл: $ExecutablePath" -ForegroundColor Green
