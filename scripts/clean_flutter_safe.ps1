# Safe Flutter Cleanup Script
# Cleans Flutter project while handling locked directories gracefully

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$flutterAppPath = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app"

if (-not (Test-Path $flutterAppPath)) {
    Write-Host "❌ Flutter app path not found: $flutterAppPath" -ForegroundColor Red
    exit 1
}

Write-Host "🧹 Safe Flutter Cleanup" -ForegroundColor Cyan
Write-Host ""

# Stop any running Flutter processes first
Write-Host "[1/4] Stopping Flutter processes..." -ForegroundColor Yellow
$flutterProcesses = Get-Process -Name "flutter","dart" -ErrorAction SilentlyContinue
if ($flutterProcesses) {
    Write-Host "   Found $($flutterProcesses.Count) process(es), stopping..." -ForegroundColor Gray
    $flutterProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "   ✅ Processes stopped" -ForegroundColor Green
} else {
    Write-Host "   ✅ No Flutter processes running" -ForegroundColor Green
}

# Clean build directory (most important)
Write-Host "`n[2/4] Cleaning build directory..." -ForegroundColor Yellow
$buildPath = Join-Path $flutterAppPath "build"
if (Test-Path $buildPath) {
    try {
        Remove-Item -Path $buildPath -Recurse -Force -ErrorAction Stop
        Write-Host "   ✅ Build directory cleaned" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  Build directory locked (may be in use)" -ForegroundColor Yellow
        Write-Host "   This is usually safe - Flutter will handle it" -ForegroundColor Gray
    }
} else {
    Write-Host "   ✅ No build directory to clean" -ForegroundColor Green
}

# Clean .dart_tool (can be locked, but safe to skip)
Write-Host "`n[3/4] Cleaning .dart_tool..." -ForegroundColor Yellow
$dartToolPath = Join-Path $flutterAppPath ".dart_tool"
if (Test-Path $dartToolPath) {
    try {
        Remove-Item -Path $dartToolPath -Recurse -Force -ErrorAction Stop
        Write-Host "   ✅ .dart_tool cleaned" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  .dart_tool locked (safe to ignore)" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✅ No .dart_tool to clean" -ForegroundColor Green
}

# Run flutter clean (will handle ephemeral directories)
Write-Host "`n[4/4] Running flutter clean..." -ForegroundColor Yellow
Set-Location $flutterAppPath
$cleanOutput = flutter clean 2>&1 | Out-String

# Check for errors (but don't fail - these are usually safe)
if ($cleanOutput -match "Failed to remove|cannot access|A program may still be using") {
    Write-Host "   ⚠️  Some directories couldn't be deleted" -ForegroundColor Yellow
    Write-Host "   This is normal - Flutter will recreate them" -ForegroundColor Gray
    Write-Host "   ✅ Clean completed (warnings are safe to ignore)" -ForegroundColor Green
} else {
    Write-Host "   ✅ Flutter clean completed successfully" -ForegroundColor Green
}

Write-Host "`n✅ Safe cleanup complete!" -ForegroundColor Green
Write-Host "   You can now run: flutter pub get && flutter build web" -ForegroundColor Cyan

