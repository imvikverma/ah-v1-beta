# Cleanup Old Backup Virtual Environments
# Removes old backup venvs, keeping only the most recent ones

param(
    [int]$KeepCount = 2  # Keep only the 2 most recent backups
)

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host "`n=== Cleanup Old Backup Venvs ===" -ForegroundColor Cyan
Write-Host ""

# Get all backup venvs, sorted by creation time (newest first)
$backupVenvs = Get-ChildItem -Directory -Filter ".venv-backup-*" | 
    Sort-Object CreationTime -Descending

if ($backupVenvs.Count -eq 0) {
    Write-Host "✅ No backup venvs found" -ForegroundColor Green
    exit 0
}

Write-Host "Found $($backupVenvs.Count) backup venv(s)" -ForegroundColor Yellow
Write-Host ""

# Show what will be kept
$toKeep = $backupVenvs | Select-Object -First $KeepCount
$toDelete = $backupVenvs | Select-Object -Skip $KeepCount

if ($toKeep.Count -gt 0) {
    Write-Host "Keeping (most recent):" -ForegroundColor Green
    foreach ($venv in $toKeep) {
        $size = (Get-ChildItem $venv.FullName -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Host "  ✅ $($venv.Name) - $([math]::Round($size, 2)) MB" -ForegroundColor Gray
    }
}

if ($toDelete.Count -gt 0) {
    Write-Host "`nDeleting (old):" -ForegroundColor Yellow
    $totalSize = 0
    foreach ($venv in $toDelete) {
        $size = (Get-ChildItem $venv.FullName -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum / 1MB
        $totalSize += $size
        Write-Host "  ❌ $($venv.Name) - $([math]::Round($size, 2)) MB" -ForegroundColor Gray
    }
    Write-Host "`nTotal space to free: $([math]::Round($totalSize, 2)) MB" -ForegroundColor Cyan
    
    $confirm = Read-Host "`nDelete these old backup venvs? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        foreach ($venv in $toDelete) {
            Write-Host "Deleting $($venv.Name)..." -ForegroundColor Yellow
            Remove-Item -Path $venv.FullName -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $venv.FullName)) {
                Write-Host "  ✅ Deleted" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️  Some files may remain (locked)" -ForegroundColor Yellow
            }
        }
        Write-Host "`n✅ Cleanup complete!" -ForegroundColor Green
    } else {
        Write-Host "`nCancelled. No backups deleted." -ForegroundColor Gray
    }
} else {
    Write-Host "`n✅ All backups are recent. Nothing to delete." -ForegroundColor Green
}

Write-Host ""

