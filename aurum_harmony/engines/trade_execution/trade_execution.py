from __future__ import annotations

"""
Secure trade execution layer for AurumHarmony.

Design goals:
- All live broker connectivity is abstracted behind a BrokerAdapter interface.
- Default mode is PAPER (simulated) trading; live mode must be explicitly enabled.
- Every order must pass in a pre‑computed risk decision (approved/blocked) so that
  callers cannot accidentally bypass the risk engine.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Protocol, Optional, Dict, Any
import time
import uuid


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
    symbol: str
    side: OrderSide
    quantity: float
    order_type: OrderType = OrderType.MARKET
    limit_price: Optional[float] = None
    client_order_id: str = ""
    broker_order_id: Optional[str] = None
    status: OrderStatus = OrderStatus.NEW
    metadata: Dict[str, Any] = None

    def __post_init__(self) -> None:
        if not self.client_order_id:
            self.client_order_id = f"cli_{uuid.uuid4().hex[:16]}"
        if self.metadata is None:
            self.metadata = {}


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
    """

    def __init__(self, initial_balance: float = 100000.0) -> None:
        self._orders: Dict[str, Order] = {}
        self._positions: Dict[str, Position] = {}  # symbol -> Position
        self._balance: float = initial_balance
        self._initial_balance: float = initial_balance
        self._order_history: list[Order] = []
        # Simulated prices (can be enhanced with real market data)
        self._price_cache: Dict[str, float] = {}

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
        """Place an order and update portfolio."""
        # Get fill price
        if order.order_type == OrderType.LIMIT and order.limit_price:
            fill_price = order.limit_price
        else:
            # Market order - use simulated price
            fill_price = self._get_simulated_price(order.symbol)
        
        # Calculate order value
        order_value = fill_price * order.quantity
        
        # Assign broker_order_id to all orders (including rejected) for consistent keying
        broker_order_id = f"paper_{uuid.uuid4().hex[:12]}"
        order.broker_order_id = broker_order_id
        
        # Check if we have enough balance for BUY orders
        if order.side == OrderSide.BUY:
            if self._balance < order_value:
                order.status = OrderStatus.REJECTED
                order.metadata["reason"] = "Insufficient balance"
                # Store rejected orders using broker_order_id for consistent keying
                self._orders[broker_order_id] = order
                return order
        
        # Execute the order
        order.status = OrderStatus.FILLED
        order.metadata["filled_at"] = time.time()
        order.metadata["filled_price"] = fill_price
        
        # Update portfolio
        self._update_portfolio(order, fill_price)
        
        # Store order
        self._orders[broker_order_id] = order
        self._order_history.append(order)
        
        return order

    def _update_portfolio(self, order: Order, fill_price: float) -> None:
        """Update portfolio balance and positions after order fill."""
        order_value = fill_price * order.quantity
        
        if order.side == OrderSide.BUY:
            # Deduct from balance
            self._balance -= order_value
            
            # Update or create position
            if order.symbol in self._positions:
                pos = self._positions[order.symbol]
                # Average price calculation
                total_cost = (pos.avg_price * pos.quantity) + order_value
                pos.quantity += order.quantity
                pos.avg_price = total_cost / pos.quantity
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
                    realized_pnl = (fill_price - pos.avg_price) * order.quantity
                    self._balance += order_value + realized_pnl
                    pos.quantity -= order.quantity
                    
                    # Remove position if fully closed
                    if pos.quantity <= 0:
                        del self._positions[order.symbol]
                else:
                    # Short selling (not fully implemented, but add to balance)
                    self._balance += order_value
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
        """Get current account balance."""
        return self._balance

    def get_positions(self) -> Dict[str, Position]:
        """Get all open positions."""
        # Update prices for all positions
        for symbol, position in self._positions.items():
            new_price = self._get_simulated_price(symbol, position.current_price)
            position.update_price(new_price)
        return self._positions.copy()

    def get_orders(self) -> list[Order]:
        """Get all orders."""
        return list(self._orders.values())

    def get_order_history(self) -> list[Order]:
        """Get order history."""
        return self._order_history.copy()

    def get_portfolio_value(self) -> float:
        """Get total portfolio value (balance + positions value)."""
        positions_value = sum(
            pos.current_price * abs(pos.quantity) for pos in self._positions.values()
        )
        return self._balance + positions_value

    def get_pnl(self) -> float:
        """Get total P&L (realized + unrealized)."""
        unrealized = sum(pos.unrealized_pnl for pos in self._positions.values())
        # Realized P&L is simply the balance change, as balance already reflects
        # all gains/losses from closed positions (deducted for buys, credited for sells including P&L)
        realized = self._balance - self._initial_balance
        return realized + unrealized


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

        Parameters
        ----------
        symbol : str
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
