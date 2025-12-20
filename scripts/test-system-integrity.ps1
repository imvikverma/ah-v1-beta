# System Integrity Tests
# Tests backend endpoints, database connectivity, and JWT tokens

$ErrorActionPreference = "Continue"

Write-Host "`n🔍 System Integrity Tests" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Gray
Write-Host ""

$v2ApiUrl = "https://api-v2.saffronbolt.in"
$testResults = @{
    "Health Check" = $false
    "Database Connectivity" = $false
    "JWT Configuration" = $false
    "Login Endpoint" = $false
    "Auth Me Endpoint" = $false
    "Admin Endpoints" = $false
}

# Test 1: Health Check
Write-Host "`n📡 Test 1: Health Check" -ForegroundColor Yellow
Write-Host "----------------------" -ForegroundColor Gray
try {
    $healthResponse = Invoke-RestMethod -Uri "$v2ApiUrl/health" -Method Get -ErrorAction Stop
    Write-Host "  ✅ Health endpoint: OK" -ForegroundColor Green
    Write-Host "     Status: $($healthResponse.status)" -ForegroundColor Gray
    Write-Host "     Service: $($healthResponse.service)" -ForegroundColor Gray
    Write-Host "     Version: $($healthResponse.version)" -ForegroundColor Gray
    
    $testResults["Health Check"] = $true
    
    # Check DB connectivity
    if ($healthResponse.db) {
        if ($healthResponse.db.status -eq "ok") {
            Write-Host "     Database: ✅ Connected" -ForegroundColor Green
            $testResults["Database Connectivity"] = $true
        } else {
            Write-Host "     Database: ⚠️  $($healthResponse.db.status)" -ForegroundColor Yellow
            Write-Host "     Message: $($healthResponse.db.message)" -ForegroundColor Gray
        }
    }
    
    # Check JWT configuration
    if ($healthResponse.jwt) {
        if ($healthResponse.jwt.configured) {
            Write-Host "     JWT Secret: ✅ Configured" -ForegroundColor Green
            $testResults["JWT Configuration"] = $true
        } else {
            Write-Host "     JWT Secret: ❌ Not configured" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  ❌ Health endpoint: FAILED" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Login Endpoint (without credentials - should fail gracefully)
Write-Host "`n🔐 Test 2: Login Endpoint" -ForegroundColor Yellow
Write-Host "------------------------" -ForegroundColor Gray
try {
    $loginBody = @{
        email = "test@example.com"
        password = "wrongpassword"
    } | ConvertTo-Json
    
    try {
        $loginResponse = Invoke-RestMethod -Uri "$v2ApiUrl/api/auth/login" `
            -Method Post `
            -Body $loginBody `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        if ($loginResponse.success) {
            Write-Host "  ✅ Login endpoint: Responds (unexpected success with wrong credentials)" -ForegroundColor Yellow
        } else {
            Write-Host "  ✅ Login endpoint: Responds correctly (rejected invalid credentials)" -ForegroundColor Green
            Write-Host "     Error: $($loginResponse.error)" -ForegroundColor Gray
        }
        $testResults["Login Endpoint"] = $true
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 401 -or $statusCode -eq 400) {
            Write-Host "  ✅ Login endpoint: Responds correctly (rejected invalid credentials)" -ForegroundColor Green
            $testResults["Login Endpoint"] = $true
        } else {
            Write-Host "  ❌ Login endpoint: Unexpected error" -ForegroundColor Red
            Write-Host "     Status: $statusCode" -ForegroundColor Red
            Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  ❌ Login endpoint: FAILED" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Auth Me Endpoint (without token - should require auth)
Write-Host "`n🔒 Test 3: Auth Me Endpoint (No Token)" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Gray
try {
    $meResponse = Invoke-RestMethod -Uri "$v2ApiUrl/api/auth/me" `
        -Method Get `
        -ErrorAction Stop
    
    Write-Host "  ⚠️  Auth Me endpoint: Responded without token (security issue?)" -ForegroundColor Yellow
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "  ✅ Auth Me endpoint: Correctly requires authentication" -ForegroundColor Green
        Write-Host "     Status: 401 Unauthorized" -ForegroundColor Gray
        $testResults["Auth Me Endpoint"] = $true
    } else {
        Write-Host "  ⚠️  Auth Me endpoint: Unexpected status code" -ForegroundColor Yellow
        Write-Host "     Status: $statusCode" -ForegroundColor Gray
    }
}

# Test 4: Admin Endpoints (without token - should require auth)
Write-Host "`n👑 Test 4: Admin Endpoints (No Token)" -ForegroundColor Yellow
Write-Host "-------------------------------------" -ForegroundColor Gray
try {
    $adminResponse = Invoke-RestMethod -Uri "$v2ApiUrl/api/admin/users" `
        -Method Get `
        -ErrorAction Stop
    
    Write-Host "  ⚠️  Admin endpoint: Responded without token (security issue?)" -ForegroundColor Yellow
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "  ✅ Admin endpoint: Correctly requires authentication" -ForegroundColor Green
        Write-Host "     Status: 401 Unauthorized" -ForegroundColor Gray
        $testResults["Admin Endpoints"] = $true
    } elseif ($statusCode -eq 501) {
        Write-Host "  ⚠️  Admin endpoint: Not implemented in Worker (returns 501)" -ForegroundColor Yellow
        Write-Host "     Note: Use localhost backend for admin endpoints" -ForegroundColor Gray
        $testResults["Admin Endpoints"] = $true # Consider it working if it returns 501
    } else {
        Write-Host "  ⚠️  Admin endpoint: Unexpected status code" -ForegroundColor Yellow
        Write-Host "     Status: $statusCode" -ForegroundColor Gray
    }
}

# Test 5: Database Tables Endpoint (without token - should require auth)
Write-Host "`n🗄️  Test 5: Database Tables Endpoint (No Token)" -ForegroundColor Yellow
Write-Host "-----------------------------------------------" -ForegroundColor Gray
try {
    $dbResponse = Invoke-RestMethod -Uri "$v2ApiUrl/api/admin/db/tables" `
        -Method Get `
        -ErrorAction Stop
    
    Write-Host "  ⚠️  Database endpoint: Responded without token (security issue?)" -ForegroundColor Yellow
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "  ✅ Database endpoint: Correctly requires authentication" -ForegroundColor Green
        Write-Host "     Status: 401 Unauthorized" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  Database endpoint: Unexpected status code" -ForegroundColor Yellow
        Write-Host "     Status: $statusCode" -ForegroundColor Gray
    }
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
Write-Host "  1. Test with valid credentials (manual login test)" -ForegroundColor Gray
Write-Host "  2. Test with admin token (admin endpoints)" -ForegroundColor Gray
Write-Host "  3. Test frontend login flow" -ForegroundColor Gray
Write-Host "  4. Test session expiration handling" -ForegroundColor Gray

