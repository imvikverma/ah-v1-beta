# Continuous Test Runner - For ML Training Data Collection
# Runs test batches continuously to build comprehensive training dataset

param(
    [int]$Batches = 5,
    [int]$RunsPerBatch = 3,
    [int]$DurationMinutes = 20,
    [int]$WaitBetweenRuns = 5,
    [int]$WaitBetweenBatches = 10
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Resolve-Path $projectRoot

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "CONTINUOUS TEST RUNNER - ML DATA COLLECTION" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  - Batches: $Batches" -ForegroundColor Gray
Write-Host "  - Runs per Batch: $RunsPerBatch" -ForegroundColor Gray
Write-Host "  - Duration per Run: $DurationMinutes minutes" -ForegroundColor Gray
Write-Host "  - Wait Between Runs: $WaitBetweenRuns minutes" -ForegroundColor Gray
Write-Host "  - Wait Between Batches: $WaitBetweenBatches minutes" -ForegroundColor Gray
Write-Host ""
Write-Host "Total Estimated Time:" -ForegroundColor Yellow
$batchTime = ($RunsPerBatch * $DurationMinutes) + (($RunsPerBatch - 1) * $WaitBetweenRuns)
$totalTime = ($Batches * $batchTime) + (($Batches - 1) * $WaitBetweenBatches)
Write-Host "  - Per Batch: $batchTime minutes" -ForegroundColor Gray
Write-Host "  - Total: $totalTime minutes ($([math]::Round($totalTime/60, 1)) hours)" -ForegroundColor Gray
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

$testScript = Join-Path $projectRoot "scripts\run_multiple_tests.py"
$collectorScript = Join-Path $projectRoot "scripts\collect_ml_training_data.py"

$startTime = Get-Date
$totalRuns = 0

Write-Host "[INFO] Starting continuous test batches..." -ForegroundColor Yellow
Write-Host ""

for ($batch = 1; $batch -le $Batches; $batch++) {
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "BATCH #$batch of $Batches" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Run batch
        & $python $testScript --runs $RunsPerBatch --duration $DurationMinutes --wait $WaitBetweenRuns
        
        if ($LASTEXITCODE -eq 0) {
            $totalRuns += $RunsPerBatch
            Write-Host ""
            Write-Host "[OK] Batch #$batch completed successfully!" -ForegroundColor Green
            Write-Host "  Total runs so far: $totalRuns" -ForegroundColor Gray
            
            # Collect ML training data after each batch
            Write-Host ""
            Write-Host "[INFO] Collecting ML training data..." -ForegroundColor Yellow
            & $python $collectorScript
            
            Write-Host ""
            Write-Host "[OK] ML training data collected for batch #$batch" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "[WARNING] Batch #$batch had some failures (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host ""
        Write-Host "[ERROR] Batch #$batch failed: $_" -ForegroundColor Red
    }
    
    # Wait before next batch (except for last batch)
    if ($batch -lt $Batches) {
        Write-Host ""
        Write-Host "Waiting $WaitBetweenBatches minutes before next batch..." -ForegroundColor Gray
        $nextBatchTime = (Get-Date).AddMinutes($WaitBetweenBatches)
        Write-Host "Next batch will start at: $($nextBatchTime.ToString('HH:mm:ss'))" -ForegroundColor Gray
        Start-Sleep -Seconds ($WaitBetweenBatches * 60)
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "ALL BATCHES COMPLETED" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  - Total Batches: $Batches" -ForegroundColor Gray
Write-Host "  - Total Runs: $totalRuns" -ForegroundColor Gray
Write-Host "  - Total Duration: $($duration.TotalMinutes) minutes ($([math]::Round($duration.TotalHours, 1)) hours)" -ForegroundColor Gray
Write-Host ""
Write-Host "ML Training Data:" -ForegroundColor Yellow
Write-Host "  - Location: _local\ml_training_data\" -ForegroundColor Gray
Write-Host "  - View datasets: python scripts\collect_ml_training_data.py" -ForegroundColor Gray
Write-Host ""
Write-Host "Aggregate Results:" -ForegroundColor Yellow
Write-Host "  - View: python scripts\view_aggregate_results.py" -ForegroundColor Gray
Write-Host "  - Reports: _local\reports\aggregate_report_*.json" -ForegroundColor Gray
Write-Host ""
