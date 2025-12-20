# Helper script to add Kotak Neo request token to .env file
# Usage: .\add_kotak_token.ps1

Write-Host "`n=== Kotak Neo Request Token Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if .env exists
if (-not (Test-Path .env)) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    New-Item -Path .env -ItemType File | Out-Null
}

# Check if token already exists
$existingToken = Get-Content .env -ErrorAction SilentlyContinue | Select-String "KOTAK_NEO_REQUEST_TOKEN"
if ($existingToken) {
    Write-Host "⚠️  KOTAK_NEO_REQUEST_TOKEN already exists in .env" -ForegroundColor Yellow
    Write-Host "Current value: $($existingToken.Line)" -ForegroundColor Gray
    $overwrite = Read-Host "Do you want to overwrite it? (y/n)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "Cancelled." -ForegroundColor Red
        exit
    }
    # Remove old line
    (Get-Content .env) | Where-Object { $_ -notmatch "KOTAK_NEO_REQUEST_TOKEN" } | Set-Content .env
}

# Get token from user
Write-Host ""
Write-Host "Please enter your Kotak Neo REQUEST TOKEN:" -ForegroundColor Green
Write-Host "(The token will be added to .env file)" -ForegroundColor Gray
$token = Read-Host "Token"

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "❌ Token cannot be empty!" -ForegroundColor Red
    exit 1
}

# Add token to .env
Add-Content -Path .env -Value "KOTAK_NEO_REQUEST_TOKEN=$token"

Write-Host ""
Write-Host "✅ Token added to .env file!" -ForegroundColor Green
Write-Host ""

# Verify
Write-Host "Verifying..." -ForegroundColor Cyan
$verify = Get-Content .env | Select-String "KOTAK_NEO_REQUEST_TOKEN"
if ($verify) {
    Write-Host "✅ Verified: Token is in .env file" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step: Test the token with:" -ForegroundColor Yellow
    Write-Host "  python config/get_kotak_token.py" -ForegroundColor White
} else {
    Write-Host "❌ Error: Token not found in .env" -ForegroundColor Red
}

