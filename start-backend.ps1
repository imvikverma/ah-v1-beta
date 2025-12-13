# Quick launcher for Flask Backend
# Shortcut to scripts/start_backend_silent.ps1

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# Activate venv first (if not already active)
if (-not $env:VIRTUAL_ENV) {
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    $venvPath = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"
    if (Test-Path $venvPath) {
        & $venvPath
    } else {
        Write-Host "⚠️  Venv not found at: $venvPath" -ForegroundColor Yellow
    }
}

# Start backend using the silent script (used by start-all.ps1)
$backendScript = Join-Path $projectRoot "scripts\start_backend_silent.ps1"
if (Test-Path $backendScript) {
    & $backendScript
} else {
    Write-Host "❌ Backend script not found at: $backendScript" -ForegroundColor Red
    Write-Host "💡 Alternative: Use start-all.ps1 Option 1 or 4" -ForegroundColor Yellow
    exit 1
}
