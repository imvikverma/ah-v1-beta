# Setup ngrok authtoken
# This removes the ngrok warning page and enables better features

Write-Host "`n=== ngrok Authtoken Setup ===" -ForegroundColor Cyan
Write-Host ""

# Prompt for authtoken
$authtoken = Read-Host "Enter your ngrok authtoken"

if (-not $authtoken) {
    Write-Host "❌ No authtoken provided" -ForegroundColor Red
    exit 1
}

Write-Host "`nConfiguring ngrok..." -ForegroundColor Yellow

try {
    # Add authtoken
    $result = ngrok config add-authtoken $authtoken 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ngrok authtoken configured successfully!`n" -ForegroundColor Green
        Write-Host "Benefits:" -ForegroundColor Cyan
        Write-Host "  - No more ngrok warning page" -ForegroundColor Gray
        Write-Host "  - Better OAuth redirects" -ForegroundColor Gray
        Write-Host "  - More stable sessions`n" -ForegroundColor Gray
        
        Write-Host "Test it:" -ForegroundColor Yellow
        Write-Host "  1. Start ngrok: ngrok http 5000" -ForegroundColor White
        Write-Host "  2. Visit the URL - no warning page should appear!`n" -ForegroundColor White
    } else {
        Write-Host "❌ Error configuring authtoken" -ForegroundColor Red
        Write-Host "Output: $result" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}

