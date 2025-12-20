# Test Broker Backtesting Integration
# Tests the new broker-integrated backtesting endpoints

$ErrorActionPreference = "Continue"

Write-Host "`n🧪 Testing Broker Backtesting Integration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Gray
Write-Host ""

# Check if backend is online
Write-Host "1. Checking backend status..." -ForegroundColor Yellow
$backendStatus = Test-NetConnection -ComputerName localhost -Port 5000 -InformationLevel Quiet -WarningAction SilentlyContinue

if (-not $backendStatus) {
    Write-Host "   ❌ Backend is offline. Please start backend first." -ForegroundColor Red
    Write-Host "   Run: Option 1 or 4 in start-all.ps1" -ForegroundColor Gray
    exit 1
}

Write-Host "   ✅ Backend is online" -ForegroundColor Green

# Test health endpoint
Write-Host "`n2. Testing health endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:5000/api/health" -Method GET -TimeoutSec 5
    Write-Host "   ✅ Health check passed: $($healthResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Health check failed: $_" -ForegroundColor Red
    exit 1
}

# Test backtest endpoints (will require auth, but we can check if they exist)
Write-Host "`n3. Testing backtest endpoints..." -ForegroundColor Yellow

# Test realistic endpoint (without auth - should return 401)
Write-Host "   Testing /api/backtest/realistic..." -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/backtest/realistic?use_broker_data=false&days=1" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   ✅ Endpoint exists (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "   ✅ Endpoint exists (requires auth - expected)" -ForegroundColor Green
    } elseif ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "   ❌ Endpoint not found (404) - blueprint may not be registered" -ForegroundColor Red
    } else {
        Write-Host "   ⚠️  Unexpected response: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    }
}

# Test edge endpoint
Write-Host "   Testing /api/backtest/edge..." -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/backtest/edge?use_broker_data=false&days=1" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "   ✅ Endpoint exists (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "   ✅ Endpoint exists (requires auth - expected)" -ForegroundColor Green
    } elseif ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "   ❌ Endpoint not found (404) - blueprint may not be registered" -ForegroundColor Red
    } else {
        Write-Host "   ⚠️  Unexpected response: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
    }
}

# Test legacy endpoints (should still work)
Write-Host "`n4. Testing legacy endpoints (backward compatibility)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/backtest/realistic" -Method GET -TimeoutSec 5
    Write-Host "   ✅ Legacy /backtest/realistic works (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Legacy endpoint issue: $_" -ForegroundColor Yellow
}

Write-Host "`n✅ Integration Test Complete!" -ForegroundColor Green
Write-Host "`n💡 To test with real broker data:" -ForegroundColor Yellow
Write-Host "   1. Connect HDFC Sky or Kotak Neo broker" -ForegroundColor Gray
Write-Host "   2. Get auth token from login" -ForegroundColor Gray
Write-Host "   3. Call: GET /api/backtest/realistic?use_broker_data=true&symbols=NIFTY&days=30" -ForegroundColor Gray
Write-Host "      Header: Authorization: Bearer <token>" -ForegroundColor Gray

