# Nightly Backup Runner
# Runs project backup and VS Code mirror

$ErrorActionPreference = "Continue"

$projectRoot = "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
Set-Location $projectRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Nightly Backup - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host "========================================
" -ForegroundColor Cyan

# Run project backup
$backupScript = Join-Path $projectRoot "scripts\backup_project.ps1"
if (Test-Path $backupScript) {
    Write-Host "Running project backup..." -ForegroundColor Yellow
    & $backupScript -Compress -Verify
} else {
    Write-Host "ERROR: backup_project.ps1 not found!" -ForegroundColor Red
}

# Run VS Code mirror
$mirrorScript = Join-Path $projectRoot "scripts\mirror_to_vscode.ps1"
if (Test-Path $mirrorScript) {
    Write-Host "
Running VS Code mirror..." -ForegroundColor Yellow
    & $mirrorScript -CreateWorkspace -SyncGit
} else {
    Write-Host "WARN: mirror_to_vscode.ps1 not found!" -ForegroundColor Yellow
}

Write-Host "
Nightly backup complete!" -ForegroundColor Green
