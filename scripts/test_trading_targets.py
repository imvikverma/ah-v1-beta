"""
Test Trading Targets Achievement
Tests that we can achieve the target trades per day for each capital level
"""

import os
import sys
import logging
import time
from datetime import datetime, timedelta
from typing import Dict, Any

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

from aurum_harmony.engines.trading_targets import TradingTargetsManager
from aurum_harmony.engines.capital_progression import CapitalProgressionManager
from scripts.test_live_market_burn_in import LiveMarketBurnInTest


class TradingTargetsTest:
    """
    Test to validate we can achieve trading targets for each capital level.
    """
    
    def __init__(self):
        self.results: Dict[str, Any] = {
            "start_time": datetime.now().isoformat(),
            "capital_levels_tested": [],
            "targets_achieved": [],
            "targets_missed": []
        }
        logger.info("TradingTargetsTest initialized")
    
    def test_capital_level(self, capital: float, test_duration_minutes: int = 10):
        """
        Test trading targets for a specific capital level.
        
        Args:
            capital: Capital amount to test
            test_duration_minutes: Test duration (scaled to daily targets)
        """
        logger.info("=" * 80)
        logger.info(f"TESTING CAPITAL LEVEL: Rs {capital:,.2f}")
        logger.info("=" * 80)
        
        # Get targets
        targets = TradingTargetsManager.get_targets_for_capital(capital)
        target_trades_per_day = targets.total_trades_per_day
        target_trades_per_index = targets.trades_per_index
        
        # Calculate scaled target for test duration
        # Scale to test duration (e.g., 10 minutes = 10/375 minutes of trading day)
        trading_minutes_per_day = 6.25 * 60  # 375 minutes
        scale_factor = test_duration_minutes / trading_minutes_per_day
        scaled_target = int(target_trades_per_day * scale_factor)
        
        logger.info(f"Target Trades per Day: {target_trades_per_day}")
        logger.info(f"Target Trades per Index: {target_trades_per_index}")
        logger.info(f"Test Duration: {test_duration_minutes} minutes")
        logger.info(f"Scaled Target for Test: {scaled_target} trades")
        logger.info(f"Target Trades per Minute: {TradingTargetsManager.calculate_trades_per_minute(capital):.3f}")
        
        # Run test
        test = LiveMarketBurnInTest(
            user_id=f"target_test_{int(capital)}",
            user_category="admin"
        )
        
        # Update capital
        test.paper_adapter.update_balance(capital)
        test.leverage_adapter.capital = capital
        test.leverage_adapter.max_exposure = capital * 3.0  # 3× leverage
        
        # Run for test duration with aggressive cycle interval
        # Calculate cycle interval to achieve target
        target_trades_per_minute = TradingTargetsManager.calculate_trades_per_minute(capital)
        # Aim for 2-3 trades per cycle across 3 indices
        trades_per_cycle = 2.5  # Average
        cycle_interval_seconds = int((trades_per_cycle / target_trades_per_minute) * 60)
        cycle_interval_seconds = max(30, min(cycle_interval_seconds, 120))  # Between 30s and 2min
        
        logger.info(f"Cycle Interval: {cycle_interval_seconds} seconds")
        logger.info(f"Expected Cycles: {int((test_duration_minutes * 60) / cycle_interval_seconds)}")
        
        end_time = datetime.now() + timedelta(minutes=test_duration_minutes)
        cycle_count = 0
        
        try:
            while datetime.now() < end_time:
                cycle_count += 1
                logger.info(f"\n--- Cycle #{cycle_count} ---")
                
                # Execute trading cycle
                cycle_results = test.execute_trading_cycle()
                
                current_trades = len(test.trades_executed)
                logger.info(f"Total Trades So Far: {current_trades} / {scaled_target}")
                
                # Wait for next cycle
                if datetime.now() < end_time:
                    wait_seconds = min(cycle_interval_seconds, (end_time - datetime.now()).total_seconds())
                    if wait_seconds > 0:
                        time.sleep(wait_seconds)
        except Exception as e:
            logger.error(f"Test failed: {e}", exc_info=True)
        
        # Calculate results
        actual_trades = len(test.trades_executed)
        achievement_percent = (actual_trades / scaled_target * 100) if scaled_target > 0 else 0
        achieved = actual_trades >= scaled_target * 0.9  # 90% of target is acceptable
        
        result = {
            "capital": capital,
            "target_trades_per_day": target_trades_per_day,
            "target_trades_per_index": target_trades_per_index,
            "test_duration_minutes": test_duration_minutes,
            "scaled_target": scaled_target,
            "actual_trades": actual_trades,
            "achievement_percent": achievement_percent,
            "achieved": achieved,
            "cycles_executed": cycle_count,
            "trades_per_cycle": actual_trades / cycle_count if cycle_count > 0 else 0
        }
        
        self.results["capital_levels_tested"].append(result)
        
        if achieved:
            self.results["targets_achieved"].append(result)
            logger.info(f"\n[OK] Target ACHIEVED: {actual_trades} trades ({achievement_percent:.1f}% of target)")
        else:
            self.results["targets_missed"].append(result)
            logger.warning(f"\n[WARNING] Target MISSED: {actual_trades} trades ({achievement_percent:.1f}% of target)")
        
        return result
    
    def run_all_capital_levels(self, test_duration_minutes: int = 10):
        """Test all capital levels."""
        logger.info("=" * 80)
        logger.info("TESTING ALL CAPITAL LEVELS")
        logger.info("=" * 80)
        
        targets = TradingTargetsManager.TARGETS
        
        for target in targets:
            self.test_capital_level(target.capital, test_duration_minutes)
            # Small delay between tests
            time.sleep(5)
        
        # Final summary
        self.results["end_time"] = datetime.now().isoformat()
        self.print_summary()
        
        # Save results
        results_file = os.path.join(
            project_root,
            '_local',
            'logs',
            f'trading_targets_test_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        )
        import json
        with open(results_file, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, default=str)
        
        logger.info(f"\n[OK] Results saved: {results_file}")
        
        return self.results
    
    def print_summary(self):
        """Print test summary."""
        logger.info("\n" + "=" * 80)
        logger.info("TRADING TARGETS TEST SUMMARY")
        logger.info("=" * 80)
        
        for result in self.results["capital_levels_tested"]:
            status = "[OK]" if result["achieved"] else "[MISSED]"
            logger.info(
                f"{status} Rs {result['capital']:,.2f}: "
                f"{result['actual_trades']}/{result['scaled_target']} trades "
                f"({result['achievement_percent']:.1f}%)"
            )
        
        logger.info(f"\nTargets Achieved: {len(self.results['targets_achieved'])}/{len(self.results['capital_levels_tested'])}")
        logger.info("=" * 80)


if __name__ == "__main__":
    import argparse
    import time
    
    parser = argparse.ArgumentParser(description="Test trading targets achievement")
    parser.add_argument("--duration", type=int, default=10, help="Test duration per capital level in minutes")
    parser.add_argument("--capital", type=float, help="Test specific capital level only")
    
    args = parser.parse_args()
    
    test = TradingTargetsTest()
    
    if args.capital:
        test.test_capital_level(args.capital, args.duration)
    else:
        test.run_all_capital_levels(args.duration)
