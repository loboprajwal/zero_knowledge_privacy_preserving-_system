# ==============================================================================
# Build Script for Mopro Native Mobile Bindings (PowerShell)
# ==============================================================================

$ErrorActionPreference = "Continue"

Write-Host "=== [1/4] Checking Mopro CLI and Cargo Targets ===" -ForegroundColor Cyan
if (Get-Command mopro -ErrorAction SilentlyContinue) {
    Write-Host "Found mopro CLI. Building via mopro build..."
    mopro build --config mopro.toml
} else {
    Write-Host "mopro CLI not found in PATH. Building standard cargo dynamic library..."
    cargo build --release
}

Write-Host "=== [2/4] Packaging Android Libraries ===" -ForegroundColor Cyan
$AndroidJni = Join-Path $PSScriptRoot "..\..\mobile\android\app\src\main\jniLibs"
New-Item -ItemType Directory -Force -Path (Join-Path $AndroidJni "arm64-v8a") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $AndroidJni "armeabi-v7a") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $AndroidJni "x86_64") | Out-Null

$BuiltSo = Join-Path $PSScriptRoot "..\target\release\libmopro_bindings.so"
if (Test-Path $BuiltSo) {
    Copy-Item $BuiltSo -Destination (Join-Path $AndroidJni "arm64-v8a\") -Force
    Write-Host "Copied libmopro_bindings.so to Android jniLibs" -ForegroundColor Green
}

Write-Host "=== [3/4] Packaging iOS Framework ===" -ForegroundColor Cyan
$IosFramework = Join-Path $PSScriptRoot "..\..\mobile\ios\Frameworks"
New-Item -ItemType Directory -Force -Path $IosFramework | Out-Null

Write-Host "=== [4/4] Mopro Mobile Build Finished ===" -ForegroundColor Green
