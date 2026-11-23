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
    Stop-Build "Файл pubspec.yaml не найден. Запустите сценарий из каталога проекта Flutter."
}

if (-not $Version) {
    $Pubspec = Get-Content $PubspecPath -Raw
    $VersionMatch = [regex]::Match($Pubspec, '(?m)^version:\s*["'']?([^''"\r\n#]+)')
    if (-not $VersionMatch.Success) {
        Stop-Build "Не удалось прочитать версию из pubspec.yaml. Укажите её явно параметром -Version."
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
Write-Host "MEDIALOG N3 DESKTOP - СБОРКА ДЛЯ WINDOWS" -ForegroundColor Cyan
Write-Host "Версия  : $Version"
Write-Host "Дата    : $Date"
Write-Host "Каталог : $ReleasePath"
Write-Host ""

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Stop-Build "Flutter не найден в PATH. Установите Flutter и перезапустите PowerShell."
}

if (-not (Test-Path (Join-Path $ProjectRoot "windows"))) {
    Write-Host "Среда запуска Windows не найдена. Создаём файлы платформы Windows..." -ForegroundColor Yellow
    flutter create --platforms=windows .
    if ($LASTEXITCODE -ne 0) { Stop-Build "Не удалось создать файлы платформы Windows." }
}

Write-Host "[1/4] Загрузка зависимостей..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { Stop-Build "Не удалось загрузить зависимости Flutter." }

if (-not $SkipAnalyze) {
    Write-Host "[2/4] Статический анализ кода..." -ForegroundColor Cyan
    flutter analyze
    if ($LASTEXITCODE -ne 0) { Stop-Build "Статический анализ завершился с ошибками. Исправьте их или повторите запуск с параметром -SkipAnalyze." }
} else {
    Write-Host "[2/4] Статический анализ пропущен." -ForegroundColor Yellow
}

Write-Host "[3/4] Сборка приложения для Windows..." -ForegroundColor Cyan
flutter build windows --release
if ($LASTEXITCODE -ne 0) { Stop-Build "Не удалось собрать приложение для Windows." }

if (-not (Test-Path $BuildPath)) {
    Stop-Build "Каталог с результатами сборки не найден: $BuildPath"
}

Write-Host "[4/4] Копирование файлов приложения..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
if (Test-Path $ReleasePath) {
    Remove-Item $ReleasePath -Recurse -Force
}
New-Item -ItemType Directory -Path $ReleasePath -Force | Out-Null
Copy-Item (Join-Path $BuildPath "*") $ReleasePath -Recurse -Force

$BuildInfo = @"
MEDIALOG N3 INTEGRATION DESKTOP
Version: $Version
Дата сборки: $Date
Целевая платформа: Windows x64
Конфигурация: выпуск

Этот пакет является визуальным прототипом. В нём нет промышленной интеграции с Медиалог SQL,
N3.Health, ФРМО/ФРМР, CryptoPro и реальными источниками медицинских данных.
"@
Set-Content -Path (Join-Path $ReleasePath "BUILD_INFO.txt") -Value $BuildInfo -Encoding UTF8

Write-Host ""
Write-Host "Сборка успешно завершена." -ForegroundColor Green
Write-Host "Каталог: $ReleasePath" -ForegroundColor Green
Write-Host "Исполняемый файл: $ReleasePath\medialog_n3_integration_desktop.exe"
