# Setup Broker Test Environment
# Helps configure broker credentials for testing

$ErrorActionPreference = "Continue"

Write-Host "`n🔧 Broker Test Environment Setup" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Gray

$envFile = ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "`n⚠️  .env file not found. Creating template..." -ForegroundColor Yellow
    @"
# Broker API Credentials
# HDFC Sky
HDFC_SKY_API_KEY=your_hdfc_api_key
HDFC_SKY_API_SECRET=your_hdfc_api_secret
HDFC_SKY_TOKEN_ID=your_hdfc_token_id
HDFC_SKY_ACCESS_TOKEN=your_hdfc_access_token

# Kotak Neo
KOTAK_NEO_ACCESS_TOKEN=your_kotak_access_token
KOTAK_NEO_MOBILE_NUMBER=+91XXXXXXXXXX
KOTAK_NEO_CLIENT_CODE=your_kotak_client_code
"@ | Out-File -FilePath $envFile -Encoding UTF8
    Write-Host "  ✅ Created .env template" -ForegroundColor Green
    Write-Host "     Please edit .env and add your broker credentials" -ForegroundColor Gray
    exit 0
}

Write-Host "`n📝 Current .env Configuration:" -ForegroundColor Yellow

# Check HDFC Sky
$hdfcKey = (Get-Content $envFile | Select-String "HDFC_SKY_API_KEY").Line
if ($hdfcKey -and $hdfcKey -notmatch "your_hdfc") {
    Write-Host "  ✅ HDFC Sky: Configured" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  HDFC Sky: Not configured" -ForegroundColor Yellow
    Write-Host "     Add to .env:" -ForegroundColor Gray
    Write-Host "     HDFC_SKY_API_KEY=your_key" -ForegroundColor Gray
    Write-Host "     HDFC_SKY_API_SECRET=your_secret" -ForegroundColor Gray
    Write-Host "     HDFC_SKY_TOKEN_ID=your_token_id" -ForegroundColor Gray
}

# Check Kotak Neo
$kotakToken = (Get-Content $envFile | Select-String "KOTAK_NEO_ACCESS_TOKEN").Line
if ($kotakToken -and $kotakToken -notmatch "your_kotak") {
    Write-Host "  ✅ Kotak Neo: Configured" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Kotak Neo: Not configured" -ForegroundColor Yellow
    Write-Host "     Add to .env:" -ForegroundColor Gray
    Write-Host "     KOTAK_NEO_ACCESS_TOKEN=your_token" -ForegroundColor Gray
    Write-Host "     KOTAK_NEO_MOBILE_NUMBER=+91XXXXXXXXXX" -ForegroundColor Gray
    Write-Host "     KOTAK_NEO_CLIENT_CODE=your_client_code" -ForegroundColor Gray
}

Write-Host "`n📚 Broker Setup Guides:" -ForegroundColor Cyan
Write-Host "  HDFC Sky:" -ForegroundColor Yellow
Write-Host "    1. Get API credentials from HDFC Sky portal" -ForegroundColor Gray
Write-Host "    2. Add to .env file" -ForegroundColor Gray
Write-Host "    3. Test: python scripts/brokers/test_hdfc_connection.py" -ForegroundColor Gray

Write-Host "`n  Kotak Neo:" -ForegroundColor Yellow
Write-Host "    1. Get access token from Kotak Neo App → Invest → Trade API" -ForegroundColor Gray
Write-Host "    2. Add credentials to .env file" -ForegroundColor Gray
Write-Host "    3. Authenticate via frontend (TOTP + MPIN) or API" -ForegroundColor Gray
Write-Host "    4. Test: python scripts/brokers/test_kotak_connection.py" -ForegroundColor Gray

Write-Host "`n✅ Setup check complete!" -ForegroundColor Green
Write-Host "   Run: .\scripts\test_broker_integration.ps1 to test" -ForegroundColor Cyan

