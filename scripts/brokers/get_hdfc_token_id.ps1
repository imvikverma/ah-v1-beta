# Get HDFC Sky token_id from URL
# After logging in via web, the URL contains api_key and token_id

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "HDFC Sky Token ID Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Step 1: Get token_id from URL" -ForegroundColor Yellow
Write-Host ""
Write-Host "After logging in to HDFC Sky developer portal," -ForegroundColor Cyan
Write-Host "check the URL in your browser. It should look like:" -ForegroundColor White
Write-Host ""
Write-Host "  https://developer.hdfcsky.com/oapi/v1/dashboard/apps?api_key=...&token_id=..." -ForegroundColor Gray
Write-Host ""
Write-Host "Option 1: Use template file (easier for pasting long URLs)" -ForegroundColor Cyan
Write-Host "  .\scripts\brokers\import_hdfc_token_id.ps1" -ForegroundColor Green
Write-Host ""
Write-Host "Option 2: Paste URL directly here" -ForegroundColor Cyan
Write-Host ""

$url = Read-Host "Paste the URL here (or press Enter to use template file method)"

if ([string]::IsNullOrWhiteSpace($url)) {
    Write-Host ""
    Write-Host "Using template file method instead..." -ForegroundColor Yellow
    Write-Host ""
    & "$PSScriptRoot\import_hdfc_token_id.ps1"
    exit 0
}

# Parse URL to extract api_key and token_id
try {
    $uri = [System.Uri]$url
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
    
    $apiKey = $query["api_key"]
    $tokenId = $query["token_id"]
    
    if (-not $apiKey) {
        Write-Host "❌ api_key not found in URL" -ForegroundColor Red
        Write-Host "   Make sure the URL contains ?api_key=..." -ForegroundColor Yellow
        exit 1
    }
    
    if (-not $tokenId) {
        Write-Host "❌ token_id not found in URL" -ForegroundColor Red
        Write-Host "   Make sure the URL contains &token_id=..." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host ""
    Write-Host "✅ Found credentials:" -ForegroundColor Green
    Write-Host "   API Key: $($apiKey.Substring(0, [Math]::Min(30, $apiKey.Length)))..." -ForegroundColor Gray
    Write-Host "   Token ID: $($tokenId.Substring(0, [Math]::Min(30, $tokenId.Length)))..." -ForegroundColor Gray
    Write-Host ""
    
    # Read existing .env
    $envFile = ".env"
    $envContent = @()
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile
    }
    
    # Update or add credentials
    $newContent = @()
    $apiKeyFound = $false
    $tokenIdFound = $false
    
    foreach ($line in $envContent) {
        if ($line -match '^HDFC_SKY_API_KEY\s*=') {
            $newContent += "HDFC_SKY_API_KEY=$apiKey"
            $apiKeyFound = $true
        } elseif ($line -match '^HDFC_SKY_TOKEN_ID\s*=') {
            $newContent += "HDFC_SKY_TOKEN_ID=$tokenId"
            $tokenIdFound = $true
        } else {
            $newContent += $line
        }
    }
    
    # Add if not found
    if (-not $apiKeyFound) {
        $newContent += ""
        $newContent += "# HDFC Sky API Credentials"
        $newContent += "HDFC_SKY_API_KEY=$apiKey"
    }
    
    if (-not $tokenIdFound) {
        if (-not $apiKeyFound) {
            # Already added section above
        } else {
            # Add token_id to existing section
            $insertIndex = $newContent.Count
            for ($i = $newContent.Count - 1; $i -ge 0; $i--) {
                if ($newContent[$i] -match '^HDFC_SKY_API_KEY\s*=') {
                    $insertIndex = $i + 1
                    break
                }
            }
            $newContent = $newContent[0..($insertIndex-1)] + "HDFC_SKY_TOKEN_ID=$tokenId" + $newContent[$insertIndex..($newContent.Count-1)]
        }
    }
    
    # Write to .env
    $newContent | Set-Content $envFile -Encoding UTF8
    
    Write-Host "✅ Credentials saved to .env file!" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "✅ Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next step: Test the connection" -ForegroundColor Yellow
    Write-Host "  python scripts/brokers/test_hdfc_connection.py" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "❌ Error parsing URL: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please make sure you paste the complete URL with ?api_key=...&token_id=..." -ForegroundColor Yellow
    exit 1
}

