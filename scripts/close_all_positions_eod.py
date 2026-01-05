"""
Emergency EOD Position Closer
Closes all open positions from test runs (for positions that weren't auto-closed)
"""

import os
import sys
import logging
from datetime import datetime
from decimal import Decimal

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
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

def close_all_positions():
    """Close all open positions from test runs."""
    logger.info("=" * 80)
    logger.info("EOD POSITION CLOSER - Closing All Open Positions")
    logger.info("=" * 80)
    
    # Initialize adapter (using same setup as test)
    initial_capital = 10000.0
    paper_adapter = PaperBrokerAdapter(initial_balance=initial_capital)
    leverage_adapter = LeverageAwareAdapter(
        broker_adapter=paper_adapter,
        capital=initial_capital,
        user_category="admin",
        leverage_multiplier=3.0
    )
    
    # Get all positions
    positions = leverage_adapter.get_positions()
    
    if not positions:
        logger.info("No open positions found. All positions are already closed.")
        return
    
    logger.info(f"\nFound {len(positions)} open position(s) to close:")
    for symbol, position in positions.items():
        logger.info(f"  {symbol}: {position.quantity:.2f} @ ₹{position.avg_price:,.2f} (Unrealized PnL: ₹{position.unrealized_pnl:,.2f})")
    
    # Close all positions
    closed_count = 0
    total_realized_pnl = 0.0
    
    for symbol, position in positions.items():
        try:
            # Close position by placing opposite order
            close_side = OrderSide.SELL if position.quantity > 0 else OrderSide.BUY
            close_order = Order(
                symbol=symbol,
                side=close_side,
                quantity=abs(position.quantity),
                order_type=OrderType.MARKET,
                limit_price=position.current_price,  # Market order at current price
                client_order_id=f"EOD_CLOSE_{symbol}_{int(datetime.now().timestamp())}"
            )
            
            logger.info(f"\nClosing {symbol}...")
            result = leverage_adapter.place_order(close_order)
            
            if result.status == OrderStatus.FILLED:
                closed_count += 1
                close_price = result.metadata.get("filled_price", result.limit_price or position.current_price)
                
                # Calculate realized PnL
                if position.quantity > 0:  # Long position
                    pnl = (close_price - position.avg_price) * abs(position.quantity)
                else:  # Short position
                    pnl = (position.avg_price - close_price) * abs(position.quantity)
                
                total_realized_pnl += pnl
                logger.info(f"  ✅ CLOSED: {symbol} @ ₹{close_price:,.2f}, Realized PnL: ₹{pnl:,.2f}")
            else:
                logger.warning(f"  ❌ FAILED: {symbol} - {result.metadata.get('reason', 'Unknown')}")
                
        except Exception as e:
            logger.error(f"  ❌ ERROR closing {symbol}: {e}", exc_info=True)
    
    logger.info("\n" + "=" * 80)
    logger.info("EOD CLOSING SUMMARY")
    logger.info("=" * 80)
    logger.info(f"Total Positions: {len(positions)}")
    logger.info(f"Successfully Closed: {closed_count}")
    logger.info(f"Failed: {len(positions) - closed_count}")
    logger.info(f"Total Realized PnL: ₹{total_realized_pnl:,.2f}")
    logger.info("=" * 80)
    
    # Check remaining positions
    remaining = leverage_adapter.get_positions()
    if remaining:
        logger.warning(f"\n⚠️  {len(remaining)} position(s) still open:")
        for symbol, pos in remaining.items():
            logger.warning(f"  {symbol}: {pos.quantity:.2f}")
    else:
        logger.info("\n✅ All positions successfully closed!")

if __name__ == "__main__":
    close_all_positions()
