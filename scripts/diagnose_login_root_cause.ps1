# Comprehensive Login Root Cause Diagnostic
# Tests each step of the login flow to identify the exact issue

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "`n=== LOGIN ROOT CAUSE DIAGNOSTIC ===" -ForegroundColor Cyan
Write-Host "Testing each step of the login flow...`n" -ForegroundColor Gray

# Step 1: Check what URL Flutter is using
Write-Host "[STEP 1] Checking Flutter Constants..." -ForegroundColor Yellow
$constantsFile = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app\lib\constants.dart"
if (Test-Path $constantsFile) {
    $constants = Get-Content $constantsFile -Raw
    Write-Host "   ✅ Constants file found" -ForegroundColor Green
    
    if ($constants -match "kBackendBaseUrl.*=.*'(.*)'") {
        Write-Host "   📍 Production URL: https://api.ah.saffronbolt.in" -ForegroundColor Cyan
    }
    if ($constants -match "kBackendBaseUrlFallback.*=.*'(.*)'") {
        Write-Host "   📍 Fallback URL: http://localhost:5000" -ForegroundColor Cyan
    }
} else {
    Write-Host "   ❌ Constants file not found" -ForegroundColor Red
}

# Step 2: Test Worker API directly
Write-Host "`n[STEP 2] Testing Worker API (https://api.ah.saffronbolt.in)..." -ForegroundColor Yellow
$workerHealth = $null
$workerLogin = $null

try {
    $workerHealth = Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/health" -Method Get -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✅ Health endpoint: Status $($workerHealth.StatusCode)" -ForegroundColor Green
    Write-Host "      Response: $($workerHealth.Content)" -ForegroundColor Gray
} catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { "N/A" }
    Write-Host "   ❌ Health endpoint failed: $statusCode" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host "`n   Testing login endpoint..." -ForegroundColor Yellow
try {
    $loginBody = @{email="test@test.com";password="test123"} | ConvertTo-Json
    $workerLogin = Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/api/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json" `
        -TimeoutSec 10 `
        -UseBasicParsing `
        -ErrorAction Stop
    
    Write-Host "   ⚠️  Login endpoint returned: Status $($workerLogin.StatusCode)" -ForegroundColor Yellow
    Write-Host "      Response: $($workerLogin.Content)" -ForegroundColor Gray
} catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { "N/A" }
    $responseBody = if ($_.Exception.Response) { 
        try {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $reader.ReadToEnd()
        } catch {
            try {
                $_.Exception.Response.Content.ReadAsStringAsync().Result
            } catch {
                "Unable to read response"
            }
        }
    } else { "N/A" }
    
    Write-Host "   📊 Login endpoint response:" -ForegroundColor Cyan
    Write-Host "      Status Code: $statusCode" -ForegroundColor White
    Write-Host "      Response Body: $responseBody" -ForegroundColor Gray
    
    if ($statusCode -eq 503) {
        Write-Host "   ✅ Expected: 503 = Database not configured (triggers fallback)" -ForegroundColor Green
    } elseif ($statusCode -eq 501) {
        Write-Host "   ✅ Expected: 501 = bcrypt not supported (triggers fallback)" -ForegroundColor Green
    } elseif ($statusCode -eq 401) {
        Write-Host "   ✅ Expected: 401 = Invalid credentials (Worker is working!)" -ForegroundColor Green
    } elseif ($statusCode -eq "N/A") {
        Write-Host "   ❌ CRITICAL: Cannot reach Worker (network error)" -ForegroundColor Red
        Write-Host "      This should trigger Flutter fallback to Flask" -ForegroundColor Yellow
    } else {
        Write-Host "   ⚠️  Unexpected status: $statusCode" -ForegroundColor Yellow
    }
}

# Step 3: Test Flask Backend
Write-Host "`n[STEP 3] Testing Flask Backend (http://localhost:5000)..." -ForegroundColor Yellow
$flaskHealth = $null
$flaskLogin = $null

try {
    $flaskHealth = Invoke-WebRequest -Uri "http://localhost:5000/health" -Method Get -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✅ Flask backend is running: Status $($flaskHealth.StatusCode)" -ForegroundColor Green
    Write-Host "      Response: $($flaskHealth.Content)" -ForegroundColor Gray
    $flaskRunning = $true
} catch {
    Write-Host "   ❌ Flask backend is NOT running" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Gray
    $flaskRunning = $false
}

if ($flaskRunning) {
    Write-Host "`n   Testing Flask login endpoint..." -ForegroundColor Yellow
    try {
        $loginBody = @{email="test@test.com";password="test123"} | ConvertTo-Json
        $flaskLogin = Invoke-WebRequest -Uri "http://localhost:5000/api/auth/login" `
            -Method Post `
            -Body $loginBody `
            -ContentType "application/json" `
            -TimeoutSec 5 `
            -UseBasicParsing `
            -ErrorAction Stop
        
        Write-Host "   ⚠️  Flask login returned: Status $($flaskLogin.StatusCode)" -ForegroundColor Yellow
    } catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { "N/A" }
        $responseBody = if ($_.Exception.Response) { 
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.ReadToEnd()
        } else { "N/A" }
        
        Write-Host "   📊 Flask login response:" -ForegroundColor Cyan
        Write-Host "      Status Code: $statusCode" -ForegroundColor White
        Write-Host "      Response Body: $responseBody" -ForegroundColor Gray
        
        if ($statusCode -eq 401) {
            Write-Host "   ✅ Expected: 401 = Invalid credentials (Flask is working!)" -ForegroundColor Green
        }
    }
}

# Step 4: Check Flutter auth service logic
Write-Host "`n[STEP 4] Analyzing Flutter Auth Service Logic..." -ForegroundColor Yellow
$authService = Join-Path $projectRoot "aurum_harmony\frontend\flutter_app\lib\services\auth_service.dart"
if (Test-Path $authService) {
    $content = Get-Content $authService -Raw
    
    # Check fallback logic
    if ($content -match "if \(apiUrl != kBackendBaseUrlFallback\)") {
        Write-Host "   ✅ Fallback logic exists (line ~127)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Fallback logic missing!" -ForegroundColor Red
    }
    
    # Check error detection
    $errorPatterns = @(
        "SERVICE_UNAVAILABLE",
        "BCRYPT_FALLBACK",
        "networkerror",
        "timeout",
        "socketexception"
    )
    
    $foundPatterns = @()
    foreach ($pattern in $errorPatterns) {
        if ($content -match $pattern) {
            $foundPatterns += $pattern
        }
    }
    
    Write-Host "   📊 Error detection patterns found: $($foundPatterns.Count)/$($errorPatterns.Count)" -ForegroundColor Cyan
    foreach ($pattern in $foundPatterns) {
        Write-Host "      ✅ $pattern" -ForegroundColor Green
    }
    foreach ($pattern in ($errorPatterns | Where-Object { $foundPatterns -notcontains $_ })) {
        Write-Host "      ❌ Missing: $pattern" -ForegroundColor Red
    }
    
    # Check if error message is shown even after fallback
    if ($content -match "Cannot connect to Cloudflare Worker API") {
        $lines = $content -split "`n"
        $errorLine = ($lines | Select-String "Cannot connect to Cloudflare Worker API").LineNumber
        Write-Host "`n   ⚠️  Error message found at line ~$errorLine" -ForegroundColor Yellow
        Write-Host "      This message is shown when BOTH Worker AND Flask fail" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ Auth service file not found" -ForegroundColor Red
}

# Step 5: Simulate the exact Flutter flow
Write-Host "`n[STEP 5] Simulating Flutter Login Flow..." -ForegroundColor Yellow

Write-Host "   Scenario 1: Worker unreachable → Should fallback to Flask" -ForegroundColor Cyan
if (-not $flaskRunning) {
    Write-Host "   ❌ PROBLEM: Flask backend is not running!" -ForegroundColor Red
    Write-Host "      Flutter will try Worker → fail → try Flask → fail → show error" -ForegroundColor Yellow
    Write-Host "      SOLUTION: Start Flask backend first" -ForegroundColor Green
} else {
    Write-Host "   ✅ Flask is running - fallback should work" -ForegroundColor Green
}

Write-Host "`n   Scenario 2: Worker returns 503 → Should fallback to Flask" -ForegroundColor Cyan
if ($workerLogin -and $workerLogin.StatusCode -eq 503) {
    Write-Host "   ✅ Worker returns 503 - Flutter should detect and fallback" -ForegroundColor Green
    if (-not $flaskRunning) {
        Write-Host "   ❌ But Flask is not running - fallback will fail!" -ForegroundColor Red
    }
}

Write-Host "`n   Scenario 3: Worker returns 501 → Should fallback to Flask" -ForegroundColor Cyan
if ($workerLogin -and $workerLogin.StatusCode -eq 501) {
    Write-Host "   ✅ Worker returns 501 - Flutter should detect and fallback" -ForegroundColor Green
    if (-not $flaskRunning) {
        Write-Host "   ❌ But Flask is not running - fallback will fail!" -ForegroundColor Red
    }
}

# Step 6: Root Cause Analysis
Write-Host "`n=== ROOT CAUSE ANALYSIS ===" -ForegroundColor Cyan
Write-Host ""

$rootCause = @()

if (-not $flaskRunning) {
    $rootCause += "❌ CRITICAL: Flask backend is not running"
    $rootCause += "   → Flutter tries Worker → fails → tries Flask → fails → shows error"
    $rootCause += "   → FIX: Start Flask backend: .\start-all.ps1 → Option 1"
}

if ($workerLogin -and $workerLogin.StatusCode -in @(503, 501)) {
    $rootCause += "✅ Worker is responding correctly with $($workerLogin.StatusCode)"
    $rootCause += "   → Flutter should detect this and fallback to Flask"
    if (-not $flaskRunning) {
        $rootCause += "   → But Flask is not running, so fallback fails"
    }
}

if ($workerLogin -eq $null -and $workerHealth -eq $null) {
    $rootCause += "❌ Worker API is completely unreachable (network error)"
    $rootCause += "   → Flutter should detect network error and fallback to Flask"
    if (-not $flaskRunning) {
        $rootCause += "   → But Flask is not running, so fallback fails"
    }
}

if ($rootCause.Count -eq 0) {
    Write-Host "✅ All systems appear to be working correctly" -ForegroundColor Green
    Write-Host "   If login still fails, check:" -ForegroundColor Yellow
    Write-Host "   1. Browser console for detailed errors" -ForegroundColor Gray
    Write-Host "   2. Flutter logs: _local\logs\flutter.log" -ForegroundColor Gray
    Write-Host "   3. Backend logs: _local\logs\backend.log" -ForegroundColor Gray
    Write-Host "   4. User credentials in database" -ForegroundColor Gray
} else {
    foreach ($cause in $rootCause) {
        Write-Host $cause -ForegroundColor $(if ($cause -match "❌") { "Red" } elseif ($cause -match "✅") { "Green" } else { "Yellow" })
    }
}

Write-Host "`n=== RECOMMENDED FIX ===" -ForegroundColor Cyan
if (-not $flaskRunning) {
    Write-Host "1. Start Flask backend: .\start-all.ps1 → Option 1" -ForegroundColor Green
    Write-Host "2. Wait 5 seconds for backend to start" -ForegroundColor Yellow
    Write-Host "3. Try login again" -ForegroundColor Yellow
} else {
    Write-Host "✅ Flask backend is running - login should work!" -ForegroundColor Green
    Write-Host "   If it still fails, the issue is likely:" -ForegroundColor Yellow
    Write-Host "   • User doesn't exist in database" -ForegroundColor Gray
    Write-Host "   • Wrong password" -ForegroundColor Gray
    Write-Host "   • CORS issue (check browser console)" -ForegroundColor Gray
    Write-Host "   • Flutter app needs rebuild (changes not applied)" -ForegroundColor Gray
}

Write-Host ""

