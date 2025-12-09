# Kotak Neo Credentials Setup Script
# Interactive script to help set up Kotak Neo API credentials in .env file

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kotak Neo API Credentials Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get project root
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$envFile = Join-Path $projectRoot ".env"

Write-Host "📋 This script will help you add Kotak Neo credentials to your .env file" -ForegroundColor Yellow
Write-Host ""

# Check if .env exists
if (-not (Test-Path $envFile)) {
    Write-Host "⚠️  .env file not found. Creating new one..." -ForegroundColor Yellow
    New-Item -Path $envFile -ItemType File -Force | Out-Null
    Write-Host "✅ Created .env file" -ForegroundColor Green
}

# Read existing .env
$envContent = @{}
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+?)\s*=\s*(.+?)\s*$') {
            $envContent[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
}

Write-Host "Step 1: API Access Token" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────" -ForegroundColor Gray
Write-Host "1. Open Kotak Neo app on your phone" -ForegroundColor White
Write-Host "2. Go to: Invest → Trade API" -ForegroundColor White
Write-Host "3. Create/Select an app and copy the Access Token" -ForegroundColor White
Write-Host ""
$accessToken = Read-Host "Enter your Access Token (or press Enter to skip)"
if ($accessToken) {
    # Remove 'Bearer ' prefix if present
    if ($accessToken -match '^Bearer\s+(.+)$') {
        $accessToken = $matches[1]
    }
    $envContent["KOTAK_NEO_ACCESS_TOKEN"] = $accessToken
    Write-Host "✅ Access Token saved" -ForegroundColor Green
} else {
    Write-Host "⏭️  Skipped" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "Step 2: Mobile Number" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────" -ForegroundColor Gray
Write-Host "Format: +91XXXXXXXXXX (no spaces, no dashes)" -ForegroundColor White
Write-Host "Example: +919876543210" -ForegroundColor White
Write-Host ""
$mobileNumber = Read-Host "Enter your mobile number (or press Enter to skip)"
if ($mobileNumber) {
    # Validate format
    if ($mobileNumber -notmatch '^\+91\d{10}$') {
        Write-Host "⚠️  Warning: Mobile number format might be incorrect" -ForegroundColor Yellow
        Write-Host "   Expected: +91XXXXXXXXXX (e.g., +919876543210)" -ForegroundColor Yellow
        $confirm = Read-Host "   Continue anyway? (y/n)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            $mobileNumber = $null
        }
    }
    if ($mobileNumber) {
        $envContent["KOTAK_NEO_MOBILE_NUMBER"] = $mobileNumber
        Write-Host "✅ Mobile Number saved" -ForegroundColor Green
    }
} else {
    Write-Host "⏭️  Skipped" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "Step 3: Client Code (UCC)" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────" -ForegroundColor Gray
Write-Host "Your Client Code (UCC) can be found in:" -ForegroundColor White
Write-Host "  - Kotak Neo app → Profile/Account section" -ForegroundColor White
Write-Host "  - Contract notes or statements" -ForegroundColor White
Write-Host "  - Kotak Securities website → My Account" -ForegroundColor White
Write-Host ""
$clientCode = Read-Host "Enter your Client Code (UCC) (or press Enter to skip)"
if ($clientCode) {
    $envContent["KOTAK_NEO_CLIENT_CODE"] = $clientCode.Trim()
    Write-Host "✅ Client Code saved" -ForegroundColor Green
} else {
    Write-Host "⏭️  Skipped" -ForegroundColor Yellow
}
Write-Host ""

# Write to .env file
Write-Host "📝 Writing credentials to .env file..." -ForegroundColor Yellow

# Read existing .env to preserve other variables
$existingLines = @()
if (Test-Path $envFile) {
    $existingLines = Get-Content $envFile
}

# Create new content
$newContent = @()
$kotakKeys = @("KOTAK_NEO_ACCESS_TOKEN", "KOTAK_NEO_MOBILE_NUMBER", "KOTAK_NEO_CLIENT_CODE")
$processedKeys = @()

# Keep existing non-Kotak variables
foreach ($line in $existingLines) {
    $shouldKeep = $true
    foreach ($key in $kotakKeys) {
        if ($line -match "^$key\s*=") {
            $shouldKeep = $false
            $processedKeys += $key
            break
        }
    }
    if ($shouldKeep) {
        $newContent += $line
    }
}

# Add Kotak credentials
if ($envContent.ContainsKey("KOTAK_NEO_ACCESS_TOKEN")) {
    $newContent += "# Kotak Neo API Credentials"
    $newContent += "KOTAK_NEO_ACCESS_TOKEN=$($envContent['KOTAK_NEO_ACCESS_TOKEN'])"
    $newContent += "KOTAK_NEO_MOBILE_NUMBER=$($envContent['KOTAK_NEO_MOBILE_NUMBER'])"
    $newContent += "KOTAK_NEO_CLIENT_CODE=$($envContent['KOTAK_NEO_CLIENT_CODE'])"
    $newContent += ""
}

# Write to file
$newContent | Set-Content $envFile -Encoding UTF8

Write-Host "✅ Credentials saved to .env file" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Set up TOTP (if not done already):" -ForegroundColor White
Write-Host "   - Open Kotak Neo app → Invest → Trade API → TOTP Registration" -ForegroundColor Gray
Write-Host "   - Scan QR code with Google/Microsoft Authenticator" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Test your connection:" -ForegroundColor White
Write-Host "   python scripts/brokers/test_kotak_connection.py" -ForegroundColor Gray
Write-Host ""
Write-Host "3. For detailed setup instructions, see:" -ForegroundColor White
Write-Host "   documentation/setup/KOTAK_NEO_SETUP_GUIDE.md" -ForegroundColor Gray
Write-Host ""

