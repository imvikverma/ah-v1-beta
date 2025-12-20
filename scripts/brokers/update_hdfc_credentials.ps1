# Helper script to update HDFC Sky credentials in .env file

Write-Host "`n=== Update HDFC Sky Credentials ===" -ForegroundColor Cyan
Write-Host ""

# Check if .env exists
if (-not (Test-Path .env)) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    New-Content -Path .env -Value "# HDFC Sky API Credentials"
}

# Get current content
$envContent = Get-Content .env -ErrorAction SilentlyContinue

# Remove old HDFC Sky entries
$newContent = $envContent | Where-Object { 
    $_ -notmatch "^\s*HDFC_SKY_API_KEY\s*=" -and 
    $_ -notmatch "^\s*HDFC_SKY_API_SECRET\s*=" 
}

# Get new credentials from user
Write-Host "Enter your NEW HDFC Sky credentials:" -ForegroundColor Yellow
Write-Host ""

$apiKey = Read-Host "HDFC Sky API Key (Consumer Key)"
$apiSecret = Read-Host "HDFC Sky API Secret (Consumer Secret)" -AsSecureString

# Convert secure string to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiSecret)
$apiSecretPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

if ([string]::IsNullOrWhiteSpace($apiKey) -or [string]::IsNullOrWhiteSpace($apiSecretPlain)) {
    Write-Host "`n❌ Both API Key and Secret are required!" -ForegroundColor Red
    exit 1
}

# Add new credentials
$newContent += ""
$newContent += "# HDFC Sky API Credentials"
$newContent += "HDFC_SKY_API_KEY=$apiKey"
$newContent += "HDFC_SKY_API_SECRET=$apiSecretPlain"

# Write back to file
$newContent | Set-Content .env

Write-Host ""
Write-Host "✅ Credentials updated in .env file!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Get request token: .\scripts\brokers\get_hdfc_request_token.ps1" -ForegroundColor White
Write-Host "2. Test: python config/get_token.py" -ForegroundColor White
Write-Host ""

