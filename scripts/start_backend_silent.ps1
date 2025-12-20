# AurumHarmony Backend Startup Script (Silent Mode)
# Runs in minimized window, only shows critical errors

# Set window title for easy identification
$host.ui.RawUI.WindowTitle = "AurumHarmony - Backend (Flask)"

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

# Log file
$logDir = Join-Path $projectRoot "_local\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile = Join-Path $logDir "backend.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage
    if ($Level -eq "ERROR" -or $Level -eq "CRITICAL") {
        Write-Host $logMessage -ForegroundColor Red
    }
}

function Show-CriticalError {
    param([string]$Message)
    Write-Log $Message "CRITICAL"
    # Show popup only for critical errors
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "AurumHarmony Backend - Critical Error`n`n$Message`n`nCheck logs: $logFile",
            "Critical Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    } catch {
        # Fallback if MessageBox fails
        Write-Host "CRITICAL ERROR: $Message" -ForegroundColor Red
    }
}

try {
    Write-Log "Starting AurumHarmony Backend (Silent Mode)" "INFO"
    
    # CRITICAL: Ensure we're not using a backup venv
    if ($env:VIRTUAL_ENV -and $env:VIRTUAL_ENV -match "backup") {
        Write-Log "Backup venv detected! Deactivating..." "WARN"
        deactivate
        Start-Sleep -Milliseconds 500
    }
    
    # Activate virtual environment
    $venvPath = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"
    if (-not (Test-Path $venvPath)) {
        Show-CriticalError "Virtual environment not found at: $venvPath"
        exit 1
    }
    
    . $venvPath
    Write-Log "Virtual environment activated" "INFO"
    
    # Check Python
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Show-CriticalError "Python not found or not accessible"
        exit 1
    }
    Write-Log "Python version: $pythonVersion" "INFO"
    
    # Start Flask app
    $appPath = Join-Path $projectRoot "aurum_harmony\master_codebase\Master_AurumHarmony_261125.py"
    if (-not (Test-Path $appPath)) {
        Show-CriticalError "Flask app not found at: $appPath"
        exit 1
    }
    
    Write-Log "Starting Flask app: $appPath" "INFO"
    Write-Log "Backend will be available at: http://localhost:5000" "INFO"
    
    # Show window title and initial message
    Write-Host "`n═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  AurumHarmony Backend Starting..." -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Backend: http://localhost:5000" -ForegroundColor Green
    Write-Host "  Admin: http://localhost:5001" -ForegroundColor Green
    Write-Host "  Logs: $logFile" -ForegroundColor Gray
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Run Flask (output to log, errors to console)
    python $appPath 2>&1 | ForEach-Object {
        $line = $_
        Write-Log $line "INFO"
        # Show all output in window (not just errors) so user can see what's happening
        Write-Host $line
        # Highlight critical errors
        if ($line -match "CRITICAL|FATAL|Traceback|Exception|Error") {
            Write-Host $line -ForegroundColor Red
        }
    }
    
} catch {
    Show-CriticalError "Unexpected error: $_"
    exit 1
}

