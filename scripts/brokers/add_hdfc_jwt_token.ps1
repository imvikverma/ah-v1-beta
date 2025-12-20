# Add HDFC Sky JWT Token to .env
# After extracting the token from browser

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "HDFC Sky JWT Token Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get token from user
Write-Host "📋 Step 1: Get JWT Token from Browser" -ForegroundColor Yellow
Write-Host ""
Write-Host "To get the token:" -ForegroundColor Cyan
Write-Host "  1. Open Developer Tools (F12)" -ForegroundColor White
Write-Host "  2. Go to Network tab" -ForegroundColor White
Write-Host "  3. Find any API call (like /update-im-app-details)" -ForegroundColor White
Write-Host "  4. Click on it → Headers tab" -ForegroundColor White
Write-Host "  5. Look for 'Authorization' header" -ForegroundColor White
Write-Host "  6. Copy the JWT token (the long string)" -ForegroundColor White
Write-Host ""

$jwtToken = Read-Host "Paste the JWT token here"

if ([string]::IsNullOrWhiteSpace($jwtToken)) {
    Write-Host "❌ No token provided" -ForegroundColor Red
    exit 1
}

# Remove "Bearer " prefix if present
if ($jwtToken -match '^Bearer\s+(.+)$') {
    $jwtToken = $matches[1]
    Write-Host "ℹ️  Removed 'Bearer ' prefix" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "✅ Token received: $($jwtToken.Substring(0, [Math]::Min(50, $jwtToken.Length)))..." -ForegroundColor Green
Write-Host ""

# Read existing .env
$envFile = ".env"
$envContent = @()
if (Test-Path $envFile) {
    $envContent = Get-Content $envFile
}

# Remove existing HDFC_SKY_ACCESS_TOKEN if present
$newContent = @()
$tokenFound = $false
foreach ($line in $envContent) {
    if ($line -match '^HDFC_SKY_ACCESS_TOKEN\s*=') {
        $newContent += "HDFC_SKY_ACCESS_TOKEN=$jwtToken"
        $tokenFound = $true
    } else {
        $newContent += $line
    }
}

# Add token if not found
if (-not $tokenFound) {
    $newContent += ""
    $newContent += "# HDFC Sky JWT Token (from web login)"
    $newContent += "HDFC_SKY_ACCESS_TOKEN=$jwtToken"
}

# Write to .env
$newContent | Set-Content $envFile -Encoding UTF8

Write-Host "✅ Token saved to .env file!" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: Test the connection" -ForegroundColor Yellow
Write-Host "  python scripts/brokers/test_hdfc_connection.py" -ForegroundColor Green
Write-Host ""

