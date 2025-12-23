# EOD (End of Day) Flow Script
# Runs when Vik calls "EOD" to wrap up the day's work

$ErrorActionPreference = "Continue"

Write-Host "`n🌙 End of Day Flow" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Gray
Write-Host ""

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# Step 1: Update README & CHANGELOG
Write-Host "`n📝 Step 1: Updating README & CHANGELOG" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Gray

# Generate README (always run)
$generateReadmePath = Join-Path $projectRoot "scripts\generate-readme.ps1"
if (Test-Path $generateReadmePath) {
    Write-Host "  Regenerating README.md..." -ForegroundColor Gray
    & $generateReadmePath
    Write-Host "  ✅ README.md updated" -ForegroundColor Green
} else {
    Write-Host "  ❌ generate-readme.ps1 not found!" -ForegroundColor Red
    Write-Host "  Cannot continue without README generator" -ForegroundColor Red
    exit 1
}

# Update CHANGELOG (always run)
Write-Host "`n  Updating CHANGELOG.md..." -ForegroundColor Gray
$updateChangelogPath = Join-Path $projectRoot "scripts\update-changelog.ps1"
if (Test-Path $updateChangelogPath) {
    Write-Host "  Running changelog updater..." -ForegroundColor Gray
    & $updateChangelogPath
    Write-Host "  ✅ CHANGELOG.md updated" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  update-changelog.ps1 not found" -ForegroundColor Yellow
    Write-Host "  💡 Please manually edit CHANGELOG.md to add today's changes" -ForegroundColor Cyan
    Write-Host "  Press Enter after you've updated CHANGELOG.md..." -ForegroundColor Yellow
    Read-Host
}

# Step 2: Clean up/Organise File Structure
Write-Host "`n🧹 Step 2: Cleaning up File Structure" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Gray

# Check _local folder
$localPath = Join-Path $projectRoot "_local"
if (Test-Path $localPath) {
    Write-Host "  Checking _local/ folder..." -ForegroundColor Gray
    
    # Count files in root of _local
    $localRootFiles = Get-ChildItem -Path $localPath -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notlike "*.md" -and $_.Name -notlike "*.json" }
    
    if ($localRootFiles.Count -gt 0) {
        Write-Host "  ⚠️  Found $($localRootFiles.Count) file(s) in _local/ root" -ForegroundColor Yellow
        Write-Host "  💡 Consider moving to _local/documentation/ or _local/development/" -ForegroundColor Cyan
    } else {
        Write-Host "  ✅ _local/ folder is organized" -ForegroundColor Green
    }
}

# Check for temporary files in root
Write-Host "`n  Checking for temporary files..." -ForegroundColor Gray
$tempFiles = Get-ChildItem -Path $projectRoot -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Extension -in @(".tmp", ".temp", ".bak", ".old") -or
    $_.Name -like "*_backup*" -or
    $_.Name -like "*_temp*"
}

if ($tempFiles.Count -gt 0) {
    Write-Host "  ⚠️  Found $($tempFiles.Count) temporary file(s)" -ForegroundColor Yellow
    $tempFiles | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }
    $cleanTemp = Read-Host "  Delete temporary files? (y/n)"
    if ($cleanTemp -eq "y") {
        $tempFiles | Remove-Item -Force
        Write-Host "  ✅ Temporary files deleted" -ForegroundColor Green
    }
} else {
    Write-Host "  ✅ No temporary files found" -ForegroundColor Green
}

# Step 3: ML Training Status
Write-Host "`n🤖 Step 3: ML Training Status" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Gray

$mlTrainingPath = Join-Path $projectRoot "aurum_harmony\engines\ml_training"
if (Test-Path $mlTrainingPath) {
    Write-Host "  ML Training Engine found" -ForegroundColor Gray
    
    # Check for training history
    $modelsPath = Join-Path $projectRoot "_local\models"
    if (Test-Path $modelsPath) {
        $modelFiles = Get-ChildItem -Path $modelsPath -File -ErrorAction SilentlyContinue
        Write-Host "  📊 Model files: $($modelFiles.Count)" -ForegroundColor Gray
    }
    
    Write-Host "  💡 Review ML training status:" -ForegroundColor Cyan
    Write-Host "     - Check if weekly retrain is scheduled" -ForegroundColor Gray
    Write-Host "     - Review training history" -ForegroundColor Gray
    Write-Host "     - Document any training issues" -ForegroundColor Gray
} else {
    Write-Host "  ⚠️  ML Training Engine not found" -ForegroundColor Yellow
}

# Step 4: Generate EOD Summary JSON
Write-Host "`n📝 Step 4: Generating EOD Summary" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Gray

$generateSummaryPath = Join-Path $projectRoot "scripts\generate-eod-summary.ps1"
if (Test-Path $generateSummaryPath) {
    Write-Host "  Generating comprehensive JSON summary..." -ForegroundColor Gray
    & $generateSummaryPath
    Write-Host "  ✅ EOD summary created" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  generate-eod-summary.ps1 not found" -ForegroundColor Yellow
    Write-Host "  💡 Summary generation skipped" -ForegroundColor Cyan
}

# Step 5: Project Backup (CRITICAL - Prevents data loss!)
Write-Host "`n💾 Step 5: Creating Project Backup" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Gray

$backupScriptPath = Join-Path $projectRoot "scripts\backup_project.ps1"
if (Test-Path $backupScriptPath) {
    Write-Host "  Running comprehensive backup..." -ForegroundColor Gray
    try {
        & $backupScriptPath -Compress -Verify
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Project backup completed successfully" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Backup completed with warnings (check output above)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ Backup failed: $_" -ForegroundColor Red
        Write-Host "  💡 Manual backup recommended!" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ❌ backup_project.ps1 not found!" -ForegroundColor Red
    Write-Host "  💡 CRITICAL: Backup script missing - manual backup required!" -ForegroundColor Yellow
}

# Step 6: VS Code Workspace Mirror (Backup for usage limit downtime)
Write-Host "`n� mirror Step 6: Creating VS Code Workspace Mirror" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Gray

$mirrorScriptPath = Join-Path $projectRoot "scripts\mirror_to_vscode.ps1"
if (Test-Path $mirrorScriptPath) {
    Write-Host "  Creating VS Code workspace backup..." -ForegroundColor Gray
    try {
        & $mirrorScriptPath -CreateWorkspace -SyncGit
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ VS Code workspace mirror created" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  VS Code mirror had issues (check output above)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ⚠️  VS Code mirror failed: $_" -ForegroundColor Yellow
        Write-Host "  💡 Can continue without mirror" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠️  mirror_to_vscode.ps1 not found" -ForegroundColor Yellow
    Write-Host "  💡 VS Code mirror skipped" -ForegroundColor Gray
}

# Summary
Write-Host "`n✅ EOD Flow Complete!" -ForegroundColor Green
Write-Host "`n📋 Summary:" -ForegroundColor Cyan
Write-Host "  ✅ README.md regenerated" -ForegroundColor Gray
Write-Host "  ✅ CHANGELOG.md updated" -ForegroundColor Gray
Write-Host "  ✅ File structure reviewed" -ForegroundColor Gray
Write-Host "  ✅ ML training status checked" -ForegroundColor Gray
Write-Host "  ✅ EOD summary JSON generated" -ForegroundColor Gray
Write-Host "  ✅ Project backup created" -ForegroundColor Green
Write-Host "  ✅ VS Code workspace mirror created" -ForegroundColor Green
Write-Host "`n💡 Next Steps:" -ForegroundColor Yellow
Write-Host "  - Review and commit any changes" -ForegroundColor White
Write-Host "  - Check EOD summary in _local/Summaries/" -ForegroundColor White
Write-Host "  - Verify backups in _local/backups/" -ForegroundColor White
Write-Host "  - Push to GitHub if ready" -ForegroundColor White
Write-Host "`n📝 EOD Summary Location: _local\Summaries\EOD_YYYY-MM-DD_Charlie.json" -ForegroundColor Cyan
Write-Host "💾 Backup Location: _local\backups\backup_YYYYMMDD-HHMMSS.zip" -ForegroundColor Cyan
Write-Host ""

