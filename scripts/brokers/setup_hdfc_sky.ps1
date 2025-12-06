# HDFC Sky Setup Helper
# This script helps you set up HDFC Sky API credentials

Write-Host "`n=== HDFC Sky API Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if .env exists
if (-not (Test-Path .env)) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    New-Item -Path .env -ItemType File | Out-Null
}

# Check current credentials
Write-Host "Checking current credentials..." -ForegroundColor Yellow
$envContent = Get-Content .env -ErrorAction SilentlyContinue

$hasApiKey = $envContent | Select-String "^HDFC_SKY_API_KEY="
$hasApiSecret = $envContent | Select-String "^HDFC_SKY_API_SECRET="
$hasRequestToken = $envContent | Select-String "^HDFC_SKY_REQUEST_TOKEN="

if ($hasApiKey) {
    Write-Host "✅ HDFC_SKY_API_KEY found" -ForegroundColor Green
} else {
    Write-Host "❌ HDFC_SKY_API_KEY missing" -ForegroundColor Red
    $apiKey = Read-Host "Enter your HDFC Sky API Key"
    if ($apiKey) {
        Add-Content -Path .env -Value "HDFC_SKY_API_KEY=$apiKey"
        Write-Host "✅ API Key added" -ForegroundColor Green
    }
}

if ($hasApiSecret) {
    Write-Host "✅ HDFC_SKY_API_SECRET found" -ForegroundColor Green
} else {
    Write-Host "❌ HDFC_SKY_API_SECRET missing" -ForegroundColor Red
    $apiSecret = Read-Host "Enter your HDFC Sky API Secret"
    if ($apiSecret) {
        Add-Content -Path .env -Value "HDFC_SKY_API_SECRET=$apiSecret"
        Write-Host "✅ API Secret added" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""

if (-not $hasRequestToken) {
    Write-Host "📝 You need to get a REQUEST TOKEN from HDFC Sky:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Visit: https://developer.hdfcsky.com" -ForegroundColor White
    Write-Host "2. Log in with your HDFC Sky account" -ForegroundColor White
    Write-Host "3. Navigate to OAuth/Authorization section" -ForegroundColor White
    Write-Host "4. Generate a request token" -ForegroundColor White
    Write-Host "5. Copy the request token" -ForegroundColor White
    Write-Host ""
    Write-Host "Then run this script again or add manually:" -ForegroundColor Yellow
    Write-Host "  Add-Content -Path .env -Value 'HDFC_SKY_REQUEST_TOKEN=your_token_here'" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "✅ All credentials found!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Test your setup:" -ForegroundColor Yellow
    Write-Host "  python config/get_token.py" -ForegroundColor White
    Write-Host ""
    Write-Host "This will get your access token from HDFC Sky." -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Current Status ===" -ForegroundColor Cyan
Write-Host "API Key: $(if ($hasApiKey) { '✅ Set' } else { '❌ Missing' })" -ForegroundColor $(if ($hasApiKey) { 'Green' } else { 'Red' })
Write-Host "API Secret: $(if ($hasApiSecret) { '✅ Set' } else { '❌ Missing' })" -ForegroundColor $(if ($hasApiSecret) { 'Green' } else { 'Red' })
Write-Host "Request Token: $(if ($hasRequestToken) { '✅ Set' } else { '❌ Missing' })" -ForegroundColor $(if ($hasRequestToken) { 'Green' } else { 'Red' })
Write-Host ""

