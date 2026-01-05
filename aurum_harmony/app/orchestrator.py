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
from aurum_harmony.engines.adaptive_intelligence import (
    adaptive_parameter_engine,
    preemptive_risk_manager,
    trade_direction_switcher,
    TradeDirection,
    DirectionSwitchRecommendation
)
from aurum_harmony.engines.risk_management.trailing_sl_tp import (
    TrailingSLTPManager,
    ExitReason
)
from aurum_harmony.engines.option_selection.low_premium_picker import (
    LowPremiumOptionPicker,
    OptionContract
)
from aurum_harmony.engines.market_data.nse_option_chain import nse_option_chain
from aurum_harmony.engines.trading_targets import TradingTargetsManager
import threading

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
        # Initialize adaptive intelligence engines
        self.adaptive_engine = adaptive_parameter_engine
        self.risk_manager = preemptive_risk_manager
        self.direction_switcher = trade_direction_switcher
        self.current_trade_direction: Optional[TradeDirection] = None
        
        # Initialize trailing SL/TP manager (LEGACY KEY ENGINE for loss minimization)
        self.trailing_sl_tp = TrailingSLTPManager(
            default_trailing_sl_pct=2.0,  # 2% trailing distance
            default_tp_levels=[
                (1.02, 33.3),  # 2% profit, exit 33.3%
                (1.05, 33.3),  # 5% profit, exit 33.3%
                (1.10, 33.4)   # 10% profit, exit remaining 33.4%
            ]
        )
        
        # Initialize low premium option picker (for chasing low premium options)
        self.option_picker = LowPremiumOptionPicker(
            max_premium=200.0,  # Max ₹200 per lot
            min_premium=10.0,   # Min ₹10 per lot (avoid too cheap, low liquidity)
            preferred_moneyness_range=(-2.0, 2.0),  # -2% to +2% from ATM
            min_volume=1000,    # Minimum volume for liquidity
            prefer_otm=True     # Prefer OTM options (cheaper)
        )
        
        # Price monitoring thread (for autonomous SL/TP updates)
        self._price_monitoring_active = False
        self._price_monitoring_thread = None
        
        # Initialize trading targets manager (for production trading frequency guidance)
        self.trading_targets = TradingTargetsManager()
        self._daily_trade_count = 0
        self._last_target_reset_date = self._get_current_date_str()
        
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
        
        # Start autonomous price monitoring for trailing SL/TP
        self._start_price_monitoring()
    
    def _get_current_date_str(self) -> str:
        """Get current date string for daily reset tracking."""
        from datetime import datetime
        return datetime.now().strftime("%Y-%m-%d")
    
    def _reset_daily_targets_if_needed(self) -> None:
        """Reset daily trade count if a new day has started."""
        current_date = self._get_current_date_str()
        if current_date != self._last_target_reset_date:
            logger.info(f"Resetting daily trade count (new day: {current_date})")
            self._daily_trade_count = 0
            self._last_target_reset_date = current_date
    
    def _check_trading_targets(self, capital: float) -> Dict[str, Any]:
        """
        Check current progress against trading targets.
        
        Returns:
            Dict with target info and current progress
        """
        self._reset_daily_targets_if_needed()
        
        targets = self.trading_targets.get_targets_for_capital(capital)
        progress = {
            "target_total_trades": targets.total_trades_per_day,
            "current_trades": self._daily_trade_count,
            "target_trades_per_index": targets.trades_per_index,
            "trades_per_hour": self.trading_targets.calculate_trades_per_hour(capital),
            "trades_per_minute": self.trading_targets.calculate_trades_per_minute(capital),
            "progress_percent": (self._daily_trade_count / targets.total_trades_per_day * 100) if targets.total_trades_per_day > 0 else 0
        }
        return progress

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
            
            # ADAPTIVE INTELLIGENCE: Assess opportunity and adjust parameters
            # Convert hard rules to adaptive guidelines based on ML/AI intelligence
            market_data = {}  # Can be enhanced with real market data
            signal_confidence = 0.7  # Default, will be calculated from signals
            current_pnl = self.risk_engine.daily_pnl
            recent_performance = {
                "win_rate": 0.5,  # Can be calculated from trade history
                "recent_pnl": current_pnl
            }
            vix_level = 15.0  # Default, should be fetched from market data
            
            # Calculate average signal confidence
            if signals:
                confidences = [
                    float(sig.reason.split("confidence: ")[1].split("%")[0]) / 100
                    if "confidence:" in sig.reason else 0.7
                    for sig in signals
                ]
                signal_confidence = sum(confidences) / len(confidences) if confidences else 0.7
            
            # Assess opportunity using adaptive intelligence
            opportunity_assessment = self.adaptive_engine.assess_opportunity(
                market_data=market_data,
                signal_confidence=signal_confidence,
                current_pnl=current_pnl,
                recent_performance=recent_performance,
                vix_level=vix_level
            )
            
            # Get adjusted parameters based on opportunity
            adjusted_params = self.adaptive_engine.get_all_adjusted_parameters(opportunity_assessment)
            
            logger.info(
                f"Adaptive Intelligence: {opportunity_assessment.recommended_action} "
                f"(opportunity: {opportunity_assessment.opportunity_score:.2f}, "
                f"risk: {opportunity_assessment.risk_score:.2f})"
            )
            
            # PREEMPTIVE RISK MANAGEMENT: Detect and prevent losses
            # Analyze trade patterns for loss sequences
            recent_trades = []  # Can be populated from trade history
            risk_signal = self.risk_manager.analyze_trade_pattern(
                recent_trades=recent_trades,
                current_pnl=current_pnl,
                market_data=market_data
            )
            
            # Check if trading should be paused
            should_pause, pause_reason = self.risk_manager.should_pause_trading(
                current_pnl=current_pnl,
                recent_performance=recent_performance,
                risk_signals=[risk_signal] if risk_signal else []
            )
            
            if should_pause:
                logger.warning(f"Trading paused: {pause_reason}")
                return results  # Return empty results, don't process signals
            
            # TRADE DIRECTION SWITCHING: Preemptively switch direction to prevent losses
            # Get current positions to check PnL
            current_positions = {}
            current_position_pnl = 0.0
            position_entry_prices = {}
            current_prices = {}
            
            if hasattr(self.executor, 'broker_adapter') and hasattr(self.executor.broker_adapter, 'get_positions'):
                try:
                    positions = self.executor.broker_adapter.get_positions()
                    for symbol, position in positions.items():
                        current_positions[symbol] = position
                        current_position_pnl += position.unrealized_pnl if hasattr(position, 'unrealized_pnl') else 0.0
                        position_entry_prices[symbol] = position.avg_price if hasattr(position, 'avg_price') else 0.0
                        current_prices[symbol] = position.current_price if hasattr(position, 'current_price') else 0.0
                except Exception as e:
                    logger.warning(f"Could not fetch positions for direction switching: {e}")
            
            # Get price data for trend analysis (from signals or market data)
            prices = market_data.get("prices", [])
            volumes = market_data.get("volumes", [])
            indicators = market_data.get("indicators", {})
            
            # Get AI direction prediction from PredictiveAIEngine if available
            ai_direction_prediction = None
            if hasattr(self.signal_source, 'predict') or hasattr(self.signal_source, 'get_direction_prediction'):
                try:
                    # Try to get direction prediction from PredictiveAIEngine
                    if hasattr(self.signal_source, 'predict'):
                        # Use predict method with current market features
                        features = {
                            "rsi": indicators.get("rsi", 50.0),
                            "atr": market_data.get("atr", 1.0),
                            "vix": vix_level,
                            "oi_change": market_data.get("oi_change", 0.0),
                            "volume_spike": market_data.get("volume_spike", 0.0)
                        }
                        ai_direction_prediction = self.signal_source.predict(features)
                    elif hasattr(self.signal_source, 'get_direction_prediction'):
                        ai_direction_prediction = self.signal_source.get_direction_prediction()
                except Exception as e:
                    logger.debug(f"Could not get AI direction prediction: {e}")
            
            # Check if direction should be switched (integrated with existing AI prediction)
            direction_switch = self.direction_switcher.should_switch_direction(
                current_direction=self.current_trade_direction or TradeDirection.NEUTRAL,
                prices=prices if prices else [100.0] * 20,  # Default prices if not available
                volumes=volumes if volumes else None,
                indicators=indicators,
                current_position_pnl=current_position_pnl,
                position_entry_price=position_entry_prices.get(signals[0].symbol) if signals else None,
                current_price=current_prices.get(signals[0].symbol) if signals else None,
                ai_direction_prediction=ai_direction_prediction  # Pass AI prediction to switcher
            )
            
            if direction_switch:
                logger.warning(
                    f"🔄 DIRECTION SWITCH RECOMMENDED: {direction_switch.current_direction.value} → "
                    f"{direction_switch.recommended_direction.value} "
                    f"(confidence: {direction_switch.confidence:.2f}, urgency: {direction_switch.urgency}, "
                    f"expected loss prevention: ₹{direction_switch.expected_loss_prevention:,.2f})"
                )
                logger.info(f"Reason: {direction_switch.reasoning}")
                
                # Close current positions if switching direction
                if direction_switch.urgency in ["HIGH", "CRITICAL"] and current_positions:
                    logger.info(f"Closing {len(current_positions)} position(s) before direction switch...")
                    for symbol, position in current_positions.items():
                        try:
                            # Close position by placing opposite order
                            close_side = OrderSide.SELL if position.quantity > 0 else OrderSide.BUY
                            close_order = self.executor.execute_order(
                                symbol=symbol,
                                side=close_side,
                                quantity=abs(position.quantity),
                                order_type=OrderType.MARKET,
                                risk_approved=True,
                                reason=f"Direction switch: {direction_switch.current_direction.value} → {direction_switch.recommended_direction.value}"
                            )
                            if close_order.status == OrderStatus.FILLED:
                                logger.info(f"✅ Position closed: {symbol} (PnL: ₹{position.unrealized_pnl:,.2f})")
                                results.append(close_order)
                        except Exception as e:
                            logger.error(f"Error closing position {symbol}: {e}")
                
                # Update current direction
                self.current_trade_direction = direction_switch.recommended_direction
                
                # Filter/adjust signals to match new direction
                if direction_switch.recommended_direction == TradeDirection.BULLISH:
                    # Only process BUY signals
                    signals = [s for s in signals if s.side == OrderSide.BUY]
                    logger.info(f"Direction switched to BULLISH - filtering to {len(signals)} BUY signal(s)")
                elif direction_switch.recommended_direction == TradeDirection.BEARISH:
                    # Only process SELL signals
                    signals = [s for s in signals if s.side == OrderSide.SELL]
                    logger.info(f"Direction switched to BEARISH - filtering to {len(signals)} SELL signal(s)")
            
            # Apply loss prevention actions if risk detected
            if risk_signal:
                prevention_action = self.risk_manager.generate_loss_prevention_action(
                    risk_signal=risk_signal,
                    current_parameters=adjusted_params
                )
                
                # Apply parameter adjustments from loss prevention
                for param_name, multiplier in prevention_action.parameters.items():
                    if param_name.endswith("_multiplier"):
                        base_param = param_name.replace("_multiplier", "")
                        if base_param in adjusted_params:
                            adjusted_params[base_param] *= multiplier
                            logger.info(
                                f"Loss prevention: {base_param} adjusted by {multiplier:.1%} "
                                f"({prevention_action.urgency} urgency)"
                            )
            
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
                    
                    # Get AI-driven adaptive capacity (use adjusted parameters)
                    ai_capacity_info = self.signal_source.get_adaptive_trade_capacity(
                        current_trades=self.risk_engine.daily_trade_count,
                        average_confidence=avg_confidence,
                        market_conditions={
                            "opportunity_score": opportunity_assessment.opportunity_score,
                            "risk_score": opportunity_assessment.risk_score,
                            "adjusted_trades_per_day": adjusted_params.get("trades_per_day", 27),
                            "adjusted_capacity": adjusted_params.get("vix_capacity", 1.0)
                        }
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
                            
                            # LOW PREMIUM OPTION SELECTION: Select best low-premium option
                            selected_option = None
                            actual_symbol = sig.symbol
                            actual_quantity = sig.quantity
                            
                            try:
                                # Get underlying price
                                underlying_price = self._get_underlying_price(sig.symbol)
                                if underlying_price:
                                    # Fetch option chain
                                    option_chain_data = nse_option_chain.get_option_chain(sig.symbol)
                                    if option_chain_data:
                                        # Parse option chain into list format
                                        option_chain_list = self._parse_option_chain(option_chain_data, sig.symbol)
                                        
                                        # Select low-premium option
                                        selected_option = self.option_picker.select_option(
                                            symbol=sig.symbol,
                                            direction=sig.side.value,
                                            underlying_price=underlying_price,
                                            option_chain=option_chain_list
                                        )
                                        
                                        if selected_option:
                                            # Use selected option contract name as symbol
                                            actual_symbol = selected_option.contract_name
                                            # Adjust quantity based on lot size (convert to lots, then back)
                                            quantity_in_lots = max(1, int(sig.quantity / selected_option.lot_size))
                                            actual_quantity = quantity_in_lots * selected_option.lot_size
                                            logger.info(
                                                f"Selected low-premium option: {selected_option.contract_name} "
                                                f"@ ₹{selected_option.premium:.2f} (Strike: {selected_option.strike}, "
                                                f"Qty: {actual_quantity} lots)"
                                            )
                                        else:
                                            logger.warning(f"No suitable low-premium option found for {sig.symbol}, using index directly")
                                    else:
                                        logger.warning(f"Could not fetch option chain for {sig.symbol}, using index directly")
                                else:
                                    logger.warning(f"Could not get underlying price for {sig.symbol}, using index directly")
                            except Exception as e:
                                logger.warning(f"Error in option selection: {e}, using index directly", exc_info=True)
                            
                            # Execute order (with selected option if available)
                            order = self.executor.execute_order(
                                symbol=actual_symbol,
                                side=sig.side,
                                quantity=actual_quantity,
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
                                
                                # TRAILING SL/TP: Register position with trailing SL/TP manager
                                try:
                                    filled_price = order.metadata.get("filled_price") or order.limit_price or 0.0
                                    if filled_price > 0:
                                        entry = self.trailing_sl_tp.add_position(
                                            symbol=order.symbol,
                                            side=order.side.value,
                                            price=filled_price,
                                            quantity=abs(order.quantity),
                                            stop_loss_pct=2.0,  # 2% initial SL
                                            trailing_sl_pct=1.5   # 1.5% trailing distance
                                        )
                                        logger.info(
                                            f"Position registered with trailing SL/TP: {order.symbol} "
                                            f"Entry: ₹{filled_price:.2f}, SL: ₹{entry.stop_loss:.2f}, "
                                            f"TP Levels: {[f'₹{tp:.2f}' for tp in entry.take_profit_levels]}"
                                        )
                                except Exception as e:
                                    logger.warning(f"Error registering position with trailing SL/TP: {e}", exc_info=True)
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
            
            # Update daily trade count for trading targets
            filled_count = sum(1 for r in results if r.status == OrderStatus.FILLED)
            self._daily_trade_count += filled_count
            
            # Log trading targets progress (if capital available)
            try:
                if hasattr(self.executor, 'broker_adapter'):
                    if hasattr(self.executor.broker_adapter, 'get_balance'):
                        balance = self.executor.broker_adapter.get_balance()
                        if balance:
                            target_progress = self._check_trading_targets(balance)
                            if target_progress["progress_percent"] > 0:
                                logger.debug(
                                    f"Trading Targets: {target_progress['current_trades']}/{target_progress['target_total_trades']} "
                                    f"({target_progress['progress_percent']:.1f}%)"
                                )
            except:
                pass  # Silently fail if balance not available
            
            logger.info(
                f"Execution cycle completed in {execution_time:.3f}s: "
                f"{self.execution_stats['filled_orders']} filled, "
                f"{self.execution_stats['rejected_signals']} rejected"
            )
            
        except Exception as e:
            logger.error(f"Critical error in run_once(): {e}", exc_info=True)
            raise
        
        return results

    def _get_underlying_price(self, symbol: str) -> Optional[float]:
        """Get underlying price for symbol."""
        try:
            # Try NSE option chain
            price = nse_option_chain.get_underlying_price(symbol)
            if price:
                return price
            
            # Try broker adapter if available
            if hasattr(self.executor, 'broker_adapter'):
                if hasattr(self.executor.broker_adapter, 'get_current_price'):
                    price = self.executor.broker_adapter.get_current_price(symbol)
                    if price:
                        return price
            
            return None
        except Exception as e:
            logger.debug(f"Error getting underlying price: {e}")
            return None
    
    def _parse_option_chain(self, option_chain_data: Dict, symbol: str) -> List[Dict]:
        """Parse NSE option chain data into list format for picker."""
        option_list = []
        
        try:
            # NSE option chain format: records.data[] with CE and PE
            if "records" in option_chain_data and "data" in option_chain_data["records"]:
                for strike_data in option_chain_data["records"]["data"]:
                    strike = strike_data.get("strikePrice")
                    if not strike:
                        continue
                    
                    # Add CALL option
                    if "CE" in strike_data and strike_data["CE"]:
                        ce_data = strike_data["CE"]
                        # Only include if has price data
                        if ce_data.get("lastPrice") or ce_data.get("bidPrice") or ce_data.get("askPrice"):
                            option_list.append({
                                "strikePrice": strike,
                                "strike": strike,
                                "optionType": "CE",
                                "option_type": "CE",
                                "lastPrice": ce_data.get("lastPrice"),
                                "ltp": ce_data.get("lastPrice"),
                                "bidPrice": ce_data.get("bidPrice"),
                                "bid": ce_data.get("bidPrice"),
                                "askPrice": ce_data.get("askPrice"),
                                "ask": ce_data.get("askPrice"),
                                "volume": ce_data.get("totalTradedVolume") or ce_data.get("volume", 0),
                                "totalTradedVolume": ce_data.get("totalTradedVolume") or ce_data.get("volume", 0),
                                "openInterest": ce_data.get("openInterest") or ce_data.get("oi", 0),
                                "oi": ce_data.get("openInterest") or ce_data.get("oi", 0),
                                "impliedVolatility": ce_data.get("impliedVolatility") or ce_data.get("iv", 0)
                            })
                    
                    # Add PUT option
                    if "PE" in strike_data and strike_data["PE"]:
                        pe_data = strike_data["PE"]
                        # Only include if has price data
                        if pe_data.get("lastPrice") or pe_data.get("bidPrice") or pe_data.get("askPrice"):
                            option_list.append({
                                "strikePrice": strike,
                                "strike": strike,
                                "optionType": "PE",
                                "option_type": "PE",
                                "lastPrice": pe_data.get("lastPrice"),
                                "ltp": pe_data.get("lastPrice"),
                                "bidPrice": pe_data.get("bidPrice"),
                                "bid": pe_data.get("bidPrice"),
                                "askPrice": pe_data.get("askPrice"),
                                "ask": pe_data.get("askPrice"),
                                "volume": pe_data.get("totalTradedVolume") or pe_data.get("volume", 0),
                                "totalTradedVolume": pe_data.get("totalTradedVolume") or pe_data.get("volume", 0),
                                "openInterest": pe_data.get("openInterest") or pe_data.get("oi", 0),
                                "oi": pe_data.get("openInterest") or pe_data.get("oi", 0),
                                "impliedVolatility": pe_data.get("impliedVolatility") or pe_data.get("iv", 0)
                            })
        except Exception as e:
            logger.warning(f"Error parsing option chain: {e}", exc_info=True)
        
        logger.debug(f"Parsed {len(option_list)} options from chain for {symbol}")
        return option_list
    
    def _start_price_monitoring(self):
        """Start autonomous price monitoring thread for trailing SL/TP."""
        if self._price_monitoring_active:
            return
        
        self._price_monitoring_active = True
        
        def monitor_prices():
            """Autonomous price monitoring loop."""
            logger.info("Starting autonomous price monitoring for trailing SL/TP")
            
            while self._price_monitoring_active:
                try:
                    # Get all tracked positions
                    all_positions = self.trailing_sl_tp.get_all_positions_status()
                    
                    if not all_positions:
                        time.sleep(5)  # Wait 5 seconds if no positions
                        continue
                    
                    # Collect current prices for all symbols
                    prices = {}
                    for position_key, position_status in all_positions.items():
                        if position_status:
                            symbol = position_status["symbol"]
                            
                            # For option contracts, extract underlying symbol
                            underlying_symbol = symbol
                            if any(idx in symbol.upper() for idx in ["NIFTY", "BANKNIFTY", "SENSEX"]):
                                # Extract underlying from option contract name
                                # Format: NIFTY24500CE or NIFTY50-24500-CE
                                for idx in ["NIFTY50", "BANKNIFTY", "SENSEX"]:
                                    if idx in symbol.upper():
                                        underlying_symbol = idx
                                        break
                            
                            # Get current price (try option premium first, then underlying)
                            current_price = None
                            
                            # Try to get option premium directly
                            try:
                                if hasattr(self.executor, 'broker_adapter'):
                                    if hasattr(self.executor.broker_adapter, 'get_current_price'):
                                        current_price = self.executor.broker_adapter.get_current_price(symbol)
                            except:
                                pass
                            
                            # Fallback to underlying price
                            if not current_price:
                                current_price = self._get_underlying_price(underlying_symbol)
                            
                            if current_price:
                                prices[symbol] = current_price
                    
                    # Update prices and check for SL/TP triggers
                    if prices:
                        exit_actions = self.trailing_sl_tp.update_prices(prices)
                        
                        # Process exit actions
                        for position_key, exits in exit_actions.items():
                            for exit_action in exits:
                                try:
                                    # Get position tracker
                                    tracker = self.trailing_sl_tp.positions.get(position_key)
                                    if not tracker:
                                        continue
                                    
                                    # Execute exit
                                    exit_pnl = tracker.exit_entry(
                                        entry_id=exit_action["entry_id"],
                                        exit_price=exit_action["price"],
                                        exit_quantity=exit_action.get("quantity"),
                                        reason=exit_action["reason"]
                                    )
                                    
                                    # Create and execute exit order
                                    exit_order = self.executor.execute_order(
                                        symbol=tracker.symbol,
                                        side=OrderSide.SELL if tracker.side == "BUY" else OrderSide.BUY,
                                        quantity=exit_action.get("quantity", abs(tracker.total_quantity)),
                                        order_type=OrderType.MARKET,
                                        risk_approved=True,
                                        reason=f"Auto exit: {exit_action['reason'].value}"
                                    )
                                    
                                    if exit_order.status == OrderStatus.FILLED:
                                        logger.info(
                                            f"Auto exit executed: {tracker.symbol} {exit_action['reason'].value} "
                                            f"@ ₹{exit_action['price']:.2f}, PnL: ₹{exit_pnl:,.2f}"
                                        )
                                    
                                except Exception as e:
                                    logger.error(f"Error processing exit action: {e}", exc_info=True)
                    
                    # Wait before next update (update every 5 seconds)
                    time.sleep(5)
                    
                except Exception as e:
                    logger.error(f"Error in price monitoring: {e}", exc_info=True)
                    time.sleep(10)  # Wait longer on error
        
        # Start monitoring thread
        self._price_monitoring_thread = threading.Thread(target=monitor_prices, daemon=True)
        self._price_monitoring_thread.start()
        logger.info("Autonomous price monitoring started")
    
    def stop_price_monitoring(self):
        """Stop autonomous price monitoring."""
        self._price_monitoring_active = False
        if self._price_monitoring_thread:
            self._price_monitoring_thread.join(timeout=5)
        logger.info("Price monitoring stopped")
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get comprehensive execution statistics."""
        # Get trailing SL/TP status
        sl_tp_status = self.trailing_sl_tp.get_all_positions_status()
        
        return {
            **self.execution_stats,
            "risk_status": self.risk_engine.get_risk_status(),
            "trading_mode": "LIVE" if self.config.is_live else "PAPER",
            "trailing_sl_tp_positions": len(sl_tp_status),
            "price_monitoring_active": self._price_monitoring_active
        }


__all__ = [
    "TradeSignal",
    "SignalSource",
    "SimpleRiskEngine",
    "TradingOrchestrator",
]


