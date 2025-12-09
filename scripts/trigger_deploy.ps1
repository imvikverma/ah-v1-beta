# Quick Deploy Trigger Script
# Use this to manually trigger a deployment when Cursor saves files
# Can be run from the Firefox refresh tool or manually

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host "🚀 Triggering deployment..." -ForegroundColor Cyan
Write-Host ""

# Run the deploy script
$deployScript = Join-Path $projectRoot "scripts\deploy_cloudflare.ps1"
if (Test-Path $deployScript) {
    & $deployScript -CommitMessage "Deploy: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Deployment triggered successfully!" -ForegroundColor Green
        Write-Host "   Cloudflare will build in 1-3 minutes" -ForegroundColor Yellow
        Write-Host "   Live URL: https://ah.saffronbolt.in" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "❌ Deployment failed. Check errors above." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ Deploy script not found: $deployScript" -ForegroundColor Red
    exit 1
}
