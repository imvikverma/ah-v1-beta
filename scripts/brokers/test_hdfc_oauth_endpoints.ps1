# Test different OAuth endpoint variations for HDFC Sky
# The /oauth/authorize returns 404, so let's try alternatives

Write-Host "`n=== Testing HDFC Sky OAuth Endpoints ===" -ForegroundColor Cyan
Write-Host ""

# Load API key
$envPath = ".env"
$apiKey = $null
$ngrokUrl = "top-manatee-busy.ngrok-free.app"  # Your current ngrok URL

Get-Content $envPath | ForEach-Object {
    if ($_ -match "^HDFC_SKY_API_KEY=(.+)$") {
        $apiKey = $matches[1].Trim()
    }
}

if (-not $apiKey) {
    Write-Host "❌ HDFC_SKY_API_KEY not found" -ForegroundColor Red
    exit 1
}

$redirectUri = "https://$ngrokUrl/callback"

Write-Host "API Key: $($apiKey.Substring(0, [Math]::Min(20, $apiKey.Length)))..."
Write-Host "Redirect URI: $redirectUri"
Write-Host ""

# Different OAuth endpoint variations to try
$endpoints = @(
    "https://developer.hdfcsky.com/oauth/authorize",
    "https://developer.hdfcsky.com/oapi/v1/oauth/authorize",
    "https://developer.hdfcsky.com/api/oauth/authorize",
    "https://developer.hdfcsky.com/oapi/oauth/authorize",
    "https://developer.hdfcsky.com/authorize",
    "https://developer.hdfcsky.com/oapi/v1/authorize",
    "https://developer.hdfcsky.com/api/v1/authorize",
    "https://api.hdfcsky.com/oauth/authorize"
)

Write-Host "Testing OAuth endpoints (checking if they exist):" -ForegroundColor Yellow
Write-Host ""

foreach ($endpoint in $endpoints) {
    $url = "$endpoint?api_key=$apiKey&redirect_uri=$redirectUri"
    Write-Host "Testing: $endpoint" -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method Get -MaximumRedirection 0 -ErrorAction Stop
        Write-Host "  ✅ Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "  URL: $url" -ForegroundColor White
        Write-Host "`n🎉 Found working endpoint!" -ForegroundColor Green
        Write-Host "Open this URL in your browser:" -ForegroundColor Yellow
        Write-Host "  $url`n" -ForegroundColor White
        exit 0
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 404) {
            Write-Host "  ❌ 404 Not Found" -ForegroundColor Red
        } elseif ($statusCode -eq 302 -or $statusCode -eq 301) {
            Write-Host "  ✅ Redirect (endpoint exists!)" -ForegroundColor Green
            Write-Host "  URL: $url" -ForegroundColor White
            Write-Host "`n🎉 Found working endpoint!" -ForegroundColor Green
            Write-Host "Open this URL in your browser:" -ForegroundColor Yellow
            Write-Host "  $url`n" -ForegroundColor White
            exit 0
        } else {
            Write-Host "  ⚠️ Status: $statusCode" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

Write-Host "❌ None of the OAuth endpoints worked" -ForegroundColor Red
Write-Host "`nHDFC Sky might not use standard OAuth redirect flow." -ForegroundColor Yellow
Write-Host "`nAlternative: Generate request token directly in portal:" -ForegroundColor Cyan
Write-Host "  1. Go to: https://developer.hdfcsky.com" -ForegroundColor White
Write-Host "  2. Log in" -ForegroundColor White
Write-Host "  3. Go to your app: AurumHarmony_HDFC_Test" -ForegroundColor White
Write-Host "  4. Look for 'Generate Request Token' or 'Get Token' button" -ForegroundColor White
Write-Host "  5. Copy the token and add to .env" -ForegroundColor White
Write-Host ""

