"""
Monitor Live Market Test
Check progress and generate interim reports
"""

import os
import sys
import json
from datetime import datetime
from pathlib import Path

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
logs_dir = os.path.join(project_root, '_local', 'logs')

def find_latest_test_results():
    """Find latest test results file."""
    pattern = "live_market_test_results_*.json"
    files = list(Path(logs_dir).glob(pattern))
    if not files:
        return None
    return max(files, key=lambda p: p.stat().st_mtime)

def display_status():
    """Display current test status."""
    results_file = find_latest_test_results()
    
    if not results_file:
        print("No test results found. Test may still be running...")
        return
    
    with open(results_file, 'r', encoding='utf-8') as f:
        results = json.load(f)
    
    print("=" * 80)
    print("LIVE MARKET TEST STATUS")
    print("=" * 80)
    print(f"Start Time: {results.get('start_time', 'N/A')}")
    print(f"End Time: {results.get('end_time', 'Still running...')}")
    
    if results.get('end_time'):
        duration = results.get('duration_minutes', 0)
        print(f"Duration: {duration:.1f} minutes ({duration/60:.1f} hours)")
    
    print(f"Total Cycles: {results.get('total_cycles', 0)}")
    print(f"Total Trades: {len(results.get('trades', []))}")
    print(f"Errors: {len(results.get('errors', []))}")
    print(f"Warnings: {len(results.get('warnings', []))}")
    
    if results.get('reports'):
        latest_report = results['reports'][-1]
        perf = latest_report.get('trading_performance', {})
        print("\nLatest Performance:")
        print(f"  Total Trades: {perf.get('total_trades', 0)}")
        print(f"  Win Rate: {perf.get('win_rate', 0):.2f}%")
        print(f"  Total PnL: Rs {perf.get('total_pnl', 0):,.2f}")
        print(f"  Realized PnL: Rs {perf.get('realized_pnl', 0):,.2f}")
        print(f"  Unrealized PnL: Rs {perf.get('unrealized_pnl', 0):,.2f}")
    
    print("=" * 80)

if __name__ == "__main__":
    display_status()
