# Prepare for Production Deployment
# Handles git sync, staging, and pre-deployment checks

$ErrorActionPreference = "Continue"

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

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║     🚀 PREPARING FOR PRODUCTION DEPLOYMENT            ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Step 1: Check current status
Write-Host "[1/5] Checking current status..." -ForegroundColor Cyan
& "$projectRoot\scripts\check_repo_sync.ps1"

Write-Host "`n[2/5] Pulling remote changes..." -ForegroundColor Cyan
$pullOutput = git pull origin main 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Pulled remote changes" -ForegroundColor Green
    if ($pullOutput -match "Already up to date") {
        Write-Host "   ℹ️  Already up to date" -ForegroundColor Gray
    }
} else {
    Write-Host "   ⚠️  Pull had issues - check output above" -ForegroundColor Yellow
    Write-Host "   Continue anyway? (Y/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    if ($response -ne "Y" -and $response -ne "y") {
        exit 1
    }
}

# Step 3: Stage production files
Write-Host "`n[3/5] Staging production files..." -ForegroundColor Cyan

$filesToStage = @(
    ".continue/",
    "engines/",
    "scripts/backup_project.ps1",
    "scripts/check_repo_sync.ps1",
    "scripts/comprehensive_integrity_check.ps1",
    "scripts/mirror_to_vscode.ps1",
    "scripts/setup_nightly_backup.ps1",
    "scripts/setup_auto_venv_activation.ps1",
    "scripts/test_broker_connections.ps1"
)

$stagedCount = 0
foreach ($file in $filesToStage) {
    $fullPath = Join-Path $projectRoot $file
    if (Test-Path $fullPath) {
        git add $file 2>&1 | Out-Null
        $stagedCount++
        Write-Host "   ✅ Staged: $file" -ForegroundColor Green
    } else {
        Write-Host "   ⏭️  Skipped (not found): $file" -ForegroundColor Gray
    }
}

# Also stage any modified essential files
Write-Host "`n   Staging modified essential files..." -ForegroundColor Gray
git add scripts/*.ps1 start-all.ps1 requirements.txt 2>&1 | Out-Null

Write-Host "   ✅ Staged $stagedCount production file(s)" -ForegroundColor Green

# Step 4: Show what will be committed
Write-Host "`n[4/5] Review staged changes..." -ForegroundColor Cyan
$stagedFiles = git diff --staged --name-only
if ($stagedFiles) {
    Write-Host "   📝 Files ready to commit:" -ForegroundColor Yellow
    $stagedFiles | Select-Object -First 20 | ForEach-Object {
        Write-Host "      + $_" -ForegroundColor Green
    }
    if (($stagedFiles | Measure-Object).Count -gt 20) {
        Write-Host "      ... and $(($stagedFiles | Measure-Object).Count - 20) more" -ForegroundColor Gray
    }
} else {
    Write-Host "   ⚠️  No files staged" -ForegroundColor Yellow
}

# Step 5: Pre-deployment check
Write-Host "`n[5/5] Running pre-deployment checks..." -ForegroundColor Cyan

$issues = @()

# Check if .env files are tracked (they shouldn't be)
$envFiles = git ls-files | Where-Object { $_ -match "\.env" }
if ($envFiles) {
    $issues += "⚠️  .env files are tracked (security risk!)"
    Write-Host "   ⚠️  Found tracked .env files:" -ForegroundColor Red
    $envFiles | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
}

# Check if _local is tracked (it shouldn't be)
$localFiles = git ls-files | Where-Object { $_ -match "^_local/" }
if ($localFiles) {
    $issues += "⚠️  _local files are tracked (should be ignored)"
    Write-Host "   ⚠️  Found tracked _local files" -ForegroundColor Yellow
}

# Check if .venv is tracked
$venvFiles = git ls-files | Where-Object { $_ -match "\.venv" }
if ($venvFiles) {
    $issues += "⚠️  .venv files are tracked (should be ignored)"
    Write-Host "   ⚠️  Found tracked .venv files" -ForegroundColor Yellow
}

if ($issues.Count -eq 0) {
    Write-Host "   ✅ All checks passed!" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Found $($issues.Count) issue(s)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║     📊 PREPARATION SUMMARY                             ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

if ($issues.Count -eq 0) {
    Write-Host "✅ Ready to commit and deploy!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review staged files: git status" -ForegroundColor White
    Write-Host "  2. Commit: git commit -m 'Production: Add recovered modules and deployment tools'" -ForegroundColor White
    Write-Host "  3. Push: git push origin main" -ForegroundColor White
    Write-Host "  4. Deploy: .\scripts\deploy_incremental.ps1" -ForegroundColor White
} else {
    Write-Host "⚠️  Please fix issues above before deploying" -ForegroundColor Yellow
}

Write-Host ""
Set-Location $projectRoot

