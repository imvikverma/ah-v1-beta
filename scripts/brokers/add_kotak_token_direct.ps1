# Simple script to add Kotak Neo ACCESS TOKEN directly to .env
# Usage: .\add_kotak_token_direct.ps1 -Token "your_access_token_here"

param(
    [Parameter(Mandatory=$true)]
    [string]$Token
)

Write-Host "`n=== Adding Kotak Neo Access Token ===" -ForegroundColor Cyan

# Check if .env exists
if (-not (Test-Path .env)) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    New-Item -Path .env -ItemType File | Out-Null
}

# Remove existing token if present
$content = Get-Content .env -ErrorAction SilentlyContinue
if ($content) {
    $content = $content | Where-Object { $_ -notmatch "^KOTAK_NEO_ACCESS_TOKEN=" }
    $content | Set-Content .env
}

# Add new token
Add-Content -Path .env -Value "KOTAK_NEO_ACCESS_TOKEN=$Token"

Write-Host "✅ Access Token added to .env file!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: If you need Consumer Key/Secret later, add:" -ForegroundColor Yellow
Write-Host "  KOTAK_NEO_API_KEY=your_consumer_key" -ForegroundColor Gray
Write-Host "  KOTAK_NEO_API_SECRET=your_consumer_secret" -ForegroundColor Gray
Write-Host ""
Write-Host "Next: Test with: python config/get_kotak_token.py" -ForegroundColor Yellow

