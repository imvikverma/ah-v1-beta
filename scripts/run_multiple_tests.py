"""
Multiple Test Runner - Aggregate Average Output
Runs multiple test iterations and aggregates results for average performance metrics

This script:
1. Runs multiple test iterations throughout the day
2. Collects results from each run
3. Calculates aggregate averages
4. Generates comprehensive aggregate reports
"""

import os
import sys
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any
import json
import time
import statistics

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(
            os.path.join(project_root, '_local', 'logs', f'multi_test_runner_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
            encoding='utf-8'
        ),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Import test script
from scripts.test_live_market_burn_in import LiveMarketBurnInTest


class MultipleTestRunner:
    """
    Runs multiple test iterations and aggregates results.
    """
    
    def __init__(self):
        self.test_runs: List[Dict[str, Any]] = []
        self.aggregate_results: Dict[str, Any] = {
            "start_time": datetime.now().isoformat(),
            "total_runs": 0,
            "completed_runs": 0,
            "failed_runs": 0,
            "run_results": []
        }
        logger.info("MultipleTestRunner initialized")
    
    def run_single_test(self, test_duration_minutes: int = 30, run_number: int = 1) -> Dict[str, Any]:
        """
        Run a single test iteration.
        
        Args:
            test_duration_minutes: Duration of this test run
            run_number: Test run number
            
        Returns:
            Test results dictionary
        """
        logger.info("=" * 80)
        logger.info(f"STARTING TEST RUN #{run_number}")
        logger.info(f"Duration: {test_duration_minutes} minutes")
        logger.info("=" * 80)
        
        try:
            test = LiveMarketBurnInTest(
                user_id=f"test_run_{run_number}",
                user_category="admin"
            )
            
            results = test.run_continuous_test(duration_minutes=test_duration_minutes)
            
            # Extract key metrics
            run_summary = {
                "run_number": run_number,
                "start_time": results.get("start_time"),
                "end_time": results.get("end_time"),
                "duration_minutes": results.get("duration_minutes", 0),
                "total_cycles": results.get("total_cycles", 0),
                "total_trades": len(results.get("trades", [])),
                "errors": len(results.get("errors", [])),
                "warnings": len(results.get("warnings", [])),
                "latest_report": results.get("reports", [{}])[-1] if results.get("reports") else None,
                "full_results": results
            }
            
            logger.info(f"[OK] Test Run #{run_number} completed successfully")
            logger.info(f"  - Duration: {run_summary['duration_minutes']:.1f} minutes")
            logger.info(f"  - Total Trades: {run_summary['total_trades']}")
            logger.info(f"  - Total Cycles: {run_summary['total_cycles']}")
            
            return run_summary
            
        except Exception as e:
            logger.error(f"[ERROR] Test Run #{run_number} failed: {e}", exc_info=True)
            return {
                "run_number": run_number,
                "status": "FAILED",
                "error": str(e),
                "start_time": datetime.now().isoformat(),
                "end_time": datetime.now().isoformat()
            }
    
    def calculate_aggregate_statistics(self) -> Dict[str, Any]:
        """
        Calculate aggregate statistics from all test runs.
        
        Returns:
            Dictionary with aggregate statistics
        """
        if not self.test_runs:
            return {}
        
        completed_runs = [r for r in self.test_runs if r.get("status") != "FAILED" and r.get("latest_report")]
        
        if not completed_runs:
            return {"error": "No completed runs to aggregate"}
        
        # Extract performance metrics
        total_trades_list = [r.get("total_trades", 0) for r in completed_runs]
        duration_list = [r.get("duration_minutes", 0) for r in completed_runs]
        cycles_list = [r.get("total_cycles", 0) for r in completed_runs]
        
        # Extract from latest reports
        win_rates = []
        total_pnls = []
        realized_pnls = []
        unrealized_pnls = []
        total_volumes = []
        
        for run in completed_runs:
            report = run.get("latest_report", {})
            perf = report.get("trading_performance", {})
            if perf:
                win_rates.append(perf.get("win_rate", 0))
                total_pnls.append(perf.get("total_pnl", 0))
                realized_pnls.append(perf.get("realized_pnl", 0))
                unrealized_pnls.append(perf.get("unrealized_pnl", 0))
                total_volumes.append(perf.get("total_volume", 0))
        
        # Calculate statistics
        aggregate = {
            "total_runs": len(self.test_runs),
            "completed_runs": len(completed_runs),
            "failed_runs": len([r for r in self.test_runs if r.get("status") == "FAILED"]),
            "averages": {
                "total_trades": {
                    "mean": statistics.mean(total_trades_list) if total_trades_list else 0,
                    "median": statistics.median(total_trades_list) if total_trades_list else 0,
                    "min": min(total_trades_list) if total_trades_list else 0,
                    "max": max(total_trades_list) if total_trades_list else 0,
                    "stdev": statistics.stdev(total_trades_list) if len(total_trades_list) > 1 else 0
                },
                "duration_minutes": {
                    "mean": statistics.mean(duration_list) if duration_list else 0,
                    "median": statistics.median(duration_list) if duration_list else 0,
                    "min": min(duration_list) if duration_list else 0,
                    "max": max(duration_list) if duration_list else 0
                },
                "cycles": {
                    "mean": statistics.mean(cycles_list) if cycles_list else 0,
                    "median": statistics.median(cycles_list) if cycles_list else 0,
                    "min": min(cycles_list) if cycles_list else 0,
                    "max": max(cycles_list) if cycles_list else 0
                },
                "win_rate_percent": {
                    "mean": statistics.mean(win_rates) if win_rates else 0,
                    "median": statistics.median(win_rates) if win_rates else 0,
                    "min": min(win_rates) if win_rates else 0,
                    "max": max(win_rates) if win_rates else 0
                },
                "total_pnl": {
                    "mean": statistics.mean(total_pnls) if total_pnls else 0,
                    "median": statistics.median(total_pnls) if total_pnls else 0,
                    "min": min(total_pnls) if total_pnls else 0,
                    "max": max(total_pnls) if total_pnls else 0,
                    "sum": sum(total_pnls) if total_pnls else 0
                },
                "realized_pnl": {
                    "mean": statistics.mean(realized_pnls) if realized_pnls else 0,
                    "median": statistics.median(realized_pnls) if realized_pnls else 0,
                    "sum": sum(realized_pnls) if realized_pnls else 0
                },
                "unrealized_pnl": {
                    "mean": statistics.mean(unrealized_pnls) if unrealized_pnls else 0,
                    "median": statistics.median(unrealized_pnls) if unrealized_pnls else 0,
                    "sum": sum(unrealized_pnls) if unrealized_pnls else 0
                },
                "total_volume": {
                    "mean": statistics.mean(total_volumes) if total_volumes else 0,
                    "median": statistics.median(total_volumes) if total_volumes else 0,
                    "sum": sum(total_volumes) if total_volumes else 0
                }
            },
            "consistency": {
                "trades_consistency": {
                    # Coefficient of Variation for trades: only compute stdev when we have 2+ data points
                    "cv": (
                        statistics.stdev(total_trades_list) / statistics.mean(total_trades_list) * 100
                    ) if len(total_trades_list) > 1 and statistics.mean(total_trades_list) > 0 else 0,
                    "description": "Coefficient of Variation - lower is more consistent"
                },
                "pnl_consistency": {
                    # Coefficient of Variation for PnL: guard against single data point
                    "cv": (
                        statistics.stdev(total_pnls) / abs(statistics.mean(total_pnls)) * 100
                    ) if len(total_pnls) > 1 and statistics.mean(total_pnls) != 0 else 0,
                    "description": "Coefficient of Variation - lower is more consistent"
                }
            }
        }
        
        return aggregate
    
    def run_multiple_tests(
        self,
        num_runs: int = 5,
        test_duration_minutes: int = 30,
        wait_between_runs_minutes: int = 10
    ):
        """
        Run multiple test iterations.
        
        Args:
            num_runs: Number of test runs to execute
            test_duration_minutes: Duration of each test run
            wait_between_runs_minutes: Wait time between runs
        """
        logger.info("=" * 80)
        logger.info("STARTING MULTIPLE TEST RUNS")
        logger.info(f"Total Runs: {num_runs}")
        logger.info(f"Duration per Run: {test_duration_minutes} minutes")
        logger.info(f"Wait Between Runs: {wait_between_runs_minutes} minutes")
        logger.info("=" * 80)
        
        start_time = datetime.now()
        
        for run_num in range(1, num_runs + 1):
            logger.info(f"\n{'='*80}")
            logger.info(f"TEST RUN {run_num} of {num_runs}")
            logger.info(f"{'='*80}")
            
            # Run test
            run_result = self.run_single_test(
                test_duration_minutes=test_duration_minutes,
                run_number=run_num
            )
            
            self.test_runs.append(run_result)
            self.aggregate_results["total_runs"] += 1
            
            if run_result.get("status") != "FAILED":
                self.aggregate_results["completed_runs"] += 1
            else:
                self.aggregate_results["failed_runs"] += 1
            
            # Calculate and log aggregate stats so far
            if len(self.test_runs) > 0:
                aggregate = self.calculate_aggregate_statistics()
                if aggregate and not aggregate.get("error"):
                    logger.info("\n" + "=" * 80)
                    logger.info("CURRENT AGGREGATE STATISTICS")
                    logger.info("=" * 80)
                    logger.info(f"Completed Runs: {aggregate['completed_runs']}/{aggregate['total_runs']}")
                    logger.info(f"Average Trades per Run: {aggregate['averages']['total_trades']['mean']:.1f}")
                    logger.info(f"Average Win Rate: {aggregate['averages']['win_rate_percent']['mean']:.2f}%")
                    logger.info(f"Average Total PnL: Rs {aggregate['averages']['total_pnl']['mean']:,.2f}")
                    logger.info(f"Total PnL (Sum): Rs {aggregate['averages']['total_pnl']['sum']:,.2f}")
                    logger.info("=" * 80)
            
            # Wait before next run (except for last run) - Reduced to 20 seconds for high frequency
            if run_num < num_runs:
                # Use 20 seconds for high frequency testing (ignore wait_between_runs_minutes parameter)
                wait_seconds = 20  # Fixed 20 seconds between runs for maximum throughput
                logger.info(f"\nWaiting {wait_seconds} seconds before next run...")
                logger.info(f"Next run will start at: {(datetime.now() + timedelta(seconds=wait_seconds)).strftime('%H:%M:%S')}")
                time.sleep(wait_seconds)
        
        # Final aggregate calculation
        end_time = datetime.now()
        self.aggregate_results["end_time"] = end_time.isoformat()
        self.aggregate_results["total_duration_minutes"] = (end_time - start_time).total_seconds() / 60
        self.aggregate_results["run_results"] = self.test_runs
        self.aggregate_results["aggregate_statistics"] = self.calculate_aggregate_statistics()
        
        # Save results
        results_file = os.path.join(
            project_root,
            '_local',
            'logs',
            f'multi_test_aggregate_results_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        )
        os.makedirs(os.path.dirname(results_file), exist_ok=True)
        with open(results_file, 'w', encoding='utf-8') as f:
            json.dump(self.aggregate_results, f, indent=2, default=str)
        
        # Generate final report
        self.generate_aggregate_report()
        
        logger.info("\n" + "=" * 80)
        logger.info("ALL TEST RUNS COMPLETED")
        logger.info("=" * 80)
        logger.info(f"Total Runs: {self.aggregate_results['total_runs']}")
        logger.info(f"Completed: {self.aggregate_results['completed_runs']}")
        logger.info(f"Failed: {self.aggregate_results['failed_runs']}")
        logger.info(f"Results saved to: {results_file}")
        logger.info("=" * 80)
        
        return self.aggregate_results
    
    def generate_aggregate_report(self):
        """Generate comprehensive aggregate report."""
        aggregate = self.aggregate_results.get("aggregate_statistics", {})
        
        if not aggregate or aggregate.get("error"):
            logger.warning("Cannot generate aggregate report: insufficient data")
            return
        
        reports_dir = os.path.join(project_root, '_local', 'reports')
        os.makedirs(reports_dir, exist_ok=True)
        
        report_file = os.path.join(
            reports_dir,
            f"aggregate_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        )
        
        report = {
            "report_generated_at": datetime.now().isoformat(),
            "test_period": {
                "start_time": self.aggregate_results.get("start_time"),
                "end_time": self.aggregate_results.get("end_time"),
                "total_duration_minutes": self.aggregate_results.get("total_duration_minutes", 0),
                "total_runs": self.aggregate_results.get("total_runs", 0),
                "completed_runs": self.aggregate_results.get("completed_runs", 0),
                "failed_runs": self.aggregate_results.get("failed_runs", 0)
            },
            "aggregate_statistics": aggregate,
            "individual_runs": [
                {
                    "run_number": r.get("run_number"),
                    "duration_minutes": r.get("duration_minutes", 0),
                    "total_trades": r.get("total_trades", 0),
                    "total_cycles": r.get("total_cycles", 0),
                    "latest_report": r.get("latest_report")
                }
                for r in self.test_runs
            ]
        }
        
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, default=str)
        
        # Print summary
        logger.info("\n" + "=" * 80)
        logger.info("AGGREGATE REPORT SUMMARY")
        logger.info("=" * 80)
        logger.info(f"Total Runs: {report['test_period']['total_runs']}")
        logger.info(f"Completed Runs: {report['test_period']['completed_runs']}")
        logger.info(f"Failed Runs: {report['test_period']['failed_runs']}")
        logger.info(f"Total Duration: {report['test_period']['total_duration_minutes']:.1f} minutes")
        
        if aggregate.get("averages"):
            avgs = aggregate["averages"]
            logger.info("\nAverage Performance:")
            logger.info(f"  Trades per Run: {avgs['total_trades']['mean']:.1f} (min: {avgs['total_trades']['min']}, max: {avgs['total_trades']['max']})")
            logger.info(f"  Win Rate: {avgs['win_rate_percent']['mean']:.2f}% (min: {avgs['win_rate_percent']['min']:.2f}%, max: {avgs['win_rate_percent']['max']:.2f}%)")
            logger.info(f"  Total PnL: Rs {avgs['total_pnl']['mean']:,.2f} (sum: Rs {avgs['total_pnl']['sum']:,.2f})")
            logger.info(f"  Realized PnL: Rs {avgs['realized_pnl']['mean']:,.2f} (sum: Rs {avgs['realized_pnl']['sum']:,.2f})")
            logger.info(f"  Total Volume: Rs {avgs['total_volume']['mean']:,.2f} (sum: Rs {avgs['total_volume']['sum']:,.2f})")
        
        if aggregate.get("consistency"):
            cons = aggregate["consistency"]
            logger.info("\nConsistency Metrics:")
            logger.info(f"  Trades CV: {cons['trades_consistency']['cv']:.2f}% (lower is better)")
            logger.info(f"  PnL CV: {cons['pnl_consistency']['cv']:.2f}% (lower is better)")
        
        logger.info(f"\nReport saved to: {report_file}")
        logger.info("=" * 80)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Run multiple test iterations and aggregate results")
    parser.add_argument("--runs", type=int, default=5, help="Number of test runs (default: 5)")
    parser.add_argument("--duration", type=int, default=30, help="Duration of each run in minutes (default: 30)")
    parser.add_argument("--wait", type=int, default=10, help="Wait between runs in minutes (default: 10)")
    
    args = parser.parse_args()
    
    runner = MultipleTestRunner()
    results = runner.run_multiple_tests(
        num_runs=args.runs,
        test_duration_minutes=args.duration,
        wait_between_runs_minutes=args.wait
    )
    
    sys.exit(0 if results.get("failed_runs", 0) == 0 else 1)
