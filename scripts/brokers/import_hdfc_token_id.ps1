# Import HDFC Sky Token ID from File
# Easier method - paste the URL into hdfc_token_id_template.txt first

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "HDFC Sky Token ID Import" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templateFile = Join-Path $scriptDir "hdfc_token_id_template.txt"
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
# HDFC Sky Credentials Template
# 
# INSTRUCTIONS:
# Since the URL doesn't contain api_key and token_id, extract them from browser:
#
# METHOD 1: Browser Console (Easiest)
# 1. Open Developer Tools (F12) → Console tab
# 2. Run: Object.keys(localStorage).forEach(k => console.log(k, localStorage.getItem(k)))
# 3. Look for api_key and token_id values
#
# METHOD 2: Application Tab
# 1. Open Developer Tools (F12) → Application tab
# 2. Check Local Storage → https://developer.hdfcsky.com
# 3. Look for api_key and token_id keys
#
# METHOD 3: Network Tab
# 1. Open Developer Tools (F12) → Network tab
# 2. Refresh page, check any API call's URL or headers
# 3. Look for ?api_key=...&token_id=... in request URL
#
# Once you have the values, paste them below:
#
# IMPORTANT: This file will be deleted after importing for security

# Option 1: Paste the COMPLETE URL here (if it has ?api_key=...&token_id=...)
URL=

# Option 2: Or paste the values directly here:
API_KEY=
TOKEN_ID=
"@ | Out-File -FilePath $templateFile -Encoding UTF8
    
    Write-Host "✅ Template file created!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Open: $templateFile" -ForegroundColor White
    Write-Host "   2. Replace the placeholder URL with your actual URL" -ForegroundColor White
    Write-Host "   3. Save the file" -ForegroundColor White
    Write-Host "   4. Run this script again" -ForegroundColor White
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
    if ($content -match 'your_api_key_here|your_token_id_here') {
        Write-Host "⚠️  Template file still has placeholder values" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Opening template file in Notepad for you to fill in..." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📝 Instructions:" -ForegroundColor Yellow
        Write-Host "   The URL doesn't contain api_key and token_id!" -ForegroundColor Cyan
        Write-Host "   Extract them from browser DevTools:" -ForegroundColor White
        Write-Host ""
        Write-Host "   METHOD 1: Browser Console (Easiest) - Based on React Code" -ForegroundColor Yellow
        Write-Host "   1. Press F12 → Console tab" -ForegroundColor White
        Write-Host "   2. Run these exact commands:" -ForegroundColor White
        Write-Host "      localStorage.getItem('api_key')" -ForegroundColor Gray
        Write-Host "      localStorage.getItem('token_id')" -ForegroundColor Gray
        Write-Host "      localStorage.getItem('accessToken')" -ForegroundColor Gray
        Write-Host "   3. Copy the values and paste them in template file" -ForegroundColor White
        Write-Host ""
        Write-Host "   METHOD 2: Application Tab" -ForegroundColor Yellow
        Write-Host "   1. Press F12 → Application tab" -ForegroundColor White
        Write-Host "   2. Check Local Storage → https://developer.hdfcsky.com" -ForegroundColor White
        Write-Host "   3. Look for api_key and token_id keys" -ForegroundColor White
        Write-Host ""
        Write-Host "   Then paste the values in the template file (API_KEY=... and TOKEN_ID=...)" -ForegroundColor Cyan
        Write-Host "   Or paste the complete URL if it has ?api_key=...&token_id=..." -ForegroundColor Cyan
        Write-Host "   4. Save the file (Ctrl+S)" -ForegroundColor White
        Write-Host "   5. Close Notepad and come back here" -ForegroundColor White
        Write-Host ""
        Start-Sleep -Milliseconds 500
        Start-Process notepad.exe -ArgumentList $templateFile
        Write-Host "Press Enter after you've saved the file in Notepad..." -ForegroundColor Cyan
        Read-Host
    }
}

# Read template file
Write-Host "📋 Reading URL from template file..." -ForegroundColor Yellow
Write-Host "   File: $templateFile" -ForegroundColor Gray
Write-Host ""

$apiKey = $null
$tokenId = $null
$url = $null
$lines = Get-Content $templateFile

foreach ($line in $lines) {
    # Skip comments and empty lines
    if ($line -match '^\s*#') { continue }
    if ($line -match '^\s*$') { continue }
    
    # Parse API_KEY=...
    if ($line -match '^\s*API_KEY\s*=\s*(.+?)\s*$') {
        $apiKey = $matches[1].Trim()
    }
    
    # Parse TOKEN_ID=...
    if ($line -match '^\s*TOKEN_ID\s*=\s*(.+?)\s*$') {
        $tokenId = $matches[1].Trim()
    }
    
    # Parse ACCESS_TOKEN=... (optional, JWT token)
    if ($line -match '^\s*ACCESS_TOKEN\s*=\s*(.+?)\s*$') {
        $accessToken = $matches[1].Trim()
    }
    
    # Parse URL=... (fallback method)
    if ($line -match '^\s*URL\s*=\s*(.+?)\s*$') {
        $url = $matches[1].Trim()
    }
}

# If URL provided, try to extract from URL
if ($url -and -not $apiKey -and -not $tokenId) {
    Write-Host "📋 Found URL, extracting credentials..." -ForegroundColor Yellow
    try {
        $uri = [System.Uri]$url
        $query = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
        
        if (-not $apiKey) { $apiKey = $query["api_key"] }
        if (-not $tokenId) { $tokenId = $query["token_id"] }
    } catch {
        Write-Host "⚠️  Could not parse URL, trying direct values..." -ForegroundColor Yellow
    }
}

# Validate we have the values
if (-not $apiKey -or [string]::IsNullOrWhiteSpace($apiKey)) {
    Write-Host "❌ api_key not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please extract api_key from browser DevTools:" -ForegroundColor Yellow
    Write-Host "  1. Press F12 → Console tab" -ForegroundColor White
    Write-Host "  2. Run: Object.keys(localStorage).forEach(k => console.log(k, localStorage.getItem(k)))" -ForegroundColor Gray
    Write-Host "  3. Look for api_key value and paste it in the template file" -ForegroundColor White
    Write-Host ""
    exit 1
}

if (-not $tokenId -or [string]::IsNullOrWhiteSpace($tokenId)) {
    Write-Host "❌ token_id not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please extract token_id from browser DevTools:" -ForegroundColor Yellow
    Write-Host "  1. Press F12 → Console tab" -ForegroundColor White
    Write-Host "  2. Run: Object.keys(localStorage).forEach(k => console.log(k, localStorage.getItem(k)))" -ForegroundColor Gray
    Write-Host "  3. Look for token_id value and paste it in the template file" -ForegroundColor White
    Write-Host ""
    exit 1
}

try {
    
    Write-Host "✅ Extracted credentials:" -ForegroundColor Green
    Write-Host "   API Key: $($apiKey.Substring(0, [Math]::Min(30, $apiKey.Length)))..." -ForegroundColor Gray
    Write-Host "   Token ID: $($tokenId.Substring(0, [Math]::Min(30, $tokenId.Length)))..." -ForegroundColor Gray
    Write-Host ""
    
    # Read existing .env
    $envContent = @()
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile
    }
    
    # Update or add credentials
    $newContent = @()
    $apiKeyFound = $false
    $tokenIdFound = $false
    $accessTokenFound = $false
    
    foreach ($line in $envContent) {
        if ($line -match '^HDFC_SKY_API_KEY\s*=') {
            $newContent += "HDFC_SKY_API_KEY=$apiKey"
            $apiKeyFound = $true
        } elseif ($line -match '^HDFC_SKY_TOKEN_ID\s*=') {
            $newContent += "HDFC_SKY_TOKEN_ID=$tokenId"
            $tokenIdFound = $true
        } elseif ($line -match '^HDFC_SKY_ACCESS_TOKEN\s*=') {
            if ($accessToken) {
                $newContent += "HDFC_SKY_ACCESS_TOKEN=$accessToken"
            } else {
                $newContent += $line
            }
            $accessTokenFound = $true
        } else {
            $newContent += $line
        }
    }
    
    # Add if not found
    if (-not $apiKeyFound) {
        $newContent += ""
        $newContent += "# HDFC Sky API Credentials (from localStorage)"
        $newContent += "HDFC_SKY_API_KEY=$apiKey"
    }
    
    if (-not $tokenIdFound) {
        if (-not $apiKeyFound) {
            # Already added section above
        } else {
            # Add token_id after api_key
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
    
    # Add access token if provided
    if ($accessToken -and -not $accessTokenFound) {
        $insertIndex = $newContent.Count
        for ($i = $newContent.Count - 1; $i -ge 0; $i--) {
            if ($newContent[$i] -match '^HDFC_SKY_TOKEN_ID\s*=') {
                $insertIndex = $i + 1
                break
            }
        }
        $newContent = $newContent[0..($insertIndex-1)] + "HDFC_SKY_ACCESS_TOKEN=$accessToken" + $newContent[$insertIndex..($newContent.Count-1)]
    }
    
    # Write to .env
    $newContent | Set-Content $envFile -Encoding UTF8
    
    Write-Host "✅ Credentials saved to .env file!" -ForegroundColor Green
    Write-Host ""
    
    # Ask if user wants to delete template file
    Write-Host "🔒 Security: Delete template file with URL? (recommended)" -ForegroundColor Yellow
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
    Write-Host "Next step: Test the connection" -ForegroundColor Yellow
    Write-Host "  python scripts/brokers/test_hdfc_connection.py" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check the template file and make sure API_KEY and TOKEN_ID are filled in" -ForegroundColor Yellow
    exit 1
}

