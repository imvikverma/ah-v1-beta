# Quick Break Backup Script
# Creates a quick backup when Vik takes a break
# Faster than full backup - just essential files

$ErrorActionPreference = "Continue"

Write-Host "`n☕ Break Backup" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Gray
Write-Host ""

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

# Use the main backup script with quick settings
$backupScript = Join-Path $projectRoot "scripts\backup_project.ps1"

if (Test-Path $backupScript) {
    Write-Host "Creating break backup..." -ForegroundColor Yellow
    Write-Host ""
    & $backupScript -Compress -Verify
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Break backup completed!" -ForegroundColor Green
        Write-Host "   Location: _local\backups\" -ForegroundColor Gray
    } else {
        Write-Host "`n⚠️  Backup completed with warnings" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Backup script not found!" -ForegroundColor Red
    exit 1
}

Write-Host ""

