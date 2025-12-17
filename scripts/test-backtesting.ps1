# Backtesting Tests
# Tests realistic and edge case backtesting endpoints

$ErrorActionPreference = "Continue"

Write-Host "`n📊 Backtesting Tests" -ForegroundColor Cyan
Write-Host "====================" -ForegroundColor Gray
Write-Host ""

$backendUrl = "http://localhost:5000"
$v2ApiUrl = "https://api-v2.saffronbolt.in"
$testResults = @{
    "Backend Running" = $false
    "Realistic Backtest Endpoint" = $false
    "Edge Case Backtest Endpoint" = $false
    "Worker Backtest Endpoint" = $false
}

# Test 1: Check if backend is running
Write-Host "`n📡 Test 1: Backend Health Check" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Gray
try {
    $healthResponse = Invoke-RestMethod -Uri "$backendUrl/health" -Method Get -ErrorAction Stop -TimeoutSec 5
    Write-Host "  ✅ Backend is running" -ForegroundColor Green
    Write-Host "     Status: $($healthResponse.status)" -ForegroundColor Gray
    $testResults["Backend Running"] = $true
} catch {
    Write-Host "  ⚠️  Backend is not running (will test Worker endpoint instead)" -ForegroundColor Yellow
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Gray
}

# Test 2: Worker Backtest Endpoint (Realistic)
Write-Host "`n📊 Test 2: Worker Backtest Endpoint (Realistic)" -ForegroundColor Yellow
Write-Host "----------------------------------------------" -ForegroundColor Gray
try {
    $testUrl = "$v2ApiUrl/api/backtest/realistic?use_broker_data=true&symbols=NIFTY,BANKNIFTY&days=20&exchange=NSE"
    
    try {
        $backtestResponse = Invoke-RestMethod -Uri $testUrl `
            -Method Get `
            -Headers @{
                "Authorization" = "Bearer test_token"
            } `
            -ErrorAction Stop
        
        Write-Host "  ⚠️  Backtest endpoint: Responded without valid token (security issue?)" -ForegroundColor Yellow
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "  ✅ Backtest endpoint: Correctly requires authentication" -ForegroundColor Green
            Write-Host "     Status: 401 Unauthorized" -ForegroundColor Gray
            Write-Host "     Endpoint: /api/backtest/realistic" -ForegroundColor Gray
            $testResults["Worker Backtest Endpoint"] = $true
        } else {
            Write-Host "  ⚠️  Backtest endpoint: Unexpected status code" -ForegroundColor Yellow
            Write-Host "     Status: $statusCode" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  ❌ Backtest endpoint: Could not test" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Backend Realistic Backtest Endpoint (if backend is running)
if ($testResults["Backend Running"]) {
    Write-Host "`n📊 Test 3: Backend Realistic Backtest Endpoint" -ForegroundColor Yellow
    Write-Host "---------------------------------------------" -ForegroundColor Gray
    try {
        $testUrl = "$backendUrl/api/backtest/realistic?use_broker_data=true&symbols=NIFTY,BANKNIFTY&days=20&exchange=NSE"
        
        try {
            $backtestResponse = Invoke-RestMethod -Uri $testUrl `
                -Method Get `
                -Headers @{
                    "Authorization" = "Bearer test_token"
                } `
                -ErrorAction Stop
            
            Write-Host "  ⚠️  Backtest endpoint: Responded without valid token (security issue?)" -ForegroundColor Yellow
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode -eq 401) {
                Write-Host "  ✅ Backtest endpoint: Correctly requires authentication" -ForegroundColor Green
                Write-Host "     Status: 401 Unauthorized" -ForegroundColor Gray
                Write-Host "     Endpoint: /api/backtest/realistic" -ForegroundColor Gray
                $testResults["Realistic Backtest Endpoint"] = $true
            } else {
                Write-Host "  ⚠️  Backtest endpoint: Unexpected status code" -ForegroundColor Yellow
                Write-Host "     Status: $statusCode" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Host "  ❌ Backtest endpoint: Could not test" -ForegroundColor Red
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 4: Edge Case Backtest Endpoint
Write-Host "`n🔬 Test 4: Edge Case Backtest Endpoint" -ForegroundColor Yellow
Write-Host "-------------------------------------" -ForegroundColor Gray
try {
    $testUrl = "$v2ApiUrl/api/backtest/edge?use_broker_data=true&symbols=NIFTY&days=20&vix=35.0&exchange=NSE"
    
    try {
        $edgeResponse = Invoke-RestMethod -Uri $testUrl `
            -Method Get `
            -Headers @{
                "Authorization" = "Bearer test_token"
            } `
            -ErrorAction Stop
        
        Write-Host "  ⚠️  Edge case endpoint: Responded without valid token (security issue?)" -ForegroundColor Yellow
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "  ✅ Edge case endpoint: Correctly requires authentication" -ForegroundColor Green
            Write-Host "     Status: 401 Unauthorized" -ForegroundColor Gray
            Write-Host "     Endpoint: /api/backtest/edge" -ForegroundColor Gray
            $testResults["Edge Case Backtest Endpoint"] = $true
        } else {
            Write-Host "  ⚠️  Edge case endpoint: Unexpected status code" -ForegroundColor Yellow
            Write-Host "     Status: $statusCode" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  ❌ Edge case endpoint: Could not test" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n📊 Test Summary" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Gray
$passed = ($testResults.Values | Where-Object { $_ -eq $true }).Count
$total = $testResults.Count
Write-Host "  Passed: $passed / $total" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

foreach ($test in $testResults.GetEnumerator()) {
    $status = if ($test.Value) { "✅" } else { "❌" }
    Write-Host "  $status $($test.Key)" -ForegroundColor $(if ($test.Value) { "Green" } else { "Red" })
}

Write-Host "`n💡 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test with valid auth token and broker credentials" -ForegroundColor Gray
Write-Host "  2. Test with broker data (use_broker_data=true)" -ForegroundColor Gray
Write-Host "  3. Test with VIX simulation (fallback)" -ForegroundColor Gray
Write-Host "  4. Verify results accuracy and performance metrics" -ForegroundColor Gray
Write-Host "  5. Test with multiple symbols and date ranges" -ForegroundColor Gray
Write-Host "`n📋 Test Commands (with valid token):" -ForegroundColor Cyan
Write-Host "  # Realistic backtest" -ForegroundColor Gray
Write-Host "  curl -H 'Authorization: Bearer <token>' '$backendUrl/api/backtest/realistic?use_broker_data=true&symbols=NIFTY,BANKNIFTY&days=20&exchange=NSE'" -ForegroundColor Gray
Write-Host "`n  # Edge case backtest" -ForegroundColor Gray
Write-Host "  curl -H 'Authorization: Bearer <token>' '$backendUrl/api/backtest/edge?use_broker_data=true&symbols=NIFTY&days=20&vix=35.0&exchange=NSE'" -ForegroundColor Gray

