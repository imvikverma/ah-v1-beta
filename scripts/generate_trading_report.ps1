# Generate Trading Report for User
# Generates and displays actual trading reports from the system

param(
    [Parameter(Mandatory=$false)]
    [string]$UserId = "test_user_001",
    
    [Parameter(Mandatory=$false)]
    [switch]$SaveToFile = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$DisplayOnly = $false
)

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
    & ".venv\Scripts\Activate.ps1" | Out-Null
} else {
    Write-Host "[ERROR] Virtual environment not found!" -ForegroundColor Red
    exit 1
}

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Trading Report Generator                            ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$reportScript = @"
import sys
import os
import json
from datetime import datetime
sys.path.insert(0, r'$projectRoot')

from engines.reporting.Reporting_Engine import reporting_engine

user_id = r'$UserId'

print(f"Generating trading report for: {user_id}")
print("=" * 60)

try:
    # Generate report
    summary = reporting_engine.user_trade_summary(user_id)
    
    # Display formatted report
    print("\n📊 TRADING PERFORMANCE REPORT")
    print("=" * 60)
    print(f"User ID:        {summary.get('user_id', 'N/A')}")
    print(f"Report Date:    {datetime.fromtimestamp(summary.get('timestamp', 0)).strftime('%Y-%m-%d %H:%M:%S')}")
    print("")
    print("📈 TRADE STATISTICS")
    print("-" * 60)
    print(f"Total Trades:   {summary.get('total_trades', 0)}")
    print(f"Winning Trades: {summary.get('wins', 0)}")
    print(f"Losing Trades:  {summary.get('losses', 0)}")
    print(f"Win Rate:       {summary.get('win_rate', 0) * 100:.2f}%")
    print("")
    print("💰 PROFIT & LOSS")
    print("-" * 60)
    print(f"Gross Profit:   ₹{summary.get('gross_profit', 0):>15,.2f}")
    print(f"Gross Loss:     ₹{summary.get('gross_loss', 0):>15,.2f}")
    print(f"Net Profit:     ₹{summary.get('net_profit', 0):>15,.2f}")
    print("=" * 60)
    
    # Save to file if requested
    if r'$SaveToFile' == 'True':
        reportDir = os.path.join(r'$projectRoot', '_local', 'reports')
        os.makedirs(reportDir, exist_ok=True)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        reportFile = os.path.join(reportDir, f'trading_report_{user_id}_{timestamp}.json')
        
        with open(reportFile, 'w', encoding='utf-8') as f:
            json.dump(summary, f, indent=2, default=str)
        
        print(f"\n✅ Report saved to: {reportFile}")
    
    # Also output JSON for PowerShell to parse
    print("\n---JSON_START---")
    print(json.dumps(summary, indent=2, default=str))
    print("---JSON_END---")
    
except Exception as e:
    print(f"\n❌ Error generating report: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
"@

$output = $reportScript | python 2>&1
$output | Write-Host

# Extract JSON if present
if ($output -match "---JSON_START---(.*?)---JSON_END---") {
    $jsonContent = $matches[1]
    try {
        $reportData = $jsonContent | ConvertFrom-Json
        Write-Host "`n✅ Report generated successfully!" -ForegroundColor Green
    } catch {
        Write-Host "`n⚠️  Could not parse JSON output" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n⚠️  Report generation completed (check output above)" -ForegroundColor Yellow
}

Write-Host "`n💡 Tip: View reports in browser at:" -ForegroundColor Cyan
Write-Host "   http://localhost:5000/report/user/$UserId" -ForegroundColor White
Write-Host ""

