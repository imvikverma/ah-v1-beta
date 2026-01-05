# Continuous Test Runner
# Runs multiple test iterations throughout the day to get aggregate averages

param(
    [int]$NumRuns = 5,
    [int]$DurationMinutes = 30,
    [int]$WaitBetweenRuns = 10
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Resolve-Path $projectRoot

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Multiple Test Runner - Aggregate Averages" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  - Number of Runs: $NumRuns" -ForegroundColor Gray
Write-Host "  - Duration per Run: $DurationMinutes minutes" -ForegroundColor Gray
Write-Host "  - Wait Between Runs: $WaitBetweenRuns minutes" -ForegroundColor Gray
Write-Host "  - Total Estimated Time: $($NumRuns * $DurationMinutes + ($NumRuns - 1) * $WaitBetweenRuns) minutes" -ForegroundColor Gray
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

# Run the multiple test runner
Write-Host "[INFO] Starting multiple test runs..." -ForegroundColor Yellow
Write-Host ""

$testScript = Join-Path $projectRoot "scripts\run_multiple_tests.py"

try {
    & $python $testScript --runs $NumRuns --duration $DurationMinutes --wait $WaitBetweenRuns
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[OK] All test runs completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Check aggregate results in:" -ForegroundColor Cyan
        Write-Host "  - Logs: _local\logs\multi_test_aggregate_results_*.json" -ForegroundColor Gray
        Write-Host "  - Reports: _local\reports\aggregate_report_*.json" -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "[ERROR] Some test runs failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} catch {
    Write-Host ""
    Write-Host "[ERROR] Test execution failed: $_" -ForegroundColor Red
    exit 1
}
