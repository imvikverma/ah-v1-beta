"""
Analyze Closed Trades Report
Focuses on successfully closed trades with realized PnL
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

def find_all_test_results():
    """Find all test results files."""
    pattern = "live_market_test_results_*.json"
    files = list(Path(logs_dir).glob(pattern))
    if not files:
        return []
    return sorted(files, key=lambda p: p.stat().st_mtime, reverse=True)

def analyze_closed_trades():
    """Analyze closed trades from test results."""
    results_files = find_all_test_results()
    
    if not results_files:
        print("No test results found.")
        return
    
    print("=" * 80)
    print("CLOSED TRADES ANALYSIS")
    print("=" * 80)
    print(f"\nAnalyzing {len(results_files)} test result file(s)...\n")
    
    all_closed_trades = []
    all_open_positions = []
    
    for results_file in results_files:
        with open(results_file, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        trades = results.get('trades', [])
        
        # Separate closed trades from open positions
        # A trade is closed if it has close_timestamp OR pnl != 0 OR closed flag
        for trade in trades:
            # Skip closing trades themselves (they're just records)
            if trade.get('order_id', '').startswith('EOD_CLOSE_'):
                continue
            
            # Check if trade is closed
            has_close_timestamp = trade.get('close_timestamp') is not None
            has_pnl = trade.get('pnl', 0) != 0
            is_closed_flag = trade.get('closed', False)
            
            if has_close_timestamp or has_pnl or is_closed_flag:
                all_closed_trades.append(trade)
            else:  # Open position (no close timestamp, no PnL, not marked closed)
                all_open_positions.append(trade)
    
    # Statistics for closed trades
    print("=" * 80)
    print("CLOSED TRADES SUMMARY")
    print("=" * 80)
    print(f"\nTotal Closed Trades: {len(all_closed_trades)}")
    print(f"Total Open Positions: {len(all_open_positions)}")
    
    if not all_closed_trades:
        print("\n[WARNING] No closed trades found yet (all positions are still open)")
        print("   This is normal if positions haven't been closed yet.")
        print("   The system closes positions when:")
        print("   - PnL > Rs 500, OR")
        print("   - Every 5 cycles, OR")
        print("   - At market close (15:30 IST)")
        print(f"\n   Found {len(all_open_positions)} open positions that need to be closed.")
        print("   Run: python scripts\\close_positions_from_results.py to close them.")
        return
    
    # Closed trade statistics
    winning_closed = [t for t in all_closed_trades if t.get('pnl', 0) > 0]
    losing_closed = [t for t in all_closed_trades if t.get('pnl', 0) < 0]
    
    total_closed_pnl = sum(t.get('pnl', 0) for t in all_closed_trades)
    total_closed_volume = sum(t.get('value', 0) for t in all_closed_trades)
    
    win_rate = (len(winning_closed) / len(all_closed_trades) * 100) if all_closed_trades else 0.0
    
    avg_win = sum(t.get('pnl', 0) for t in winning_closed) / len(winning_closed) if winning_closed else 0.0
    avg_loss = sum(t.get('pnl', 0) for t in losing_closed) / len(losing_closed) if losing_closed else 0.0
    
    print(f"\nClosed Trade Performance:")
    print(f"  Winning Trades: {len(winning_closed)}")
    print(f"  Losing Trades: {len(losing_closed)}")
    print(f"  Win Rate: {win_rate:.2f}%")
    print(f"  Total Realized PnL: Rs {total_closed_pnl:,.2f}")
    print(f"  Total Closed Volume: Rs {total_closed_volume:,.2f}")
    print(f"  Average Win: Rs {avg_win:,.2f}")
    print(f"  Average Loss: Rs {avg_loss:,.2f}")
    
    # By symbol
    closed_by_symbol = {}
    for trade in all_closed_trades:
        symbol = trade.get('symbol', 'UNKNOWN')
        if symbol not in closed_by_symbol:
            closed_by_symbol[symbol] = {
                "count": 0,
                "wins": 0,
                "losses": 0,
                "total_pnl": 0.0,
                "volume": 0.0
            }
        closed_by_symbol[symbol]["count"] += 1
        closed_by_symbol[symbol]["total_pnl"] += trade.get('pnl', 0)
        closed_by_symbol[symbol]["volume"] += trade.get('value', 0)
        if trade.get('pnl', 0) > 0:
            closed_by_symbol[symbol]["wins"] += 1
        else:
            closed_by_symbol[symbol]["losses"] += 1
    
    print(f"\nClosed Trades by Symbol:")
    for symbol, stats in closed_by_symbol.items():
        symbol_win_rate = (stats["wins"] / stats["count"] * 100) if stats["count"] > 0 else 0.0
        print(f"  {symbol}:")
        print(f"    Closed: {stats['count']} trades")
        print(f"    Wins: {stats['wins']}, Losses: {stats['losses']} ({symbol_win_rate:.1f}% win rate)")
        print(f"    Total PnL: Rs {stats['total_pnl']:,.2f}")
        print(f"    Volume: Rs {stats['volume']:,.2f}")
    
    # Save detailed report
    os.makedirs(reports_dir, exist_ok=True)
    report_file = os.path.join(
        reports_dir,
        f"closed_trades_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    )
    
    report = {
        "analysis_time": datetime.now().isoformat(),
        "total_closed_trades": len(all_closed_trades),
        "total_open_positions": len(all_open_positions),
        "closed_trade_performance": {
            "winning_trades": len(winning_closed),
            "losing_trades": len(losing_closed),
            "win_rate_percent": win_rate,
            "total_realized_pnl": total_closed_pnl,
            "total_closed_volume": total_closed_volume,
            "average_win": avg_win,
            "average_loss": avg_loss
        },
        "closed_trades_by_symbol": closed_by_symbol,
        "all_closed_trades": all_closed_trades
    }
    
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, default=str)
    
    print(f"\n[OK] Detailed report saved to: {report_file}")
    print("=" * 80)

if __name__ == "__main__":
    analyze_closed_trades()
