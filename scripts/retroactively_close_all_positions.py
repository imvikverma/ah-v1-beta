"""
Retroactively Close All Open Positions
Creates closing trades for all open positions in test results and updates the files
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

# Configure logging with UTF-8
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

def retroactively_close_positions():
    """Add closing trades to all test result files for open positions."""
    logger.info("=" * 80)
    logger.info("RETROACTIVELY CLOSING ALL OPEN POSITIONS")
    logger.info("=" * 80)
    
    # Find all test result files
    results_dir = os.path.join(project_root, '_local', 'logs')
    pattern = os.path.join(results_dir, 'live_market_test_results_*.json')
    result_files = glob.glob(pattern)
    
    if not result_files:
        logger.warning("No test result files found.")
        return
    
    logger.info(f"\nFound {len(result_files)} test result file(s)")
    
    total_closed = 0
    total_realized_pnl = 0.0
    
    for result_file in sorted(result_files):
        try:
            with open(result_file, 'r', encoding='utf-8') as f:
                results = json.load(f)
            
            trades = results.get('trades', [])
            positions = results.get('positions', {})
            
            # Find open trades (pnl = 0) and positions
            open_trades = [t for t in trades if t.get('pnl', 0) == 0.0]
            
            if not open_trades and not positions:
                continue  # Skip files with no open positions
            
            logger.info(f"\nProcessing: {os.path.basename(result_file)}")
            logger.info(f"  Open trades: {len(open_trades)}")
            logger.info(f"  Positions: {len(positions)}")
            
            # Create closing trades for all open positions
            closing_trades = []
            file_pnl = 0.0
            
            # Close positions from positions dict
            for symbol, pos_data in positions.items():
                if isinstance(pos_data, dict):
                    quantity = pos_data.get('quantity', 0)
                    if abs(quantity) > 0.01:  # Position still open
                        avg_price = pos_data.get('avg_price', 0)
                        current_price = pos_data.get('current_price', avg_price)
                        unrealized_pnl = pos_data.get('unrealized_pnl', 0)
                        
                        # Create closing trade
                        close_trade = {
                            "order_id": f"EOD_CLOSE_{symbol}_{int(datetime.now().timestamp())}",
                            "symbol": symbol,
                            "side": "SELL" if quantity > 0 else "BUY",
                            "quantity": abs(quantity),
                            "price": current_price,
                            "value": current_price * abs(quantity),
                            "timestamp": datetime.now().isoformat(),
                            "pnl": unrealized_pnl,  # Use unrealized PnL as realized
                            "close_price": current_price,
                            "close_timestamp": datetime.now().isoformat(),
                            "entry_price": avg_price
                        }
                        closing_trades.append(close_trade)
                        file_pnl += unrealized_pnl
                        
                        # Update original trade's PnL (find matching trade and update)
                        for trade in trades:
                            if (trade.get('symbol') == symbol and 
                                trade.get('pnl', 0) == 0.0 and
                                abs(trade.get('quantity', 0) - quantity) < 0.01):  # Match quantity
                                # Calculate actual PnL
                                entry_price = trade.get('price', avg_price)
                                if quantity > 0:  # Long
                                    calculated_pnl = (current_price - entry_price) * abs(quantity)
                                else:  # Short
                                    calculated_pnl = (entry_price - current_price) * abs(quantity)
                                
                                trade['pnl'] = calculated_pnl
                                trade['close_price'] = current_price
                                trade['close_timestamp'] = datetime.now().isoformat()
                                break
            
            # Also close trades that are still open (pnl = 0) and not in positions dict
            for trade in open_trades:
                symbol = trade.get('symbol')
                if symbol in positions:
                    continue  # Already handled above
                
                # For trades without position data, use entry price as close (flat PnL)
                # This is realistic for retroactive closing when we don't have price movement data
                entry_price = trade.get('price', 0)
                quantity = trade.get('quantity', 0)
                current_price = entry_price  # Close at entry = flat PnL
                
                # Calculate PnL (will be 0 since entry = close, but mark as closed)
                pnl = 0.0  # Flat close
                
                # Update trade to mark as closed
                trade['pnl'] = pnl
                trade['close_price'] = current_price
                trade['close_timestamp'] = datetime.now().isoformat()
                trade['closed'] = True
                
                # Add closing trade
                close_trade = {
                    "order_id": f"EOD_CLOSE_{symbol}_{int(datetime.now().timestamp())}",
                    "symbol": symbol,
                    "side": "SELL" if quantity > 0 else "BUY",
                    "quantity": abs(quantity),
                    "price": current_price,
                    "value": current_price * abs(quantity),
                    "timestamp": datetime.now().isoformat(),
                    "pnl": pnl,
                    "close_price": current_price,
                    "close_timestamp": datetime.now().isoformat(),
                    "entry_price": entry_price
                }
                closing_trades.append(close_trade)
                file_pnl += pnl
            
            # Add closing trades to results
            if closing_trades:
                results['trades'].extend(closing_trades)
                results['positions'] = {}  # Clear positions (all closed)
                results['eod_closed'] = True
                results['eod_close_timestamp'] = datetime.now().isoformat()
                results['eod_realized_pnl'] = file_pnl
                
                # Save updated file
                with open(result_file, 'w', encoding='utf-8') as f:
                    json.dump(results, f, indent=2, default=str)
                
                total_closed += len(closing_trades)
                total_realized_pnl += file_pnl
                logger.info(f"  ✅ Closed {len(closing_trades)} position(s), Realized PnL: Rs {file_pnl:,.2f}")
            
        except Exception as e:
            logger.error(f"Error processing {result_file}: {e}", exc_info=True)
    
    logger.info("\n" + "=" * 80)
    logger.info("RETROACTIVE CLOSING SUMMARY")
    logger.info("=" * 80)
    logger.info(f"Total Positions Closed: {total_closed}")
    logger.info(f"Total Realized PnL: Rs {total_realized_pnl:,.2f}")
    logger.info("=" * 80)
    
    if total_closed > 0:
        logger.info("\n✅ All positions retroactively closed in test result files!")
        logger.info("   Run: python scripts\\analyze_closed_trades.py to see updated results.")

if __name__ == "__main__":
    retroactively_close_positions()
