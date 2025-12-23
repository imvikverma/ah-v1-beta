# Comprehensive Production Tests
# Tests: Broker APIs, Paper Trading, Report Generation

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
Write-Host "║     Comprehensive Production Tests                    ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$testResults = @{
    BrokerAPIs = @{ Status = "Pending"; Details = @() }
    PaperTrading = @{ Status = "Pending"; Details = @() }
    Reports = @{ Status = "Pending"; Details = @() }
}

# ============================================================================
# TEST 1: Broker API Connections
# ============================================================================
Write-Host "[TEST 1] Testing Broker API Connections..." -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────" -ForegroundColor Gray

$brokerTestScript = @"
import sys
import os
sys.path.insert(0, r'$projectRoot')

from api.hdfc_sky_api import HDFCSkyAPI
from api.kotak_neo import KotakNeoAPI

results = {'hdfc': False, 'kotak': False, 'errors': []}

# Test HDFC Sky
print("Testing HDFC Sky API...")
try:
    api_key = os.getenv('HDFC_SKY_API_KEY')
    api_secret = os.getenv('HDFC_SKY_API_SECRET')
    token_id = os.getenv('HDFC_SKY_TOKEN_ID')
    access_token = os.getenv('HDFC_SKY_ACCESS_TOKEN')
    
    if api_key and api_secret:
        hdfc = HDFCSkyAPI(
            api_key=api_key,
            api_secret=api_secret,
            token_id=token_id,
            access_token=access_token
        )
        if hdfc.is_authenticated():
            print("[OK] HDFC Sky: Authenticated")
            results['hdfc'] = True
            try:
                account = hdfc.get_account_info()
                print(f"   Account Info: {account}")
            except Exception as e:
                print(f"   [WARN] Account info error: {e}")
        else:
            print("[WARN] HDFC Sky: Credentials found but not authenticated")
            print("   Set HDFC_SKY_TOKEN_ID or HDFC_SKY_ACCESS_TOKEN")
            results['errors'].append("HDFC Sky: Not authenticated")
    else:
        print("[WARN] HDFC Sky: Credentials not configured")
        print("   Set HDFC_SKY_API_KEY and HDFC_SKY_API_SECRET")
        results['errors'].append("HDFC Sky: Credentials not configured")
except Exception as e:
    print(f"[ERROR] HDFC Sky Error: {e}")
    results['errors'].append(f"HDFC Sky: {str(e)}")

# Test Kotak Neo
print("\nTesting Kotak Neo API...")
try:
    access_token = os.getenv('KOTAK_NEO_ACCESS_TOKEN')
    mobile = os.getenv('KOTAK_NEO_MOBILE')
    client_code = os.getenv('KOTAK_NEO_CLIENT_CODE')
    
    if access_token and mobile and client_code:
        kotak = KotakNeoAPI(
            access_token=access_token,
            mobile_number=mobile,
            client_code=client_code
        )
        # Try to get account info (requires login)
        try:
            account = kotak.get_account_info()
            print("[OK] Kotak Neo: Authenticated")
            results['kotak'] = True
        except:
            print("[WARN] Kotak Neo: Credentials found but login required")
            print("   Run login_with_totp() first")
            results['errors'].append("Kotak Neo: Login required")
    else:
        print("[WARN] Kotak Neo: Credentials not configured")
        print("   Set KOTAK_NEO_ACCESS_TOKEN, KOTAK_NEO_MOBILE, KOTAK_NEO_CLIENT_CODE")
        results['errors'].append("Kotak Neo: Credentials not configured")
except Exception as e:
    print(f"[ERROR] Kotak Neo Error: {e}")
    results['errors'].append(f"Kotak Neo: {str(e)}")

# Print summary
print("\n" + "="*50)
print("Broker API Test Summary:")
print(f"  HDFC Sky: {'[OK] Connected' if results['hdfc'] else '[FAIL] Not connected'}")
print(f"  Kotak Neo: {'[OK] Connected' if results['kotak'] else '[FAIL] Not connected'}")
if results['errors']:
    print(f"\n  Errors: {len(results['errors'])}")
    for err in results['errors']:
        print(f"    - {err}")
print("="*50)

import json
print(json.dumps(results))
"@

try {
    $brokerOutput = $brokerTestScript | python 2>&1
    Write-Host $brokerOutput
    
    # Parse results
    if ($brokerOutput -match '"hdfc":\s*true') {
        $testResults.BrokerAPIs.Details += "HDFC Sky: ✅ Connected"
    } else {
        $testResults.BrokerAPIs.Details += "HDFC Sky: ❌ Not connected"
    }
    
    if ($brokerOutput -match '"kotak":\s*true') {
        $testResults.BrokerAPIs.Details += "Kotak Neo: ✅ Connected"
    } else {
        $testResults.BrokerAPIs.Details += "Kotak Neo: ❌ Not connected"
    }
    
    if ($testResults.BrokerAPIs.Details -match "✅") {
        $testResults.BrokerAPIs.Status = "Partial Success"
    } else {
        $testResults.BrokerAPIs.Status = "Failed"
    }
} catch {
    Write-Host "❌ Broker API test failed: $_" -ForegroundColor Red
    $testResults.BrokerAPIs.Status = "Error"
    $testResults.BrokerAPIs.Details += "Test execution error"
}

# ============================================================================
# TEST 2: Paper Trading with Live Data
# ============================================================================
Write-Host "`n[TEST 2] Testing Paper Trading with Live Data..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────────────" -ForegroundColor Gray

$paperTradingScript = @"
import sys
import os
sys.path.insert(0, r'$projectRoot')

from aurum_harmony.engines.trade_execution.broker_adapter_factory import create_broker_adapter
from aurum_harmony.engines.trade_execution.trade_execution import Order, OrderType, OrderSide

print("Testing Paper Trading with Live Data...")

try:
    # Create paper trading adapter
    adapter = create_broker_adapter("paper")
    
    if adapter:
        print("[OK] Paper trading adapter created")
        
        # Try to place a test order (will use live market data)
        # Note: user_id goes in metadata, not as a parameter
        test_order = Order(
            symbol="RELIANCE",
            side=OrderSide.BUY,
            quantity=1,
            order_type=OrderType.MARKET,
            metadata={'user_id': 'test_user_001', 'reason': 'Test order'}
        )
        
        print(f"\nPlacing test order: {test_order.symbol} {test_order.side} {test_order.quantity}")
        
        try:
            result = adapter.place_order(test_order)
            print(f"[OK] Order placed successfully!")
            print(f"   Client Order ID: {result.client_order_id}")
            print(f"   Broker Order ID: {result.broker_order_id}")
            print(f"   Status: {result.status}")
            $testResults.PaperTrading.Details += "Order placement: [OK] Success"
        except Exception as e:
            print(f"[WARN] Order placement error: {e}")
            print("   This is expected if market is closed or data unavailable")
            $testResults.PaperTrading.Details += f"Order placement: [WARN] {str(e)}"
        
        # Try to get positions
        try:
            positions = adapter.get_positions("test_user_001")
            print(f"\n[OK] Positions retrieved: {len(positions)} positions")
            $testResults.PaperTrading.Details += f"Positions: [OK] {len(positions)} positions"
        except Exception as e:
            print(f"[WARN] Positions error: {e}")
            $testResults.PaperTrading.Details += f"Positions: [WARN] {str(e)}"
        
        $testResults.PaperTrading.Status = "Success"
    else:
        print("[ERROR] Could not create paper trading adapter")
        $testResults.PaperTrading.Status = "Failed"
        $testResults.PaperTrading.Details += "Adapter creation failed"
        
except Exception as e:
    print(f"❌ Paper trading test error: {e}")
    import traceback
    traceback.print_exc()
    $testResults.PaperTrading.Status = "Error"
    $testResults.PaperTrading.Details += f"Error: {str(e)}"
"@

try {
    $paperOutput = $paperTradingScript | python 2>&1
    Write-Host $paperOutput
} catch {
    Write-Host "❌ Paper trading test failed: $_" -ForegroundColor Red
    $testResults.PaperTrading.Status = "Error"
}

# ============================================================================
# TEST 3: Generate Trading Reports
# ============================================================================
Write-Host "`n[TEST 3] Generating Trading Reports..." -ForegroundColor Yellow
Write-Host "───────────────────────────────────────────" -ForegroundColor Gray

$reportScript = @"
import sys
import os
import json
from datetime import datetime
sys.path.insert(0, r'$projectRoot')

try:
    from aurum_harmony.engines.reporting.reporting import reporting_engine
    from datetime import datetime, timedelta
    
    user_id = os.getenv('TEST_USER_ID', 'test_user_001')
    
    print(f"Generating report for user: {user_id}")
    
    # Generate trading report (need trades data - using empty list for now)
    period_end = datetime.now()
    period_start = period_end - timedelta(days=30)
    
    # Generate report with empty trades (will return empty report)
    report = reporting_engine.generate_trading_report(
        user_id=user_id,
        period_start=period_start,
        period_end=period_end,
        trades=[],
        positions=None
    )
    
    # Convert to dict for display
    summary = {
        'user_id': report.user_id,
        'total_trades': report.total_trades,
        'wins': report.winning_trades,
        'losses': report.losing_trades,
        'win_rate': report.win_rate / 100.0,  # Convert percentage to decimal
        'gross_profit': report.average_win * report.winning_trades if report.winning_trades > 0 else 0,
        'gross_loss': abs(report.average_loss * report.losing_trades) if report.losing_trades > 0 else 0,
        'net_profit': report.total_pnl,
        'timestamp': report.period_end.timestamp()
    }
    
    print("\n📊 Trading Report Summary:")
    print("=" * 50)
    print(f"User ID: {summary.get('user_id', 'N/A')}")
    print(f"Total Trades: {summary.get('total_trades', 0)}")
    print(f"Wins: {summary.get('wins', 0)}")
    print(f"Losses: {summary.get('losses', 0)}")
    win_rate = summary.get('win_rate', 0) * 100
    print(f"Win Rate: {win_rate:.2f}%")
    print(f"Gross Profit: ₹{summary.get('gross_profit', 0):,.2f}")
    print(f"Gross Loss: ₹{summary.get('gross_loss', 0):,.2f}")
    print(f"Net Profit: ₹{summary.get('net_profit', 0):,.2f}")
    print("=" * 50)
    
    # Save report
    reportDir = os.path.join(r'$projectRoot', '_local', 'reports')
    os.makedirs(reportDir, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    reportFile = os.path.join(reportDir, f'trading_report_{user_id}_{timestamp}.json')
    
    with open(reportFile, 'w') as f:
        json.dump(summary, f, indent=2, default=str)
    
    print(f"\n[OK] Report saved to: {reportFile}")
    $testResults.Reports.Status = "Success"
    $testResults.Reports.Details += f"Report generated: {reportFile}"
    
except Exception as e:
    print(f"[ERROR] Error generating report: {e}")
    import traceback
    traceback.print_exc()
    $testResults.Reports.Status = "Error"
    $testResults.Reports.Details += f"Error: {str(e)}"
"@

try {
    $reportOutput = $reportScript | python 2>&1
    Write-Host $reportOutput
} catch {
    Write-Host "❌ Report generation failed: $_" -ForegroundColor Red
    $testResults.Reports.Status = "Error"
}

# ============================================================================
# SUMMARY
# ============================================================================
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Test Results Summary                               ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Broker API Connections:" -ForegroundColor Cyan
Write-Host "  Status: $($testResults.BrokerAPIs.Status)" -ForegroundColor $(if ($testResults.BrokerAPIs.Status -eq "Success") { "Green" } else { "Yellow" })
foreach ($detail in $testResults.BrokerAPIs.Details) {
    Write-Host "  $detail" -ForegroundColor Gray
}
Write-Host ""

Write-Host "Paper Trading:" -ForegroundColor Cyan
Write-Host "  Status: $($testResults.PaperTrading.Status)" -ForegroundColor $(if ($testResults.PaperTrading.Status -eq "Success") { "Green" } else { "Yellow" })
foreach ($detail in $testResults.PaperTrading.Details) {
    Write-Host "  $detail" -ForegroundColor Gray
}
Write-Host ""

Write-Host "Report Generation:" -ForegroundColor Cyan
Write-Host "  Status: $($testResults.Reports.Status)" -ForegroundColor $(if ($testResults.Reports.Status -eq "Success") { "Green" } else { "Yellow" })
foreach ($detail in $testResults.Reports.Details) {
    Write-Host "  $detail" -ForegroundColor Gray
}
Write-Host ""

Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Check reports in: _local\reports\" -ForegroundColor White
Write-Host "  2. Configure broker credentials in .env if needed" -ForegroundColor White
Write-Host "  3. Start backend for full API testing: .\scripts\start_backend_silent.ps1" -ForegroundColor White
Write-Host ""

