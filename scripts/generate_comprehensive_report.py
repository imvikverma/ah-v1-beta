"""
Generate Comprehensive Trading Report
Creates detailed reports from test results
"""

import os
import sys
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
logs_dir = os.path.join(project_root, '_local', 'logs')
reports_dir = os.path.join(project_root, '_local', 'reports')

def find_latest_test_results():
    """Find latest test results file."""
    pattern = "live_market_test_results_*.json"
    files = list(Path(logs_dir).glob(pattern))
    if not files:
        return None
    return max(files, key=lambda p: p.stat().st_mtime)

def generate_comprehensive_report():
    """Generate comprehensive trading report."""
    results_file = find_latest_test_results()
    
    if not results_file:
        print("No test results found.")
        return
    
    with open(results_file, 'r', encoding='utf-8') as f:
        results = json.load(f)
    
    # Create reports directory
    os.makedirs(reports_dir, exist_ok=True)
    
    # Generate report
    report_file = os.path.join(
        reports_dir,
        f"comprehensive_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    )
    
    # Calculate statistics
    trades = results.get('trades', [])
    reports = results.get('reports', [])
    
    # Aggregate statistics
    total_trades = len(trades)
    winning_trades = sum(1 for t in trades if t.get('pnl', 0) > 0)
    losing_trades = sum(1 for t in trades if t.get('pnl', 0) < 0)
    total_pnl = sum(t.get('pnl', 0) for t in trades)
    total_volume = sum(t.get('value', 0) for t in trades)
    
    win_rate = (winning_trades / total_trades * 100) if total_trades > 0 else 0.0
    
    winning_pnls = [t.get('pnl', 0) for t in trades if t.get('pnl', 0) > 0]
    losing_pnls = [t.get('pnl', 0) for t in trades if t.get('pnl', 0) < 0]
    
    average_win = sum(winning_pnls) / len(winning_pnls) if winning_pnls else 0.0
    average_loss = sum(losing_pnls) / len(losing_pnls) if losing_pnls else 0.0
    largest_win = max(winning_pnls) if winning_pnls else 0.0
    largest_loss = min(losing_pnls) if losing_pnls else 0.0
    
    # Trades by symbol
    trades_by_symbol = {}
    for trade in trades:
        symbol = trade.get('symbol', 'UNKNOWN')
        if symbol not in trades_by_symbol:
            trades_by_symbol[symbol] = {
                "count": 0,
                "total_pnl": 0.0,
                "total_volume": 0.0,
                "wins": 0,
                "losses": 0
            }
        trades_by_symbol[symbol]["count"] += 1
        trades_by_symbol[symbol]["total_pnl"] += trade.get('pnl', 0)
        trades_by_symbol[symbol]["total_volume"] += trade.get('value', 0)
        if trade.get('pnl', 0) > 0:
            trades_by_symbol[symbol]["wins"] += 1
        elif trade.get('pnl', 0) < 0:
            trades_by_symbol[symbol]["losses"] += 1
    
    # Comprehensive report
    comprehensive_report = {
        "report_generated_at": datetime.now().isoformat(),
        "test_period": {
            "start_time": results.get('start_time'),
            "end_time": results.get('end_time', 'Still running...'),
            "duration_minutes": results.get('duration_minutes', 0),
            "total_cycles": results.get('total_cycles', 0)
        },
        "trading_performance": {
            "total_trades": total_trades,
            "winning_trades": winning_trades,
            "losing_trades": losing_trades,
            "win_rate_percent": win_rate,
            "total_pnl": total_pnl,
            "total_volume": total_volume,
            "average_win": average_win,
            "average_loss": average_loss,
            "largest_win": largest_win,
            "largest_loss": largest_loss,
            "profit_factor": abs(average_win / average_loss) if average_loss != 0 else 0.0
        },
        "trades_by_symbol": trades_by_symbol,
        "latest_report": reports[-1] if reports else None,
        "errors": results.get('errors', []),
        "warnings": results.get('warnings', []),
        "positions": results.get('positions', {})
    }
    
    # Save report
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(comprehensive_report, f, indent=2, default=str)
    
    # Print summary
    print("=" * 80)
    print("COMPREHENSIVE TRADING REPORT")
    print("=" * 80)
    print(f"Report Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Test Period: {results.get('start_time', 'N/A')} to {results.get('end_time', 'Still running...')}")
    print(f"Duration: {results.get('duration_minutes', 0):.1f} minutes")
    print(f"Total Cycles: {results.get('total_cycles', 0)}")
    print("\nTrading Performance:")
    print(f"  Total Trades: {total_trades}")
    print(f"  Winning Trades: {winning_trades}")
    print(f"  Losing Trades: {losing_trades}")
    print(f"  Win Rate: {win_rate:.2f}%")
    print(f"  Total PnL: Rs {total_pnl:,.2f}")
    print(f"  Total Volume: Rs {total_volume:,.2f}")
    print(f"  Average Win: Rs {average_win:,.2f}")
    print(f"  Average Loss: Rs {average_loss:,.2f}")
    print(f"  Largest Win: Rs {largest_win:,.2f}")
    print(f"  Largest Loss: Rs {largest_loss:,.2f}")
    print(f"  Profit Factor: {comprehensive_report['trading_performance']['profit_factor']:.2f}")
    
    if trades_by_symbol:
        print("\nTrades by Symbol:")
        for symbol, stats in trades_by_symbol.items():
            print(f"  {symbol}:")
            print(f"    Count: {stats['count']}")
            print(f"    PnL: Rs {stats['total_pnl']:,.2f}")
            print(f"    Volume: Rs {stats['total_volume']:,.2f}")
            print(f"    Wins: {stats['wins']}, Losses: {stats['losses']}")
    
    if results.get('errors'):
        print(f"\nErrors: {len(results['errors'])}")
        for error in results['errors'][:5]:  # Show first 5
            print(f"  - {error}")
    
    print(f"\nReport saved to: {report_file}")
    print("=" * 80)
    
    return comprehensive_report

if __name__ == "__main__":
    generate_comprehensive_report()
