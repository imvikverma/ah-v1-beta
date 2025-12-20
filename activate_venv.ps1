# Quick Venv Activation Script
# Run this in any new terminal to activate the .venv

$ErrorActionPreference = "Continue"

# Get project root (where this script is located)
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

Write-Host "`n🔧 Activating Virtual Environment..." -ForegroundColor Cyan
Write-Host ""

# Check if venv exists
$venvPath = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"
if (-not (Test-Path $venvPath)) {
    Write-Host "❌ Virtual environment not found!" -ForegroundColor Red
    Write-Host "   Expected: $venvPath" -ForegroundColor Yellow
    Write-Host "`n💡 Run .\rebuild_flask_env.ps1 to create it" -ForegroundColor Yellow
    exit 1
}

# Deactivate any existing venv (especially backups)
if ($env:VIRTUAL_ENV) {
    $currentVenv = $env:VIRTUAL_ENV
    Write-Host "Deactivating current venv: $currentVenv" -ForegroundColor Gray
    
    if ($currentVenv -match "backup") {
        Write-Host "⚠️  Backup venv detected!" -ForegroundColor Yellow
    }
    
    try {
        deactivate
        Start-Sleep -Milliseconds 300
    } catch {
        # deactivate might not exist, that's okay
    }
}

# Activate the correct venv
Write-Host "Activating: $venvPath" -ForegroundColor Green
try {
    & $venvPath
    
    # Verify activation
    Start-Sleep -Milliseconds 300
    if ($env:VIRTUAL_ENV) {
        Write-Host "`n✅ Virtual environment activated!" -ForegroundColor Green
        Write-Host "   Path: $env:VIRTUAL_ENV" -ForegroundColor Gray
        
        $pyVersion = python --version 2>&1
        Write-Host "   Python: $pyVersion" -ForegroundColor Gray
        Write-Host "`n💡 You can now run Python commands in this terminal" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host "`n⚠️  Activation may have failed (VIRTUAL_ENV not set)" -ForegroundColor Yellow
        Write-Host "   Try running: . .venv\Scripts\Activate.ps1" -ForegroundColor Gray
    }
} catch {
    Write-Host "`n❌ Activation failed: $_" -ForegroundColor Red
    Write-Host "`n💡 Try manually:" -ForegroundColor Yellow
    Write-Host "   . .venv\Scripts\Activate.ps1" -ForegroundColor Gray
    exit 1
}

