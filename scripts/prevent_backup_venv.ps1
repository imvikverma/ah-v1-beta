# Prevent Backup Venv Activation
# This script should be run at PowerShell startup or before any venv activation
# It automatically deactivates any backup venv and ensures correct .venv is used

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

# Check if a backup venv is active
if ($env:VIRTUAL_ENV) {
    if ($env:VIRTUAL_ENV -match "backup") {
        Write-Host "⚠️  Backup venv detected! Deactivating..." -ForegroundColor Yellow
        deactivate
        Start-Sleep -Milliseconds 300
        
        # Clear the prompt modification
        if (Get-Command prompt -ErrorAction SilentlyContinue) {
            function global:prompt {
                $originalPrompt = "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
                return $originalPrompt
            }
        }
    }
}

# If no venv is active and we're in the project directory, optionally activate correct .venv
# (Comment out the next section if you don't want auto-activation)
<#
$correctVenv = Join-Path $projectRoot ".venv\Scripts\Activate.ps1"
if (-not $env:VIRTUAL_ENV -and (Test-Path $correctVenv)) {
    & $correctVenv
}
#>

