# Fix Virtual Environment Activation
# Use this script to ensure you're using the correct .venv

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host "`n=== Fixing Virtual Environment Activation ===" -ForegroundColor Cyan
Write-Host ""

# Check current activation
if ($env:VIRTUAL_ENV) {
    Write-Host "Current venv: $env:VIRTUAL_ENV" -ForegroundColor Yellow
    
    if ($env:VIRTUAL_ENV -match "backup") {
        Write-Host "[WARN] Backup venv is activated!" -ForegroundColor Red
        Write-Host "Deactivating..." -ForegroundColor Yellow
        deactivate
        Start-Sleep -Milliseconds 500
    } else {
        Write-Host "[INFO] Deactivating current venv..." -ForegroundColor Gray
        deactivate
        Start-Sleep -Milliseconds 500
    }
} else {
    Write-Host "[INFO] No venv currently activated" -ForegroundColor Gray
}

# Activate correct .venv
$correctVenv = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"

if (Test-Path $correctVenv) {
    Write-Host "Activating correct .venv..." -ForegroundColor Green
    & $correctVenv
    
    Start-Sleep -Milliseconds 500
    
    # Verify
    if ($env:VIRTUAL_ENV -eq (Join-Path $projectRoot ".venv")) {
        Write-Host "[OK] Correct venv activated!" -ForegroundColor Green
        Write-Host "   Path: $env:VIRTUAL_ENV" -ForegroundColor Gray
        
        # Verify Python version
        $pyVersion = python --version 2>&1
        Write-Host "   Python: $pyVersion" -ForegroundColor Gray
        
        # Verify Flask
        $flaskVersion = pip show Flask 2>&1 | Select-String "Version:"
        if ($flaskVersion) {
            Write-Host "   $flaskVersion" -ForegroundColor Gray
        }
    } else {
        Write-Host "[ERROR] Failed to activate correct venv" -ForegroundColor Red
        Write-Host "   Current: $env:VIRTUAL_ENV" -ForegroundColor Yellow
    }
} else {
    Write-Host "[ERROR] Correct venv not found at: $correctVenv" -ForegroundColor Red
    Write-Host "   Run .\rebuild_flask_env.ps1 to create it" -ForegroundColor Yellow
}

Write-Host ""

