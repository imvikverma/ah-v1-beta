# Quick test for HDFC Sky token - tries current token immediately
# If it fails, helps generate fresh token

Write-Host "`n=== HDFC Sky Token Test ===" -ForegroundColor Cyan
Write-Host ""

# Load credentials
$envPath = ".env"
$apiKey = $null
$apiSecret = $null
$requestToken = $null
$tokenId = $null

Get-Content $envPath | ForEach-Object {
    if ($_ -match "^HDFC_SKY_API_KEY=(.+)$") { $apiKey = $matches[1].Trim() }
    if ($_ -match "^HDFC_SKY_API_SECRET=(.+)$") { $apiSecret = $matches[1].Trim() }
    if ($_ -match "^HDFC_SKY_REQUEST_TOKEN=(.+)$") { $requestToken = $matches[1].Trim() }
    if ($_ -match "^HDFC_SKY_TOKEN_ID=(.+)$") { $tokenId = $matches[1].Trim() }
}

Write-Host "Current credentials:" -ForegroundColor Yellow
Write-Host "  API Key: $($apiKey.Substring(0, [Math]::Min(20, $apiKey.Length)))..." -ForegroundColor Gray
Write-Host "  Request Token: $($requestToken.Substring(0, [Math]::Min(40, $requestToken.Length)))..." -ForegroundColor Gray
if ($tokenId) {
    Write-Host "  Token ID: $($tokenId.Substring(0, [Math]::Min(20, $tokenId.Length)))... ✅" -ForegroundColor Green
} else {
    Write-Host "  Token ID: Not set ⚠️" -ForegroundColor Yellow
}
Write-Host ""

# Step 1: Try authorise if token_id is available
if ($tokenId) {
    Write-Host "[Step 1] Authorising request token with token_id..." -ForegroundColor Cyan
    $authoriseUrl = "https://developer.hdfcsky.com/oapi/v1/authorise?api_key=$apiKey&token_id=$tokenId&consent=True&request_token=$requestToken"
    $headers = @{
        "User-Agent" = "AurumHarmony/1.0"
        "Content-Type" = "application/json"
    }
    
    try {
        $authResponse = Invoke-RestMethod -Uri $authoriseUrl -Method Get -Headers $headers -ErrorAction Stop
        Write-Host "  ✅ Authorise successful!" -ForegroundColor Green
        $validatedToken = $authResponse.requestToken
        if ($validatedToken) {
            Write-Host "  Got validated token: $($validatedToken.Substring(0, [Math]::Min(40, $validatedToken.Length)))..." -ForegroundColor Cyan
            $requestToken = $validatedToken
        }
    } catch {
        Write-Host "  ⚠️ Authorise failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "  Proceeding with original token..." -ForegroundColor Gray
    }
    Write-Host ""
}

# Step 2: Try to get access token
Write-Host "[Step 2] Getting access token..." -ForegroundColor Cyan
$accessUrl = "https://developer.hdfcsky.com/oapi/v1/access-token?api_key=$apiKey&request_token=$requestToken"
$accessBody = @{ api_secret = $apiSecret } | ConvertTo-Json
$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
    "User-Agent" = "AurumHarmony/1.0"
}

try {
    $response = Invoke-RestMethod -Uri $accessUrl -Method Post -Body $accessBody -Headers $headers -ErrorAction Stop
    Write-Host "`n🎉 SUCCESS! Access Token obtained!" -ForegroundColor Green
    Write-Host "Access Token: $($response.access_token.Substring(0, [Math]::Min(50, $response.access_token.Length)))..." -ForegroundColor Cyan
    Write-Host "Full Response: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Gray
    Write-Host "`n✅ You can now use the HDFC Sky API!" -ForegroundColor Green
    exit 0
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMsg = $_.ErrorDetails.Message
    
    Write-Host "`n❌ Error $statusCode" -ForegroundColor Red
    Write-Host "Response: $errorMsg" -ForegroundColor Yellow
    
    if ($statusCode -eq 401) {
        Write-Host "`n⚠️ 401 Error - Possible causes:" -ForegroundColor Yellow
        Write-Host "  1. Request token expired (they expire quickly!)" -ForegroundColor Gray
        Write-Host "  2. Need token_id for /authorise step" -ForegroundColor Gray
        Write-Host "  3. Token format incorrect`n" -ForegroundColor Gray
        
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Generate a FRESH request token in portal" -ForegroundColor White
        Write-Host "  2. Use it IMMEDIATELY (within seconds)" -ForegroundColor White
        Write-Host "  3. If you found token_id, add it to .env:" -ForegroundColor White
        Write-Host "     Add-Content -Path .env -Value 'HDFC_SKY_TOKEN_ID=your_token_id'`n" -ForegroundColor Gray
        
        # Try form-data format as fallback
        Write-Host "Trying form-data format as fallback..." -ForegroundColor Yellow
        $formBody = @{ api_secret = $apiSecret }
        $formHeaders = @{
            "Content-Type" = "application/x-www-form-urlencoded"
            "Accept" = "application/json"
            "User-Agent" = "AurumHarmony/1.0"
        }
        
        try {
            $formResponse = Invoke-RestMethod -Uri $accessUrl -Method Post -Body $formBody -ContentType "application/x-www-form-urlencoded" -Headers $formHeaders -ErrorAction Stop
            Write-Host "`n🎉 SUCCESS with form-data!" -ForegroundColor Green
            Write-Host "Access Token: $($formResponse.access_token.Substring(0, [Math]::Min(50, $formResponse.access_token.Length)))..." -ForegroundColor Cyan
            exit 0
        } catch {
            Write-Host "  ❌ Form-data also failed" -ForegroundColor Red
        }
    }
}

Write-Host ""

