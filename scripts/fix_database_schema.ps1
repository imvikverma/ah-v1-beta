# Quick Database Schema Fix
# Adds missing columns to the users table

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Fixing Database Schema" -ForegroundColor Yellow
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

# Activate virtual environment
$venvPath = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"
if (Test-Path $venvPath) {
    . $venvPath
    Write-Host "Virtual environment activated" -ForegroundColor Green
} else {
    Write-Host "Warning: Virtual environment not found" -ForegroundColor Yellow
}

# Run migration
Write-Host "Running database migration..." -ForegroundColor Cyan
python aurum_harmony\database\migrate.py

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Database schema fixed!" -ForegroundColor Green
    Write-Host "You can now restart the backend." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "❌ Migration failed. Check the error above." -ForegroundColor Red
    exit 1
}

