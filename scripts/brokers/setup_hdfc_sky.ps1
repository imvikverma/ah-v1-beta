# HDFC Sky API Setup Script
# Interactive setup for HDFC Sky API credentials

Write-Host "`n=== HDFC Sky API Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  .env file not found. Creating it..." -ForegroundColor Yellow
    New-Item -Path ".env" -ItemType File | Out-Null
    Write-Host "✅ Created .env file" -ForegroundColor Green
}

# Read existing .env
$envContent = Get-Content ".env" -ErrorAction SilentlyContinue

# Function to update or add env variable
function Update-EnvVar {
    param(
        [string]$Key,
        [string]$Value,
        [string]$Description
    )
    
    $pattern = "^$Key\s*="
    $newLine = "$Key=$Value"
    
    if ($envContent -match $pattern) {
        # Update existing
        $envContent = $envContent -replace $pattern, $newLine
        Write-Host "   ✅ Updated $Description" -ForegroundColor Green
    } else {
        # Add new
        $envContent += $newLine
        Write-Host "   ✅ Added $Description" -ForegroundColor Green
    }
}

Write-Host "📋 Step 1: API Credentials" -ForegroundColor Yellow
Write-Host ""

# Get API Key
$currentApiKey = ($envContent | Select-String "^\s*HDFC_SKY_API_KEY=(.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() })
if ($currentApiKey) {
    Write-Host "   Current API Key: $($currentApiKey.Substring(0, [Math]::Min(20, $currentApiKey.Length)))..." -ForegroundColor Gray
    $useExisting = Read-Host "   Use existing API Key? (y/n)"
    if ($useExisting -ne "y" -and $useExisting -ne "Y") {
        $apiKey = Read-Host "   Enter HDFC Sky API Key"
        if ($apiKey) {
            Update-EnvVar -Key "HDFC_SKY_API_KEY" -Value $apiKey -Description "API Key"
        }
    } else {
        $apiKey = $currentApiKey
    }
} else {
    Write-Host "   Get your API Key from: https://developer.hdfcsky.com" -ForegroundColor Cyan
    $apiKey = Read-Host "   Enter HDFC Sky API Key"
    if ($apiKey) {
        Update-EnvVar -Key "HDFC_SKY_API_KEY" -Value $apiKey -Description "API Key"
    }
}

Write-Host ""

# Get API Secret
$currentApiSecret = ($envContent | Select-String "^\s*HDFC_SKY_API_SECRET=(.+)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() })
if ($currentApiSecret) {
    Write-Host "   Current API Secret: $($currentApiSecret.Substring(0, [Math]::Min(20, $currentApiSecret.Length)))..." -ForegroundColor Gray
    $useExisting = Read-Host "   Use existing API Secret? (y/n)"
    if ($useExisting -ne "y" -and $useExisting -ne "Y") {
        $apiSecret = Read-Host "   Enter HDFC Sky API Secret" -AsSecureString
        $apiSecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiSecret)
        )
        if ($apiSecretPlain) {
            Update-EnvVar -Key "HDFC_SKY_API_SECRET" -Value $apiSecretPlain -Description "API Secret"
        }
    } else {
        $apiSecretPlain = $currentApiSecret
    }
} else {
    Write-Host "   Get your API Secret from: https://developer.hdfcsky.com" -ForegroundColor Cyan
    $apiSecret = Read-Host "   Enter HDFC Sky API Secret" -AsSecureString
    $apiSecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiSecret)
    )
    if ($apiSecretPlain) {
        Update-EnvVar -Key "HDFC_SKY_API_SECRET" -Value $apiSecretPlain -Description "API Secret"
    }
}

Write-Host ""
Write-Host "📋 Step 2: OAuth Authentication" -ForegroundColor Yellow
Write-Host ""
Write-Host "   To complete OAuth, you need to:" -ForegroundColor Cyan
Write-Host "   1. Get a request_token via OAuth flow" -ForegroundColor White
Write-Host "   2. Exchange it for an access_token" -ForegroundColor White
Write-Host ""
Write-Host "   Run this script to get request_token:" -ForegroundColor Cyan
Write-Host "   .\scripts\brokers\get_hdfc_request_token.ps1" -ForegroundColor White
Write-Host ""
Write-Host "   Or test the full connection:" -ForegroundColor Cyan
Write-Host "   python scripts/brokers/test_hdfc_connection.py" -ForegroundColor White
Write-Host ""

# Save .env
$envContent | Set-Content ".env"

Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Complete OAuth flow to get access_token" -ForegroundColor White
Write-Host "  2. Run: python scripts/brokers/test_hdfc_connection.py" -ForegroundColor White
Write-Host "  3. Add access_token and refresh_token to .env when prompted" -ForegroundColor White
Write-Host ""
