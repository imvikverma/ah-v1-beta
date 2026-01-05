# Trading Targets Validation Runner
# Tests all capital levels to validate we can achieve target trades

param(
    [int]$DurationMinutes = 10
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Resolve-Path $projectRoot

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "TRADING TARGETS VALIDATION" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Targets:" -ForegroundColor Yellow
Write-Host "  - Rs 10,000: 27 trades/day (~9/index)" -ForegroundColor Gray
Write-Host "  - Rs 50,000: 45 trades/day (~15/index)" -ForegroundColor Gray
Write-Host "  - Rs 1,00,000: 90 trades/day (~30/index)" -ForegroundColor Gray
Write-Host "  - Rs 5,00,000: 150 trades/day (~50/index)" -ForegroundColor Gray
Write-Host "  - Rs 15,00,000: 180 trades/day (~60/index)" -ForegroundColor Gray
Write-Host ""
Write-Host "Test Duration per Level: $DurationMinutes minutes" -ForegroundColor Yellow
Write-Host ""

# Check virtual environment
$venvPath = Join-Path $projectRoot ".venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "[ERROR] Virtual environment not found" -ForegroundColor Red
    exit 1
}

# Activate virtual environment
Write-Host "[INFO] Activating virtual environment..." -ForegroundColor Yellow
& "$venvPath\Scripts\Activate.ps1"

# Check Python
$python = Join-Path $venvPath "Scripts\python.exe"
if (-not (Test-Path $python)) {
    Write-Host "[ERROR] Python not found" -ForegroundColor Red
    exit 1
}

$testScript = Join-Path $projectRoot "scripts\test_trading_targets.py"

Write-Host "[INFO] Running trading targets validation..." -ForegroundColor Yellow
Write-Host ""

try {
    & $python $testScript --duration $DurationMinutes
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] Trading targets validation completed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Check results:" -ForegroundColor Cyan
        Write-Host "  - Logs: _local\logs\trading_targets_test_*.json" -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "[WARNING] Some targets may not have been achieved" -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host "[ERROR] Validation failed: $_" -ForegroundColor Red
    exit 1
}
