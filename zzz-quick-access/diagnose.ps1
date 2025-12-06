# Diagnostic script to check common issues

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   AurumHarmony Diagnostic Tool        " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()

# Check ngrok
Write-Host "Checking ngrok..." -ForegroundColor Yellow
$ngrok = Get-Command ngrok -ErrorAction SilentlyContinue
if ($ngrok) {
    Write-Host "  ✅ ngrok is installed" -ForegroundColor Green
    Write-Host "     Path: $($ngrok.Path)" -ForegroundColor Gray
} else {
    Write-Host "  ❌ ngrok is NOT installed or not in PATH" -ForegroundColor Red
    $issues += "ngrok not found"
}

# Check Flutter
Write-Host ""
Write-Host "Checking Flutter..." -ForegroundColor Yellow
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutter) {
    Write-Host "  ✅ Flutter is installed" -ForegroundColor Green
    Write-Host "     Path: $($flutter.Path)" -ForegroundColor Gray
    
    # Check Flutter doctor
    Write-Host "  Running flutter doctor..." -ForegroundColor Gray
    flutter doctor 2>&1 | Select-Object -First 10
} else {
    Write-Host "  ❌ Flutter is NOT installed or not in PATH" -ForegroundColor Red
    $issues += "Flutter not found"
}

# Check Python
Write-Host ""
Write-Host "Checking Python..." -ForegroundColor Yellow
$python = Get-Command python -ErrorAction SilentlyContinue
if ($python) {
    Write-Host "  ✅ Python is installed" -ForegroundColor Green
    Write-Host "     Version: $(python --version)" -ForegroundColor Gray
} else {
    Write-Host "  ❌ Python is NOT installed or not in PATH" -ForegroundColor Red
    $issues += "Python not found"
}

# Check virtual environment
Write-Host ""
Write-Host "Checking virtual environment..." -ForegroundColor Yellow
if (Test-Path ".venv\Scripts\Activate.ps1") {
    Write-Host "  ✅ Virtual environment found" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Virtual environment not found (.venv)" -ForegroundColor Yellow
    $issues += "Virtual environment missing"
}

# Check backend port
Write-Host ""
Write-Host "Checking port 5000..." -ForegroundColor Yellow
$port5000 = Test-NetConnection -ComputerName localhost -Port 5000 -InformationLevel Quiet -WarningAction SilentlyContinue
if ($port5000) {
    Write-Host "  ✅ Port 5000 is in use (backend may be running)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Port 5000 is free (backend not running)" -ForegroundColor Yellow
}

# Check Flutter app directory
Write-Host ""
Write-Host "Checking Flutter app directory..." -ForegroundColor Yellow
$flutterApp = "aurum_harmony\frontend\flutter_app"
if (Test-Path "$flutterApp\pubspec.yaml") {
    Write-Host "  ✅ Flutter app directory found" -ForegroundColor Green
} else {
    Write-Host "  ❌ Flutter app directory not found: $flutterApp" -ForegroundColor Red
    $issues += "Flutter app directory missing"
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($issues.Count -eq 0) {
    Write-Host "  ✅ All checks passed!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Found $($issues.Count) issue(s):" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "     - $issue" -ForegroundColor Red
    }
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to exit"
