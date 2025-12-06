# Test HDFC Sky authorise endpoint with different token_id values
# The 401 error suggests we need to validate the request_token first

Write-Host "`n=== Testing HDFC Sky Authorise Endpoint ===" -ForegroundColor Cyan
Write-Host ""

# Load .env
$envPath = ".env"
$apiKey = $null
$apiSecret = $null
$requestToken = $null

Get-Content $envPath | ForEach-Object {
    if ($_ -match "^HDFC_SKY_API_KEY=(.+)$") { $apiKey = $matches[1].Trim() }
    if ($_ -match "^HDFC_SKY_API_SECRET=(.+)$") { $apiSecret = $matches[1].Trim() }
    if ($_ -match "^HDFC_SKY_REQUEST_TOKEN=(.+)$") { $requestToken = $matches[1].Trim() }
}

Write-Host "API Key: $($apiKey.Substring(0, [Math]::Min(20, $apiKey.Length)))..."
Write-Host "Request Token: $($requestToken.Substring(0, [Math]::Min(40, $requestToken.Length)))..."
Write-Host ""

# Try different token_id values
$tokenIdOptions = @(
    @{ name = "API Key as token_id"; value = $apiKey },
    @{ name = "API Secret as token_id"; value = $apiSecret },
    @{ name = "Request Token as token_id"; value = $requestToken },
    @{ name = "Empty string"; value = "" },
    @{ name = "True (string)"; value = "True" },
    @{ name = "1"; value = "1" }
)

$authoriseUrl = "https://developer.hdfcsky.com/oapi/v1/authorise"
$headers = @{
    "User-Agent" = "AurumHarmony/1.0"
    "Content-Type" = "application/json"
}

foreach ($option in $tokenIdOptions) {
    Write-Host "[Testing] $($option.name)" -ForegroundColor Yellow
    
    $url = "$authoriseUrl?api_key=$apiKey&token_id=$($option.value)&consent=True&request_token=$requestToken"
    Write-Host "  URL: $($url.Substring(0, [Math]::Min(120, $url.Length)))..." -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -ErrorAction Stop
        Write-Host "  ✅ SUCCESS!" -ForegroundColor Green
        Write-Host "  Response: $($response | ConvertTo-Json -Depth 3)"
        
        $validatedToken = $response.requestToken
        if ($validatedToken) {
            Write-Host "`n🎉 Got validated requestToken!" -ForegroundColor Green
            Write-Host "Validated Token: $validatedToken" -ForegroundColor Cyan
            Write-Host "`nNow trying to get access token with validated token..." -ForegroundColor Yellow
            
            # Try to get access token with validated token
            $accessUrl = "https://developer.hdfcsky.com/oapi/v1/access-token?api_key=$apiKey&request_token=$validatedToken"
            $accessBody = @{ api_secret = $apiSecret } | ConvertTo-Json
            
            try {
                $accessResponse = Invoke-RestMethod -Uri $accessUrl -Method Post -Body $accessBody -ContentType "application/json" -Headers $headers -ErrorAction Stop
                Write-Host "✅ Access Token: $($accessResponse.access_token.Substring(0, [Math]::Min(50, $accessResponse.access_token.Length)))..." -ForegroundColor Green
                Write-Host "Full Response: $($accessResponse | ConvertTo-Json -Depth 3)"
                exit 0
            } catch {
                Write-Host "  ⚠️ Access token step failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        exit 0
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMsg = $_.ErrorDetails.Message
        Write-Host "  ❌ Error $statusCode" -ForegroundColor Red
        if ($errorMsg) {
            Write-Host "  $($errorMsg.Substring(0, [Math]::Min(150, $errorMsg.Length)))" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

Write-Host "❌ None of the token_id options worked" -ForegroundColor Red
Write-Host "`nYou may need to:" -ForegroundColor Yellow
Write-Host "  1. Find token_id in HDFC Sky portal" -ForegroundColor White
Write-Host "  2. Check if request_token has expired" -ForegroundColor White
Write-Host "  3. Generate a new request_token" -ForegroundColor White

