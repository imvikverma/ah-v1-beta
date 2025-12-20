# Check Cloudflare Worker Status
# Helps diagnose Worker build/deployment issues

Write-Host "=== Cloudflare Worker Status Check ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Worker: aurum-api" -ForegroundColor Yellow
Write-Host "URL: https://api.ah.saffronbolt.in" -ForegroundColor Gray
Write-Host ""

# Test Worker endpoint
Write-Host "Testing Worker endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/health" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "  Worker is responding!" -ForegroundColor Green
        $content = $response.Content
        Write-Host "  Response: $content" -ForegroundColor Gray
    } else {
        Write-Host "  Worker returned status: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    $errorMsg = $_.Exception.Message
    Write-Host "  Worker is NOT responding" -ForegroundColor Red
    Write-Host "  Error: $errorMsg" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible causes:" -ForegroundColor Yellow
    Write-Host "  1. Latest build failed (check Cloudflare dashboard)" -ForegroundColor White
    Write-Host "  2. Worker not deployed yet" -ForegroundColor White
    Write-Host "  3. DNS not configured correctly" -ForegroundColor White
    Write-Host "  4. Worker code has errors" -ForegroundColor White
    Write-Host ""
    Write-Host "Solutions:" -ForegroundColor Yellow
    Write-Host "  1. Check Cloudflare Dashboard -> Workers & Pages -> aurum-api" -ForegroundColor Cyan
    Write-Host "  2. Look at 'Deployments' tab for build errors" -ForegroundColor Cyan
    Write-Host "  3. Check 'Settings' -> 'Variables and Secrets' for missing env vars" -ForegroundColor Cyan
    Write-Host "  4. For local testing, use: http://localhost:58643 (uses localhost:5000 backend)" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Local Backend Status:" -ForegroundColor Yellow
try {
    $localResponse = Invoke-WebRequest -Uri "http://localhost:5000/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($localResponse.StatusCode -eq 200) {
        Write-Host "  Local backend is working - use this for development!" -ForegroundColor Green
        Write-Host "  Access app from: http://localhost:58643" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  Local backend not running" -ForegroundColor Yellow
    Write-Host "  Start with: .\start-all.ps1 -> Option 1" -ForegroundColor Gray
}

Write-Host ""

