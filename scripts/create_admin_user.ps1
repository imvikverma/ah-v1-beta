# Create Admin User Script
# Creates a hardcoded admin user in the database

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

Write-Host 'Creating admin user in database...' -ForegroundColor Green
Write-Host ''

$scriptPath = Join-Path $projectRoot 'scripts\create_admin_user.py'
& $pythonExe $scriptPath

Write-Host ''
Read-Host 'Press Enter to exit'

