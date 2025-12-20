# Simple script to add Kotak Neo token - accepts token as parameter
# Usage: .\add_kotak_token_simple.ps1 -Token "your_token_here"

param(
    [Parameter(Mandatory=$true)]
    [string]$Token
)

Write-Host "`n=== Adding Kotak Neo Request Token ===" -ForegroundColor Cyan

# Check if .env exists
if (-not (Test-Path .env)) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    New-Item -Path .env -ItemType File | Out-Null
}

# Remove existing token if present
$content = Get-Content .env -ErrorAction SilentlyContinue
if ($content) {
    $content = $content | Where-Object { $_ -notmatch "^KOTAK_NEO_REQUEST_TOKEN=" }
    $content | Set-Content .env
}

# Add new token
Add-Content -Path .env -Value "KOTAK_NEO_REQUEST_TOKEN=$Token"

Write-Host "✅ Token added to .env file!" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Test with: python config/get_kotak_token.py" -ForegroundColor Yellow

