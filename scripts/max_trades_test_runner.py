"""
Maximum Trades Test Runner
Aggressively runs tests to maximize trades per session and capture every data point

Configuration:
- Very short cycles (1-2 minutes)
- High frequency execution
- Maximum data capture
- Comprehensive logging
"""

import os
import sys
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, List
import json
import time

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

# Configure comprehensive logging
log_file = os.path.join(project_root, '_local', 'logs', f'max_trades_test_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')
os.makedirs(os.path.dirname(log_file), exist_ok=True)

logging.basicConfig(
    level=logging.DEBUG,  # DEBUG level to capture everything
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file, encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

from scripts.test_live_market_burn_in import LiveMarketBurnInTest


class MaxTradesTestRunner:
    """
    Aggressive test runner to maximize trades and data capture.
    """
    
    def __init__(self):
        self.total_trades = 0
        self.total_cycles = 0
        self.all_trades: List[Dict[str, Any]] = []
        self.all_cycles: List[Dict[str, Any]] = []
        self.start_time = datetime.now()
        logger.info("=" * 80)
        logger.info("MAXIMUM TRADES TEST RUNNER INITIALIZED")
        logger.info("=" * 80)
    
    def run_high_frequency_test(
        self,
        duration_minutes: int = 60,
        cycle_interval_seconds: int = 60,  # 1 minute cycles for maximum trades
        max_concurrent_positions: int = 10
    ):
        """
        Run high-frequency test to maximize trades.
        
        Args:
            duration_minutes: Total test duration
            cycle_interval_seconds: Time between cycles (shorter = more trades)
            max_concurrent_positions: Maximum positions to hold
        """
        logger.info("=" * 80)
        logger.info("STARTING HIGH-FREQUENCY MAX TRADES TEST")
        logger.info(f"Duration: {duration_minutes} minutes")
        logger.info(f"Cycle Interval: {cycle_interval_seconds} seconds")
        logger.info(f"Max Concurrent Positions: {max_concurrent_positions}")
        logger.info("=" * 80)
        
        test = LiveMarketBurnInTest(
            user_id=f"max_trades_{int(time.time())}",
            user_category="admin"
        )
        
        end_time = self.start_time + timedelta(minutes=duration_minutes)
        cycle_count = 0
        
        try:
            while datetime.now() < end_time:
                cycle_count += 1
                self.total_cycles += 1
                
                logger.info(f"\n{'='*80}")
                logger.info(f"TRADING CYCLE #{cycle_count} - MAX TRADES MODE")
                logger.info(f"{'='*80}")
                logger.info(f"Time: {datetime.now().strftime('%H:%M:%S')}")
                logger.info(f"Remaining: {(end_time - datetime.now()).total_seconds()/60:.1f} minutes")
                
                # Execute trading cycle
                cycle_start = datetime.now()
                cycle_results = test.execute_trading_cycle()
                cycle_duration = (datetime.now() - cycle_start).total_seconds()
                
                # Capture comprehensive cycle data
                cycle_data = {
                    "cycle_number": cycle_count,
                    "timestamp": datetime.now().isoformat(),
                    "duration_seconds": cycle_duration,
                    "orders_placed": cycle_results.get("orders_placed", 0),
                    "orders_filled": cycle_results.get("orders_filled", 0),
                    "orders_rejected": cycle_results.get("orders_rejected", 0),
                    "positions_opened": cycle_results.get("positions_opened", 0),
                    "positions_closed": cycle_results.get("positions_closed", 0),
                    "pnl": cycle_results.get("pnl", 0),
                    "exposure_status": test.leverage_adapter.get_exposure_status(),
                    "positions": {
                        symbol: {
                            "quantity": pos.quantity,
                            "avg_price": pos.avg_price,
                            "current_price": pos.current_price,
                            "unrealized_pnl": pos.unrealized_pnl,
                            "side": pos.side.value if hasattr(pos.side, 'value') else str(pos.side)
                        }
                        for symbol, pos in test.positions_tracked.items()
                    }
                }
                
                self.all_cycles.append(cycle_data)
                self.total_trades += cycle_results.get("orders_filled", 0)
                
                # Log comprehensive cycle data
                logger.info(f"\nCycle #{cycle_count} Results:")
                logger.info(f"  Orders Placed: {cycle_results.get('orders_placed', 0)}")
                logger.info(f"  Orders Filled: {cycle_results.get('orders_filled', 0)}")
                logger.info(f"  Orders Rejected: {cycle_results.get('orders_rejected', 0)}")
                logger.info(f"  Positions Opened: {cycle_results.get('positions_opened', 0)}")
                logger.info(f"  Positions Closed: {cycle_results.get('positions_closed', 0)}")
                logger.info(f"  PnL: Rs {cycle_results.get('pnl', 0):,.2f}")
                logger.info(f"  Cycle Duration: {cycle_duration:.2f} seconds")
                logger.info(f"  Total Trades So Far: {self.total_trades}")
                
                # Capture all trades from this cycle
                for trade in test.trades_executed:
                    if trade not in self.all_trades:
                        trade_data = {
                            **trade,
                            "cycle_number": cycle_count,
                            "cycle_timestamp": datetime.now().isoformat()
                        }
                        self.all_trades.append(trade_data)
                
                # Close some positions if we have too many (to free up capital for more trades)
                positions = test.leverage_adapter.get_positions()
                if len(positions) >= max_concurrent_positions:
                    logger.info(f"\nMax positions reached ({len(positions)}). Closing oldest positions...")
                    positions_list = list(positions.items())[:3]  # Close 3 oldest
                    for symbol, position in positions_list:
                    from aurum_harmony.engines.trade_execution.trade_execution import Order, OrderSide, OrderType
                    close_order = Order(
                        symbol=symbol,
                        side=OrderSide.SELL if position.side.value == "BUY" else OrderSide.BUY,
                        quantity=abs(position.quantity),
                        order_type=OrderType.MARKET,
                        limit_price=position.current_price,
                        client_order_id=f"CLOSE_{symbol}_{int(time.time())}"
                    )
                        result = test.leverage_adapter.place_order(close_order)
                        if result.status.value == "FILLED":
                            logger.info(f"  Closed {symbol} to free capital")
                
                # Generate report every 10 cycles
                if cycle_count % 10 == 0:
                    logger.info("\n" + "=" * 80)
                    logger.info("PERIODIC REPORT")
                    logger.info("=" * 80)
                    report = test.generate_report()
                    logger.info(f"Total Cycles: {cycle_count}")
                    logger.info(f"Total Trades: {self.total_trades}")
                    logger.info(f"Average Trades per Cycle: {self.total_trades/cycle_count:.2f}")
                    logger.info("=" * 80)
                
                # Wait for next cycle
                if datetime.now() < end_time:
                    wait_seconds = min(cycle_interval_seconds, (end_time - datetime.now()).total_seconds())
                    if wait_seconds > 0:
                        logger.info(f"\nWaiting {wait_seconds:.0f} seconds until next cycle...")
                        time.sleep(wait_seconds)
                
        except KeyboardInterrupt:
            logger.info("\n[INTERRUPTED] Test stopped by user")
        except Exception as e:
            logger.error(f"[ERROR] Test failed: {e}", exc_info=True)
        finally:
            # Final comprehensive report
            end_time = datetime.now()
            duration = (end_time - self.start_time).total_seconds() / 60
            
            logger.info("\n" + "=" * 80)
            logger.info("FINAL COMPREHENSIVE REPORT")
            logger.info("=" * 80)
            logger.info(f"Total Duration: {duration:.1f} minutes")
            logger.info(f"Total Cycles: {self.total_cycles}")
            logger.info(f"Total Trades: {self.total_trades}")
            logger.info(f"Average Trades per Cycle: {self.total_trades/self.total_cycles:.2f}" if self.total_cycles > 0 else "N/A")
            logger.info(f"Trades per Minute: {self.total_trades/duration:.2f}" if duration > 0 else "N/A")
            logger.info("=" * 80)
            
            # Save comprehensive data
            self.save_comprehensive_data(test, duration)
    
    def save_comprehensive_data(self, test: LiveMarketBurnInTest, duration_minutes: float):
        """Save all captured data comprehensively."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        data_dir = os.path.join(project_root, '_local', 'comprehensive_test_data')
        os.makedirs(data_dir, exist_ok=True)
        
        # Comprehensive results
        comprehensive_data = {
            "test_metadata": {
                "start_time": self.start_time.isoformat(),
                "end_time": datetime.now().isoformat(),
                "duration_minutes": duration_minutes,
                "total_cycles": self.total_cycles,
                "total_trades": self.total_trades,
                "trades_per_minute": self.total_trades / duration_minutes if duration_minutes > 0 else 0,
                "trades_per_cycle": self.total_trades / self.total_cycles if self.total_cycles > 0 else 0
            },
            "all_trades": self.all_trades,
            "all_cycles": self.all_cycles,
            "final_positions": {
                symbol: {
                    "quantity": pos.quantity,
                    "avg_price": pos.avg_price,
                    "current_price": pos.current_price,
                    "unrealized_pnl": pos.unrealized_pnl,
                    "side": pos.side.value if hasattr(pos.side, 'value') else str(pos.side)
                }
                for symbol, pos in test.positions_tracked.items()
            },
            "final_exposure": test.leverage_adapter.get_exposure_status(),
            "final_report": test.generate_report() if hasattr(test, 'generate_report') else None
        }
        
        # Save comprehensive JSON
        json_file = os.path.join(data_dir, f"max_trades_comprehensive_{timestamp}.json")
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(comprehensive_data, f, indent=2, default=str)
        
        logger.info(f"\n[OK] Comprehensive data saved: {json_file}")
        logger.info(f"  - Total Trades: {len(self.all_trades)}")
        logger.info(f"  - Total Cycles: {len(self.all_cycles)}")
        logger.info(f"  - File Size: {os.path.getsize(json_file) / 1024:.1f} KB")
        
        # Also save to test results format for ML collector
        test_results_file = os.path.join(
            project_root,
            '_local',
            'logs',
            f'max_trades_test_results_{timestamp}.json'
        )
        test_results = {
            "start_time": self.start_time.isoformat(),
            "end_time": datetime.now().isoformat(),
            "duration_minutes": duration_minutes,
            "total_cycles": self.total_cycles,
            "total_trades": self.total_trades,
            "trades": self.all_trades,
            "cycles": self.all_cycles
        }
        with open(test_results_file, 'w', encoding='utf-8') as f:
            json.dump(test_results, f, indent=2, default=str)
        
        logger.info(f"[OK] Test results saved: {test_results_file}")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Maximum trades test runner")
    parser.add_argument("--duration", type=int, default=60, help="Duration in minutes (default: 60)")
    parser.add_argument("--cycle-interval", type=int, default=60, help="Cycle interval in seconds (default: 60)")
    parser.add_argument("--max-positions", type=int, default=10, help="Max concurrent positions (default: 10)")
    
    args = parser.parse_args()
    
    runner = MaxTradesTestRunner()
    runner.run_high_frequency_test(
        duration_minutes=args.duration,
        cycle_interval_seconds=args.cycle_interval,
        max_concurrent_positions=args.max_positions
    )
