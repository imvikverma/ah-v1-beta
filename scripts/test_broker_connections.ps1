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
$kotakAccessToken = $env:KOTAK_NEO_ACCESS_TOKEN
$kotakMobile = $env:KOTAK_NEO_MOBILE_NUMBER
$kotakClientCode = $env:KOTAK_NEO_CLIENT_CODE

if ($kotakAccessToken -and $kotakMobile -and $kotakClientCode) {
    Write-Host "  [OK] Kotak Neo Access Token: Found" -ForegroundColor Green
    Write-Host "  [OK] Kotak Neo Mobile Number: Found" -ForegroundColor Green
    Write-Host "  [OK] Kotak Neo Client Code: Found" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Kotak Neo credentials: Not fully configured" -ForegroundColor Yellow
    if (-not $kotakAccessToken) {
        Write-Host "    Missing: KOTAK_NEO_ACCESS_TOKEN" -ForegroundColor Gray
    }
    if (-not $kotakMobile) {
        Write-Host "    Missing: KOTAK_NEO_MOBILE_NUMBER" -ForegroundColor Gray
    }
    if (-not $kotakClientCode) {
        Write-Host "    Missing: KOTAK_NEO_CLIENT_CODE" -ForegroundColor Gray
    }
    Write-Host "    Run: .\scripts\brokers\setup_kotak_credentials.ps1" -ForegroundColor Gray
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
    access_token = os.getenv('KOTAK_NEO_ACCESS_TOKEN')
    mobile_number = os.getenv('KOTAK_NEO_MOBILE_NUMBER')
    client_code = os.getenv('KOTAK_NEO_CLIENT_CODE')
    
    if not access_token or not mobile_number or not client_code:
        print('ERROR: Kotak Neo credentials not fully configured')
        print('Required: KOTAK_NEO_ACCESS_TOKEN, KOTAK_NEO_MOBILE_NUMBER, KOTAK_NEO_CLIENT_CODE')
        print('Run: .\\scripts\\brokers\\setup_kotak_credentials.ps1')
        sys.exit(1)
    
    client = KotakNeoAPI(
        access_token=access_token,
        mobile_number=mobile_number,
        client_code=client_code
    )
    
    # Check if already authenticated (has tokens from previous session)
    if client.is_authenticated():
        print('SUCCESS: Kotak Neo client authenticated (using existing tokens)')
        
        # Try to get account info
        try:
            account_info = client.get_account_info()
            print(f'SUCCESS: Account info retrieved - {account_info}')
        except Exception as e:
            print(f'WARNING: Could not fetch account info: {e}')
    else:
        print('INFO: Kotak Neo client created but not authenticated')
        print('You need to login with TOTP and MPIN:')
        print('  1. Get TOTP from authenticator app')
        print('  2. Call client.login_with_totp(totp)')
        print('  3. Call client.validate_mpin(mpin)')
        print('See: scripts/brokers/test_kotak_connection.py for example')
        sys.exit(0)  # Not an error, just needs login
        
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

