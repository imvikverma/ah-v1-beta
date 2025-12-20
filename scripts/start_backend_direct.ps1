# Direct Backend Startup - Bypasses all Start-Process issues
# Use this if start-all.ps1 still has RemoteException issues

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host "Starting Backend Directly (No Start-Process)..." -ForegroundColor Green
Write-Host ""

# Deactivate any existing venv first (especially backup venvs)
if ($env:VIRTUAL_ENV) {
    if ($env:VIRTUAL_ENV -match "backup") {
        Write-Host "[WARN] Backup venv detected, deactivating..." -ForegroundColor Yellow
        deactivate
        Start-Sleep -Milliseconds 500
    } else {
        Write-Host "[INFO] Deactivating current venv..." -ForegroundColor Gray
        deactivate
        Start-Sleep -Milliseconds 500
    }
}

# Activate correct .venv (not backup)
$venvPath = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"
if (Test-Path $venvPath) {
    . $venvPath
    if ($env:VIRTUAL_ENV -eq (Join-Path $projectRoot ".venv")) {
        Write-Host "[OK] Correct virtual environment activated" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Venv activated but path doesn't match expected .venv" -ForegroundColor Yellow
        Write-Host "   Current: $env:VIRTUAL_ENV" -ForegroundColor Gray
    }
} else {
    Write-Host "[ERROR] Virtual environment not found at: $venvPath" -ForegroundColor Red
    exit 1
}

# Start Flask app directly
$appPath = Join-Path $projectRoot "aurum_harmony\master_codebase\Master_AurumHarmony_261125.py"
if (Test-Path $appPath) {
    Write-Host "[OK] Starting Flask backend..." -ForegroundColor Green
    Write-Host "   Main app: http://localhost:5000" -ForegroundColor Yellow
    Write-Host "   Admin panel: http://localhost:5001" -ForegroundColor Yellow
    Write-Host "   Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    
    python $appPath
} else {
    Write-Host "[ERROR] Flask app not found at: $appPath" -ForegroundColor Red
    exit 1
}

