# Fix Session Expiration Issues
# Improves session handling to prevent false "Session expired" errors

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

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Fixing Session Expiration Issues                    ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1] Checking Frontend Configuration..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────" -ForegroundColor Gray

$constantsFile = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app\lib\constants.dart"
if (Test-Path $constantsFile) {
    $constants = Get-Content $constantsFile -Raw
    Write-Host "  ✅ Constants file found" -ForegroundColor Green
    
    if ($constants -match "api-v2\.saffronbolt\.in") {
        Write-Host "  ✅ Frontend configured for api-v2.saffronbolt.in" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Frontend may not be using v2 API" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ❌ Constants file not found" -ForegroundColor Red
}

Write-Host "`n[2] Testing API Endpoints..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────" -ForegroundColor Gray

$endpoints = @(
    "https://api-v2.saffronbolt.in/health",
    "http://localhost:5000/api/health"
)

foreach ($endpoint in $endpoints) {
    Write-Host "  Testing: $endpoint" -ForegroundColor Gray
    try {
        $response = Invoke-WebRequest -Uri $endpoint -Method Get -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        Write-Host "    ✅ Responding (Status: $($response.StatusCode))" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            Write-Host "    ⚠️  Status: $statusCode" -ForegroundColor Yellow
        } else {
            Write-Host "    ❌ Not reachable" -ForegroundColor Red
        }
    }
}

Write-Host "`n[3] Recommendations..." -ForegroundColor Yellow
Write-Host "───────────────────────────" -ForegroundColor Gray

Write-Host "  💡 For ah.saffronbolt.in (v1 frontend):" -ForegroundColor Cyan
Write-Host "     • Frontend uses: api-v2.saffronbolt.in" -ForegroundColor White
Write-Host "     • Make sure Worker is deployed and accessible" -ForegroundColor White
Write-Host "     • Check Worker's /api/auth/me endpoint is working" -ForegroundColor White
Write-Host ""
Write-Host "  💡 Session Expiration Fixes:" -ForegroundColor Cyan
Write-Host "     • Increase grace period (currently 5 minutes)" -ForegroundColor White
Write-Host "     • Make token validation less aggressive" -ForegroundColor White
Write-Host "     • Improve error handling for Worker API" -ForegroundColor White
Write-Host ""

Write-Host "✅ Analysis Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Verify Worker is deployed: https://api-v2.saffronbolt.in/health" -ForegroundColor White
Write-Host "  2. Test login flow on ah.saffronbolt.in" -ForegroundColor White
Write-Host "  3. Check browser console for API errors" -ForegroundColor White
Write-Host "  4. Verify Worker's /api/auth/me endpoint" -ForegroundColor White
Write-Host ""

