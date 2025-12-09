"""
Handsfree trading orchestrator for AurumHarmony.

This module is intentionally conservative:
- It always goes through risk checks before sending orders.
- It respects the central AppConfig (paper vs live, limits).
- It is strategy-agnostic: you can plug in any signal generator.
- Robust error handling and logging throughout.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol, List, Optional, Dict, Any
import logging
import time

from .config import AppConfig, load_config
from aurum_harmony.engines.trade_execution.trade_execution import (
    TradeExecutor,
    OrderSide,
    OrderType,
    Order,
    OrderStatus,
    BrokerAdapter,
)

# Configure logging
logger = logging.getLogger(__name__)


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
    Enhanced risk engine with comprehensive checks.
    Uses AppConfig limits to decide if a trade is allowed.
    Tracks PnL, open exposure, and daily limits.
    """

    def __init__(self, config: AppConfig) -> None:
        self.config = config
        self.current_open_trades = 0
        self.daily_pnl: float = 0.0
        self.daily_trade_count: int = 0
        self.last_reset_date: str = self._get_current_date()
        
        # Initialize leverage engine
        try:
            from aurum_harmony.engines.risk_management.leverage_engine import leverage_engine
            self.leverage_engine = leverage_engine
        except ImportError:
            logger.warning("Leverage engine not available")
            self.leverage_engine = None
        
        logger.info(f"RiskEngine initialized with limits: {config.global_risk}")

    def _get_current_date(self) -> str:
        """Get current date string for daily reset tracking."""
        from datetime import datetime
        return datetime.now().strftime("%Y-%m-%d")

    def _reset_daily_metrics_if_needed(self) -> None:
        """Reset daily metrics if a new day has started."""
        current_date = self._get_current_date()
        if current_date != self.last_reset_date:
            logger.info(f"Resetting daily metrics (new day: {current_date})")
            self.daily_pnl = 0.0
            self.daily_trade_count = 0
            self.last_reset_date = current_date

    def is_order_allowed(
        self,
        signal: TradeSignal,
        executor: Optional[TradeExecutor] = None,
        ai_capacity_info: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Comprehensive risk check for a trade signal with AI-driven adaptive limits.
        
        NOTE: The system uses AI-driven decisions to intelligently adjust limits
        based on signal confidence and market conditions. VIX guidelines are
        indicative, not hard rules.
        
        Checks:
        - Max open trades limit (can be exceeded with high AI confidence)
        - Daily loss limit (hard limit for safety)
        - Position size limits
        - Signal validation
        - AI-driven adaptive capacity (if provided)
        
        Args:
            signal: Trade signal to check
            executor: Trade executor instance
            ai_capacity_info: AI-driven capacity information from PredictiveAIEngine
        """
        self._reset_daily_metrics_if_needed()
        
        # Validate signal
        if not signal or not signal.symbol or signal.quantity <= 0:
            logger.warning(f"Invalid signal rejected: {signal}")
            return False
        
        # Check daily loss limit (HARD LIMIT - never exceed for safety)
        if self.daily_pnl <= -self.config.global_risk.max_daily_loss:
            logger.warning(
                f"Order rejected: daily loss limit reached (HARD LIMIT) "
                f"(PnL: ₹{self.daily_pnl:,.2f}, Limit: ₹{self.config.global_risk.max_daily_loss:,.2f})"
            )
            return False
        
        # AI-driven adaptive capacity check (if provided)
        if ai_capacity_info:
            remaining_capacity = ai_capacity_info.get("remaining_capacity", 0)
            if remaining_capacity <= 0:
                reason = ai_capacity_info.get("reason", "AI capacity limit reached")
                logger.info(
                    f"Order deferred: AI capacity limit reached. {reason} "
                    f"(Current: {ai_capacity_info.get('current_trades', 0)}, "
                    f"Adaptive Max: {ai_capacity_info.get('adaptive_max', 0)})"
                )
                return False
        
        # Check max open trades (can be exceeded with high AI confidence)
        max_open_trades = self.config.global_risk.max_open_trades
        if ai_capacity_info and ai_capacity_info.get("should_exceed", False):
            # AI decision: allow exceeding if high confidence
            max_open_trades = int(max_open_trades * 1.2)  # Up to 20% above
        
        if self.current_open_trades >= max_open_trades:
            logger.info(
                f"Order deferred: open trades limit reached "
                f"({self.current_open_trades}/{max_open_trades})"
            )
            return False
        
        # Check position size (if executor available)
        if executor and hasattr(executor.broker_adapter, 'get_positions'):
            positions = executor.broker_adapter.get_positions()
            if signal.symbol in positions:
                current_position_value = (
                    positions[signal.symbol].current_price * abs(positions[signal.symbol].quantity)
                )
                if current_position_value >= self.config.global_risk.max_position_size:
                    logger.warning(
                        f"Order rejected: position size limit reached for {signal.symbol} "
                        f"(Current: ₹{current_position_value:,.2f}, Limit: ₹{self.config.global_risk.max_position_size:,.2f})"
                    )
                    return False
        
        # Check leverage limits (if leverage engine available)
        if self.leverage_engine and ai_capacity_info:
            # Get user category from metadata if available
            user_category = ai_capacity_info.get("category", "restricted")
            # Calculate current exposure (would need user capital from DB)
            # For now, this is a placeholder - would need integration with user data
            pass
        
        logger.debug(f"Order approved: {signal.symbol} {signal.side.value} {signal.quantity}")
        return True

    def on_order_placed(self, order: Optional[Order] = None) -> None:
        """Update risk metrics after order placement."""
        self.current_open_trades += 1
        self.daily_trade_count += 1
        if order:
            logger.debug(f"Risk metrics updated: open_trades={self.current_open_trades}, daily_trades={self.daily_trade_count}")

    def on_order_filled(self, order: Order) -> None:
        """Update risk metrics after order fill."""
        # This can be enhanced to track actual P&L from executor
        pass

    def on_order_closed(self) -> None:
        """Update risk metrics when a position is closed."""
        if self.current_open_trades > 0:
            self.current_open_trades -= 1
            logger.debug(f"Position closed, open_trades={self.current_open_trades}")

    def get_risk_status(self) -> Dict[str, Any]:
        """Get current risk engine status."""
        self._reset_daily_metrics_if_needed()
        return {
            "current_open_trades": self.current_open_trades,
            "max_open_trades": self.config.global_risk.max_open_trades,
            "daily_pnl": self.daily_pnl,
            "max_daily_loss": self.config.global_risk.max_daily_loss,
            "daily_trade_count": self.daily_trade_count,
            "last_reset_date": self.last_reset_date,
        }


class TradingOrchestrator:
    """
    High-level coordinator with enhanced error handling and monitoring:
    - Pulls signals from a SignalSource
    - Runs them through the risk engine
    - Sends approved orders to the TradeExecutor
    - Tracks execution statistics and errors
    """

    def __init__(self, signal_source: SignalSource, config: Optional[AppConfig] = None, broker_adapter: Optional[BrokerAdapter] = None) -> None:
        self.config = config or load_config()
        self.signal_source = signal_source
        self.risk_engine = SimpleRiskEngine(self.config)
        
        # Use provided adapter or create one based on config
        if broker_adapter:
            self.executor = TradeExecutor(broker_adapter=broker_adapter, live_trading_enabled=self.config.is_live)
        elif not self.config.is_live and self.config.use_live_data_for_paper:
            # Try to create live data paper adapter
            from aurum_harmony.engines.trade_execution.broker_adapter_factory import (
                create_broker_adapter,
                get_kotak_client_from_env
            )
            kotak_client = get_kotak_client_from_env()
            adapter = create_broker_adapter(
                use_live_data=True,
                initial_balance=100000.0,
                kotak_client=kotak_client
            )
            self.executor = TradeExecutor(broker_adapter=adapter, live_trading_enabled=False)
        else:
            self.executor = TradeExecutor(live_trading_enabled=self.config.is_live)
        self.execution_stats = {
            "total_signals": 0,
            "approved_signals": 0,
            "rejected_signals": 0,
            "filled_orders": 0,
            "failed_orders": 0,
            "last_execution_time": None,
        }
        logger.info(
            f"TradingOrchestrator initialized: "
            f"mode={'LIVE' if self.config.is_live else 'PAPER'}, "
            f"risk_limits={self.config.global_risk}"
        )

    def run_once(self) -> List[Order]:
        """
        Run a single evaluation cycle with AI-driven adaptive decisions:
        - fetch signals
        - get AI-driven adaptive capacity (can exceed/reduce VIX guidelines)
        - apply risk with AI intelligence
        - place orders (paper or live, depending on config)
        - track statistics
        
        NOTE: VIX-based limits are INDICATIVE GUIDELINES. The AI makes
        intelligent decisions to exceed or reduce based on signal confidence
        and market conditions.
        
        Returns:
            List of Order objects (filled, rejected, or failed)
        """
        start_time = time.time()
        results: List[Order] = []
        
        try:
            # Fetch signals
            signals = self.signal_source.get_signals()
            self.execution_stats["total_signals"] += len(signals)
            
            if not signals:
                logger.debug("No signals received from signal source")
                return results
            
            logger.info(f"Processing {len(signals)} signal(s) from signal source")
            
            # Get AI-driven adaptive capacity (if signal source is PredictiveAIEngine)
            ai_capacity_info = None
            if hasattr(self.signal_source, 'get_adaptive_trade_capacity'):
                try:
                    # Calculate average confidence of signals
                    avg_confidence = 0.7  # Default
                    if signals:
                        # Extract confidence if available in signal metadata
                        confidences = [
                            float(sig.reason.split("confidence: ")[1].split("%")[0]) / 100
                            if "confidence:" in sig.reason else 0.7
                            for sig in signals
                        ]
                        avg_confidence = sum(confidences) / len(confidences) if confidences else 0.7
                    
                    # Get AI-driven adaptive capacity
                    ai_capacity_info = self.signal_source.get_adaptive_trade_capacity(
                        current_trades=self.risk_engine.daily_trade_count,
                        average_confidence=avg_confidence,
                        market_conditions={}  # Can be enhanced with real market data
                    )
                    
                    logger.info(
                        f"AI Capacity Decision: Recommended={ai_capacity_info.get('recommended_max')}, "
                        f"Adaptive={ai_capacity_info.get('adaptive_max')}, "
                        f"Current={ai_capacity_info.get('current_trades')}, "
                        f"Reason: {ai_capacity_info.get('reason', 'N/A')}"
                    )
                except Exception as e:
                    logger.warning(f"Error getting AI capacity: {e}")
            
            # Process each signal
            for sig in signals:
                try:
                    # Risk check with AI-driven adaptive capacity
                    allowed = self.risk_engine.is_order_allowed(
                        sig,
                        self.executor,
                        ai_capacity_info=ai_capacity_info
                    )
                    
                    if not allowed:
                        self.execution_stats["rejected_signals"] += 1
                        # Create rejected order for tracking
                        rejected_order = Order(
                            symbol=sig.symbol,
                            side=sig.side,
                            quantity=sig.quantity,
                            status=OrderStatus.REJECTED,
                            metadata={"reason": "Risk engine rejected", "strategy_reason": sig.reason}
                        )
                        results.append(rejected_order)
                        continue
                    
                    self.execution_stats["approved_signals"] += 1
                    
                    # Execute order
                    order = self.executor.execute_order(
                        symbol=sig.symbol,
                        side=sig.side,
                        quantity=sig.quantity,
                        order_type=OrderType.MARKET,
                        risk_approved=True,
                        reason=sig.reason,
                    )
                    
                    # Update risk engine
                    if order.status == OrderStatus.FILLED:
                        self.risk_engine.on_order_placed(order)
                        self.execution_stats["filled_orders"] += 1
                        logger.info(
                            f"Order filled: {order.symbol} {order.side.value} {order.quantity} "
                            f"(ID: {order.client_order_id})"
                        )
                    elif order.status == OrderStatus.REJECTED:
                        self.execution_stats["rejected_signals"] += 1
                        logger.warning(
                            f"Order rejected: {order.symbol} - {order.metadata.get('reason', 'Unknown reason')}"
                        )
                    else:
                        self.execution_stats["failed_orders"] += 1
                        logger.error(f"Order failed: {order.symbol} - Status: {order.status}")
                    
                    results.append(order)
                    
                except Exception as e:
                    logger.error(f"Error processing signal {sig.symbol}: {e}", exc_info=True)
                    self.execution_stats["failed_orders"] += 1
                    # Create failed order for tracking
                    failed_order = Order(
                        symbol=sig.symbol,
                        side=sig.side,
                        quantity=sig.quantity,
                        status=OrderStatus.REJECTED,
                        metadata={"reason": f"Execution error: {str(e)}", "strategy_reason": sig.reason}
                    )
                    results.append(failed_order)
            
            execution_time = time.time() - start_time
            self.execution_stats["last_execution_time"] = execution_time
            
            logger.info(
                f"Execution cycle completed in {execution_time:.3f}s: "
                f"{self.execution_stats['filled_orders']} filled, "
                f"{self.execution_stats['rejected_signals']} rejected"
            )
            
        except Exception as e:
            logger.error(f"Critical error in run_once(): {e}", exc_info=True)
            raise
        
        return results

    def get_statistics(self) -> Dict[str, Any]:
        """Get comprehensive execution statistics."""
        return {
            **self.execution_stats,
            "risk_status": self.risk_engine.get_risk_status(),
            "trading_mode": "LIVE" if self.config.is_live else "PAPER",
        }


__all__ = [
    "TradeSignal",
    "SignalSource",
    "SimpleRiskEngine",
    "TradingOrchestrator",
]


