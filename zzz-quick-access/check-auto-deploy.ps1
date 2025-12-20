# Quick check for auto-deploy setup

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Cloudflare Auto-Deploy Status       " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if workflow files exist
$workflowSimple = Test-Path ".github\workflows\cloudflare-deploy-simple.yml"
$workflowDirect = Test-Path ".github\workflows\cloudflare-deploy.yml"

if ($workflowSimple) {
    Write-Host "✅ Simple workflow file exists" -ForegroundColor Green
} else {
    Write-Host "❌ Simple workflow file missing" -ForegroundColor Red
}

if ($workflowDirect) {
    Write-Host "✅ Direct workflow file exists" -ForegroundColor Green
} else {
    Write-Host "⚠️  Direct workflow file missing (optional)" -ForegroundColor Yellow
}

Write-Host ""

# Check git status
Write-Host "Checking git status..." -ForegroundColor Yellow
$gitStatus = git status --short .github/workflows/ 2>&1

if ($gitStatus -match "^\?\?") {
    Write-Host "⚠️  Workflow files are not committed yet" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To enable auto-deploy, run:" -ForegroundColor Cyan
    Write-Host "  git add .github/workflows/" -ForegroundColor White
    Write-Host "  git commit -m 'Add automatic Cloudflare deployment'" -ForegroundColor White
    Write-Host "  git push" -ForegroundColor White
} elseif ($gitStatus -match "^A|^M") {
    Write-Host "✅ Workflow files are staged/committed" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Push to GitHub" -ForegroundColor Cyan
    Write-Host "  git push" -ForegroundColor White
} else {
    Write-Host "✅ Workflow files are in repository" -ForegroundColor Green
    Write-Host ""
    Write-Host "Auto-deploy should be active!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To test:" -ForegroundColor Yellow
    Write-Host "  1. Make a small change to a Flutter file" -ForegroundColor White
    Write-Host "  2. Commit and push" -ForegroundColor White
    Write-Host "  3. Check GitHub Actions tab" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
