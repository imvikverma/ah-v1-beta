"""
Close Positions from Test Results
Reads test result files and closes all positions that are still open
"""

import os
import sys
import json
import logging
import glob
from datetime import datetime
from pathlib import Path

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Import AurumHarmony components
from aurum_harmony.engines.trade_execution.trade_execution import (
    PaperBrokerAdapter,
    Order,
    OrderSide,
    OrderType,
    OrderStatus
)
from aurum_harmony.engines.trade_execution.leverage_aware_adapter import LeverageAwareAdapter

def close_positions_from_results():
    """Close all open positions from test result files."""
    logger.info("=" * 80)
    logger.info("CLOSING POSITIONS FROM TEST RESULTS")
    logger.info("=" * 80)
    
    # Find all test result files
    results_dir = os.path.join(project_root, '_local', 'logs')
    pattern = os.path.join(results_dir, 'live_market_test_results_*.json')
    result_files = glob.glob(pattern)
    
    if not result_files:
        logger.warning("No test result files found.")
        return
    
    logger.info(f"\nFound {len(result_files)} test result file(s)")
    
    # Collect all open positions from all test files
    all_positions = {}
    total_open_count = 0
    
    for result_file in sorted(result_files):
        try:
            with open(result_file, 'r', encoding='utf-8') as f:
                results = json.load(f)
            
            # Check if there are positions tracked
            positions = results.get('positions', {})
            if isinstance(positions, dict):
                for symbol, pos_data in positions.items():
                    if isinstance(pos_data, dict):
                        quantity = pos_data.get('quantity', 0)
                        if abs(quantity) > 0.01:  # Position still open
                            if symbol not in all_positions:
                                all_positions[symbol] = {
                                    'quantity': 0,
                                    'avg_price': pos_data.get('avg_price', 0),
                                    'current_price': pos_data.get('current_price', pos_data.get('avg_price', 0)),
                                    'unrealized_pnl': 0
                                }
                            # Aggregate quantities (if multiple test runs have same symbol)
                            all_positions[symbol]['quantity'] += quantity
                            all_positions[symbol]['unrealized_pnl'] += pos_data.get('unrealized_pnl', 0)
                            total_open_count += 1
        except Exception as e:
            logger.warning(f"Error reading {result_file}: {e}")
    
    if not all_positions:
        logger.info("\n✅ No open positions found in test results. All positions are closed.")
        return
    
    logger.info(f"\nFound {len(all_positions)} unique symbol(s) with open positions:")
    for symbol, pos in all_positions.items():
        logger.info(f"  {symbol}: {pos['quantity']:.2f} @ ₹{pos['avg_price']:,.2f} (Unrealized PnL: ₹{pos['unrealized_pnl']:,.2f})")
    
    logger.info(f"\nTotal open position entries: {total_open_count}")
    
    # Initialize adapter to close positions
    initial_capital = 10000.0
    paper_adapter = PaperBrokerAdapter(initial_balance=initial_capital)
    leverage_adapter = LeverageAwareAdapter(
        broker_adapter=paper_adapter,
        capital=initial_capital,
        user_category="admin",
        leverage_multiplier=3.0
    )
    
    # Close all positions
    closed_count = 0
    total_realized_pnl = 0.0
    
    logger.info("\n" + "=" * 80)
    logger.info("CLOSING POSITIONS")
    logger.info("=" * 80)
    
    for symbol, pos_data in all_positions.items():
        try:
            quantity = pos_data['quantity']
            avg_price = pos_data['avg_price']
            current_price = pos_data.get('current_price', avg_price)
            
            # Close position by placing opposite order
            close_side = OrderSide.SELL if quantity > 0 else OrderSide.BUY
            close_order = Order(
                symbol=symbol,
                side=close_side,
                quantity=abs(quantity),
                order_type=OrderType.MARKET,
                limit_price=current_price,
                client_order_id=f"EOD_CLOSE_{symbol}_{int(datetime.now().timestamp())}"
            )
            
            logger.info(f"\nClosing {symbol} (Qty: {quantity:.2f}, Entry: ₹{avg_price:,.2f})...")
            result = leverage_adapter.place_order(close_order)
            
            if result.status == OrderStatus.FILLED:
                closed_count += 1
                close_price = result.metadata.get("filled_price", result.limit_price or current_price)
                
                # Calculate realized PnL
                if quantity > 0:  # Long position
                    pnl = (close_price - avg_price) * abs(quantity)
                else:  # Short position
                    pnl = (avg_price - close_price) * abs(quantity)
                
                total_realized_pnl += pnl
                logger.info(f"  ✅ CLOSED: {symbol} @ ₹{close_price:,.2f}, Realized PnL: ₹{pnl:,.2f}")
            else:
                logger.warning(f"  ❌ FAILED: {symbol} - {result.metadata.get('reason', 'Unknown')}")
                
        except Exception as e:
            logger.error(f"  ❌ ERROR closing {symbol}: {e}", exc_info=True)
    
    logger.info("\n" + "=" * 80)
    logger.info("CLOSING SUMMARY")
    logger.info("=" * 80)
    logger.info(f"Total Unique Symbols: {len(all_positions)}")
    logger.info(f"Total Position Entries: {total_open_count}")
    logger.info(f"Successfully Closed: {closed_count}")
    logger.info(f"Total Realized PnL: ₹{total_realized_pnl:,.2f}")
    logger.info("=" * 80)
    
    if closed_count == len(all_positions):
        logger.info("\n✅ All positions successfully closed!")
    else:
        logger.warning(f"\n⚠️  {len(all_positions) - closed_count} position(s) failed to close")

if __name__ == "__main__":
    close_positions_from_results()
