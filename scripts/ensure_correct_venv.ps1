# Ensure Correct Virtual Environment
# This script ensures the correct .venv is activated (not a backup)

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host "`n=== Ensuring Correct Virtual Environment ===" -ForegroundColor Cyan

# Step 1: Deactivate any active venv (especially backups)
if ($env:VIRTUAL_ENV) {
    $currentVenv = $env:VIRTUAL_ENV
    Write-Host "Current venv: $currentVenv" -ForegroundColor Gray
    
    if ($currentVenv -match "backup") {
        Write-Host "❌ Backup venv detected! Deactivating..." -ForegroundColor Red
        deactivate
        Start-Sleep -Milliseconds 500
    } else {
        Write-Host "Deactivating current venv..." -ForegroundColor Yellow
        deactivate
        Start-Sleep -Milliseconds 500
    }
} else {
    Write-Host "No venv currently active" -ForegroundColor Gray
}

# Step 2: Activate correct .venv
$correctVenv = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"

if (Test-Path $correctVenv) {
    Write-Host "Activating correct .venv..." -ForegroundColor Green
    & $correctVenv
    
    Start-Sleep -Milliseconds 500
    
    # Step 3: Verify
    if ($env:VIRTUAL_ENV) {
        $expectedPath = (Resolve-Path (Join-Path $projectRoot ".venv")).Path
        $actualPath = (Resolve-Path $env:VIRTUAL_ENV).Path
        
        if ($actualPath -eq $expectedPath) {
            Write-Host "✅ Correct venv activated!" -ForegroundColor Green
            Write-Host "   Path: $env:VIRTUAL_ENV" -ForegroundColor Gray
            
            # Show Python version
            $pyVersion = python --version 2>&1
            Write-Host "   Python: $pyVersion" -ForegroundColor Gray
            
            return $true
        } else {
            Write-Host "❌ Wrong venv activated!" -ForegroundColor Red
            Write-Host "   Expected: $expectedPath" -ForegroundColor Yellow
            Write-Host "   Actual: $actualPath" -ForegroundColor Yellow
            return $false
        }
    } else {
        Write-Host "❌ Failed to activate venv" -ForegroundColor Red
        return $false
    }
} else {
    Write-Host "❌ Correct venv not found at: $correctVenv" -ForegroundColor Red
    Write-Host "   Run .\rebuild_flask_env.ps1 to create it" -ForegroundColor Yellow
    return $false
}

