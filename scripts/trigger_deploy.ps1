# Quick Deploy Trigger Script
# This can be called from the Firefox auto-refresh tool or run directly

Param(
    [switch]$Force = $true
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host "=== Triggering Force Deploy ===" -ForegroundColor Yellow
Write-Host ""

$deployScript = Join-Path $projectRoot "scripts\deploy_cloudflare.ps1"
if (Test-Path $deployScript) {
    & $deployScript -Force:$Force
} else {
    Write-Host "❌ Deploy script not found: $deployScript" -ForegroundColor Red
    exit 1
}

