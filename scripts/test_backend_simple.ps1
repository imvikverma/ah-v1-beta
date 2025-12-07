# Simple Backend Test - No Timeouts
Write-Host "=== Simple Backend Test ===" -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host "1. Activating virtual environment..." -ForegroundColor Yellow
. .venv\Scripts\Activate.ps1

Write-Host "2. Testing Python import..." -ForegroundColor Yellow
python -c "import sys; print(f'Python: {sys.version}')"

Write-Host "3. Testing Flask app import..." -ForegroundColor Yellow
python -c "import sys; sys.path.insert(0, '.'); from aurum_harmony.master_codebase.Master_AurumHarmony_261125 import app; print('✅ Flask app imported successfully')" 2>&1

Write-Host ""
Write-Host "4. If no errors above, backend should start..." -ForegroundColor Green
Write-Host "   Run: python aurum_harmony\master_codebase\Master_AurumHarmony_261125.py" -ForegroundColor Gray
Write-Host ""

