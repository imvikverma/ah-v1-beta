# Maximum Trades Test Runner
# Aggressively runs tests to maximize trades and capture all data points

param(
    [int]$DurationMinutes = 60,
    [int]$CycleIntervalSeconds = 60,
    [int]$MaxPositions = 10,
    [int]$Instances = 3
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Resolve-Path $projectRoot

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "MAXIMUM TRADES TEST RUNNER" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  - Duration: $DurationMinutes minutes" -ForegroundColor Gray
Write-Host "  - Cycle Interval: $CycleIntervalSeconds seconds" -ForegroundColor Gray
Write-Host "  - Max Positions: $MaxPositions" -ForegroundColor Gray
Write-Host "  - Parallel Instances: $Instances" -ForegroundColor Gray
Write-Host ""
Write-Host "Expected Output:" -ForegroundColor Yellow
$cyclesPerInstance = ($DurationMinutes * 60) / $CycleIntervalSeconds
$expectedTrades = $cyclesPerInstance * $Instances * 2  # Estimate 2 trades per cycle
Write-Host "  - Cycles per Instance: ~$([math]::Round($cyclesPerInstance, 0))" -ForegroundColor Gray
Write-Host "  - Estimated Total Trades: ~$expectedTrades" -ForegroundColor Gray
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

$testScript = Join-Path $projectRoot "scripts\max_trades_test_runner.py"
$collectorScript = Join-Path $projectRoot "scripts\collect_ml_training_data.py"

Write-Host "[INFO] Starting $Instances parallel test instances..." -ForegroundColor Yellow
Write-Host ""

$processes = @()

# Start multiple parallel instances
for ($i = 1; $i -le $Instances; $i++) {
    Write-Host "[INFO] Starting instance #$i..." -ForegroundColor Cyan
    
    $process = Start-Process -FilePath $python -ArgumentList @(
        $testScript,
        "--duration", $DurationMinutes,
        "--cycle-interval", $CycleIntervalSeconds,
        "--max-positions", $MaxPositions
    ) -PassThru -WindowStyle Minimized
    
    $processes += $process
    Write-Host "  [OK] Instance #$i started (PID: $($process.Id))" -ForegroundColor Green
    
    # Small delay between starts
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "[OK] All $Instances instances started!" -ForegroundColor Green
Write-Host ""
Write-Host "Monitoring test progress..." -ForegroundColor Yellow
Write-Host "  - Logs: _local\logs\max_trades_test_*.log" -ForegroundColor Gray
Write-Host "  - Results: _local\logs\max_trades_test_results_*.json" -ForegroundColor Gray
Write-Host "  - Comprehensive Data: _local\comprehensive_test_data\max_trades_comprehensive_*.json" -ForegroundColor Gray
Write-Host ""

# Wait for all processes to complete
$allCompleted = $false
$checkInterval = 30  # Check every 30 seconds

while (-not $allCompleted) {
    Start-Sleep -Seconds $checkInterval
    
    $running = @()
    foreach ($proc in $processes) {
        if (-not $proc.HasExited) {
            $running += $proc.Id
        }
    }
    
    if ($running.Count -eq 0) {
        $allCompleted = $true
        Write-Host ""
        Write-Host "[OK] All test instances completed!" -ForegroundColor Green
    } else {
        $elapsed = ((Get-Date) - (Get-Process -Id $running[0] -ErrorAction SilentlyContinue).StartTime).TotalMinutes
        Write-Host "[INFO] $($running.Count) instance(s) still running (elapsed: $([math]::Round($elapsed, 1)) min)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "COLLECTING ML TRAINING DATA" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Collect ML training data
Write-Host "[INFO] Running ML data collector..." -ForegroundColor Yellow
& $python $collectorScript

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  - Check logs: _local\logs\max_trades_test_*.log" -ForegroundColor Gray
Write-Host "  - Check comprehensive data: _local\comprehensive_test_data\" -ForegroundColor Gray
Write-Host "  - Check ML datasets: _local\ml_training_data\" -ForegroundColor Gray
Write-Host ""
