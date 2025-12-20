# Test the /authorise endpoint directly with correct parameters

Write-Host "`n=== Testing HDFC Sky /authorise Endpoint ===" -ForegroundColor Cyan
Write-Host ""

# Load credentials
$envPath = ".env"
$apiKey = $null
$requestToken = $null
$tokenId = $null

Get-Content $envPath | ForEach-Object {
    if ($_ -match "^HDFC_SKY_API_KEY=(.+)$") { $apiKey = $matches[1].Trim() }
    if ($_ -match "^HDFC_SKY_REQUEST_TOKEN=(.+)$") { $requestToken = $matches[1].Trim() }
    if ($_ -match "^HDFC_SKY_TOKEN_ID=(.+)$") { $tokenId = $matches[1].Trim() }
}

Write-Host "Credentials loaded:" -ForegroundColor Yellow
Write-Host "  API Key: $($apiKey.Substring(0, [Math]::Min(20, $apiKey.Length)))..." -ForegroundColor Gray
Write-Host "  Token ID: $($tokenId.Substring(0, [Math]::Min(20, $tokenId.Length)))..." -ForegroundColor Gray
Write-Host "  Request Token: $($requestToken.Substring(0, [Math]::Min(40, $requestToken.Length)))..." -ForegroundColor Gray
Write-Host ""

if (-not $apiKey -or -not $tokenId -or -not $requestToken) {
    Write-Host "❌ Missing credentials!" -ForegroundColor Red
    Write-Host "  API Key: $(if ($apiKey) { '✅' } else { '❌' })"
    Write-Host "  Token ID: $(if ($tokenId) { '✅' } else { '❌' })"
    Write-Host "  Request Token: $(if ($requestToken) { '✅' } else { '❌' })"
    exit 1
}

# Test with consent=True
Write-Host "[Test 1] Testing with consent=True..." -ForegroundColor Yellow
$url1 = "https://developer.hdfcsky.com/oapi/v1/authorise?api_key=$apiKey&token_id=$tokenId&consent=True&request_token=$requestToken"
Write-Host "URL: $url1" -ForegroundColor Gray

$headers = @{
    "User-Agent" = "AurumHarmony/1.0"
    "Content-Type" = "application/json"
}

try {
    $response1 = Invoke-RestMethod -Uri $url1 -Method Get -Headers $headers -ErrorAction Stop
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Response: $($response1 | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
    
    $validatedToken = $response1.requestToken
    if ($validatedToken) {
        Write-Host "`n🎉 Got validated requestToken!" -ForegroundColor Green
        Write-Host "Validated Token: $validatedToken" -ForegroundColor Cyan
        Write-Host "`nSave this to .env as HDFC_SKY_REQUEST_TOKEN and use it for access token!" -ForegroundColor Yellow
    }
    exit 0
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMsg = $_.ErrorDetails.Message
    Write-Host "❌ Error $statusCode" -ForegroundColor Red
    Write-Host "Response: $errorMsg" -ForegroundColor Yellow
}

Write-Host ""

# Test with consent=False
Write-Host "[Test 2] Testing with consent=False..." -ForegroundColor Yellow
$url2 = "https://developer.hdfcsky.com/oapi/v1/authorise?api_key=$apiKey&token_id=$tokenId&consent=False&request_token=$requestToken"

try {
    $response2 = Invoke-RestMethod -Uri $url2 -Method Get -Headers $headers -ErrorAction Stop
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Response: $($response2 | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
    exit 0
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMsg = $_.ErrorDetails.Message
    Write-Host "❌ Error $statusCode" -ForegroundColor Red
    Write-Host "Response: $errorMsg" -ForegroundColor Yellow
}

Write-Host ""

# Test with consent=1
Write-Host "[Test 3] Testing with consent=1..." -ForegroundColor Yellow
$url3 = "https://developer.hdfcsky.com/oapi/v1/authorise?api_key=$apiKey&token_id=$tokenId&consent=1&request_token=$requestToken"

try {
    $response3 = Invoke-RestMethod -Uri $url3 -Method Get -Headers $headers -ErrorAction Stop
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "Response: $($response3 | ConvertTo-Json -Depth 3)" -ForegroundColor Cyan
    exit 0
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMsg = $_.ErrorDetails.Message
    Write-Host "❌ Error $statusCode" -ForegroundColor Red
    Write-Host "Response: $errorMsg" -ForegroundColor Yellow
}

Write-Host "`n❌ All consent values failed" -ForegroundColor Red
Write-Host "`nPossible issues:" -ForegroundColor Yellow
Write-Host "  1. Request token might be expired" -ForegroundColor Gray
Write-Host "  2. Token ID might be incorrect" -ForegroundColor Gray
Write-Host "  3. API key might be incorrect" -ForegroundColor Gray
Write-Host "  4. Request token format might be wrong (ends with 'x'?)" -ForegroundColor Gray

