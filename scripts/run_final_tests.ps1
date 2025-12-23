# Final Production Tests - With Backend Running
# Simplified version without Unicode issues

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

# Activate venv
if (Test-Path ".venv\Scripts\Activate.ps1") {
    & ".venv\Scripts\Activate.ps1"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Final Production Tests" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Backend API
Write-Host "[TEST 1] Backend API Test" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/health" -Method Get -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  [OK] Backend is running" -ForegroundColor Green
    Write-Host "  Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
} catch {
    Write-Host "  [FAIL] Backend not responding" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Gray
}

# Test 2: Paper Trading via API
Write-Host "`n[TEST 2] Paper Trading via API" -ForegroundColor Yellow
Write-Host "-------------------------------" -ForegroundColor Gray

$testOrder = @{
    user_id = "test_user_001"
    symbol = "RELIANCE"
    side = "BUY"
    quantity = 1
    order_type = "MARKET"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/paper/orders" -Method Post -Body $testOrder -ContentType "application/json" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "  [OK] Order placed successfully" -ForegroundColor Green
    Write-Host "  Order ID: $($response.order.client_order_id)" -ForegroundColor Gray
    Write-Host "  Status: $($response.order.status)" -ForegroundColor Gray
} catch {
    Write-Host "  [FAIL] Order placement failed" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Gray
}

# Test 3: Generate Report via API
Write-Host "`n[TEST 3] Generate Report via API" -ForegroundColor Yellow
Write-Host "---------------------------------" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/report/user/test_user_001" -Method Get -TimeoutSec 10 -ErrorAction Stop
    Write-Host "  [OK] Report generated" -ForegroundColor Green
    Write-Host "  Total Trades: $($response.total_trades)" -ForegroundColor Gray
    Write-Host "  Net Profit: $($response.net_profit)" -ForegroundColor Gray
} catch {
    Write-Host "  [FAIL] Report generation failed" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Gray
}

# Test 4: Worker API
Write-Host "`n[TEST 4] Worker API Test" -ForegroundColor Yellow
Write-Host "------------------------" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri "https://api-v2.saffronbolt.in/health" -Method Get -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host "  [OK] Worker is online" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Gray
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode) {
        Write-Host "  [WARN] Worker Status: $statusCode" -ForegroundColor Yellow
    } else {
        Write-Host "  [FAIL] Worker not reachable" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Tests Complete" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

