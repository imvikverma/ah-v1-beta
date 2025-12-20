# Script to resolve git rebase and commit cleanup changes
# Run this script to complete the git cleanup

$projectRoot = "d:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
Set-Location $projectRoot

Write-Host "=== Resolving Git Issues ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if in rebase
$rebaseStatus = git status 2>&1 | Select-String "rebasing"
if ($rebaseStatus) {
    Write-Host "Step 1: Completing rebase..." -ForegroundColor Yellow
    git rebase --continue
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Rebase failed. You may need to resolve conflicts manually." -ForegroundColor Red
        Write-Host "Or abort with: git rebase --abort" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✓ Rebase completed" -ForegroundColor Green
} else {
    Write-Host "✓ Not in rebase" -ForegroundColor Green
}

Write-Host ""

# Step 2: Pull remote changes
Write-Host "Step 2: Pulling remote changes..." -ForegroundColor Yellow
git fetch origin main
$localCommit = git rev-parse HEAD
$remoteCommit = git rev-parse origin/main

if ($localCommit -ne $remoteCommit) {
    Write-Host "Remote has changes. Pulling with rebase..." -ForegroundColor Yellow
    git pull --rebase origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Pull failed. You may need to resolve conflicts manually." -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Remote changes pulled" -ForegroundColor Green
} else {
    Write-Host "✓ Local and remote are in sync" -ForegroundColor Green
}

Write-Host ""

# Step 3: Stage deletions and .gitignore
Write-Host "Step 3: Staging cleanup changes..." -ForegroundColor Yellow
git add .gitignore
git add -u  # Stage all deletions and modifications
Write-Host "✓ Staged deletions and .gitignore" -ForegroundColor Green

Write-Host ""

# Step 4: Show what will be committed
Write-Host "Step 4: Files to be committed:" -ForegroundColor Yellow
git status --short | Where-Object { $_ -match "^(A|M|D)" } | Select-Object -First 20

Write-Host ""

# Step 5: Commit
Write-Host "Step 5: Ready to commit?" -ForegroundColor Cyan
Write-Host "Run: git commit -m 'chore: Remove all non-production files from git tracking'" -ForegroundColor White
Write-Host ""
Write-Host "Then push with: git push origin main" -ForegroundColor White
