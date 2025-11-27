# AurumHarmony Backend Startup Script
# Double-click this file or run: .\start_backend.ps1

cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
Write-Host "Activating virtual environment..." -ForegroundColor Cyan
.\.venv\Scripts\Activate.ps1

Write-Host "Starting AurumHarmony Backend..." -ForegroundColor Green
Write-Host "Main app: http://localhost:5000" -ForegroundColor Yellow
Write-Host "Admin panel: http://localhost:5001" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

python .\aurum_harmony\master_codebase\Master_AurumHarmony_261125.py

