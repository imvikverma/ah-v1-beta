# Test Broker API Connections
# Tests HDFC Sky and Kotak Neo API connections

param(
    [switch]$HDFC = $false,
    [switch]$Kotak = $false,
    [switch]$All = $true
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Broker API Connection Test" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

# Get project root
$scriptPath = $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath
$maxDepth = 10
$depth = 0
while ($depth -lt $maxDepth) {
    if (Test-Path (Join-Path $projectRoot ".git")) { break }
    if (Test-Path (Join-Path $projectRoot "start-all.ps1")) { break }
    $parent = Split-Path -Parent $projectRoot
    if ($parent -eq $projectRoot) { break }
    $projectRoot = $parent
    $depth++
}

Set-Location $projectRoot

# Activate venv
if (Test-Path ".venv\Scripts\Activate.ps1") {
    & ".venv\Scripts\Activate.ps1"
    Write-Host "[OK] Virtual environment activated" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Virtual environment not found!" -ForegroundColor Red
    Write-Host "Run rebuild_flask_env.ps1 first" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[1] Checking environment variables..." -ForegroundColor Yellow

# Check HDFC Sky credentials
$hdfcKey = $env:HDFC_SKY_API_KEY
$hdfcSecret = $env:HDFC_SKY_API_SECRET
$hdfcTokenId = $env:HDFC_SKY_TOKEN_ID
$hdfcAccessToken = $env:HDFC_SKY_ACCESS_TOKEN

if ($hdfcKey -and $hdfcSecret) {
    Write-Host "  [OK] HDFC Sky API Key: Found" -ForegroundColor Green
    Write-Host "  [OK] HDFC Sky API Secret: Found" -ForegroundColor Green
    if ($hdfcTokenId) {
        Write-Host "  [OK] HDFC Sky Token ID: Found" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] HDFC Sky Token ID: Not set" -ForegroundColor Yellow
    }
    if ($hdfcAccessToken) {
        Write-Host "  [OK] HDFC Sky Access Token: Found" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] HDFC Sky Access Token: Not set (will be fetched)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] HDFC Sky credentials: Not configured" -ForegroundColor Yellow
    Write-Host "    Set HDFC_SKY_API_KEY and HDFC_SKY_API_SECRET environment variables" -ForegroundColor Gray
}

# Check Kotak Neo credentials
$kotakApiKey = $env:KOTAK_NEO_API_KEY
$kotakApiSecret = $env:KOTAK_NEO_API_SECRET
$kotakUserId = $env:KOTAK_NEO_USER_ID
$kotakPassword = $env:KOTAK_NEO_PASSWORD
$kotakPin = $env:KOTAK_NEO_PIN

if ($kotakApiKey -and $kotakApiSecret) {
    Write-Host "  [OK] Kotak Neo API Key: Found" -ForegroundColor Green
    Write-Host "  [OK] Kotak Neo API Secret: Found" -ForegroundColor Green
    if ($kotakUserId -and $kotakPassword) {
        Write-Host "  [OK] Kotak Neo User Credentials: Found" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Kotak Neo User Credentials: Not set" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] Kotak Neo credentials: Not configured" -ForegroundColor Yellow
    Write-Host "    Set KOTAK_NEO_API_KEY and KOTAK_NEO_API_SECRET environment variables" -ForegroundColor Gray
}

Write-Host "`n[2] Testing broker connections..." -ForegroundColor Yellow

# Test HDFC Sky
if ($All -or $HDFC) {
    Write-Host "`n  Testing HDFC Sky..." -ForegroundColor Cyan
    try {
        $testScript = @"
import sys
import os
sys.path.insert(0, r'$projectRoot')

from api.hdfc_sky_api import HDFCSkyAPI

# Try to create client
try:
    api_key = os.getenv('HDFC_SKY_API_KEY')
    api_secret = os.getenv('HDFC_SKY_API_SECRET')
    token_id = os.getenv('HDFC_SKY_TOKEN_ID')
    access_token = os.getenv('HDFC_SKY_ACCESS_TOKEN')
    
    if not api_key or not api_secret:
        print('ERROR: HDFC Sky credentials not configured')
        sys.exit(1)
    
    client = HDFCSkyAPI(
        api_key=api_key,
        api_secret=api_secret,
        token_id=token_id,
        access_token=access_token
    )
    
    # Test authentication
    if client.is_authenticated():
        print('SUCCESS: HDFC Sky client authenticated')
        
        # Try to get account info
        try:
            account_info = client.get_account_info()
            print(f'SUCCESS: Account info retrieved - {account_info}')
        except Exception as e:
            print(f'WARNING: Could not fetch account info: {e}')
    else:
        print('ERROR: HDFC Sky client not authenticated')
        print('You may need to generate access token first')
        sys.exit(1)
        
except Exception as e:
    print(f'ERROR: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"@
        $testScript | python
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] HDFC Sky connection test passed" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] HDFC Sky connection test failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [ERROR] HDFC Sky test error: $_" -ForegroundColor Red
    }
}

# Test Kotak Neo
if ($All -or $Kotak) {
    Write-Host "`n  Testing Kotak Neo..." -ForegroundColor Cyan
    try {
        $testScript = @"
import sys
import os
sys.path.insert(0, r'$projectRoot')

from api.kotak_neo import KotakNeoAPI

# Try to create client
try:
    api_key = os.getenv('KOTAK_NEO_API_KEY')
    api_secret = os.getenv('KOTAK_NEO_API_SECRET')
    user_id = os.getenv('KOTAK_NEO_USER_ID')
    password = os.getenv('KOTAK_NEO_PASSWORD')
    pin = os.getenv('KOTAK_NEO_PIN')
    
    if not api_key or not api_secret:
        print('ERROR: Kotak Neo credentials not configured')
        sys.exit(1)
    
    client = KotakNeoAPI(
        api_key=api_key,
        api_secret=api_secret,
        user_id=user_id,
        password=password,
        pin=pin
    )
    
    # Test authentication
    if client.is_authenticated():
        print('SUCCESS: Kotak Neo client authenticated')
        
        # Try to get account info
        try:
            account_info = client.get_account_info()
            print(f'SUCCESS: Account info retrieved - {account_info}')
        except Exception as e:
            print(f'WARNING: Could not fetch account info: {e}')
    else:
        print('ERROR: Kotak Neo client not authenticated')
        print('You may need to login first')
        sys.exit(1)
        
except Exception as e:
    print(f'ERROR: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"@
        $testScript | python
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Kotak Neo connection test passed" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] Kotak Neo connection test failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [ERROR] Kotak Neo test error: $_" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Test Complete" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Configure broker credentials in .env file" -ForegroundColor White
Write-Host "  2. Run: .\scripts\test_broker_connections.ps1 -HDFC" -ForegroundColor White
Write-Host "  3. Run: .\scripts\test_broker_connections.ps1 -Kotak" -ForegroundColor White
Write-Host "  4. Start backend: .\start-all.ps1 (Option 1)" -ForegroundColor White
Write-Host "  5. Test API endpoints via frontend or Postman" -ForegroundColor White
Write-Host ""

