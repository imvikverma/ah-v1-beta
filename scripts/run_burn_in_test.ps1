# Comprehensive Trading Lifecycle Burn-In Test Runner
# Tests: Trading, Compliance, Reporting, Funds Management, Settlement

param(
    [string]$UserId = "test_user_001",
    [string]$UserCategory = "admin"
)

$ErrorActionPreference = "Stop"

# Get project root
$projectRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Resolve-Path $projectRoot

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "AurumHarmony Trading Lifecycle Burn-In Test" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check virtual environment
$venvPath = Join-Path $projectRoot ".venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "[ERROR] Virtual environment not found at: $venvPath" -ForegroundColor Red
    Write-Host "Please run: python -m venv .venv" -ForegroundColor Yellow
    exit 1
}

# Activate virtual environment
Write-Host "[INFO] Activating virtual environment..." -ForegroundColor Yellow
& "$venvPath\Scripts\Activate.ps1"

# Check Python
$python = Join-Path $venvPath "Scripts\python.exe"
if (-not (Test-Path $python)) {
    Write-Host "[ERROR] Python not found in virtual environment" -ForegroundColor Red
    exit 1
}

# Run the test
Write-Host "[INFO] Starting comprehensive burn-in test..." -ForegroundColor Yellow
Write-Host "  - User ID: $UserId" -ForegroundColor Gray
Write-Host "  - User Category: $UserCategory" -ForegroundColor Gray
Write-Host ""

$testScript = Join-Path $projectRoot "scripts\test_full_trading_lifecycle.py"

try {
    & $python $testScript
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] Burn-in test completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Check logs in: _local\logs\" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "[ERROR] Burn-in test failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} catch {
    Write-Host ""
    Write-Host "[ERROR] Test execution failed: $_" -ForegroundColor Red
    exit 1
}
