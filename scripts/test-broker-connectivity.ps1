# Broker API Connectivity Tests
# Tests HDFC Sky and Kotak Neo broker API endpoints

$ErrorActionPreference = "Continue"

Write-Host "`n🔌 Broker API Connectivity Tests" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Gray
Write-Host ""

$backendUrl = "http://localhost:5000"
$testResults = @{
    "Backend Running" = $false
    "Broker List Endpoint" = $false
    "HDFC Sky Endpoints" = $false
    "Kotak Neo Endpoints" = $false
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
    Write-Host "  ❌ Backend is not running" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n💡 Start the backend first:" -ForegroundColor Yellow
    Write-Host "     .\start-backend.ps1" -ForegroundColor Gray
    Write-Host "     OR" -ForegroundColor Gray
    Write-Host "     .\start-all.ps1 → Option 1" -ForegroundColor Gray
    exit 1
}

# Test 2: Broker List Endpoint (requires auth)
Write-Host "`n📋 Test 2: Broker List Endpoint" -ForegroundColor Yellow
Write-Host "-----------------------------" -ForegroundColor Gray
try {
    $listResponse = Invoke-RestMethod -Uri "$backendUrl/api/brokers/list" `
        -Method Get `
        -ErrorAction Stop
    
    Write-Host "  ⚠️  Broker list endpoint: Responded without token (security issue?)" -ForegroundColor Yellow
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "  ✅ Broker list endpoint: Correctly requires authentication" -ForegroundColor Green
        Write-Host "     Status: 401 Unauthorized" -ForegroundColor Gray
        $testResults["Broker List Endpoint"] = $true
    } else {
        Write-Host "  ⚠️  Broker list endpoint: Unexpected status code" -ForegroundColor Yellow
        Write-Host "     Status: $statusCode" -ForegroundColor Gray
    }
}

# Test 3: HDFC Sky Endpoints
Write-Host "`n🏦 Test 3: HDFC Sky Endpoints" -ForegroundColor Yellow
Write-Host "---------------------------" -ForegroundColor Gray

# Test HDFC connect endpoint (requires auth)
try {
    $hdfcConnectBody = @{
        broker_name = "HDFC_SKY"
        api_key = "test_key"
        api_secret = "test_secret"
    } | ConvertTo-Json
    
    try {
        $hdfcResponse = Invoke-RestMethod -Uri "$backendUrl/api/brokers/hdfc/connect" `
            -Method Post `
            -Body $hdfcConnectBody `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        Write-Host "  ⚠️  HDFC connect endpoint: Responded without token (security issue?)" -ForegroundColor Yellow
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401) {
            Write-Host "  ✅ HDFC connect endpoint: Correctly requires authentication" -ForegroundColor Green
            Write-Host "     Status: 401 Unauthorized" -ForegroundColor Gray
            $testResults["HDFC Sky Endpoints"] = $true
        } else {
            Write-Host "  ⚠️  HDFC connect endpoint: Unexpected status code" -ForegroundColor Yellow
            Write-Host "     Status: $statusCode" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  ⚠️  HDFC Sky endpoints: Could not test" -ForegroundColor Yellow
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Gray
}

# Test 4: Kotak Neo Endpoints
Write-Host "`n🏦 Test 4: Kotak Neo Endpoints" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Gray

# Test Kotak TOTP login endpoint
try {
    $kotakTotpBody = @{
        user_id = "test_user"
        totp = "123456"
    } | ConvertTo-Json
    
    try {
        $kotakResponse = Invoke-RestMethod -Uri "$backendUrl/api/brokers/kotak/login/totp" `
            -Method Post `
            -Body $kotakTotpBody `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        Write-Host "  ⚠️  Kotak TOTP endpoint: Responded (may not require auth for login)" -ForegroundColor Yellow
        $testResults["Kotak Neo Endpoints"] = $true
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 400 -or $statusCode -eq 401) {
            Write-Host "  ✅ Kotak TOTP endpoint: Responds correctly" -ForegroundColor Green
            Write-Host "     Status: $statusCode" -ForegroundColor Gray
            $testResults["Kotak Neo Endpoints"] = $true
        } else {
            Write-Host "  ⚠️  Kotak TOTP endpoint: Unexpected status code" -ForegroundColor Yellow
            Write-Host "     Status: $statusCode" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  ⚠️  Kotak Neo endpoints: Could not test" -ForegroundColor Yellow
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Gray
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
Write-Host "  1. Test with valid credentials and auth token" -ForegroundColor Gray
Write-Host "  2. Test actual broker connection (requires API keys)" -ForegroundColor Gray
Write-Host "  3. Test order placement (paper trading mode)" -ForegroundColor Gray
Write-Host "  4. Test position tracking" -ForegroundColor Gray
Write-Host "  5. Test market data fetching" -ForegroundColor Gray
Write-Host "`n⚠️  Note: Broker API tests require:" -ForegroundColor Yellow
Write-Host "     - Valid broker API credentials" -ForegroundColor Gray
Write-Host "     - Authentication token" -ForegroundColor Gray
Write-Host "     - Backend running on localhost:5000" -ForegroundColor Gray

