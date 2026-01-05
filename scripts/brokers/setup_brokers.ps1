# Comprehensive Broker Setup Script
# Guides through setup of both HDFC Sky and Kotak Neo

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  AurumHarmony Broker Integration Setup" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Get project root
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
Set-Location $projectRoot

$envFile = Join-Path $projectRoot ".env"

# Check if .env exists
if (-not (Test-Path $envFile)) {
    Write-Host "⚠️  .env file not found. Creating it..." -ForegroundColor Yellow
    New-Item -Path $envFile -ItemType File -Force | Out-Null
    Write-Host "✅ Created .env file`n" -ForegroundColor Green
}

Write-Host "This script will help you set up broker integrations for live data testing.`n" -ForegroundColor White
Write-Host "Available Brokers:" -ForegroundColor Cyan
Write-Host "  1. HDFC Sky - For live trading and paper trading with live data" -ForegroundColor White
Write-Host "  2. Kotak Neo - For paper trading with live market data" -ForegroundColor White
Write-Host ""

$setupHDFC = $false
$setupKotak = $false

# Ask which brokers to setup
Write-Host "Which brokers would you like to set up?" -ForegroundColor Yellow
Write-Host "  1. HDFC Sky only" -ForegroundColor White
Write-Host "  2. Kotak Neo only" -ForegroundColor White
Write-Host "  3. Both brokers" -ForegroundColor White
Write-Host "  4. Skip (exit)" -ForegroundColor Gray
Write-Host ""
$choice = Read-Host "Enter choice (1-4)"

switch ($choice) {
    "1" { $setupHDFC = $true }
    "2" { $setupKotak = $true }
    "3" { $setupHDFC = $true; $setupKotak = $true }
    "4" { 
        Write-Host "`nSetup cancelled. Exiting..." -ForegroundColor Yellow
        exit 0
    }
    default {
        Write-Host "`nInvalid choice. Exiting..." -ForegroundColor Red
        exit 1
    }
}

# Setup HDFC Sky
if ($setupHDFC) {
    Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
    Write-Host "Setting up HDFC Sky" -ForegroundColor Yellow
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Running HDFC Sky setup script..." -ForegroundColor White
    & "$projectRoot\scripts\brokers\setup_hdfc_sky.ps1"
    
    Write-Host "`n✅ HDFC Sky setup complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps for HDFC Sky:" -ForegroundColor Yellow
    Write-Host "  1. Get token_id from URL after logging into HDFC Sky web portal" -ForegroundColor White
    Write-Host "  2. Or complete OAuth flow to get access_token" -ForegroundColor White
    Write-Host "  3. Test connection: python scripts\brokers\test_hdfc_connection.py" -ForegroundColor White
    Write-Host ""
}

# Setup Kotak Neo
if ($setupKotak) {
    Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
    Write-Host "Setting up Kotak Neo" -ForegroundColor Yellow
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Running Kotak Neo setup script..." -ForegroundColor White
    & "$projectRoot\scripts\brokers\setup_kotak_credentials.ps1"
    
    Write-Host "`n✅ Kotak Neo setup complete" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps for Kotak Neo:" -ForegroundColor Yellow
    Write-Host "  1. Set up TOTP in Kotak Neo app (if not done)" -ForegroundColor White
    Write-Host "  2. Test connection: python scripts\brokers\test_kotak_connection.py" -ForegroundColor White
    Write-Host "  3. Login with TOTP and MPIN when prompted" -ForegroundColor White
    Write-Host ""
}

# Summary
Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "Setup Summary" -ForegroundColor Yellow
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host ""

if ($setupHDFC) {
    Write-Host "✅ HDFC Sky credentials added to .env" -ForegroundColor Green
}
if ($setupKotak) {
    Write-Host "✅ Kotak Neo credentials added to .env" -ForegroundColor Green
}

Write-Host ""
Write-Host "Testing Connections:" -ForegroundColor Yellow
Write-Host "  Run: .\scripts\test_broker_connections.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Individual Tests:" -ForegroundColor Yellow
if ($setupHDFC) {
    Write-Host "  HDFC Sky: python scripts\brokers\test_hdfc_connection.py" -ForegroundColor White
}
if ($setupKotak) {
    Write-Host "  Kotak Neo: python scripts\brokers\test_kotak_connection.py" -ForegroundColor White
}
Write-Host ""
Write-Host "Once connections are verified, you can:" -ForegroundColor Yellow
Write-Host "  1. Start backend: .\start-all.ps1 (Option 1)" -ForegroundColor White
Write-Host "  2. Test paper trading with live data" -ForegroundColor White
Write-Host "  3. Test live trading (after paper trading verified)" -ForegroundColor White
Write-Host ""
