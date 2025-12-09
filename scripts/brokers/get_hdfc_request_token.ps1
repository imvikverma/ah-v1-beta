# HDFC Sky OAuth Request Token Helper
# This script helps you get a request token via OAuth flow

# ============================================================================
# CONFIGURATION: Cloudflare Pages Callback URL
# ============================================================================
$CALLBACK_BASE_URL = "https://aurumharmony-v1-beta.pages.dev"

Write-Host "`n=== HDFC Sky OAuth Request Token ===" -ForegroundColor Cyan
Write-Host ""

# Check if API key is set
$envContent = Get-Content .env -ErrorAction SilentlyContinue
# Match with optional leading whitespace
$apiKeyMatch = $envContent | Select-String "^\s*HDFC_SKY_API_KEY=(.+)"

if ($apiKeyMatch -and $apiKeyMatch.Matches -and $apiKeyMatch.Matches.Groups.Count -gt 1) {
    $apiKey = $apiKeyMatch.Matches.Groups[1].Value.Trim()
} else {
    # Try alternative: find line containing HDFC_SKY_API_KEY and extract value
    $hdfcLine = $envContent | Where-Object { $_ -match "HDFC_SKY_API_KEY\s*=" }
    if ($hdfcLine) {
        if ($hdfcLine -match "HDFC_SKY_API_KEY\s*=\s*(.+)") {
            $apiKey = $matches[1].Trim()
        }
    }
    if (-not $apiKey) {
        $apiKey = $null
    }
}

if (-not $apiKey) {
    Write-Host "❌ HDFC_SKY_API_KEY not found in .env" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please add it to .env file first:" -ForegroundColor Yellow
    Write-Host "  Add-Content -Path .env -Value 'HDFC_SKY_API_KEY=your_api_key_here'" -ForegroundColor White
    Write-Host ""
    Write-Host "Or edit manually:" -ForegroundColor Yellow
    Write-Host "  notepad .env" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "✅ API Key found: $($apiKey.Substring(0, [Math]::Min(10, $apiKey.Length)))..." -ForegroundColor Green
Write-Host ""

# Method 1: Direct OAuth URL
# Using Cloudflare Pages callback URL
$redirectUri = "$CALLBACK_BASE_URL/callback/hdfc"

# Try different OAuth endpoint paths (HDFC Sky might use different path)
# Option 1: Standard OAuth (currently getting 404)
$oauthUrl1 = "https://developer.hdfcsky.com/oauth/authorize?api_key=$apiKey&redirect_uri=$redirectUri"

# Option 2: Alternative paths to try
$oauthUrl2 = "https://developer.hdfcsky.com/api/oauth/authorize?api_key=$apiKey&redirect_uri=$redirectUri"
$oauthUrl3 = "https://developer.hdfcsky.com/oapi/v1/authorize?api_key=$apiKey&redirect_uri=$redirectUri"
$oauthUrl4 = "https://developer.hdfcsky.com/authorize?api_key=$apiKey&redirect_uri=$redirectUri"

# Use the first one (update if docs show different path)
$oauthUrl = $oauthUrl1

Write-Host "Using callback URL: $redirectUri" -ForegroundColor Gray
Write-Host ""

Write-Host "=== Method 1: Direct OAuth URL ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Open this URL in your browser:" -ForegroundColor Cyan
Write-Host "   $oauthUrl" -ForegroundColor White
Write-Host ""
Write-Host "2. Log in with your HDFC Sky account" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Authorize the application" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. You'll be redirected to: $redirectUri?request_token=YOUR_TOKEN" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. Copy the request_token from the URL" -ForegroundColor Cyan
Write-Host ""

# Method 2: Using Flask endpoint (if backend is running)
Write-Host "=== Method 2: Using Flask Backend ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "If your Flask backend is running on port 5000:" -ForegroundColor Cyan
Write-Host "1. Visit: http://localhost:5000/get-login-url" -ForegroundColor White
Write-Host "2. This will redirect you to HDFC Sky OAuth" -ForegroundColor Gray
Write-Host "3. After authorization, you'll be redirected back" -ForegroundColor Gray
Write-Host "4. The request_token will be in the callback URL" -ForegroundColor Gray
Write-Host ""

# Method 3: Manual portal navigation
Write-Host "=== Method 3: Manual Portal Navigation ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Go to: https://developer.hdfcsky.com" -ForegroundColor White
Write-Host "2. Log in with your HDFC Sky credentials" -ForegroundColor White
Write-Host "3. Look for:" -ForegroundColor Cyan
Write-Host "   - 'My Apps' or 'Applications' section" -ForegroundColor Gray
Write-Host "   - 'API Keys' or 'Credentials' section" -ForegroundColor Gray
Write-Host "   - 'OAuth' or 'Authorization' tab" -ForegroundColor Gray
Write-Host "4. Find 'Request Token' or 'Generate Token' button" -ForegroundColor Gray
Write-Host "5. Copy the generated request token" -ForegroundColor Gray
Write-Host ""

Write-Host "=== After Getting Request Token ===" -ForegroundColor Green
Write-Host ""
Write-Host "Add it to .env file:" -ForegroundColor Yellow
Write-Host "  Add-Content -Path .env -Value 'HDFC_SKY_REQUEST_TOKEN=your_token_here'" -ForegroundColor White
Write-Host ""
Write-Host "Or edit manually:" -ForegroundColor Yellow
Write-Host "  notepad .env" -ForegroundColor White
Write-Host "  (Add: HDFC_SKY_REQUEST_TOKEN=your_token_here)" -ForegroundColor Gray
Write-Host ""

# Offer to open browser
$openBrowser = Read-Host "Would you like to open the OAuth URL in your browser now? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    Start-Process $oauthUrl
    Write-Host ""
    Write-Host "✅ Browser opened! Complete the OAuth flow, then add the request_token to .env" -ForegroundColor Green
}

