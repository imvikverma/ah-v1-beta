# Add Ngrok API Key to .env file
# This script safely adds your ngrok API key to .env

Write-Host "`n=== Add Ngrok API Key to .env ===" -ForegroundColor Cyan
Write-Host ""

$envPath = ".env"

# Check if .env exists
if (-not (Test-Path $envPath)) {
    Write-Host "Creating .env file..." -ForegroundColor Yellow
    New-Item -Path $envPath -ItemType File -Force | Out-Null
}

# Check if API key already exists
$envContent = Get-Content $envPath -ErrorAction SilentlyContinue
$apiKeyExists = $envContent | Where-Object { $_ -match "^NGROK_API_KEY=" }

if ($apiKeyExists) {
    Write-Host "⚠️  NGROK_API_KEY already exists in .env" -ForegroundColor Yellow
    Write-Host "Current value: $($apiKeyExists -replace 'NGROK_API_KEY=', '')" -ForegroundColor Gray
    Write-Host ""
    $overwrite = Read-Host "Overwrite? (y/N)"
    
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "❌ Cancelled. API key not updated." -ForegroundColor Red
        exit 0
    }
    
    # Remove old entry
    $newContent = $envContent | Where-Object { $_ -notmatch "^NGROK_API_KEY=" }
    $newContent | Set-Content $envPath
}

# Add API key
$apiKey = "ak_367YEZKNQ4gVLJKCqi2TYKuBFc1"
Add-Content -Path $envPath -Value "NGROK_API_KEY=$apiKey"

Write-Host "✅ API key added to .env file" -ForegroundColor Green
Write-Host ""
Write-Host "API Key: $apiKey" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  Security Reminder:" -ForegroundColor Yellow
Write-Host "   - .env is already in .gitignore (safe)" -ForegroundColor White
Write-Host "   - Never commit API keys to git" -ForegroundColor White
Write-Host "   - Keep this key secret" -ForegroundColor White
Write-Host ""

