# Test New Admin Account Login & Password Change Flow

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "ADMIN ACCOUNT LOGIN & PASSWORD CHANGE TEST" -ForegroundColor Yellow
Write-Host "======================================================================`n" -ForegroundColor Cyan

$headers = @{"Content-Type"="application/json"}

# Step 1: Login with temporary password
Write-Host "[1] Testing login with temporary password..." -ForegroundColor Cyan
try {
    $body = @{
        email = "vikram@saffronbolt.in"
        password = "AurumAdmin@2025"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -Headers $headers -Body $body -TimeoutSec 10
    
    Write-Host "    [OK] Login successful!" -ForegroundColor Green
    Write-Host "    User: $($response.user.email) ($($response.user.user_code))" -ForegroundColor Gray
    Write-Host "    Admin: $($response.user.is_admin)" -ForegroundColor Gray
    Write-Host "    Force Password Change: $($response.force_password_change)" -ForegroundColor $(if($response.force_password_change){'Yellow'}else{'Gray'})
    
    $Global:AdminToken = $response.token
    
    if ($response.force_password_change) {
        Write-Host "`n    [!] Password change is REQUIRED`n" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [ERROR] Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Check password change requirement
Write-Host "[2] Checking password change requirement..." -ForegroundColor Cyan
try {
    $authHeaders = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $Global:AdminToken"
    }
    
    $checkResponse = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/check-password-change-required" -Method Post -Headers $authHeaders -TimeoutSec 10
    
    Write-Host "    [OK] Check successful!" -ForegroundColor Green
    Write-Host "    Force Change: $($checkResponse.force_password_change)" -ForegroundColor Yellow
    Write-Host "    Message: $($checkResponse.message)" -ForegroundColor Gray
} catch {
    Write-Host "    [ERROR] Check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Change password
Write-Host "`n[3] Testing password change..." -ForegroundColor Cyan
try {
    $changeBody = @{
        current_password = "AurumAdmin@2025"
        new_password = "VikramSecure@2025"
        confirm_password = "VikramSecure@2025"
    } | ConvertTo-Json
    
    $changeResponse = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/change-password" -Method Post -Headers $authHeaders -Body $changeBody -TimeoutSec 10
    
    Write-Host "    [OK] Password changed successfully!" -ForegroundColor Green
    Write-Host "    Message: $($changeResponse.message)" -ForegroundColor Gray
} catch {
    Write-Host "    [ERROR] Password change failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "    [INFO] This is expected if password was already changed" -ForegroundColor Yellow
}

# Step 4: Test new login with new password
Write-Host "`n[4] Testing login with NEW password..." -ForegroundColor Cyan
try {
    $newLoginBody = @{
        email = "vikram@saffronbolt.in"
        password = "VikramSecure@2025"
    } | ConvertTo-Json
    
    $newLoginResponse = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -Headers $headers -Body $newLoginBody -TimeoutSec 10
    
    Write-Host "    [OK] Login with new password successful!" -ForegroundColor Green
    Write-Host "    User: $($newLoginResponse.user.email)" -ForegroundColor Gray
    Write-Host "    Force Password Change: $($newLoginResponse.force_password_change)" -ForegroundColor $(if($newLoginResponse.force_password_change){'Red'}else{'Green'})
    
    if (-not $newLoginResponse.force_password_change) {
        Write-Host "    [OK] Password change flag cleared!" -ForegroundColor Green
    }
} catch {
    Write-Host "    [ERROR] New login failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "    [INFO] Password may not have been changed in step 3" -ForegroundColor Yellow
}

# Step 5: Test admin access
Write-Host "`n[5] Testing admin access to user list..." -ForegroundColor Cyan
try {
    $adminHeaders = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $($newLoginResponse.token)"
    }
    
    $usersResponse = Invoke-RestMethod -Uri "http://localhost:5000/api/admin/users" -Method Get -Headers $adminHeaders -TimeoutSec 10
    
    Write-Host "    [OK] Admin access verified!" -ForegroundColor Green
    Write-Host "    Users in system: $($usersResponse.count)" -ForegroundColor Gray
    
    foreach ($user in $usersResponse.users) {
        $role = if ($user.is_admin) { "ADMIN" } else { "USER" }
        Write-Host "    - $($user.email) ($($user.user_code)) - $role" -ForegroundColor Gray
    }
} catch {
    Write-Host "    [ERROR] Admin access failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE!" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "`nFinal Admin Credentials:" -ForegroundColor Yellow
Write-Host "  Email: vikram@saffronbolt.in" -ForegroundColor White
Write-Host "  Password: VikramSecure@2025" -ForegroundColor White
Write-Host "  (You can change this to your preferred password)" -ForegroundColor Gray
Write-Host "======================================================================" -ForegroundColor Cyan

