# AurumHarmony Backend Startup Script
# Double-click this file or run: .\start_backend.ps1

cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"

# Use the virtual environment's Python directly
$pythonExe = ".\\.venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    Write-Host "❌ ERROR: Virtual environment not found at .\.venv\" -ForegroundColor Red
    Write-Host "   Please create a virtual environment first:" -ForegroundColor Yellow
    Write-Host "   python -m venv .venv" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Using Python: $pythonExe" -ForegroundColor Cyan
Write-Host "Starting AurumHarmony Backend..." -ForegroundColor Green
Write-Host "Main app: http://localhost:5000" -ForegroundColor Yellow
Write-Host "Admin panel: http://localhost:5001" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

& $pythonExe .\aurum_harmony\master_codebase\Master_AurumHarmony_261125.py

