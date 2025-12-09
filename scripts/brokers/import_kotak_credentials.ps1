# Import Kotak Neo Credentials from File
# Easier method - paste credentials into kotak_credentials_template.txt first

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Kotak Neo Credentials Import" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templateFile = Join-Path $scriptDir "kotak_credentials_template.txt"
$projectRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$envFile = Join-Path $projectRoot ".env"

# Check if template exists
if (-not (Test-Path $templateFile)) {
    Write-Host "❌ Template file not found!" -ForegroundColor Red
    Write-Host "   Expected: $templateFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Creating template file for you..." -ForegroundColor Yellow
    
    # Create template
    @"
# Kotak Neo API Credentials Template
# 
# INSTRUCTIONS:
# 1. Fill in the values below (remove the # and example values)
# 2. Save this file
# 3. Run this script again: .\scripts\brokers\import_kotak_credentials.ps1
#
# IMPORTANT: This file will be deleted after importing for security

# Paste your Access Token here (the long string from Kotak Neo app)
ACCESS_TOKEN=your_access_token_here

# Your mobile number in format: +91XXXXXXXXXX (no spaces)
MOBILE_NUMBER=+919876543210

# Your Client Code (UCC) - usually 6-8 characters
CLIENT_CODE=ABC123
"@ | Out-File -FilePath $templateFile -Encoding UTF8
    
    Write-Host "✅ Template file created!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Open: $templateFile" -ForegroundColor White
    Write-Host "   2. Fill in your credentials (paste your token!)" -ForegroundColor White
    Write-Host "   3. Save the file" -ForegroundColor White
    Write-Host "   4. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "Opening template file for you..." -ForegroundColor Yellow
    Start-Process notepad.exe -ArgumentList $templateFile
    exit 0
}

# Read template file
Write-Host "📋 Reading credentials from template file..." -ForegroundColor Yellow
Write-Host "   File: $templateFile" -ForegroundColor Gray
Write-Host ""

$credentials = @{}
$lines = Get-Content $templateFile

foreach ($line in $lines) {
    # Skip comments and empty lines
    if ($line -match '^\s*#') { continue }
    if ($line -match '^\s*$') { continue }
    
    # Parse KEY=VALUE
    if ($line -match '^\s*([^=]+?)\s*=\s*(.+?)\s*$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # Skip placeholder values (but allow actual values that might match)
        $isPlaceholder = $false
        if ($key -eq "ACCESS_TOKEN" -and ($value -eq "your_access_token_here" -or $value -match '^your_')) {
            $isPlaceholder = $true
        }
        if ($key -eq "MOBILE_NUMBER" -and $value -eq "+919876543210") {
            $isPlaceholder = $true
        }
        if ($key -eq "CLIENT_CODE" -and $value -eq "ABC123") {
            $isPlaceholder = $true
        }
        
        if ($isPlaceholder) {
            Write-Host "⚠️  Skipping placeholder: $key" -ForegroundColor Yellow
            continue
        }
        
        $credentials[$key] = $value
    }
}

# Validate credentials
$required = @("ACCESS_TOKEN", "MOBILE_NUMBER", "CLIENT_CODE")
$missing = @()

foreach ($key in $required) {
    if (-not $credentials.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($credentials[$key])) {
        $missing += $key
    }
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Missing required credentials:" -ForegroundColor Red
    foreach ($key in $missing) {
        Write-Host "   - $key" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Please fill in all values in the template file and try again." -ForegroundColor Yellow
    Write-Host "Template file: $templateFile" -ForegroundColor Gray
    exit 1
}

# Display what we found (masked)
Write-Host "✅ Found credentials:" -ForegroundColor Green
Write-Host "   Access Token: $($credentials['ACCESS_TOKEN'].Substring(0, [Math]::Min(20, $credentials['ACCESS_TOKEN'].Length)))..." -ForegroundColor Gray
Write-Host "   Mobile Number: $($credentials['MOBILE_NUMBER'])" -ForegroundColor Gray
Write-Host "   Client Code: $($credentials['CLIENT_CODE'])" -ForegroundColor Gray
Write-Host ""

# Validate mobile number format
if ($credentials['MOBILE_NUMBER'] -notmatch '^\+91\d{10}$') {
    Write-Host "⚠️  Warning: Mobile number format might be incorrect" -ForegroundColor Yellow
    Write-Host "   Expected: +91XXXXXXXXXX (e.g., +919876543210)" -ForegroundColor Yellow
    Write-Host "   Got: $($credentials['MOBILE_NUMBER'])" -ForegroundColor Yellow
    $confirm = Read-Host "   Continue anyway? (y/n)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 1
    }
}

# Process access token (remove Bearer prefix if present)
$accessToken = $credentials['ACCESS_TOKEN']
if ($accessToken -match '^Bearer\s+(.+)$') {
    $accessToken = $matches[1]
    Write-Host "ℹ️  Removed 'Bearer ' prefix from access token" -ForegroundColor Cyan
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

# Update Kotak credentials
$envContent["KOTAK_NEO_ACCESS_TOKEN"] = $accessToken
$envContent["KOTAK_NEO_MOBILE_NUMBER"] = $credentials['MOBILE_NUMBER']
$envContent["KOTAK_NEO_CLIENT_CODE"] = $credentials['CLIENT_CODE']

# Write to .env
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

# Add Kotak credentials section
$newContent += ""
$newContent += "# Kotak Neo API Credentials"
$newContent += "KOTAK_NEO_ACCESS_TOKEN=$accessToken"
$newContent += "KOTAK_NEO_MOBILE_NUMBER=$($credentials['MOBILE_NUMBER'])"
$newContent += "KOTAK_NEO_CLIENT_CODE=$($credentials['CLIENT_CODE'])"

# Write to file
$newContent | Set-Content $envFile -Encoding UTF8

Write-Host "✅ Credentials saved to .env file!" -ForegroundColor Green
Write-Host ""

# Ask if user wants to delete template file
Write-Host "🔒 Security: Delete template file with credentials? (recommended)" -ForegroundColor Yellow
$delete = Read-Host "   Delete template file? (y/n)"
if ($delete -eq 'y' -or $delete -eq 'Y') {
    Remove-Item $templateFile -Force
    Write-Host "✅ Template file deleted for security" -ForegroundColor Green
} else {
    Write-Host "⚠️  Template file kept (remember to delete it manually for security)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: Test your connection" -ForegroundColor Yellow
Write-Host "   python scripts/brokers/test_kotak_connection.py" -ForegroundColor Green
Write-Host ""

