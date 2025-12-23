# Setup Nightly Backup Schedule
# Creates Windows Task Scheduler task to run backup every night after EOD flow

param(
    [string]$BackupTime = "23:00",  # Default: 11 PM
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Setup Nightly Backup Schedule" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Get project root
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$maxDepth = 10
$depth = 0
while ($depth -lt $maxDepth) {
    if (Test-Path (Join-Path $projectRoot ".git")) { break }
    if (Test-Path (Join-Path $projectRoot "start-all.ps1")) { break }
    $parent = Split-Path -Parent $projectRoot
    if ($parent -eq $projectRoot) { break }
    $projectRoot = $parent
    $depth++
}

Set-Location $projectRoot

$taskName = "AurumHarmony_Nightly_Backup"
$backupScriptPath = Join-Path $projectRoot "scripts\backup_project.ps1"
$mirrorScriptPath = Join-Path $projectRoot "scripts\mirror_to_vscode.ps1"

Write-Host "[1] Configuration" -ForegroundColor Yellow
Write-Host "  Project Root: $projectRoot" -ForegroundColor Gray
Write-Host "  Backup Time: $BackupTime" -ForegroundColor Gray
Write-Host "  Task Name: $taskName" -ForegroundColor Gray
Write-Host ""

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask -and -not $Force) {
    Write-Host "[WARN] Task '$taskName' already exists!" -ForegroundColor Yellow
    Write-Host "  Use -Force to overwrite" -ForegroundColor Gray
    Write-Host ""
    $response = Read-Host "  Remove existing task and create new one? (y/n)"
    if ($response -ne "y") {
        Write-Host "  Cancelled" -ForegroundColor Gray
        exit 0
    }
}

# Remove existing task if exists
if ($existingTask) {
    Write-Host "`n[2] Removing existing task..." -ForegroundColor Yellow
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
        Write-Host "  [OK] Existing task removed" -ForegroundColor Green
    } catch {
        Write-Host "  [WARN] Could not remove existing task: $_" -ForegroundColor Yellow
    }
}

# Create PowerShell script that runs both backup and mirror
Write-Host "`n[3] Creating backup runner script..." -ForegroundColor Yellow

$runnerScript = @"
# Nightly Backup Runner
# Runs project backup and VS Code mirror

`$ErrorActionPreference = "Continue"

`$projectRoot = "$projectRoot"
Set-Location `$projectRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Nightly Backup - `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Run project backup
`$backupScript = Join-Path `$projectRoot "scripts\backup_project.ps1"
if (Test-Path `$backupScript) {
    Write-Host "Running project backup..." -ForegroundColor Yellow
    & `$backupScript -Compress -Verify
} else {
    Write-Host "ERROR: backup_project.ps1 not found!" -ForegroundColor Red
}

# Run VS Code mirror
`$mirrorScript = Join-Path `$projectRoot "scripts\mirror_to_vscode.ps1"
if (Test-Path `$mirrorScript) {
    Write-Host "`nRunning VS Code mirror..." -ForegroundColor Yellow
    & `$mirrorScript -CreateWorkspace -SyncGit
} else {
    Write-Host "WARN: mirror_to_vscode.ps1 not found!" -ForegroundColor Yellow
}

Write-Host "`nNightly backup complete!" -ForegroundColor Green
"@

$runnerScriptPath = Join-Path $projectRoot "scripts\nightly_backup_runner.ps1"
$runnerScript | Out-File -FilePath $runnerScriptPath -Encoding UTF8
Write-Host "  [OK] Runner script created: nightly_backup_runner.ps1" -ForegroundColor Green

# Create scheduled task
Write-Host "`n[4] Creating scheduled task..." -ForegroundColor Yellow

try {
    # Parse backup time
    $timeParts = $BackupTime.Split(":")
    $hour = [int]$timeParts[0]
    $minute = [int]$timeParts[1]
    
    # Create action (run PowerShell script)
    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$runnerScriptPath`""
    
    # Create trigger (daily at specified time)
    $trigger = New-ScheduledTaskTrigger -Daily -At "$BackupTime"
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable:$false `
        -WakeToRun:$false
    
    # Create principal (run as current user)
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" `
        -LogonType Interactive `
        -RunLevel Highest
    
    # Register task
    Register-ScheduledTask -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "AurumHarmony Nightly Backup - Runs project backup and VS Code mirror after EOD flow" `
        -Force | Out-Null
    
    Write-Host "  [OK] Scheduled task created successfully" -ForegroundColor Green
    Write-Host "  [OK] Task will run daily at $BackupTime" -ForegroundColor Green
    
} catch {
    Write-Host "  [ERROR] Failed to create scheduled task: $_" -ForegroundColor Red
    Write-Host "`n  Manual Setup Instructions:" -ForegroundColor Yellow
    Write-Host "  1. Open Task Scheduler (taskschd.msc)" -ForegroundColor White
    Write-Host "  2. Create Basic Task" -ForegroundColor White
    Write-Host "  3. Name: $taskName" -ForegroundColor White
    Write-Host "  4. Trigger: Daily at $BackupTime" -ForegroundColor White
    Write-Host "  5. Action: Start a program" -ForegroundColor White
    Write-Host "  6. Program: powershell.exe" -ForegroundColor White
    Write-Host "  7. Arguments: -NoProfile -ExecutionPolicy Bypass -File `"$runnerScriptPath`"" -ForegroundColor White
    exit 1
}

# Verify task
Write-Host "`n[5] Verifying task..." -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "  [OK] Task verified" -ForegroundColor Green
    Write-Host "  Task State: $($task.State)" -ForegroundColor Gray
    Write-Host "  Next Run: $((Get-ScheduledTaskInfo -TaskName $taskName).NextRunTime)" -ForegroundColor Gray
} else {
    Write-Host "  [WARN] Task not found after creation" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Setup Complete" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "✅ Nightly backup scheduled successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Task Name: $taskName" -ForegroundColor White
Write-Host "  Schedule: Daily at $BackupTime" -ForegroundColor White
Write-Host "  Script: scripts\nightly_backup_runner.ps1" -ForegroundColor White
Write-Host ""
Write-Host "To manage the task:" -ForegroundColor Yellow
Write-Host "  View: Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Cyan
Write-Host "  Run Now: Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Cyan
Write-Host "  Disable: Disable-ScheduledTask -TaskName '$taskName'" -ForegroundColor Cyan
Write-Host "  Remove: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backup locations:" -ForegroundColor Yellow
Write-Host "  Project Backups: _local\backups\" -ForegroundColor White
Write-Host "  VS Code Mirrors: Parent directory (with timestamp)" -ForegroundColor White
Write-Host ""

