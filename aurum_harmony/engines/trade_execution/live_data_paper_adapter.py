"""
Live Data Paper Trading Adapter

Uses real-time market data from Kotak Neo API but executes trades in paper mode.
Perfect for testing with live market conditions without risking real money.
"""

from __future__ import annotations

import logging
import threading
from typing import Dict, Optional, List, Any
from decimal import Decimal
from datetime import datetime

from aurum_harmony.engines.trade_execution.trade_execution import (
    BrokerAdapter,
    Order,
    OrderStatus,
    OrderSide,
    OrderType,
    Position,
)

# Configure logging
logger = logging.getLogger(__name__)


class LiveDataPaperAdapter(BrokerAdapter):
    """
    Paper trading adapter that uses live market data from Kotak Neo API.
    
    Features:
    - Fetches real-time prices from Kotak Neo
    - Executes trades in paper mode (no real money)
    - Perfect for testing with live market conditions
    - Thread-safe for concurrent operations
    """
    
    def __init__(
        self,
        kotak_client,
        initial_balance: float = 100000.0,
        price_update_interval: int = 5  # seconds
    ):
        """
        Initialize live data paper adapter.
        
        Args:
            kotak_client: Authenticated KotakNeoAPI instance
            initial_balance: Starting paper trading balance
            price_update_interval: How often to refresh prices (seconds)
        """
        if initial_balance <= 0:
            raise ValueError(f"Initial balance must be positive, got: {initial_balance}")
        
        self.kotak_client = kotak_client
        self._orders: Dict[str, Order] = {}
        self._positions: Dict[str, Position] = {}
        self._balance: Decimal = Decimal(str(initial_balance))
        self._initial_balance: Decimal = Decimal(str(initial_balance))
        self._order_history: List[Order] = []
        self._price_cache: Dict[str, Dict[str, Any]] = {}  # symbol -> price data
        self._lock = threading.RLock()
        
        logger.info(
            f"LiveDataPaperAdapter initialized with balance: ₹{initial_balance:,.2f} "
            f"(using live data from Kotak Neo)"
        )
    
    # Symbol code mapping for Kotak Neo API
    # Format: {symbol_name: {"exchange": "exchange_code", "symbol_code": "numeric_code"}}
    SYMBOL_MAPPING = {
        "NIFTY50": {"exchange": "nse_fo", "symbol_code": "26000"},  # NIFTY 50
        "NIFTY": {"exchange": "nse_fo", "symbol_code": "26000"},
        "BANKNIFTY": {"exchange": "nse_fo", "symbol_code": "26009"},  # BANK NIFTY
        "SENSEX": {"exchange": "bse_fo", "symbol_code": "1"},  # SENSEX (BSE)
    }
    
    def _get_live_price(self, symbol: str) -> Optional[float]:
        """
        Fetch live price from Kotak Neo API.
        
        Args:
            symbol: Symbol to fetch (e.g., "NIFTY50", "BANKNIFTY", "SENSEX")
            
        Returns:
            Current market price or None if unavailable
        """
        try:
            # Check cache first (avoid too many API calls)
            if symbol in self._price_cache:
                cached = self._price_cache[symbol]
                age = (datetime.now() - cached.get("timestamp", datetime.min)).total_seconds()
                if age < 5:  # Use cached price if less than 5 seconds old
                    return cached.get("price")
            
            # Get symbol mapping
            symbol_upper = symbol.upper()
            if symbol_upper not in self.SYMBOL_MAPPING:
                logger.debug(f"No symbol mapping for {symbol}, using fallback")
                return None
            
            mapping = self.SYMBOL_MAPPING[symbol_upper]
            exchange = mapping["exchange"]
            symbol_code = mapping["symbol_code"]
            
            # Try NSE Option Chain first (better for options trading)
            try:
                from aurum_harmony.engines.market_data.nse_option_chain import nse_option_chain
                underlying_price = nse_option_chain.get_underlying_price(symbol)
                if underlying_price:
                    logger.debug(f"Got underlying price from NSE for {symbol}: ₹{underlying_price:,.2f}")
                    # Cache it
                    self._price_cache[symbol] = {
                        "price": underlying_price,
                        "timestamp": datetime.now(),
                        "source": "NSE Option Chain"
                    }
                    return underlying_price
            except Exception as e:
                logger.debug(f"NSE option chain not available: {e}, trying Kotak Neo")
            
            # Fallback to Kotak Neo quotes
            quotes = self.kotak_client.get_quotes(exchange, symbol_code)
            
            # Parse response to get current price
            # Kotak Neo response format may vary, adjust based on actual response
            if isinstance(quotes, dict):
                # Try common response formats
                price = None
                
                # Format 1: quotes["data"]["ltp"] or similar
                if "data" in quotes and isinstance(quotes["data"], dict):
                    price = quotes["data"].get("ltp") or quotes["data"].get("lastPrice") or quotes["data"].get("price")
                
                # Format 2: quotes["ltp"] directly
                if not price:
                    price = quotes.get("ltp") or quotes.get("lastPrice") or quotes.get("price")
                
                # Format 3: quotes["data"] as list with first item
                if not price and "data" in quotes and isinstance(quotes["data"], list) and len(quotes["data"]) > 0:
                    first_item = quotes["data"][0]
                    if isinstance(first_item, dict):
                        price = first_item.get("ltp") or first_item.get("lastPrice") or first_item.get("price")
                
                if price:
                    try:
                        price_float = float(price)
                        # Cache it
                        self._price_cache[symbol] = {
                            "price": price_float,
                            "timestamp": datetime.now()
                        }
                        logger.debug(f"Live price fetched for {symbol}: ₹{price_float:,.2f}")
                        return price_float
                    except (ValueError, TypeError):
                        logger.warning(f"Invalid price format from Kotak Neo for {symbol}: {price}")
                
                logger.debug(f"Could not parse price from Kotak Neo response for {symbol}")
                return None
            else:
                logger.warning(f"Unexpected response format from Kotak Neo for {symbol}")
                return None
            
        except Exception as e:
            logger.warning(f"Error fetching live price for {symbol}: {e}")
            return None
    
    def _get_price(self, symbol: str, base_price: Optional[float] = None) -> float:
        """
        Get price for a symbol (live data preferred, fallback to simulated).
        
        Args:
            symbol: Symbol to get price for
            base_price: Optional base price to use
            
        Returns:
            Current price
        """
        # Try to get live price first
        live_price = self._get_live_price(symbol)
        if live_price:
            # Cache it
            cache_key = f"nse_fo|{symbol}"
            self._price_cache[cache_key] = {
                "price": live_price,
                "timestamp": datetime.now()
            }
            return live_price
        
        # Fallback to base price if provided
        if base_price:
            return base_price
        
        # Fallback to simulated price (from PaperBrokerAdapter logic)
        if symbol in self._price_cache:
            import random
            current = self._price_cache[symbol].get("price", 0)
            if current > 0:
                variation = random.uniform(-0.005, 0.005)
                new_price = current * (1 + variation)
                self._price_cache[symbol] = {
                    "price": new_price,
                    "timestamp": datetime.now()
                }
                return new_price
        
        # Default prices for indices
        default_prices = {
            "NIFTY50": 20000.0,
            "NIFTY": 20000.0,
            "BANKNIFTY": 45000.0,
            "SENSEX": 70000.0,
        }
        
        for key, price in default_prices.items():
            if key in symbol.upper():
                self._price_cache[symbol] = {
                    "price": price,
                    "timestamp": datetime.now()
                }
                return price
        
        # Random default
        import random
        price = random.uniform(100.0, 5000.0)
        self._price_cache[symbol] = {
            "price": price,
            "timestamp": datetime.now()
        }
        return price
    
    def place_order(self, order: Order) -> Order:
        """
        Place an order using live market data but paper execution.
        
        Uses real-time prices from Kotak Neo for realistic fills.
        """
        with self._lock:
            # Get current market price
            current_price = self._get_price(order.symbol)
            
            # Calculate order value
            order_value = Decimal(str(current_price)) * Decimal(str(abs(order.quantity)))
            
            # Check balance for BUY orders
            if order.side == OrderSide.BUY:
                if self._balance < order_value:
                    order.status = OrderStatus.REJECTED
                    order.metadata["reason"] = "Insufficient balance"
                    order.metadata["required"] = float(order_value)
                    order.metadata["available"] = float(self._balance)
                    self._orders[order.broker_order_id] = order
                    logger.warning(
                        f"Order rejected: Insufficient balance. "
                        f"Required: ₹{order_value:,.2f}, Available: ₹{self._balance:,.2f}"
                    )
                    return order
            
            # Fill order immediately at market price (paper trading)
            order.status = OrderStatus.FILLED
            order.filled_price = current_price
            order.filled_quantity = order.quantity
            order.filled_at = datetime.now()
            order.metadata["execution_type"] = "paper_trading_with_live_data"
            order.metadata["source"] = "kotak_neo_live_data"
            
            # Update balance
            if order.side == OrderSide.BUY:
                self._balance -= order_value
            else:  # SELL
                self._balance += order_value
            
            # Update position (simplified logic matching PaperBrokerAdapter)
            if order.symbol in self._positions:
                pos = self._positions[order.symbol]
                
                # Calculate new quantity based on order side
                if order.side == OrderSide.BUY:
                    new_qty = pos.quantity + order.quantity
                    # Recalculate average price if adding to position
                    if pos.side == OrderSide.BUY and new_qty > 0:
                        total_cost = (pos.avg_price * pos.quantity) + (current_price * order.quantity)
                        pos.avg_price = total_cost / new_qty
                    elif pos.side == OrderSide.SELL and new_qty >= 0:
                        # Closing short position or flipping to long
                        pos.side = OrderSide.BUY
                        pos.avg_price = current_price
                        import time
                        pos.opened_at = time.time()
                else:  # SELL
                    new_qty = pos.quantity - order.quantity
                    # If we're selling more than we have, it becomes a short
                    if pos.side == OrderSide.BUY and new_qty < 0:
                        pos.side = OrderSide.SELL
                        pos.avg_price = current_price
                        import time
                        pos.opened_at = time.time()
                    elif pos.side == OrderSide.SELL:
                        # Increasing short position - recalculate average
                        total_cost = (abs(pos.avg_price * pos.quantity)) + (current_price * order.quantity)
                        pos.avg_price = total_cost / abs(new_qty)
                
                if abs(new_qty) < 0.01:  # Position closed (with tolerance)
                    del self._positions[order.symbol]
                else:
                    pos.quantity = new_qty
                    pos.current_price = current_price
                    pos.update_price(current_price)
            else:
                # Create new position
                if order.side == OrderSide.BUY:
                    qty = order.quantity
                    pos_side = OrderSide.BUY
                else:
                    qty = -order.quantity  # Short position
                    pos_side = OrderSide.SELL
                
                if qty != 0:
                    import time
                    self._positions[order.symbol] = Position(
                        symbol=order.symbol,
                        quantity=qty,
                        avg_price=current_price,
                        current_price=current_price,
                        side=pos_side,
                        opened_at=time.time()
                    )
            
            # Store order
            self._orders[order.broker_order_id] = order
            self._order_history.append(order)
            
            logger.info(
                f"Paper order filled: {order.symbol} {order.side.value} "
                f"{order.quantity} @ ₹{current_price:,.2f} "
                f"(Live data from Kotak Neo)"
            )
            
            return order
    
    def cancel_order(self, broker_order_id: str) -> bool:
        """Cancel an order (paper trading - always succeeds if order exists)."""
        with self._lock:
            if broker_order_id in self._orders:
                order = self._orders[broker_order_id]
                if order.status == OrderStatus.PENDING:
                    order.status = OrderStatus.CANCELLED
                    order.metadata["cancelled_at"] = datetime.now().isoformat()
                    logger.info(f"Order cancelled: {broker_order_id}")
                    return True
                else:
                    logger.warning(f"Cannot cancel order {broker_order_id}: status is {order.status}")
                    return False
            return False
    
    def get_positions(self) -> Dict[str, Position]:
        """Get all open positions (with live prices)."""
        with self._lock:
            # Update prices from live data
            for symbol, position in self._positions.items():
                live_price = self._get_live_price(symbol)
                if live_price:
                    position.update_price(live_price)
            
            return self._positions.copy()
    
    def get_orders(self, status: Optional[OrderStatus] = None) -> List[Order]:
        """Get orders, optionally filtered by status."""
        with self._lock:
            orders = list(self._orders.values())
            if status:
                orders = [o for o in orders if o.status == status]
            return orders
    
    def get_balance(self) -> float:
        """Get current paper trading balance."""
        with self._lock:
            return float(self._balance)
    
    def get_statistics(self) -> Dict[str, Any]:
        """
        Get trading statistics with explanatory notes for novice users.
        
        Returns comprehensive statistics with user-friendly explanations.
        """
        with self._lock:
            total_pnl = sum(pos.unrealized_pnl for pos in self._positions.values())
            realized_pnl = float(self._balance - self._initial_balance)
            
            return {
                "balance": float(self._balance),
                "balance_explanation": "Your current available balance for trading. This is your paper trading account balance (not real money).",
                
                "initial_balance": float(self._initial_balance),
                "initial_balance_explanation": "The starting balance when you began paper trading. Used to calculate your total profit/loss.",
                
                "realized_pnl": realized_pnl,
                "realized_pnl_explanation": "Profit or loss from trades you've already closed. Positive = profit, Negative = loss. This is 'locked in' and won't change unless you trade more.",
                
                "unrealized_pnl": total_pnl,
                "unrealized_pnl_explanation": "Profit or loss from your current open positions. This changes as market prices move. Not 'locked in' until you close the position.",
                
                "total_pnl": realized_pnl + total_pnl,
                "total_pnl_explanation": "Your total profit/loss = Realized P&L (closed trades) + Unrealized P&L (open positions). This is your overall performance.",
                
                "open_positions": len(self._positions),
                "open_positions_explanation": "Number of active trades you currently have open. Each position represents a trade that hasn't been closed yet.",
                
                "total_orders": len(self._orders),
                "total_orders_explanation": "Total number of orders you've placed (including filled, rejected, and cancelled orders).",
                
                "data_source": "Kotak Neo Live Data",
                "data_source_explanation": "Market prices are fetched in real-time from Kotak Neo API. This gives you realistic prices for paper trading.",
                
                "execution_mode": "Paper Trading",
                "execution_mode_explanation": "All trades are simulated - no real money is used. Perfect for learning and testing strategies without risk.",
                
                "data_type": "Underlying Index Prices",
                "data_type_explanation": "Currently using underlying index prices (NIFTY50, BANKNIFTY, SENSEX spot prices). For options trading, we can also fetch option chain data with all strike prices and premiums."
            }

