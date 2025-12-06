# Test HDFC Sky Access Token API
# This script tests different authentication methods

Write-Host "`n=== HDFC SKY ACCESS TOKEN TEST ===" -ForegroundColor Cyan
Write-Host ""

# Load .env file
$envPath = ".env"
if (-not (Test-Path $envPath)) {
    Write-Host "❌ .env file not found!" -ForegroundColor Red
    exit 1
}

# Read credentials from .env
$apiKey = $null
$apiSecret = $null
$requestToken = $null

Get-Content $envPath | ForEach-Object {
    if ($_ -match "^HDFC_SKY_API_KEY=(.+)$") {
        $apiKey = $matches[1].Trim()
    }
    if ($_ -match "^HDFC_SKY_API_SECRET=(.+)$") {
        $apiSecret = $matches[1].Trim()
    }
    if ($_ -match "^HDFC_SKY_REQUEST_TOKEN=(.+)$") {
        $requestToken = $matches[1].Trim()
    }
}

Write-Host "API Key: $($apiKey.Substring(0, [Math]::Min(15, $apiKey.Length)))... (length: $($apiKey.Length))"
Write-Host "API Secret: $($apiSecret.Substring(0, [Math]::Min(15, $apiSecret.Length)))... (length: $($apiSecret.Length))"
Write-Host "Request Token: $($requestToken.Substring(0, [Math]::Min(30, $requestToken.Length)))..."
Write-Host ""

if (-not $apiKey -or -not $apiSecret -or -not $requestToken) {
    Write-Host "❌ Missing credentials!" -ForegroundColor Red
    Write-Host "  API Key: $(if ($apiKey) { '✅' } else { '❌' })"
    Write-Host "  API Secret: $(if ($apiSecret) { '✅' } else { '❌' })"
    Write-Host "  Request Token: $(if ($requestToken) { '✅' } else { '❌' })"
    exit 1
}

# Test Method 1: API key + request_token in URL, secret in JSON body
Write-Host "[1/6] Testing: API key + request_token in URL, secret in JSON body" -ForegroundColor Yellow
$url1 = "https://developer.hdfcsky.com/oapi/v1/access-token?api_key=$apiKey&request_token=$requestToken"
$body1 = @{
    api_secret = $apiSecret
} | ConvertTo-Json

try {
    $response1 = Invoke-RestMethod -Uri $url1 -Method Post -Body $body1 -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Access Token: $($response1.access_token.Substring(0, [Math]::Min(50, $response1.access_token.Length)))..."
    Write-Host "Full Response: $($response1 | ConvertTo-Json -Depth 3)"
    exit 0
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }
}

# Test Method 2: API key + request_token in URL, secret in form-data
Write-Host "`n[2/6] Testing: API key + request_token in URL, secret in form-data" -ForegroundColor Yellow
$url2 = "https://developer.hdfcsky.com/oapi/v1/access-token?api_key=$apiKey&request_token=$requestToken"
$body2 = @{
    api_secret = $apiSecret
}

try {
    $response2 = Invoke-RestMethod -Uri $url2 -Method Post -Body $body2 -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Access Token: $($response2.access_token.Substring(0, [Math]::Min(50, $response2.access_token.Length)))..."
    Write-Host "Full Response: $($response2 | ConvertTo-Json -Depth 3)"
    exit 0
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }
}

# Test Method 3: All in JSON body
Write-Host "`n[3/6] Testing: All parameters in JSON body" -ForegroundColor Yellow
$url3 = "https://developer.hdfcsky.com/oapi/v1/access-token"
$body3 = @{
    api_key = $apiKey
    api_secret = $apiSecret
    request_token = $requestToken
} | ConvertTo-Json

try {
    $response3 = Invoke-RestMethod -Uri $url3 -Method Post -Body $body3 -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Access Token: $($response3.access_token.Substring(0, [Math]::Min(50, $response3.access_token.Length)))..."
    Write-Host "Full Response: $($response3 | ConvertTo-Json -Depth 3)"
    exit 0
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }
}

# Test Method 4: All in form-data
Write-Host "`n[4/6] Testing: All parameters in form-data" -ForegroundColor Yellow
$url4 = "https://developer.hdfcsky.com/oapi/v1/access-token"
$body4 = @{
    api_key = $apiKey
    api_secret = $apiSecret
    request_token = $requestToken
}

try {
    $response4 = Invoke-RestMethod -Uri $url4 -Method Post -Body $body4 -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Access Token: $($response4.access_token.Substring(0, [Math]::Min(50, $response4.access_token.Length)))..."
    Write-Host "Full Response: $($response4 | ConvertTo-Json -Depth 3)"
    exit 0
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }
}

# Test Method 5: API key in URL, secret + token in body (JSON)
Write-Host "`n[5/6] Testing: API key in URL, secret + token in JSON body" -ForegroundColor Yellow
$url5 = "https://developer.hdfcsky.com/oapi/v1/access-token?api_key=$apiKey"
$body5 = @{
    api_secret = $apiSecret
    request_token = $requestToken
} | ConvertTo-Json

try {
    $response5 = Invoke-RestMethod -Uri $url5 -Method Post -Body $body5 -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Access Token: $($response5.access_token.Substring(0, [Math]::Min(50, $response5.access_token.Length)))..."
    Write-Host "Full Response: $($response5 | ConvertTo-Json -Depth 3)"
    exit 0
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }
}

# Test Method 6: API key in URL, secret + token in body (form)
Write-Host "`n[6/6] Testing: API key in URL, secret + token in form-data" -ForegroundColor Yellow
$url6 = "https://developer.hdfcsky.com/oapi/v1/access-token?api_key=$apiKey"
$body6 = @{
    api_secret = $apiSecret
    request_token = $requestToken
}

try {
    $response6 = Invoke-RestMethod -Uri $url6 -Method Post -Body $body6 -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Access Token: $($response6.access_token.Substring(0, [Math]::Min(50, $response6.access_token.Length)))..."
    Write-Host "Full Response: $($response6 | ConvertTo-Json -Depth 3)"
    exit 0
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }
}

Write-Host "`n❌ None of the methods worked" -ForegroundColor Red
Write-Host "`nPossible issues:" -ForegroundColor Yellow
Write-Host "  1. Request token might be expired or invalid"
Write-Host "  2. API key/secret might be incorrect"
Write-Host "  3. Account might not be approved/activated"
Write-Host "  4. Endpoint URL might be different"
Write-Host "`nCheck the HDFC Sky documentation for the correct format." -ForegroundColor Gray

