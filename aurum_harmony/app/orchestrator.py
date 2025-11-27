"""
Handsfree trading orchestrator for AurumHarmony.

This module is intentionally conservative:
- It always goes through risk checks before sending orders.
- It respects the central AppConfig (paper vs live, limits).
- It is strategy-agnostic: you can plug in any signal generator.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol, List

from .config import AppConfig, load_config
from aurum_harmony.engines.trade_execution.trade_execution import (
    TradeExecutor,
    OrderSide,
    OrderType,
)


@dataclass
class TradeSignal:
    symbol: str
    side: OrderSide
    quantity: float
    reason: str = ""


class SignalSource(Protocol):
    """
    Any strategy/engine that can emit trade signals should implement this interface.
    """

    def get_signals(self) -> List[TradeSignal]:
        ...


class SimpleRiskEngine:
    """
    Very basic risk engine that can be replaced later.
    Uses AppConfig limits to decide if a trade is allowed.
    """

    def __init__(self, config: AppConfig) -> None:
        self.config = config
        # In a real implementation, track PnL and open exposure.
        self.current_open_trades = 0

    def is_order_allowed(self, signal: TradeSignal) -> bool:
        if self.current_open_trades >= self.config.global_risk.max_open_trades:
            return False
        # Simple placeholder: allow everything else for now.
        return True

    def on_order_placed(self) -> None:
        self.current_open_trades += 1


class TradingOrchestrator:
    """
    High-level coordinator:
    - Pulls signals from a SignalSource
    - Runs them through the risk engine
    - Sends approved orders to the TradeExecutor
    """

    def __init__(self, signal_source: SignalSource, config: AppConfig | None = None) -> None:
        self.config = config or load_config()
        self.signal_source = signal_source
        self.risk_engine = SimpleRiskEngine(self.config)
        self.executor = TradeExecutor(live_trading_enabled=self.config.is_live)

    def run_once(self):
        """
        Run a single evaluation cycle:
        - fetch signals
        - apply risk
        - place orders (paper or live, depending on config)
        """
        signals = self.signal_source.get_signals()
        results = []
        for sig in signals:
            allowed = self.risk_engine.is_order_allowed(sig)
            order = self.executor.execute_order(
                symbol=sig.symbol,
                side=sig.side,
                quantity=sig.quantity,
                order_type=OrderType.MARKET,
                risk_approved=allowed,
                reason=sig.reason,
            )
            if allowed and order:
                self.risk_engine.on_order_placed()
            results.append(order)
        return results


__all__ = [
    "TradeSignal",
    "SignalSource",
    "SimpleRiskEngine",
    "TradingOrchestrator",
]


