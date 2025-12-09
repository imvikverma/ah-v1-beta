# Get a fresh HDFC Sky request token and test it immediately
# Request tokens often expire quickly, so we need to use them right away

Write-Host "`n=== Get Fresh HDFC Sky Request Token ===" -ForegroundColor Cyan
Write-Host ""

# Load API key from .env
$envPath = ".env"
$apiKey = $null

Get-Content $envPath | ForEach-Object {
    if ($_ -match "^HDFC_SKY_API_KEY=(.+)$") {
        $apiKey = $matches[1].Trim()
    }
}

if (-not $apiKey) {
    Write-Host "❌ HDFC_SKY_API_KEY not found in .env" -ForegroundColor Red
    exit 1
}

Write-Host "API Key: $($apiKey.Substring(0, [Math]::Min(20, $apiKey.Length)))..." -ForegroundColor Gray
Write-Host ""

# ============================================================================
# CONFIGURATION: Cloudflare Pages Callback URL
# ============================================================================
$CALLBACK_BASE_URL = "https://aurumharmony-v1-beta.pages.dev"

# Construct OAuth URL
$redirectUri = "$CALLBACK_BASE_URL/callback/hdfc"
$oauthUrl = "https://developer.hdfcsky.com/oauth/authorize?api_key=$apiKey&redirect_uri=$redirectUri"

Write-Host "Step 1: Open this URL in your browser:" -ForegroundColor Yellow
Write-Host "  $oauthUrl`n" -ForegroundColor White

Write-Host "Step 2: After authorization, you'll be redirected to:" -ForegroundColor Yellow
Write-Host "  $redirectUri?requestToken=YOUR_TOKEN`n" -ForegroundColor White

Write-Host "Step 3: Copy the requestToken from the URL and paste it here:" -ForegroundColor Yellow
$requestToken = Read-Host "Request Token"

if (-not $requestToken) {
    Write-Host "❌ No token provided" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Got request token: $($requestToken.Substring(0, [Math]::Min(40, $requestToken.Length)))..." -ForegroundColor Green

# Save to .env immediately
Write-Host "`nSaving to .env..." -ForegroundColor Cyan
$envLines = Get-Content $envPath
$tokenFound = $false
$newLines = @()

foreach ($line in $envLines) {
    if ($line -match "^HDFC_SKY_REQUEST_TOKEN=") {
        $newLines += "HDFC_SKY_REQUEST_TOKEN=$requestToken"
        $tokenFound = $true
    } else {
        $newLines += $line
    }
}

if (-not $tokenFound) {
    $newLines += "HDFC_SKY_REQUEST_TOKEN=$requestToken"
}

$newLines | Set-Content $envPath
Write-Host "✅ Saved to .env" -ForegroundColor Green

# Now try to get access token immediately
Write-Host "`nStep 4: Trying to get access token immediately..." -ForegroundColor Yellow

$apiSecret = $null
Get-Content $envPath | ForEach-Object {
    if ($_ -match "^HDFC_SKY_API_SECRET=(.+)$") {
        $apiSecret = $matches[1].Trim()
    }
}

if (-not $apiSecret) {
    Write-Host "❌ HDFC_SKY_API_SECRET not found" -ForegroundColor Red
    exit 1
}

# Try access token endpoint directly (without authorise step)
$accessUrl = "https://developer.hdfcsky.com/oapi/v1/access-token?api_key=$apiKey&request_token=$requestToken"
$accessBody = @{ api_secret = $apiSecret } | ConvertTo-Json
$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
    "User-Agent" = "AurumHarmony/1.0"
}

Write-Host "  Calling: $accessUrl" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri $accessUrl -Method Post -Body $accessBody -Headers $headers -ErrorAction Stop
    Write-Host "`n🎉 SUCCESS! Access Token obtained!" -ForegroundColor Green
    Write-Host "Access Token: $($response.access_token.Substring(0, [Math]::Min(50, $response.access_token.Length)))..." -ForegroundColor Cyan
    Write-Host "Full Response: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Gray
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMsg = $_.ErrorDetails.Message
    
    Write-Host "`n❌ Error $statusCode" -ForegroundColor Red
    Write-Host "Response: $errorMsg" -ForegroundColor Yellow
    
    if ($statusCode -eq 401) {
        Write-Host "`n⚠️ 401 Error - The request token might need validation via /authorise endpoint" -ForegroundColor Yellow
        Write-Host "But we need token_id for that. Check the HDFC Sky portal for token_id." -ForegroundColor Gray
    }
}

Write-Host ""

