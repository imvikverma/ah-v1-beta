# Auto-Deploy Script for AurumHarmony
# Watches for changes and automatically deploys to GitHub & Cloudflare
# Runs in background, only shows errors

Param(
    [switch]$Force = $false,
    [int]$WatchInterval = 30  # Check for changes every 30 seconds
)

$ErrorActionPreference = "SilentlyContinue"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# Hide window (run minimized)
$windowStyle = "Hidden"
if ($Force) {
    $windowStyle = "Minimized"  # Show minimized if force mode
}

# Log file for auto-deploy
$logFile = Join-Path $projectRoot "_local\logs\auto_deploy.log"
$logDir = Split-Path -Parent $logFile
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage
    if ($Level -eq "ERROR") {
        Write-Host $logMessage -ForegroundColor Red
    }
}

function Test-GitChanges {
    # Check if there are uncommitted changes or unpushed commits
    Set-Location $projectRoot
    
    # Check for uncommitted changes (including untracked files in docs/)
    $uncommitted = git diff --quiet 2>&1
    $uncommittedExitCode = $LASTEXITCODE
    $untracked = git ls-files --others --exclude-standard | Where-Object { $_ -like "docs/*" -or $_ -like "README.md" -or $_ -like "CHANGELOG.md" }
    
    # Check for unpushed commits
    $unpushed = git log origin/main..HEAD --oneline 2>&1
    
    # Return true if there are changes to commit or unpushed commits
    $hasUncommitted = ($uncommittedExitCode -ne 0) -or ($untracked.Count -gt 0)
    $hasUnpushed = ($unpushed -and $unpushed.Count -gt 0)
    
    if ($hasUncommitted -or $hasUnpushed) {
        return $true
    }
    return $false
}

function Invoke-AutoDeploy {
    param([bool]$ForceDeploy = $false)
    
    try {
        Set-Location $projectRoot
        
        # Check if we're on main branch
        $currentBranch = git rev-parse --abbrev-ref HEAD 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Git error: $currentBranch" "ERROR"
            return $false
        }
        
        if ($currentBranch -ne "main") {
            Write-Log "Not on main branch (current: $currentBranch). Skipping auto-deploy." "WARN"
            return $false
        }
        
        # Check for changes
        if (-not $ForceDeploy) {
            $hasChanges = Test-GitChanges
            if (-not $hasChanges) {
                return $false  # No changes, skip deploy
            }
            Write-Log "Changes detected, proceeding with deploy..." "INFO"
        }
        
        Write-Log "Starting auto-deploy..." "INFO"
        
        # Run deploy script
        $deployScript = Join-Path $projectRoot "scripts\deploy_cloudflare.ps1"
        if (Test-Path $deployScript) {
            # Capture both stdout and stderr
            $deployOutput = & $deployScript -CommitMessage "Auto-deploy: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 2>&1 | Out-String
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Auto-deploy completed successfully" "INFO"
                Write-Log "Deploy output: $deployOutput" "INFO"
                return $true
            } else {
                Write-Log "Auto-deploy failed with exit code $LASTEXITCODE" "ERROR"
                Write-Log "Output: $deployOutput" "ERROR"
                return $false
            }
        } else {
            Write-Log "Deploy script not found: $deployScript" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error during auto-deploy: $_" "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        return $false
    }
}

# Main loop
Write-Log "Auto-deploy watcher started (interval: ${WatchInterval}s)" "INFO"
if ($Force) {
    Write-Log "Force mode enabled - will deploy immediately" "INFO"
    Invoke-AutoDeploy -ForceDeploy $true
}

while ($true) {
    try {
        Start-Sleep -Seconds $WatchInterval
        
        # Check for changes and deploy
        $deployed = Invoke-AutoDeploy -ForceDeploy $false
        
        if ($deployed) {
            Write-Log "Deployment completed. Waiting for next check..." "INFO"
        }
    } catch {
        Write-Log "Error in watch loop: $_" "ERROR"
        Start-Sleep -Seconds 60  # Wait longer on error
    }
}

