# Test System with Real Data & Generate Reports
# Tests broker APIs with live data and generates actual trading reports

$ErrorActionPreference = "Continue"

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
    exit 1
}

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Real Data Testing & Report Generation              ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Test Broker Connections
Write-Host "`n[1] Testing Broker API Connections..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────" -ForegroundColor Gray

$brokerTestScript = @"
import sys
import os
sys.path.insert(0, r'$projectRoot')

from api.hdfc_sky_api import HDFCSkyAPI
from api.kotak_neo import KotakNeoAPI

print("Testing HDFC Sky...")
try:
    hdfc = HDFCSkyAPI(
        api_key=os.getenv('HDFC_SKY_API_KEY'),
        api_secret=os.getenv('HDFC_SKY_API_SECRET'),
        token_id=os.getenv('HDFC_SKY_TOKEN_ID'),
        access_token=os.getenv('HDFC_SKY_ACCESS_TOKEN')
    )
    if hdfc.is_authenticated():
        print("✅ HDFC Sky: Authenticated")
        try:
            account = hdfc.get_account_info()
            print(f"   Account: {account}")
        except Exception as e:
            print(f"   ⚠️  Account info: {e}")
    else:
        print("❌ HDFC Sky: Not authenticated")
except Exception as e:
    print(f"❌ HDFC Sky Error: {e}")

print("\nTesting Kotak Neo...")
try:
    kotak = KotakNeoAPI(
        api_key=os.getenv('KOTAK_NEO_API_KEY'),
        api_secret=os.getenv('KOTAK_NEO_API_SECRET'),
        user_id=os.getenv('KOTAK_NEO_USER_ID'),
        password=os.getenv('KOTAK_NEO_PASSWORD'),
        pin=os.getenv('KOTAK_NEO_PIN')
    )
    if kotak.is_authenticated():
        print("✅ Kotak Neo: Authenticated")
        try:
            account = kotak.get_account_info()
            print(f"   Account: {account}")
        except Exception as e:
            print(f"   ⚠️  Account info: {e}")
    else:
        print("❌ Kotak Neo: Not authenticated")
except Exception as e:
    print(f"❌ Kotak Neo Error: {e}")
"@

$brokerTestScript | python
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n⚠️  Broker connection test had issues" -ForegroundColor Yellow
}

# Step 2: Fetch Live Market Data
Write-Host "`n[2] Fetching Live Market Data..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────" -ForegroundColor Gray

$marketDataScript = @"
import sys
import os
import json
sys.path.insert(0, r'$projectRoot')

from api.kotak_neo import KotakNeoAPI

print("Fetching live market data...")
try:
    kotak = KotakNeoAPI(
        api_key=os.getenv('KOTAK_NEO_API_KEY'),
        api_secret=os.getenv('KOTAK_NEO_API_SECRET'),
        user_id=os.getenv('KOTAK_NEO_USER_ID'),
        password=os.getenv('KOTAK_NEO_PASSWORD'),
        pin=os.getenv('KOTAK_NEO_PIN')
    )
    
    if kotak.is_authenticated():
        # Try to get market quotes (example symbols)
        symbols = ['RELIANCE', 'TCS', 'INFY', 'HDFCBANK']
        print(f"\nFetching quotes for: {', '.join(symbols)}")
        
        for symbol in symbols:
            try:
                quote = kotak.get_quote(symbol)
                print(f"  {symbol}: {quote}")
            except Exception as e:
                print(f"  {symbol}: ⚠️  {e}")
    else:
        print("❌ Kotak Neo not authenticated - cannot fetch live data")
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
"@

$marketDataScript | python

# Step 3: Generate Trading Reports
Write-Host "`n[3] Generating Trading Reports..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────" -ForegroundColor Gray

$reportScript = @"
import sys
import os
import json
from datetime import datetime, timedelta
sys.path.insert(0, r'$projectRoot')

from engines.reporting.Reporting_Engine import reporting_engine

# Get user ID from environment or use test user
user_id = os.getenv('TEST_USER_ID', 'test_user_001')

print(f"Generating report for user: {user_id}")

try:
    # Generate user trade summary
    summary = reporting_engine.user_trade_summary(user_id)
    
    print("\n📊 Trading Report Summary:")
    print("=" * 50)
    print(f"User ID: {summary.get('user_id', 'N/A')}")
    print(f"Total Trades: {summary.get('total_trades', 0)}")
    print(f"Wins: {summary.get('wins', 0)}")
    print(f"Losses: {summary.get('losses', 0)}")
    print(f"Win Rate: {summary.get('win_rate', 0) * 100:.2f}%")
    print(f"Gross Profit: ₹{summary.get('gross_profit', 0):,.2f}")
    print(f"Gross Loss: ₹{summary.get('gross_loss', 0):,.2f}")
    print(f"Net Profit: ₹{summary.get('net_profit', 0):,.2f}")
    print(f"Timestamp: {datetime.fromtimestamp(summary.get('timestamp', 0))}")
    print("=" * 50)
    
    # Save report to file
    reportDir = os.path.join(r'$projectRoot', '_local', 'reports')
    os.makedirs(reportDir, exist_ok=True)
    
    reportFile = os.path.join(reportDir, f'trading_report_{user_id}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json')
    with open(reportFile, 'w') as f:
        json.dump(summary, f, indent=2, default=str)
    
    print(f"\n✅ Report saved to: {reportFile}")
    
except Exception as e:
    print(f"❌ Error generating report: {e}")
    import traceback
    traceback.print_exc()
"@

$reportScript | python

# Step 4: Check Backend API for Reports
Write-Host "`n[4] Checking Backend Report Endpoint..." -ForegroundColor Yellow
Write-Host "──────────────────────────────────────────" -ForegroundColor Gray

$backendUrl = "http://localhost:5000"
$testUserId = "test_user_001"

Write-Host "Testing: $backendUrl/report/user/$testUserId" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$backendUrl/report/user/$testUserId" -Method Get -ErrorAction Stop
    Write-Host "`n✅ Backend Report Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10 | Write-Host
} catch {
    Write-Host "`n⚠️  Backend not running or endpoint unavailable" -ForegroundColor Yellow
    Write-Host "   Start backend with: .\start-all.ps1" -ForegroundColor Gray
    Write-Host "   Error: $_" -ForegroundColor Red
}

# Summary
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Testing Complete                                    ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Check reports in: _local\reports\" -ForegroundColor White
Write-Host "  2. View reports via API: http://localhost:5000/report/user/<user_id>" -ForegroundColor White
Write-Host "  3. View reports in Flutter app: Reports screen" -ForegroundColor White
Write-Host "  4. Run paper trading tests to generate more trade data" -ForegroundColor White
Write-Host ""

