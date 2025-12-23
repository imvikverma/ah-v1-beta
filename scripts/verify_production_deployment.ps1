# Verify Production Deployment
# Checks all production endpoints and services

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
Write-Host "║     Production Deployment Verification                ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$results = @{
    Worker = @{ Status = "Unknown"; Details = "" }
    Frontend = @{ Status = "Unknown"; Details = "" }
    Backend = @{ Status = "Unknown"; Details = "" }
}

# Step 1: Check Cloudflare Worker (api-v2.saffronbolt.in)
Write-Host "[1] Checking Cloudflare Worker API..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────" -ForegroundColor Gray

$workerEndpoints = @(
    "https://api-v2.saffronbolt.in/health",
    "https://api-v2.saffronbolt.in/api/health"
)

$workerOk = $false
foreach ($endpoint in $workerEndpoints) {
    Write-Host "  Testing: $endpoint" -ForegroundColor Gray
    try {
        $response = Invoke-WebRequest -Uri $endpoint -Method Get -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        Write-Host "    ✅ Status: $($response.StatusCode)" -ForegroundColor Green
        $workerOk = $true
        $results.Worker.Status = "Online"
        $results.Worker.Details = "Status: $($response.StatusCode)"
        break
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            Write-Host "    ⚠️  Status: $statusCode" -ForegroundColor Yellow
            $results.Worker.Details = "Status: $statusCode"
        } else {
            Write-Host "    ❌ Not reachable: $($_.Exception.Message)" -ForegroundColor Red
            $results.Worker.Status = "Offline"
            $results.Worker.Details = "Not reachable"
        }
    }
}

# Step 2: Check Frontend (ah.saffronbolt.in)
Write-Host "`n[2] Checking Frontend..." -ForegroundColor Yellow
Write-Host "───────────────────────────" -ForegroundColor Gray

$frontendUrls = @(
    "https://ah.saffronbolt.in",
    "https://ah.saffronbolt.in/"
)

$frontendOk = $false
foreach ($url in $frontendUrls) {
    Write-Host "  Testing: $url" -ForegroundColor Gray
    try {
        $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        Write-Host "    ✅ Status: $($response.StatusCode)" -ForegroundColor Green
        $frontendOk = $true
        $results.Frontend.Status = "Online"
        $results.Frontend.Details = "Status: $($response.StatusCode)"
        break
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode) {
            Write-Host "    ⚠️  Status: $statusCode" -ForegroundColor Yellow
            $results.Frontend.Details = "Status: $statusCode"
        } else {
            Write-Host "    ❌ Not reachable: $($_.Exception.Message)" -ForegroundColor Red
            $results.Frontend.Status = "Offline"
            $results.Frontend.Details = "Not reachable"
        }
    }
}

# Step 3: Check Backend (Render.com or local)
Write-Host "`n[3] Checking Backend..." -ForegroundColor Yellow
Write-Host "─────────────────────────" -ForegroundColor Gray

# Check if backend is running locally
Write-Host "  Checking local backend (localhost:5000)..." -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/health" -Method Get -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
    Write-Host "    ✅ Local backend running (Status: $($response.StatusCode))" -ForegroundColor Green
    $results.Backend.Status = "Local"
    $results.Backend.Details = "Running on localhost:5000"
} catch {
    Write-Host "    ⚠️  Local backend not running" -ForegroundColor Yellow
    
    # Check Render.com backend if configured
    $renderUrl = $env:RENDER_BACKEND_URL
    if ($renderUrl) {
        Write-Host "  Checking Render.com backend..." -ForegroundColor Gray
        try {
            $response = Invoke-WebRequest -Uri "$renderUrl/api/health" -Method Get -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            Write-Host "    ✅ Render backend running (Status: $($response.StatusCode))" -ForegroundColor Green
            $results.Backend.Status = "Render"
            $results.Backend.Details = "Running on Render.com"
        } catch {
            Write-Host "    ❌ Render backend not reachable" -ForegroundColor Red
            $results.Backend.Status = "Offline"
            $results.Backend.Details = "Not reachable"
        }
    } else {
        Write-Host "  ℹ️  No Render.com URL configured" -ForegroundColor Gray
        $results.Backend.Status = "Not Configured"
        $results.Backend.Details = "No production backend URL configured"
    }
}

# Step 4: Check Worker Authentication Endpoint
Write-Host "`n[4] Checking Worker Authentication..." -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────" -ForegroundColor Gray

$authEndpoint = "https://api-v2.saffronbolt.in/api/auth/me"
Write-Host "  Testing: $authEndpoint" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri $authEndpoint -Method Get -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host "    ✅ Endpoint accessible" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "    ✅ Endpoint working (401 = auth required, expected)" -ForegroundColor Green
    } elseif ($statusCode) {
        Write-Host "    ⚠️  Status: $statusCode" -ForegroundColor Yellow
    } else {
        Write-Host "    ❌ Not reachable" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Deployment Status Summary                           ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Cloudflare Worker (api-v2.saffronbolt.in):" -ForegroundColor Cyan
Write-Host "  Status: $($results.Worker.Status)" -ForegroundColor $(if ($results.Worker.Status -eq "Online") { "Green" } else { "Red" })
Write-Host "  Details: $($results.Worker.Details)" -ForegroundColor Gray
Write-Host ""

Write-Host "Frontend (ah.saffronbolt.in):" -ForegroundColor Cyan
Write-Host "  Status: $($results.Frontend.Status)" -ForegroundColor $(if ($results.Frontend.Status -eq "Online") { "Green" } else { "Red" })
Write-Host "  Details: $($results.Frontend.Details)" -ForegroundColor Gray
Write-Host ""

Write-Host "Backend:" -ForegroundColor Cyan
Write-Host "  Status: $($results.Backend.Status)" -ForegroundColor $(if ($results.Backend.Status -ne "Offline") { "Green" } else { "Red" })
Write-Host "  Details: $($results.Backend.Details)" -ForegroundColor Gray
Write-Host ""

# Recommendations
Write-Host "📋 Recommendations:" -ForegroundColor Yellow
if ($results.Worker.Status -ne "Online") {
    Write-Host "  ⚠️  Deploy Worker: npx wrangler deploy --env production" -ForegroundColor Yellow
}
if ($results.Frontend.Status -ne "Online") {
    Write-Host "  ⚠️  Deploy Frontend: Check Cloudflare Pages deployment" -ForegroundColor Yellow
}
if ($results.Backend.Status -eq "Offline") {
    Write-Host "  ⚠️  Start Backend: .\scripts\start_backend_silent.ps1" -ForegroundColor Yellow
}

Write-Host ""

