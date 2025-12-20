# File Watcher for Auto-Deploy
# Watches for file changes and automatically deploys when Flutter frontend files change
# Run this in the background to auto-deploy on Cursor saves

Param(
    [int]$CheckInterval = 10,  # Check every 10 seconds
    [switch]$WatchAll = $false  # Watch all files, not just Flutter
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

$logFile = Join-Path $projectRoot "_local\logs\watch_deploy.log"
$logDir = Split-Path -Parent $logFile
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMessage
    if ($Level -eq "ERROR" -or $Level -eq "INFO") {
        Write-Host $logMessage
    }
}

# Track last deployment time to avoid rapid re-deployments
$lastDeployTime = $null
$minDeployInterval = 120  # Minimum 2 minutes between deployments

# Files/directories to watch
$watchPaths = @(
    "aurum_harmony\frontend\flutter_app\lib",
    "aurum_harmony\frontend\flutter_app\pubspec.yaml",
    "aurum_harmony\frontend\flutter_app\web"
)

if ($WatchAll) {
    $watchPaths = @("aurum_harmony\frontend\flutter_app")
}

Write-Log "File watcher started (interval: ${CheckInterval}s)" "INFO"
Write-Log "Watching: $($watchPaths -join ', ')" "INFO"
Write-Log "Minimum deploy interval: ${minDeployInterval}s" "INFO"

# Get initial file timestamps
$lastCheckTime = Get-Date
$fileTimestamps = @{}

function Get-FileTimestamps {
    $timestamps = @{}
    foreach ($path in $watchPaths) {
        $fullPath = Join-Path $projectRoot $path
        if (Test-Path $fullPath) {
            if ((Get-Item $fullPath).PSIsContainer) {
                # Directory - get all files recursively
                Get-ChildItem -Path $fullPath -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                    $timestamps[$_.FullName] = $_.LastWriteTime
                }
            } else {
                # Single file
                $item = Get-Item $fullPath
                $timestamps[$item.FullName] = $item.LastWriteTime
            }
        }
    }
    return $timestamps
}

# Initialize
$fileTimestamps = Get-FileTimestamps
Write-Log "Initialized with $($fileTimestamps.Count) files to watch" "INFO"

while ($true) {
    try {
        Start-Sleep -Seconds $CheckInterval
        
        # Get current file timestamps
        $currentTimestamps = Get-FileTimestamps
        
        # Check for changes
        $hasChanges = $false
        $changedFiles = @()
        
        foreach ($file in $currentTimestamps.Keys) {
            if ($fileTimestamps.ContainsKey($file)) {
                if ($currentTimestamps[$file] -gt $fileTimestamps[$file]) {
                    $hasChanges = $true
                    $changedFiles += $file
                }
            } else {
                # New file
                $hasChanges = $true
                $changedFiles += $file
            }
        }
        
        # Check for deleted files
        foreach ($file in $fileTimestamps.Keys) {
            if (-not $currentTimestamps.ContainsKey($file)) {
                $hasChanges = $true
                $changedFiles += "DELETED: $file"
            }
        }
        
        if ($hasChanges) {
            Write-Log "File changes detected: $($changedFiles.Count) file(s)" "INFO"
            $changedFiles | ForEach-Object { Write-Log "  Changed: $_" "INFO" }
            
            # Check if enough time has passed since last deployment
            $timeSinceLastDeploy = if ($lastDeployTime) {
                ((Get-Date) - $lastDeployTime).TotalSeconds
            } else {
                $minDeployInterval + 1
            }
            
            if ($timeSinceLastDeploy -lt $minDeployInterval) {
                $waitTime = [math]::Ceiling($minDeployInterval - $timeSinceLastDeploy)
                Write-Log "Waiting $waitTime more seconds before deploying (rate limit)" "INFO"
                Start-Sleep -Seconds $waitTime
            }
            
            # Regenerate README first (to reflect latest changes)
            Write-Log "Regenerating README.md..." "INFO"
            $generateReadmePath = Join-Path $projectRoot "scripts\generate-readme.ps1"
            if (Test-Path $generateReadmePath) {
                & $generateReadmePath | Out-Null
                Write-Log "README.md regenerated" "INFO"
            }
            
            # Trigger deployment
            Write-Log "Triggering deployment..." "INFO"
            $deployScript = Join-Path $projectRoot "scripts\deploy_cloudflare.ps1"
            if (Test-Path $deployScript) {
                $deployOutput = & $deployScript -CommitMessage "Auto-deploy: File changes detected $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 2>&1 | Out-String
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Deployment completed successfully" "INFO"
                    $lastDeployTime = Get-Date
                } else {
                    Write-Log "Deployment failed: $deployOutput" "ERROR"
                }
            } else {
                Write-Log "Deploy script not found" "ERROR"
            }
            
            # Update timestamps
            $fileTimestamps = $currentTimestamps
        }
    } catch {
        Write-Log "Error in watch loop: $_" "ERROR"
        Start-Sleep -Seconds 60
    }
}

