# Test Session Expired Fix
# Verifies that the 5-minute grace period works correctly

$ErrorActionPreference = "Continue"

Write-Host "`n🔍 Testing Session Expired Fix" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Gray
Write-Host ""

# Test v1 API
Write-Host "`n📡 Testing v1 API (api.ah.saffronbolt.in)" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

try {
    $healthResponse = Invoke-RestMethod -Uri "https://api.ah.saffronbolt.in/health" -Method Get -ErrorAction Stop
    Write-Host "  ✅ v1 Health endpoint: OK" -ForegroundColor Green
    Write-Host "     Status: $($healthResponse.status)" -ForegroundColor Gray
    Write-Host "     Service: $($healthResponse.service)" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ v1 Health endpoint: FAILED" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test v2 API
Write-Host "`n📡 Testing v2 API (api-v2.saffronbolt.in)" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

try {
    $healthResponse = Invoke-RestMethod -Uri "https://api-v2.saffronbolt.in/health" -Method Get -ErrorAction Stop
    Write-Host "  ✅ v2 Health endpoint: OK" -ForegroundColor Green
    Write-Host "     Status: $($healthResponse.status)" -ForegroundColor Gray
    Write-Host "     Service: $($healthResponse.service)" -ForegroundColor Gray
    Write-Host "     Version: $($healthResponse.version)" -ForegroundColor Gray
    if ($healthResponse.diagnostic_tag) {
        Write-Host "     Diagnostic Tag: $($healthResponse.diagnostic_tag)" -ForegroundColor Gray
    }
    
    # Check DB connectivity
    if ($healthResponse.db) {
        if ($healthResponse.db.status -eq "ok") {
            Write-Host "     Database: ✅ Connected" -ForegroundColor Green
        } else {
            Write-Host "     Database: ⚠️  $($healthResponse.db.status)" -ForegroundColor Yellow
            Write-Host "     Message: $($healthResponse.db.message)" -ForegroundColor Gray
        }
    }
    
    # Check JWT configuration
    if ($healthResponse.jwt) {
        if ($healthResponse.jwt.configured) {
            Write-Host "     JWT Secret: ✅ Configured" -ForegroundColor Green
        } else {
            Write-Host "     JWT Secret: ❌ Not configured" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  ❌ v2 Health endpoint: FAILED" -ForegroundColor Red
    Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test login endpoint (v2)
Write-Host "`n🔐 Testing Login Endpoint (v2)" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Gray

$testEmail = Read-Host "  Enter test email (or press Enter to skip)"
if ([string]::IsNullOrWhiteSpace($testEmail)) {
    Write-Host "  ⏭️  Skipping login test (no email provided)" -ForegroundColor Yellow
} else {
    $testPassword = Read-Host "  Enter test password" -AsSecureString
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($testPassword)
    )
    
    try {
        $loginBody = @{
            email = $testEmail
            password = $plainPassword
        } | ConvertTo-Json
        
        $loginResponse = Invoke-RestMethod -Uri "https://api-v2.saffronbolt.in/api/auth/login" `
            -Method Post `
            -Body $loginBody `
            -ContentType "application/json" `
            -ErrorAction Stop
        
        if ($loginResponse.success -and $loginResponse.token) {
            Write-Host "  ✅ Login successful!" -ForegroundColor Green
            Write-Host "     Token received: $($loginResponse.token.Substring(0, 20))..." -ForegroundColor Gray
            
            $token = $loginResponse.token
            
            # Test /api/auth/me immediately after login (should work due to grace period)
            Write-Host "`n  🧪 Testing /api/auth/me immediately after login..." -ForegroundColor Cyan
            try {
                $meResponse = Invoke-RestMethod -Uri "https://api-v2.saffronbolt.in/api/auth/me" `
                    -Method Get `
                    -Headers @{
                        "Authorization" = "Bearer $token"
                        "Content-Type" = "application/json"
                    } `
                    -ErrorAction Stop
                
                Write-Host "     ✅ /api/auth/me succeeded immediately after login" -ForegroundColor Green
                Write-Host "        User: $($meResponse.user.email)" -ForegroundColor Gray
            } catch {
                Write-Host "     ❌ /api/auth/me failed immediately after login" -ForegroundColor Red
                Write-Host "        Error: $($_.Exception.Message)" -ForegroundColor Red
            }
            
            # Wait 1 minute and test again (still within grace period)
            Write-Host "`n  ⏳ Waiting 1 minute (still within 5-minute grace period)..." -ForegroundColor Cyan
            Start-Sleep -Seconds 60
            
            try {
                $meResponse = Invoke-RestMethod -Uri "https://api-v2.saffronbolt.in/api/auth/me" `
                    -Method Get `
                    -Headers @{
                        "Authorization" = "Bearer $token"
                        "Content-Type" = "application/json"
                    } `
                    -ErrorAction Stop
                
                Write-Host "     ✅ /api/auth/me succeeded after 1 minute (within grace period)" -ForegroundColor Green
            } catch {
                Write-Host "     ❌ /api/auth/me failed after 1 minute" -ForegroundColor Red
                Write-Host "        Error: $($_.Exception.Message)" -ForegroundColor Red
            }
            
            Write-Host "`n  💡 Note: Full 5-minute grace period test requires manual frontend testing" -ForegroundColor Yellow
            Write-Host "     The frontend skips validation during grace period, so API calls" -ForegroundColor Gray
            Write-Host "     will work. Test in browser to verify no 'session expired' error." -ForegroundColor Gray
            
        } else {
            Write-Host "  ❌ Login failed: $($loginResponse.error)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Login request failed" -ForegroundColor Red
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n✅ Session Expired Fix Test Complete!" -ForegroundColor Green
Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Test login on v1 frontend: https://ah.saffronbolt.in" -ForegroundColor Gray
Write-Host "  2. Test login on v2 frontend: https://ah-v2.saffronbolt.in" -ForegroundColor Gray
Write-Host "  3. Verify no 'session expired' error for 5 minutes after login" -ForegroundColor Gray
Write-Host "  4. Make multiple API calls immediately after login" -ForegroundColor Gray
Write-Host "  5. Check browser console for any errors" -ForegroundColor Gray

