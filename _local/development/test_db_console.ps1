# Test Database Console API (Beta Testing)
param(
    [string]$AdminToken = ""
)

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🗄️  DATABASE CONSOLE - BETA TESTING MODE" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Login as admin if no token provided
if ([string]::IsNullOrEmpty($AdminToken)) {
    Write-Host "🔐 Logging in as admin..." -ForegroundColor Yellow
    $headers = @{"Content-Type"="application/json"}
    $body = @{email="admin@aurumharmony.com"; password="admin123"} | ConvertTo-Json
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -Headers $headers -Body $body
    $AdminToken = $response.token
    Write-Host "✅ Logged in successfully`n" -ForegroundColor Green
}

$authHeaders = @{
    "Content-Type"="application/json"
    "Authorization"="Bearer $AdminToken"
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "1️⃣  TEST: Get Console Status" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray

try {
    $status = Invoke-RestMethod -Uri "http://localhost:5000/api/admin/console/status" -Method Get
    Write-Host "✅ Console Status:" -ForegroundColor Green
    Write-Host "   Beta Mode: $($status.beta_mode_enabled)" -ForegroundColor $(if($status.beta_mode_enabled){'Yellow'}else{'Red'})
    Write-Host "   Access: $($status.console_access)" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "❌ Console not available: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Hint: Register db_console_bp in Master_AurumHarmony_261125.py`n" -ForegroundColor Yellow
    exit 1
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "2️⃣  TEST: Get All Users (WITHOUT Sensitive Data)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray

try {
    $users = Invoke-RestMethod -Uri "http://localhost:5000/api/admin/console/users/all?show_sensitive=false" -Method Get -Headers $authHeaders
    Write-Host "✅ Found $($users.count) users (Safe Mode)" -ForegroundColor Green
    foreach ($user in $users.users) {
        Write-Host "`n  User: $($user.email) ($($user.user_code))" -ForegroundColor White
        Write-Host "    - Initial Capital: ₹$($user.initial_capital)" -ForegroundColor Gray
        Write-Host "    - Active: $($user.is_active)" -ForegroundColor Gray
        Write-Host "    - Admin: $($user.is_admin)" -ForegroundColor Gray
        Write-Host "    - Password Hash: $(if($user.password_hash){'❌ EXPOSED!'}else{'✅ Hidden'})" -ForegroundColor $(if($user.password_hash){'Red'}else{'Green'})
    }
    Write-Host ""
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "3️⃣  TEST: Get All Users (WITH Sensitive Data) - BETA ONLY" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray

try {
    $usersWithSensitive = Invoke-RestMethod -Uri "http://localhost:5000/api/admin/console/users/all?show_sensitive=true" -Method Get -Headers $authHeaders
    Write-Host "⚠️  Found $($usersWithSensitive.count) users (BETA MODE - ALL DATA)" -ForegroundColor Yellow
    foreach ($user in $usersWithSensitive.users) {
        Write-Host "`n  User: $($user.email) ($($user.user_code))" -ForegroundColor White
        Write-Host "    - Initial Capital: ₹$($user.initial_capital)" -ForegroundColor Gray
        Write-Host "    - Password Hash: $(if($user.password_hash){$user.password_hash.Substring(0,20)+'...'}else{'none'})" -ForegroundColor Yellow
        Write-Host "    - Broker Credentials: $($user.broker_credentials.Count) connected" -ForegroundColor Gray
        Write-Host "    - Active Sessions: $($user.sessions.Count)" -ForegroundColor Gray
    }
    Write-Host ""
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "4️⃣  TEST: Get Single User Full Details" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor DarkGray

try {
    $userDetail = Invoke-RestMethod -Uri "http://localhost:5000/api/admin/console/users/3/full?show_sensitive=true" -Method Get -Headers $authHeaders
    Write-Host "✅ Full User Details:" -ForegroundColor Green
    $userDetail.user | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ DATABASE CONSOLE TESTS COMPLETE" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

