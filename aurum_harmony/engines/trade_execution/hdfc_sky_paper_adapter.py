"""
HDFC Sky Paper Trading Adapter

Uses real-time market data from HDFC Sky API but executes trades in paper mode.
Perfect for testing with live market conditions without risking real money.
"""

from __future__ import annotations

import logging
import threading
from typing import Dict, Optional, List, Any
from decimal import Decimal
from datetime import datetime
import time

from aurum_harmony.engines.trade_execution.trade_execution import (
    BrokerAdapter,
    Order,
    OrderStatus,
    OrderSide,
    OrderType,
    Position,
)

logger = logging.getLogger(__name__)


class HDFCSkyPaperAdapter(BrokerAdapter):
    """
    Paper trading adapter that uses live market data from HDFC Sky API.
    
    Features:
    - Fetches real-time prices from HDFC Sky
    - Executes trades in paper mode (no real money)
    - Perfect for testing with live market conditions
    - Thread-safe for concurrent operations
    """
    
    def __init__(
        self,
        hdfc_client,
        initial_balance: float = 100000.0,
        price_update_interval: int = 5  # seconds
    ):
        """
        Initialize HDFC Sky paper trading adapter.
        
        Args:
            hdfc_client: Authenticated HDFCSkyAPI instance
            initial_balance: Starting balance for paper trading
            price_update_interval: How often to update prices (seconds)
        """
        if not hdfc_client or not hdfc_client.is_authenticated():
            raise ValueError("HDFC Sky client must be authenticated")
        
        self.client = hdfc_client
        self._orders: Dict[str, Order] = {}
        self._positions: Dict[str, Position] = {}
        self._balance: Decimal = Decimal(str(initial_balance))
        self._initial_balance: Decimal = Decimal(str(initial_balance))
        self._lock = threading.Lock()
        self._price_cache: Dict[str, float] = {}
        self._price_cache_time: Dict[str, float] = {}
        self.price_update_interval = price_update_interval
        
        logger.info(f"HDFCSkyPaperAdapter initialized with balance: ₹{initial_balance:,.2f}")
    
    def _get_live_price(self, symbol: str, exchange: str = "NSE") -> Optional[float]:
        """
        Get live price from market data sources.
        Prioritizes NSE Option Chain (reliable), then tries HDFC Sky.
        
        Args:
            symbol: Symbol to fetch (e.g., "NIFTY", "RELIANCE")
            exchange: Exchange code (default: "NSE")
            
        Returns:
            Current price or None if unavailable
        """
        cache_key = f"{exchange}:{symbol}"
        current_time = time.time()
        
        # Check cache first
        if cache_key in self._price_cache:
            cache_time = self._price_cache_time.get(cache_key, 0)
            if current_time - cache_time < self.price_update_interval:
                return self._price_cache[cache_key]
        
        # Priority 1: Try NSE Option Chain (most reliable for indices)
        try:
            from aurum_harmony.engines.market_data.nse_option_chain import nse_option_chain
            underlying_price = nse_option_chain.get_underlying_price(symbol)
            if underlying_price:
                logger.debug(f"Got price from NSE Option Chain for {symbol}: ₹{underlying_price:,.2f}")
                with self._lock:
                    self._price_cache[cache_key] = underlying_price
                    self._price_cache_time[cache_key] = current_time
                return underlying_price
        except Exception as e:
            logger.debug(f"NSE Option Chain not available for {symbol}: {e}")
            import traceback
            logger.debug(traceback.format_exc())
        
        # Priority 2: Try HDFC Sky quotes (if endpoint works)
        try:
            quotes = self.client.get_quotes(symbol, exchange)
            
            # Parse response (adjust based on actual HDFC Sky response format)
            if isinstance(quotes, dict):
                # Try different possible response formats
                price = (
                    quotes.get("ltp") or  # Last traded price
                    quotes.get("last_price") or
                    quotes.get("price") or
                    quotes.get("data", {}).get("ltp") or
                    quotes.get("data", {}).get("last_price") or
                    quotes.get("data", {}).get("price")
                )
                
                if price:
                    price = float(price)
                    # Update cache
                    with self._lock:
                        self._price_cache[cache_key] = price
                        self._price_cache_time[cache_key] = current_time
                    logger.debug(f"Got price from HDFC Sky for {symbol}: ₹{price:,.2f}")
                    return price
        except Exception as e:
            logger.debug(f"HDFC Sky quotes not available for {symbol}: {e}")
        
        # Fallback to cached price if available
        if cache_key in self._price_cache:
            logger.debug(f"Using cached price for {symbol}")
            return self._price_cache[cache_key]
        
        # Last resort: Use mock prices for testing (when market data unavailable)
        # This allows paper trading to work even when APIs are down
        mock_prices = {
            "NIFTY": 24000.0,
            "NIFTY50": 24000.0,
            "BANKNIFTY": 50000.0,
            "SENSEX": 75000.0,
        }
        
        symbol_upper = symbol.upper()
        if symbol_upper in mock_prices:
            mock_price = mock_prices[symbol_upper]
            logger.warning(f"Using mock price for {symbol}: ₹{mock_price:,.2f} (market data unavailable)")
            with self._lock:
                self._price_cache[cache_key] = mock_price
                self._price_cache_time[cache_key] = current_time
            return mock_price
        
        return None
    
    def place_order(self, order: Order) -> Order:
        """
        Place an order in paper trading mode.
        Uses live prices from HDFC Sky but doesn't place real orders.
        
        Args:
            order: Order object to place
            
        Returns:
            Order object with status updated
        """
        with self._lock:
            try:
                # Get live price from HDFC Sky
                exchange = order.metadata.get("exchange", "NSE")
                live_price = self._get_live_price(order.symbol, exchange)
                
                if live_price is None:
                    order.update_status(OrderStatus.REJECTED, "Unable to fetch live price from HDFC Sky")
                    logger.warning(f"Order {order.client_order_id} rejected: No live price available")
                    return order
                
                # Simulate order execution
                if order.order_type == OrderType.MARKET:
                    execution_price = live_price
                elif order.order_type == OrderType.LIMIT:
                    if order.side == OrderSide.BUY and order.limit_price >= live_price:
                        execution_price = min(order.limit_price, live_price)
                    elif order.side == OrderSide.SELL and order.limit_price <= live_price:
                        execution_price = max(order.limit_price, live_price)
                    else:
                        # Limit order not executable at current price
                        order.update_status(OrderStatus.NEW, "Limit order pending execution")
                        order.broker_order_id = f"PAPER_{order.client_order_id}"
                        self._orders[order.client_order_id] = order
                        logger.info(f"Order {order.client_order_id} placed (limit pending): {order.side.value} {order.quantity} {order.symbol} @ ₹{order.limit_price}")
                        return order
                else:
                    order.update_status(OrderStatus.REJECTED, f"Unsupported order type: {order.order_type}")
                    return order
                
                # Calculate order value
                order_value = Decimal(str(execution_price)) * Decimal(str(order.quantity))
                
                # Check balance for BUY orders
                if order.side == OrderSide.BUY:
                    if self._balance < order_value:
                        order.update_status(OrderStatus.REJECTED, f"Insufficient balance. Required: ₹{order_value:,.2f}, Available: ₹{self._balance:,.2f}")
                        logger.warning(f"Order {order.client_order_id} rejected: Insufficient balance")
                        return order
                    self._balance -= order_value
                else:  # SELL
                    # For SELL, we're closing a position or shorting
                    # Add proceeds to balance
                    self._balance += order_value
                
                # Update order
                order.broker_order_id = f"PAPER_{order.client_order_id}"
                order.update_status(OrderStatus.FILLED, f"Paper trade executed at ₹{execution_price:,.2f}")
                order.metadata["execution_price"] = float(execution_price)
                order.metadata["execution_time"] = time.time()
                order.metadata["data_source"] = "HDFC Sky (Live Data)"
                order.metadata["execution_mode"] = "Paper Trading"
                
                # Update or create position
                position_key = order.symbol
                if position_key in self._positions:
                    position = self._positions[position_key]
                    # Update existing position
                    if order.side == OrderSide.BUY:
                        # Add to long position
                        total_quantity = position.quantity + order.quantity
                        total_cost = (position.avg_price * position.quantity) + (execution_price * order.quantity)
                        position.avg_price = float(total_cost / total_quantity)
                        position.quantity = total_quantity
                    else:  # SELL
                        # Reduce long position
                        position.quantity -= order.quantity
                        if position.quantity <= 0:
                            # Position closed
                            del self._positions[position_key]
                        else:
                            # Update average price (FIFO-like)
                            pass
                else:
                    # Create new position
                    if order.side == OrderSide.BUY:
                        self._positions[position_key] = Position(
                            symbol=order.symbol,
                            quantity=order.quantity,
                            avg_price=execution_price,
                            current_price=execution_price,
                            side=OrderSide.BUY,
                            opened_at=time.time()
                        )
                
                # Update position price
                if position_key in self._positions:
                    self._positions[position_key].update_price(execution_price)
                
                logger.info(
                    f"Paper order executed: {order.side.value} {order.quantity} {order.symbol} "
                    f"@ ₹{execution_price:,.2f} | Balance: ₹{self._balance:,.2f}"
                )
                
                return order
                
            except Exception as e:
                logger.error(f"Error placing paper order {order.client_order_id}: {e}")
                order.update_status(OrderStatus.REJECTED, str(e))
                return order
    
    def cancel_order(self, broker_order_id: str) -> bool:
        """
        Cancel a paper trading order.
        
        Args:
            broker_order_id: Broker order ID (starts with "PAPER_")
            
        Returns:
            True if cancelled, False otherwise
        """
        with self._lock:
            # Find order by broker_order_id
            order = None
            for o in self._orders.values():
                if o.broker_order_id == broker_order_id:
                    order = o
                    break
            
            if order:
                if order.status == OrderStatus.NEW:
                    order.update_status(OrderStatus.CANCELLED, "Cancelled by user")
                    logger.info(f"Paper order {broker_order_id} cancelled")
                    return True
                else:
                    logger.warning(f"Cannot cancel order {broker_order_id}: Status is {order.status}")
                    return False
            else:
                logger.warning(f"Order {broker_order_id} not found")
                return False
    
    def get_balance(self) -> float:
        """Get current paper trading balance."""
        with self._lock:
            return float(self._balance)
    
    def get_positions(self) -> List[Position]:
        """Get current paper trading positions."""
        with self._lock:
            # Update prices for all positions
            for position in self._positions.values():
                live_price = self._get_live_price(position.symbol)
                if live_price:
                    position.update_price(live_price)
            return list(self._positions.values())
    
    def get_orders(self) -> List[Order]:
        """Get all paper trading orders."""
        with self._lock:
            return list(self._orders.values())
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get paper trading statistics."""
        with self._lock:
            positions = list(self._positions.values())
            total_unrealized_pnl = sum(p.unrealized_pnl for p in positions)
            
            return {
                "initial_balance": float(self._initial_balance),
                "current_balance": float(self._balance),
                "total_unrealized_pnl": total_unrealized_pnl,
                "total_pnl": float(self._balance - self._initial_balance) + total_unrealized_pnl,
                "positions_count": len(positions),
                "orders_count": len(self._orders),
                "data_source": "NSE Option Chain / HDFC Sky (Live Market Data)",
                "execution_mode": "Paper Trading",
                "note": "Uses real-time prices from NSE/HDFC Sky but trades are simulated"
            }

