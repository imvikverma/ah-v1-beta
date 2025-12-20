# Credential Cleanup Script
# Removes "_local/documentation/other-files/API Keys.txt" from ALL git history

Write-Host "=== Credential Cleanup Script ===" -ForegroundColor Yellow
Write-Host "This will remove '_local/documentation/other-files/API Keys.txt' from ALL git history" -ForegroundColor Red
Write-Host ""

# Check if file exists in history
Write-Host "[1/4] Checking git history for leaked file..." -ForegroundColor Cyan
$history = git log --all --full-history --oneline -- "_local/documentation/other-files/API Keys.txt" 2>&1

if ($LASTEXITCODE -eq 0 -and $history) {
    Write-Host "⚠️  File found in git history!" -ForegroundColor Red
    Write-Host $history
    Write-Host ""
    Write-Host "File exists in the following commits:" -ForegroundColor Yellow
    
    # Check if git-filter-repo is available
    $hasFilterRepo = Get-Command git-filter-repo -ErrorAction SilentlyContinue
    
    if (-not $hasFilterRepo) {
        Write-Host ""
        Write-Host "❌ git-filter-repo not found. Installing..." -ForegroundColor Yellow
        Write-Host "Please install git-filter-repo first:" -ForegroundColor Yellow
        Write-Host "  pip install git-filter-repo" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Or use BFG Repo-Cleaner:" -ForegroundColor Yellow
        Write-Host "  Download from: https://rtyley.github.io/bfg-repo-cleaner/" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host ""
    Write-Host "[2/4] Removing file from ALL git history..." -ForegroundColor Cyan
    Write-Host "This will rewrite git history. Make sure you have a backup!" -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Type 'YES' to continue (this is destructive)"
    if ($confirm -ne "YES") {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
    
    # Remove file from all history
    git filter-repo --path "_local/documentation/other-files/API Keys.txt" --invert-paths --force
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ File removed from git history!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to remove file from history" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ File not found in git history (or already removed)" -ForegroundColor Green
}

Write-Host ""
Write-Host "[3/4] Verifying cleanup..." -ForegroundColor Cyan
$verify = git log --all --full-history --oneline -- "_local/documentation/other-files/API Keys.txt" 2>&1
if (-not $verify -or $verify -match "fatal:") {
    Write-Host "✅ Verification passed - file no longer in history" -ForegroundColor Green
} else {
    Write-Host "⚠️  File still found in history. Manual cleanup may be needed." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[4/4] Next steps:" -ForegroundColor Cyan
Write-Host "1. Force push to GitHub: git push origin --force --all" -ForegroundColor Yellow
Write-Host "2. Force push tags: git push origin --force --tags" -ForegroundColor Yellow
Write-Host "3. (Optional) Rotate ngrok token at: https://dashboard.ngrok.com/get-started/your-authtoken" -ForegroundColor Gray
Write-Host "   Note: We're not using ngrok anymore (using ah.saffronbolt.in custom domain)" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  WARNING: Force pushing will rewrite remote history!" -ForegroundColor Red
Write-Host "   Coordinate with team before force pushing." -ForegroundColor Yellow

