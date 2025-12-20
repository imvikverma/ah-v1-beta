# Import HDFC Sky Credentials from File
# Easier method - paste credentials into hdfc_credentials_template.txt first

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "HDFC Sky Credentials Import" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templateFile = Join-Path $scriptDir "hdfc_credentials_template.txt"
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
# HDFC Sky API Credentials Template
# 
# INSTRUCTIONS:
# 1. Fill in the values below (remove the # and example values)
# 2. Replace placeholder values with your actual credentials
# 3. Save this file
# 4. Run this script again: .\scripts\brokers\import_hdfc_credentials.ps1
#
# IMPORTANT: This file will be deleted after importing for security
#
# Get these from: https://developer.hdfcsky.com
# After creating an app in the developer portal, you'll get:
# - API Key (also called Client ID)
# - API Secret (also called Client Secret)

# Paste your API Key here (from HDFC Sky developer portal)
API_KEY=your_api_key_here

# Paste your API Secret here (from HDFC Sky developer portal)
# This is a long string - paste it carefully!
API_SECRET=your_api_secret_here

# OPTIONAL: Access Token and Refresh Token (after OAuth)
# These will be obtained after completing OAuth flow
# Leave as placeholders if you haven't done OAuth yet
ACCESS_TOKEN=your_access_token_here
REFRESH_TOKEN=your_refresh_token_here
"@ | Out-File -FilePath $templateFile -Encoding UTF8
    
    Write-Host "✅ Template file created!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Fill in your credentials in Notepad:" -ForegroundColor White
    Write-Host "      - API_KEY: Get from https://developer.hdfcsky.com" -ForegroundColor Gray
    Write-Host "      - API_SECRET: Get from https://developer.hdfcsky.com" -ForegroundColor Gray
    Write-Host "      - ACCESS_TOKEN & REFRESH_TOKEN: Optional (after OAuth)" -ForegroundColor Gray
    Write-Host "   2. Save the file" -ForegroundColor White
    Write-Host "   3. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "Opening template file in Notepad..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 500
    Start-Process notepad.exe -ArgumentList $templateFile
    exit 0
} else {
    # Template exists - check if it needs to be filled
    Write-Host "📋 Template file found: $templateFile" -ForegroundColor Green
    Write-Host ""
    
    # Check if file has placeholder values
    $content = Get-Content $templateFile -Raw
    if ($content -match 'your_api_key_here|your_api_secret_here') {
        Write-Host "⚠️  Template file still has placeholder values" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Opening template file in Notepad for you to fill in..." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📝 Instructions:" -ForegroundColor Yellow
        Write-Host "   1. Replace 'your_api_key_here' with your API Key" -ForegroundColor White
        Write-Host "   2. Replace 'your_api_secret_here' with your API Secret" -ForegroundColor White
        Write-Host "   3. Save the file (Ctrl+S)" -ForegroundColor White
        Write-Host "   4. Close Notepad and come back here" -ForegroundColor White
        Write-Host ""
        Start-Sleep -Milliseconds 500
        Start-Process notepad.exe -ArgumentList $templateFile
        Write-Host "Press Enter after you've saved the file in Notepad..." -ForegroundColor Cyan
        Read-Host
    }
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
        
        # Skip placeholder values
        $isPlaceholder = $false
        if ($value -match '^your_.*_here$' -or $value -eq "") {
            $isPlaceholder = $true
        }
        
        if ($isPlaceholder) {
            Write-Host "⚠️  Skipping placeholder: $key" -ForegroundColor Yellow
            continue
        }
        
        $credentials[$key] = $value
    }
}

# Validate required credentials
$required = @("API_KEY", "API_SECRET")
$missing = @()

foreach ($key in $required) {
    if (-not $credentials.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($credentials[$key])) {
        $missing += $key
    }
}

# Check for at least one identifier (CLIENT_ID, EMAIL, or MOBILE)
$hasIdentifier = $false
if ($credentials.ContainsKey("CLIENT_ID") -and $credentials['CLIENT_ID'] -notmatch '^your_') {
    $hasIdentifier = $true
}
if ($credentials.ContainsKey("EMAIL") -and $credentials['EMAIL'] -notmatch '^your_') {
    $hasIdentifier = $true
}
if ($credentials.ContainsKey("MOBILE") -and $credentials['MOBILE'] -notmatch '^your_') {
    $hasIdentifier = $true
}

if (-not $hasIdentifier) {
    $missing += "CLIENT_ID or EMAIL or MOBILE"
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Missing required credentials:" -ForegroundColor Red
    foreach ($key in $missing) {
        Write-Host "   - $key" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Please fill in all required values in the template file and try again." -ForegroundColor Yellow
    Write-Host "Template file: $templateFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Required:" -ForegroundColor Cyan
    Write-Host "   - API_KEY: Get from https://developer.hdfcsky.com" -ForegroundColor White
    Write-Host "   - API_SECRET: Get from https://developer.hdfcsky.com" -ForegroundColor White
    Write-Host ""
    Write-Host "Optional (can add later after OAuth):" -ForegroundColor Cyan
    Write-Host "   - ACCESS_TOKEN" -ForegroundColor White
    Write-Host "   - REFRESH_TOKEN" -ForegroundColor White
    exit 1
}

# Display what we found (masked)
Write-Host "✅ Found credentials:" -ForegroundColor Green
Write-Host "   API Key: $($credentials['API_KEY'].Substring(0, [Math]::Min(20, $credentials['API_KEY'].Length)))..." -ForegroundColor Gray
Write-Host "   API Secret: $($credentials['API_SECRET'].Substring(0, [Math]::Min(20, $credentials['API_SECRET'].Length)))..." -ForegroundColor Gray

if ($credentials.ContainsKey("ACCESS_TOKEN") -and $credentials['ACCESS_TOKEN'] -notmatch '^your_') {
    Write-Host "   Access Token: $($credentials['ACCESS_TOKEN'].Substring(0, [Math]::Min(20, $credentials['ACCESS_TOKEN'].Length)))..." -ForegroundColor Gray
}

if ($credentials.ContainsKey("REFRESH_TOKEN") -and $credentials['REFRESH_TOKEN'] -notmatch '^your_') {
    Write-Host "   Refresh Token: $($credentials['REFRESH_TOKEN'].Substring(0, [Math]::Min(20, $credentials['REFRESH_TOKEN'].Length)))..." -ForegroundColor Gray
}

Write-Host ""

# Read existing .env
$envContent = @{}
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+?)\s*=\s*(.+?)\s*$') {
            $envContent[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
}

# Update HDFC Sky credentials
$envContent["HDFC_SKY_API_KEY"] = $credentials['API_KEY']
$envContent["HDFC_SKY_API_SECRET"] = $credentials['API_SECRET']

if ($credentials.ContainsKey("CLIENT_ID") -and $credentials['CLIENT_ID'] -notmatch '^your_') {
    $envContent["HDFC_SKY_CLIENT_ID"] = $credentials['CLIENT_ID']
}

if ($credentials.ContainsKey("EMAIL") -and $credentials['EMAIL'] -notmatch '^your_') {
    $envContent["HDFC_SKY_EMAIL"] = $credentials['EMAIL']
}

if ($credentials.ContainsKey("MOBILE") -and $credentials['MOBILE'] -notmatch '^your_') {
    $envContent["HDFC_SKY_MOBILE"] = $credentials['MOBILE']
}

if ($credentials.ContainsKey("ACCESS_TOKEN") -and $credentials['ACCESS_TOKEN'] -notmatch '^your_') {
    $envContent["HDFC_SKY_ACCESS_TOKEN"] = $credentials['ACCESS_TOKEN']
}

if ($credentials.ContainsKey("SESSION_ID") -and $credentials['SESSION_ID'] -notmatch '^your_') {
    $envContent["HDFC_SKY_SESSION_ID"] = $credentials['SESSION_ID']
}

# Write to .env
Write-Host "📝 Writing credentials to .env file..." -ForegroundColor Yellow

# Read existing .env to preserve other variables
$existingLines = @()
if (Test-Path $envFile) {
    $existingLines = Get-Content $envFile
}

# Create new content
$newContent = @()
$hdfcKeys = @("HDFC_SKY_API_KEY", "HDFC_SKY_API_SECRET", "HDFC_SKY_CLIENT_ID", "HDFC_SKY_EMAIL", "HDFC_SKY_MOBILE", "HDFC_SKY_ACCESS_TOKEN", "HDFC_SKY_SESSION_ID")
$processedKeys = @()

# Keep existing non-HDFC variables
foreach ($line in $existingLines) {
    $shouldKeep = $true
    foreach ($key in $hdfcKeys) {
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

# Add HDFC Sky credentials section
$newContent += ""
$newContent += "# HDFC Sky API Credentials"
$newContent += "HDFC_SKY_API_KEY=$($credentials['API_KEY'])"
$newContent += "HDFC_SKY_API_SECRET=$($credentials['API_SECRET'])"

if ($credentials.ContainsKey("CLIENT_ID") -and $credentials['CLIENT_ID'] -notmatch '^your_') {
    $newContent += "HDFC_SKY_CLIENT_ID=$($credentials['CLIENT_ID'])"
}

if ($credentials.ContainsKey("EMAIL") -and $credentials['EMAIL'] -notmatch '^your_') {
    $newContent += "HDFC_SKY_EMAIL=$($credentials['EMAIL'])"
}

if ($credentials.ContainsKey("MOBILE") -and $credentials['MOBILE'] -notmatch '^your_') {
    $newContent += "HDFC_SKY_MOBILE=$($credentials['MOBILE'])"
}

if ($credentials.ContainsKey("ACCESS_TOKEN") -and $credentials['ACCESS_TOKEN'] -notmatch '^your_') {
    $newContent += "HDFC_SKY_ACCESS_TOKEN=$($credentials['ACCESS_TOKEN'])"
}

if ($credentials.ContainsKey("SESSION_ID") -and $credentials['SESSION_ID'] -notmatch '^your_') {
    $newContent += "HDFC_SKY_SESSION_ID=$($credentials['SESSION_ID'])"
}

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

if (-not ($credentials.ContainsKey("ACCESS_TOKEN") -and $credentials['ACCESS_TOKEN'] -notmatch '^your_')) {
    Write-Host "📋 Next steps:" -ForegroundColor Yellow
    Write-Host "   1. Complete OAuth flow to get access_token" -ForegroundColor White
    Write-Host "      Run: .\scripts\brokers\get_hdfc_request_token.ps1" -ForegroundColor Gray
    Write-Host "   2. Test your connection:" -ForegroundColor White
    Write-Host "      python scripts/brokers/test_hdfc_connection.py" -ForegroundColor Gray
} else {
    Write-Host "Next step: Test your connection" -ForegroundColor Yellow
    Write-Host "   python scripts/brokers/test_hdfc_connection.py" -ForegroundColor Green
}

Write-Host ""

