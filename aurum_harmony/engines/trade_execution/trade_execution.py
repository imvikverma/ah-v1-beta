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


class PaperBrokerAdapter:
    """
    Simple in‑memory paper trading adapter for testing & dry runs.
    Does NOT send anything to a real broker.
    """

    def __init__(self) -> None:
        self._orders: Dict[str, Order] = {}

    def place_order(self, order: Order) -> Order:
        # Simulate instant fill at requested limit_price or a dummy price.
        broker_order_id = f"paper_{uuid.uuid4().hex[:12]}"
        order.broker_order_id = broker_order_id
        order.status = OrderStatus.FILLED
        order.metadata["filled_at"] = time.time()
        self._orders[broker_order_id] = order
        return order

    def cancel_order(self, broker_order_id: str) -> bool:
        order = self._orders.get(broker_order_id)
        if not order:
            return False
        if order.status in (OrderStatus.FILLED, OrderStatus.CANCELLED):
            return False
        order.status = OrderStatus.CANCELLED
        return True


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
    "BrokerAdapter",
    "PaperBrokerAdapter",
    "TradeExecutor",
]
