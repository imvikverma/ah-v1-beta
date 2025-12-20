from __future__ import annotations

"""
Secure trade execution layer for AurumHarmony.

Design goals:
- All live broker connectivity is abstracted behind a BrokerAdapter interface.
- Default mode is PAPER (simulated) trading; live mode must be explicitly enabled.
- Every order must pass in a pre‑computed risk decision (approved/blocked) so that
  callers cannot accidentally bypass the risk engine.
- Robust error handling, logging, and validation throughout.
- Thread-safe operations for concurrent trading scenarios.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Protocol, Optional, Dict, Any, List
import time
import uuid
import logging
import threading
from decimal import Decimal, ROUND_DOWN
import json

# Configure logging
logger = logging.getLogger(__name__)


class OrderSide(str, Enum):
    BUY = "BUY"
    SELL = "SELL"


class OrderType(str, Enum):
    MARKET = "MARKET"
    LIMIT = "LIMIT"


class OrderStatus(str, Enum):
    NEW = "NEW"
    REJECTED = "REJECTED"
    FILLED = "FILLED"
    PARTIALLY_FILLED = "PARTIALLY_FILLED"
    CANCELLED = "CANCELLED"


@dataclass
class Order:
    """Represents a trading order with full lifecycle tracking."""
    symbol: str
    side: OrderSide
    quantity: float
    order_type: OrderType = OrderType.MARKET
    limit_price: Optional[float] = None
    client_order_id: str = ""
    broker_order_id: Optional[str] = None
    status: OrderStatus = OrderStatus.NEW
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)

    def __post_init__(self) -> None:
        """Validate and initialize order fields."""
        # Validate symbol
        if not self.symbol or not isinstance(self.symbol, str):
            raise ValueError(f"Invalid symbol: {self.symbol}")
        self.symbol = self.symbol.strip().upper()
        
        # Validate quantity
        if self.quantity <= 0:
            raise ValueError(f"Quantity must be positive, got: {self.quantity}")
        
        # Validate limit price for limit orders
        if self.order_type == OrderType.LIMIT:
            if self.limit_price is None or self.limit_price <= 0:
                raise ValueError(f"Limit price must be positive for LIMIT orders, got: {self.limit_price}")
        
        # Generate IDs if not provided
        if not self.client_order_id:
            self.client_order_id = f"cli_{uuid.uuid4().hex[:16]}"
        
        # Ensure metadata is a dict
        if not isinstance(self.metadata, dict):
            self.metadata = {}
    
    def update_status(self, new_status: OrderStatus, reason: Optional[str] = None) -> None:
        """Update order status with timestamp and optional reason."""
        self.status = new_status
        self.updated_at = time.time()
        if reason:
            self.metadata["status_reason"] = reason
        logger.debug(f"Order {self.client_order_id} status updated to {new_status}")
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert order to dictionary for serialization."""
        return {
            "symbol": self.symbol,
            "side": self.side.value,
            "quantity": float(self.quantity),
            "order_type": self.order_type.value,
            "limit_price": self.limit_price,
            "client_order_id": self.client_order_id,
            "broker_order_id": self.broker_order_id,
            "status": self.status.value,
            "metadata": self.metadata,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
        }


class BrokerAdapter(Protocol):
    """
    Interface to be implemented by any broker integration (HDFC Sky, Kotak Neo, etc.).
    """

    def place_order(self, order: Order) -> Order:
        ...

    def cancel_order(self, broker_order_id: str) -> bool:
        ...


@dataclass
class Position:
    """Represents an open position in paper trading."""
    symbol: str
    quantity: float
    avg_price: float
    current_price: float
    side: OrderSide
    opened_at: float
    unrealized_pnl: float = 0.0
    
    def update_price(self, new_price: float) -> None:
        """Update current price and recalculate P&L."""
        self.current_price = new_price
        if self.side == OrderSide.BUY:
            self.unrealized_pnl = (new_price - self.avg_price) * self.quantity
        else:  # SELL (short)
            self.unrealized_pnl = (self.avg_price - new_price) * self.quantity


class PaperBrokerAdapter:
    """
    Enhanced paper trading adapter with portfolio tracking.
    Tracks balance, positions, orders, and simulates realistic price movements.
    Does NOT send anything to a real broker.
    
    Thread-safe for concurrent order execution.
    """

    def __init__(self, initial_balance: float = 100000.0) -> None:
        if initial_balance <= 0:
            raise ValueError(f"Initial balance must be positive, got: {initial_balance}")
        
        self._orders: Dict[str, Order] = {}
        self._positions: Dict[str, Position] = {}  # symbol -> Position
        self._balance: Decimal = Decimal(str(initial_balance))
        self._initial_balance: Decimal = Decimal(str(initial_balance))
        self._order_history: List[Order] = []
        self._price_cache: Dict[str, float] = {}
        self._lock = threading.RLock()  # Reentrant lock for thread safety
        
        logger.info(f"PaperBrokerAdapter initialized with balance: ₹{initial_balance:,.2f}")

    def _get_simulated_price(self, symbol: str, base_price: Optional[float] = None) -> float:
        """Get or generate a simulated price for a symbol."""
        if symbol in self._price_cache:
            # Add small random variation (±0.5%)
            import random
            current = self._price_cache[symbol]
            variation = random.uniform(-0.005, 0.005)
            new_price = current * (1 + variation)
            self._price_cache[symbol] = new_price
            return new_price
        
        # Generate initial price based on symbol or use provided base
        if base_price:
            self._price_cache[symbol] = base_price
            return base_price
        
        # Default prices for common symbols
        default_prices = {
            "NIFTY": 20000.0,
            "BANKNIFTY": 45000.0,
            "RELIANCE": 2500.0,
            "TCS": 3500.0,
            "INFY": 1500.0,
        }
        
        # Try to match symbol prefix
        for key, price in default_prices.items():
            if key in symbol.upper():
                self._price_cache[symbol] = price
                return price
        
        # Random default price
        import random
        price = random.uniform(100.0, 5000.0)
        self._price_cache[symbol] = price
        return price

    def place_order(self, order: Order) -> Order:
        """
        Place an order and update portfolio.
        Thread-safe operation with comprehensive error handling.
        """
        with self._lock:
            try:
                # Validate order
                if order.quantity <= 0:
                    order.update_status(OrderStatus.REJECTED, "Invalid quantity")
                    logger.warning(f"Order rejected: invalid quantity {order.quantity}")
                    return order
                
                # Get fill price
                if order.order_type == OrderType.LIMIT and order.limit_price:
                    fill_price = Decimal(str(order.limit_price))
                else:
                    # Market order - use simulated price
                    fill_price = Decimal(str(self._get_simulated_price(order.symbol)))
                
                # Calculate order value with precision
                order_value = fill_price * Decimal(str(order.quantity))
                
                # Assign broker_order_id to all orders (including rejected) for consistent keying
                broker_order_id = f"paper_{uuid.uuid4().hex[:12]}"
                order.broker_order_id = broker_order_id
                
                # Check if we have enough balance for BUY orders
                if order.side == OrderSide.BUY:
                    if self._balance < order_value:
                        order.update_status(OrderStatus.REJECTED, "Insufficient balance")
                        order.metadata["required"] = float(order_value)
                        order.metadata["available"] = float(self._balance)
                        logger.warning(
                            f"Order {broker_order_id} rejected: insufficient balance. "
                            f"Required: ₹{order_value:,.2f}, Available: ₹{self._balance:,.2f}"
                        )
                        self._orders[broker_order_id] = order
                        return order
                
                # Execute the order
                order.update_status(OrderStatus.FILLED, "Order filled successfully")
                order.metadata["filled_at"] = time.time()
                order.metadata["filled_price"] = float(fill_price)
                
                # Update portfolio
                self._update_portfolio(order, float(fill_price))
                
                # Store order
                self._orders[broker_order_id] = order
                self._order_history.append(order)
                
                logger.info(
                    f"Order {broker_order_id} filled: {order.side.value} {order.quantity} {order.symbol} "
                    f"@ ₹{fill_price:,.2f} (Value: ₹{order_value:,.2f})"
                )
                
                return order
                
            except Exception as e:
                logger.error(f"Error placing order {order.client_order_id}: {e}", exc_info=True)
                order.update_status(OrderStatus.REJECTED, f"Execution error: {str(e)}")
                if order.broker_order_id:
                    self._orders[order.broker_order_id] = order
                return order

    def _update_portfolio(self, order: Order, fill_price: float) -> None:
        """
        Update portfolio balance and positions after order fill.
        Uses Decimal for precise financial calculations.
        """
        try:
            fill_price_decimal = Decimal(str(fill_price))
            quantity_decimal = Decimal(str(order.quantity))
            order_value = fill_price_decimal * quantity_decimal
            
            if order.side == OrderSide.BUY:
                # Deduct from balance
                self._balance -= order_value
                
                # Update or create position
                if order.symbol in self._positions:
                    pos = self._positions[order.symbol]
                    # Average price calculation with precision
                    total_cost = (Decimal(str(pos.avg_price)) * Decimal(str(pos.quantity))) + order_value
                    pos.quantity = float(Decimal(str(pos.quantity)) + quantity_decimal)
                    pos.avg_price = float(total_cost / Decimal(str(pos.quantity)))
                    pos.current_price = fill_price
                    pos.update_price(fill_price)
                else:
                    self._positions[order.symbol] = Position(
                        symbol=order.symbol,
                        quantity=order.quantity,
                        avg_price=fill_price,
                        current_price=fill_price,
                        side=OrderSide.BUY,
                        opened_at=time.time()
                    )
            else:  # SELL
                # Check if we have the position
                if order.symbol in self._positions:
                    pos = self._positions[order.symbol]
                    if pos.quantity >= order.quantity:
                        # Close or reduce position
                        realized_pnl = (fill_price_decimal - Decimal(str(pos.avg_price))) * quantity_decimal
                        self._balance += order_value + realized_pnl
                        pos.quantity = float(Decimal(str(pos.quantity)) - quantity_decimal)
                        
                        # Remove position if fully closed (with small tolerance for floating point)
                        if abs(pos.quantity) < 0.01:
                            del self._positions[order.symbol]
                        else:
                            pos.current_price = fill_price
                            pos.update_price(fill_price)
                    else:
                        # Partial sell exceeding position - treat as short
                        realized_pnl = (fill_price_decimal - Decimal(str(pos.avg_price))) * Decimal(str(pos.quantity))
                        self._balance += (fill_price_decimal * Decimal(str(pos.quantity))) + realized_pnl
                        short_quantity = quantity_decimal - Decimal(str(pos.quantity))
                        self._balance += fill_price_decimal * short_quantity
                        
                        # Create short position
                        self._positions[order.symbol] = Position(
                            symbol=order.symbol,
                            quantity=-float(short_quantity),
                            avg_price=fill_price,
                            current_price=fill_price,
                            side=OrderSide.SELL,
                            opened_at=time.time()
                        )
                else:
                    # Short selling - add to balance
                    self._balance += order_value
                    # Create short position (negative quantity)
                    self._positions[order.symbol] = Position(
                        symbol=order.symbol,
                        quantity=-order.quantity,
                        avg_price=fill_price,
                        current_price=fill_price,
                        side=OrderSide.SELL,
                        opened_at=time.time()
                    )
        except Exception as e:
            logger.error(f"Error updating portfolio for order {order.client_order_id}: {e}", exc_info=True)
            raise

    def cancel_order(self, broker_order_id: str) -> bool:
        """Cancel an order (only if not filled)."""
        order = self._orders.get(broker_order_id)
        if not order:
            return False
        if order.status in (OrderStatus.FILLED, OrderStatus.CANCELLED):
            return False
        order.status = OrderStatus.CANCELLED
        return True

    def get_balance(self) -> float:
        """Get current account balance (thread-safe)."""
        with self._lock:
            return float(self._balance)

    def get_positions(self) -> Dict[str, Position]:
        """Get all open positions with updated prices (thread-safe)."""
        with self._lock:
            # Update prices for all positions
            for symbol, position in self._positions.items():
                new_price = self._get_simulated_price(symbol, position.current_price)
                position.update_price(new_price)
            return self._positions.copy()

    def get_orders(self) -> List[Order]:
        """Get all orders (thread-safe)."""
        with self._lock:
            return list(self._orders.values())

    def get_order_history(self) -> List[Order]:
        """Get order history (thread-safe)."""
        with self._lock:
            return self._order_history.copy()

    def get_portfolio_value(self) -> float:
        """Get total portfolio value (balance + positions value) (thread-safe)."""
        with self._lock:
            positions_value = sum(
                pos.current_price * abs(pos.quantity) for pos in self._positions.values()
            )
            return float(self._balance) + positions_value

    def get_pnl(self) -> float:
        """
        Get total P&L (realized + unrealized) (thread-safe).
        Realized P&L is the balance change, as balance already reflects
        all gains/losses from closed positions.
        """
        with self._lock:
            unrealized = sum(pos.unrealized_pnl for pos in self._positions.values())
            realized = float(self._balance - self._initial_balance)
            return realized + unrealized
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get comprehensive portfolio statistics (thread-safe)."""
        with self._lock:
            positions = self.get_positions()
            orders = self.get_orders()
            filled_orders = [o for o in orders if o.status == OrderStatus.FILLED]
            
            return {
                "balance": float(self._balance),
                "initial_balance": float(self._initial_balance),
                "total_pnl": self.get_pnl(),
                "portfolio_value": self.get_portfolio_value(),
                "open_positions": len(positions),
                "total_orders": len(orders),
                "filled_orders": len(filled_orders),
                "rejected_orders": len([o for o in orders if o.status == OrderStatus.REJECTED]),
            }


class TradeExecutor:
    """
    Thin execution layer that enforces:
    - explicit choice of paper vs live mode
    - non‑bypassable requirement for a risk_approved flag
    """

    def __init__(
        self,
        broker_adapter: Optional[BrokerAdapter] = None,
        live_trading_enabled: bool = False,
    ) -> None:
        # Default to paper adapter to avoid accidental live trading.
        self.broker_adapter: BrokerAdapter = broker_adapter or PaperBrokerAdapter()
        self.live_trading_enabled = live_trading_enabled

    def execute_order(
        self,
        symbol: str,
        side: OrderSide,
        quantity: float,
        *,
        order_type: OrderType = OrderType.MARKET,
        limit_price: Optional[float] = None,
        risk_approved: bool,
        reason: str = "",
    ) -> Order:
        """
        Execute a single order.

        CRITICAL: System only supports intraday options on:
        - NIFTY50 (NSE)
        - BANKNIFTY (NSE)
        - SENSEX (BSE)
        
        All individual stock orders will be rejected by compliance engine.

        Parameters
        ----------
        symbol : str
            Must be one of: NIFTY50, BANKNIFTY, SENSEX (intraday options only)
        side : OrderSide
        quantity : float
        order_type : OrderType
        limit_price : Optional[float]
        risk_approved : bool
            MUST be the output of the risk engine. If False, the order is rejected locally.
        reason : str
            Human‑readable reason / strategy tag for logging.
        """
        if quantity <= 0:
            raise ValueError("Quantity must be positive.")

        if not risk_approved:
            # Never send to broker if risk engine has not approved.
            return Order(
                symbol=symbol,
                side=side,
                quantity=quantity,
                order_type=order_type,
                limit_price=limit_price,
                status=OrderStatus.REJECTED,
                metadata={"reason": "Risk engine rejected order", "strategy_reason": reason},
            )

        order = Order(
            symbol=symbol,
            side=side,
            quantity=quantity,
            order_type=order_type,
            limit_price=limit_price,
            metadata={"strategy_reason": reason, "live_trading_enabled": self.live_trading_enabled},
        )

        # Apply dynamic order splitting if needed (>250 lots)
        try:
            from aurum_harmony.engines.compliance.order_splitting import OrderSplittingEngine
            split_result = OrderSplittingEngine.split_order_if_needed(order)
            
            if split_result.split_count > 1:
                # Order was split - execute all split orders
                logger.info(
                    f"Order split into {split_result.split_count} orders: "
                    f"{order.symbol} {order.side.value} {order.quantity} lots"
                )
                
                if not self.live_trading_enabled:
                    # Paper mode: execute all split orders
                    results = []
                    for split_order in split_result.split_orders:
                        result = self.broker_adapter.place_order(split_order)
                        results.append(result)
                    # Return first result (or could return all)
                    return results[0] if results else order
                else:
                    # Live mode: execute split orders sequentially
                    # TODO: Implement sequential execution for live trading
                    logger.warning("Live trading split order execution not yet implemented")
                    return order
            else:
                # No splitting needed, proceed normally
                order = split_result.split_orders[0]
        except ImportError:
            logger.debug("Order splitting engine not available, proceeding without splitting")
        except Exception as e:
            logger.warning(f"Error in order splitting: {e}, proceeding with original order")

        placed_order = self.broker_adapter.place_order(order)
        return placed_order

    def cancel_order(self, broker_order_id: str) -> bool:
        return self.broker_adapter.cancel_order(broker_order_id)


__all__ = [
    "Order",
    "OrderSide",
    "OrderType",
    "OrderStatus",
    "Position",
    "BrokerAdapter",
    "PaperBrokerAdapter",
    "TradeExecutor",
]
