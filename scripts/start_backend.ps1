# AurumHarmony Backend Startup Script
# Double-click this file or run: .\start_backend.ps1

# Get project root (parent of scripts directory)
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

# Use the virtual environment's Python directly
$pythonExe = Join-Path $projectRoot '.venv\Scripts\python.exe'
if (-not (Test-Path $pythonExe)) {
    Write-Host 'ERROR: Virtual environment not found at' "$projectRoot\.venv\" -ForegroundColor Red
    Write-Host '   Please create a virtual environment first:' -ForegroundColor Yellow
    Write-Host '   python -m venv .venv' -ForegroundColor White
    Write-Host ''
    Read-Host 'Press Enter to exit'
    exit 1
}

Write-Host 'Using Python:' $pythonExe -ForegroundColor Cyan

# Verify critical packages are available
Write-Host 'Verifying packages...' -ForegroundColor Cyan
$testResult = & $pythonExe -c "import flask_sqlalchemy, jwt, bcrypt; print('OK')" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host 'ERROR: Required packages not found in virtual environment!' -ForegroundColor Red
    Write-Host '   Error:' $testResult -ForegroundColor Yellow
    Write-Host '   Please run: .\.venv\Scripts\python.exe -m pip install -r requirements.txt' -ForegroundColor Yellow
    Write-Host ''
    Read-Host 'Press Enter to exit'
    exit 1
}
Write-Host 'All packages verified' -ForegroundColor Green
Write-Host ''

Write-Host 'Starting AurumHarmony Backend...' -ForegroundColor Green
Write-Host 'Main app: http://localhost:5000' -ForegroundColor Yellow
Write-Host 'Admin panel: http://localhost:5001' -ForegroundColor Yellow
Write-Host 'Press Ctrl+C to stop' -ForegroundColor Gray
Write-Host ''

$scriptPath = Join-Path $projectRoot 'aurum_harmony\master_codebase\Master_AurumHarmony_261125.py'
& $pythonExe $scriptPath
