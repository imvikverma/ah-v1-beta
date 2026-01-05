"""
View Aggregate Test Results
Displays comprehensive aggregate statistics from multiple test runs
"""

import os
import sys
import json
from datetime import datetime
from pathlib import Path

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
logs_dir = os.path.join(project_root, '_local', 'logs')
reports_dir = os.path.join(project_root, '_local', 'reports')

def find_latest_aggregate_results():
    """Find latest aggregate results file."""
    pattern = "multi_test_aggregate_results_*.json"
    files = list(Path(logs_dir).glob(pattern))
    if not files:
        return None
    return max(files, key=lambda p: p.stat().st_mtime)

def find_latest_aggregate_report():
    """Find latest aggregate report file."""
    pattern = "aggregate_report_*.json"
    files = list(Path(reports_dir).glob(pattern))
    if not files:
        return None
    return max(files, key=lambda p: p.stat().st_mtime)

def display_aggregate_results():
    """Display aggregate test results."""
    results_file = find_latest_aggregate_results()
    report_file = find_latest_aggregate_report()
    
    print("=" * 80)
    print("AGGREGATE TEST RESULTS")
    print("=" * 80)
    print()
    
    if results_file:
        with open(results_file, 'r', encoding='utf-8') as f:
            results = json.load(f)
        
        print(f"Results File: {results_file.name}")
        print(f"Generated: {results.get('end_time', 'N/A')}")
        print()
        
        print("Test Summary:")
        print(f"  Total Runs: {results.get('total_runs', 0)}")
        print(f"  Completed Runs: {results.get('completed_runs', 0)}")
        print(f"  Failed Runs: {results.get('failed_runs', 0)}")
        print(f"  Total Duration: {results.get('total_duration_minutes', 0):.1f} minutes")
        print()
        
        aggregate = results.get('aggregate_statistics', {})
        if aggregate and not aggregate.get('error'):
            avgs = aggregate.get('averages', {})
            
            print("Average Performance Metrics:")
            print()
            
            if 'total_trades' in avgs:
                trades = avgs['total_trades']
                print(f"  Trades per Run:")
                print(f"    Mean: {trades['mean']:.1f}")
                print(f"    Median: {trades['median']:.1f}")
                print(f"    Range: {trades['min']:.0f} - {trades['max']:.0f}")
                print(f"    Std Dev: {trades['stdev']:.2f}")
                print()
            
            if 'win_rate_percent' in avgs:
                wr = avgs['win_rate_percent']
                print(f"  Win Rate:")
                print(f"    Mean: {wr['mean']:.2f}%")
                print(f"    Median: {wr['median']:.2f}%")
                print(f"    Range: {wr['min']:.2f}% - {wr['max']:.2f}%")
                print()
            
            if 'total_pnl' in avgs:
                pnl = avgs['total_pnl']
                print(f"  Total PnL:")
                print(f"    Mean per Run: Rs {pnl['mean']:,.2f}")
                print(f"    Median: Rs {pnl['median']:,.2f}")
                print(f"    Range: Rs {pnl['min']:,.2f} - Rs {pnl['max']:,.2f}")
                print(f"    Total (Sum): Rs {pnl['sum']:,.2f}")
                print()
            
            if 'realized_pnl' in avgs:
                rpnl = avgs['realized_pnl']
                print(f"  Realized PnL:")
                print(f"    Mean per Run: Rs {rpnl['mean']:,.2f}")
                print(f"    Total (Sum): Rs {rpnl['sum']:,.2f}")
                print()
            
            if 'total_volume' in avgs:
                vol = avgs['total_volume']
                print(f"  Total Volume:")
                print(f"    Mean per Run: Rs {vol['mean']:,.2f}")
                print(f"    Total (Sum): Rs {vol['sum']:,.2f}")
                print()
            
            consistency = aggregate.get('consistency', {})
            if consistency:
                print("Consistency Metrics:")
                if 'trades_consistency' in consistency:
                    tc = consistency['trades_consistency']
                    print(f"  Trades CV: {tc['cv']:.2f}% ({tc['description']})")
                if 'pnl_consistency' in consistency:
                    pc = consistency['pnl_consistency']
                    print(f"  PnL CV: {pc['cv']:.2f}% ({pc['description']})")
                print()
        
        print("Individual Run Results:")
        for run in results.get('run_results', [])[:10]:  # Show first 10
            print(f"  Run #{run.get('run_number', '?')}: {run.get('total_trades', 0)} trades, "
                  f"{run.get('duration_minutes', 0):.1f} min, "
                  f"{run.get('total_cycles', 0)} cycles")
        
        if len(results.get('run_results', [])) > 10:
            print(f"  ... and {len(results.get('run_results', [])) - 10} more runs")
        print()
    else:
        print("No aggregate results file found.")
        print("Run tests first using: python scripts\\run_multiple_tests.py")
        print()
    
    if report_file:
        print(f"Aggregate Report: {report_file.name}")
        print(f"Location: {report_file}")
    else:
        print("No aggregate report found yet.")
    
    print("=" * 80)

if __name__ == "__main__":
    display_aggregate_results()
