# Fix Git Tracking for Files That Should Be Ignored
# This script stops tracking files that are in .gitignore but were previously tracked

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

Write-Host "=== Fixing Git Tracking for Ignored Files ===" -ForegroundColor Cyan
Write-Host ""

# Check if we're in a Git repository
if (-not (Test-Path ".git")) {
    Write-Host "[ERROR] Not a Git repository!" -ForegroundColor Red
    exit 1
}

$filesToUntrack = @()

# 1. Database files (should be ignored)
Write-Host "[1/4] Checking database files..." -ForegroundColor Yellow
$dbFiles = git ls-files | Where-Object { $_ -match '\.db$|\.sqlite$|\.sqlite3$' }
if ($dbFiles) {
    Write-Host "  Found database files to untrack:" -ForegroundColor Gray
    $dbFiles | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    $filesToUntrack += $dbFiles
} else {
    Write-Host "  ✅ No database files tracked" -ForegroundColor Green
}

# 2. Backup virtual environments
Write-Host "`n[2/4] Checking backup venv directories..." -ForegroundColor Yellow
$backupVenvs = git ls-files | Where-Object { $_ -match '\.venv-backup-' }
if ($backupVenvs) {
    Write-Host "  Found backup venv files to untrack:" -ForegroundColor Gray
    $backupVenvs | Select-Object -First 5 | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    if ($backupVenvs.Count -gt 5) {
        Write-Host "    ... and $($backupVenvs.Count - 5) more" -ForegroundColor Gray
    }
    $filesToUntrack += $backupVenvs
} else {
    Write-Host "  ✅ No backup venv files tracked" -ForegroundColor Green
}

# 3. Flutter generated plugin files
Write-Host "`n[3/4] Checking Flutter generated files..." -ForegroundColor Yellow
$generatedFiles = git ls-files | Where-Object { 
    $_ -match 'generated_plugin_registrant|GeneratedPluginRegistrant' 
}
if ($generatedFiles) {
    Write-Host "  Found generated files to untrack:" -ForegroundColor Gray
    $generatedFiles | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    $filesToUntrack += $generatedFiles
} else {
    Write-Host "  ✅ No generated files tracked" -ForegroundColor Green
}

# 4. _local/ directory files (if any are tracked)
Write-Host "`n[4/4] Checking _local/ directory..." -ForegroundColor Yellow
$localFiles = git ls-files | Where-Object { $_ -like '_local/*' }
if ($localFiles) {
    Write-Host "  Found _local/ files to untrack:" -ForegroundColor Gray
    $localFiles | Select-Object -First 5 | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }
    if ($localFiles.Count -gt 5) {
        Write-Host "    ... and $($localFiles.Count - 5) more" -ForegroundColor Gray
    }
    $filesToUntrack += $localFiles
} else {
    Write-Host "  ✅ No _local/ files tracked" -ForegroundColor Green
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Files to untrack: $($filesToUntrack.Count)" -ForegroundColor Yellow

if ($filesToUntrack.Count -eq 0) {
    Write-Host "`n✅ No files need to be untracked!" -ForegroundColor Green
    exit 0
}

# Ask for confirmation
Write-Host "`nThis will stop tracking these files in Git (but keep them on disk)." -ForegroundColor Yellow
$confirm = Read-Host "Continue? (y/N)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "Cancelled." -ForegroundColor Gray
    exit 0
}

# Untrack the files
Write-Host "`nUntracking files..." -ForegroundColor Yellow
try {
    foreach ($file in $filesToUntrack) {
        git rm --cached "$file" 2>&1 | Out-Null
        Write-Host "  ✓ $file" -ForegroundColor Gray
    }
    Write-Host "`n✅ Successfully untracked $($filesToUntrack.Count) files!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Review the changes: git status" -ForegroundColor White
    Write-Host "  2. Commit the .gitignore update: git commit -m 'Stop tracking ignored files'" -ForegroundColor White
    Write-Host "  3. Files will no longer show in review panel" -ForegroundColor White
} catch {
    Write-Host "`n[ERROR] Failed to untrack files: $_" -ForegroundColor Red
    exit 1
}

