# Test alternative HDFC Sky endpoints and formats
# The 400 error suggests wrong endpoint or format

Write-Host "`n=== Testing Alternative HDFC Sky Endpoints ===" -ForegroundColor Cyan
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

Write-Host "Request Token: $($requestToken.Substring(0, [Math]::Min(40, $requestToken.Length)))..."
Write-Host ""

# Alternative endpoints to try
$endpoints = @(
    "https://developer.hdfcsky.com/oapi/v1/access-token",
    "https://developer.hdfcsky.com/api/v1/access-token",
    "https://api.hdfcsky.com/oapi/v1/access-token",
    "https://developer.hdfcsky.com/oapi/access-token",
    "https://developer.hdfcsky.com/api/access-token"
)

# Different parameter combinations
$methods = @(
    @{
        name = "URL params: api_key + request_token, body: api_secret (JSON)"
        url_template = "{0}?api_key={1}&request_token={2}"
        body = @{ api_secret = $apiSecret } | ConvertTo-Json
        contentType = "application/json"
    },
    @{
        name = "URL params: api_key + request_token, body: api_secret (form)"
        url_template = "{0}?api_key={1}&request_token={2}"
        body = @{ api_secret = $apiSecret }
        contentType = "application/x-www-form-urlencoded"
    },
    @{
        name = "URL param: api_key only, body: api_secret + request_token (JSON)"
        url_template = "{0}?api_key={1}"
        body = @{ api_secret = $apiSecret; request_token = $requestToken } | ConvertTo-Json
        contentType = "application/json"
    },
    @{
        name = "URL param: api_key only, body: api_secret + request_token (form)"
        url_template = "{0}?api_key={1}"
        body = @{ api_secret = $apiSecret; request_token = $requestToken }
        contentType = "application/x-www-form-urlencoded"
    },
    @{
        name = "No URL params, all in body (JSON)"
        url_template = "{0}"
        body = @{ api_key = $apiKey; api_secret = $apiSecret; request_token = $requestToken } | ConvertTo-Json
        contentType = "application/json"
    },
    @{
        name = "No URL params, all in body (form)"
        url_template = "{0}"
        body = @{ api_key = $apiKey; api_secret = $apiSecret; request_token = $requestToken }
        contentType = "application/x-www-form-urlencoded"
    }
)

$testNum = 0
foreach ($endpoint in $endpoints) {
    foreach ($method in $methods) {
        $testNum++
        $url = $method.url_template -f $endpoint, $apiKey, $requestToken
        
        Write-Host "[$testNum] Testing: $($method.name)" -ForegroundColor Yellow
        Write-Host "    Endpoint: $endpoint" -ForegroundColor Gray
        Write-Host "    URL: $($url.Substring(0, [Math]::Min(100, $url.Length)))..." -ForegroundColor Gray
        
        try {
            $headers = @{
                "Content-Type" = $method.contentType
                "Accept" = "application/json"
            }
            
            if ($method.contentType -eq "application/json") {
                $response = Invoke-RestMethod -Uri $url -Method Post -Body $method.body -Headers $headers -ErrorAction Stop
            } else {
                $response = Invoke-RestMethod -Uri $url -Method Post -Body $method.body -ContentType $method.contentType -ErrorAction Stop
            }
            
            Write-Host "    ✅ SUCCESS!" -ForegroundColor Green
            Write-Host "    Access Token: $($response.access_token.Substring(0, [Math]::Min(50, $response.access_token.Length)))..."
            Write-Host "`n🎉 WORKING METHOD FOUND!" -ForegroundColor Green
            Write-Host "Endpoint: $endpoint" -ForegroundColor Cyan
            Write-Host "Method: $($method.name)" -ForegroundColor Cyan
            exit 0
            
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $errorMsg = $_.ErrorDetails.Message
            Write-Host "    ❌ Error $statusCode" -ForegroundColor Red
            if ($errorMsg) {
                Write-Host "    $($errorMsg.Substring(0, [Math]::Min(100, $errorMsg.Length)))" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }
}

Write-Host "❌ None of the combinations worked" -ForegroundColor Red
Write-Host "`nPossible issues:" -ForegroundColor Yellow
Write-Host "  1. Request token might be expired (they often expire quickly)"
Write-Host "  2. Request token format might be wrong"
Write-Host "  3. Account might need approval/activation"
Write-Host "  4. Endpoint might be completely different"
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Check the HDFC Sky documentation page for exact format"
Write-Host "  2. Try generating a new request token"
Write-Host "  3. Contact HDFC Sky support if account needs activation"

