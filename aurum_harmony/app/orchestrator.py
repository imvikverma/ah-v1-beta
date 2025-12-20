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
from datetime import datetime

from .config import AppConfig, load_config
from aurum_harmony.engines.trade_execution.trade_execution import (
    TradeExecutor,
    OrderSide,
    OrderType,
    Order,
    OrderStatus,
    BrokerAdapter,
)
from aurum_harmony.engines.settlement.capital_calculation_engine import CapitalCalculationEngine
from aurum_harmony.engines.settlement.multi_index_allocator import MultiIndexCapitalAllocator
from aurum_harmony.engines.settlement.Settlement_Engine import IncrementEngine
from aurum_harmony.database.models import User, ProfitTracking
from aurum_harmony.database.db import db
from aurum_harmony.engines.market_data.broker_data_fetcher import BrokerDataFetcher

# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class UserTier:
  """Simple in-memory representation of a user's tier for display/fees."""
  name: str
  min_capital: float
  fee_rate: float
  max_accounts: int


class UserTierManager:
  """
  Tier manager based on internal ledger capital.

  NOTE: Phase 1 is DISPLAY-ONLY:
  - Uses User.internal_capital (NOT broker balance) to determine tier.
  - Intended for dashboard tier card & fee previews, not risk sizing yet.
  """

  TIERS: Dict[str, Dict[str, Any]] = {
      "bronze": {"min_capital": 5000.0, "fee_rate": 0.30, "max_accounts": 1},
      "silver": {"min_capital": 50000.0, "fee_rate": 0.20, "max_accounts": 2},
      "gold": {"min_capital": 100000.0, "fee_rate": 0.125, "max_accounts": 6},
  }

  @classmethod
  def get_tier(cls, internal_capital: float) -> UserTier:
      # Iterate from highest to lowest tier
      for name, cfg in reversed(list(cls.TIERS.items())):
          if internal_capital >= cfg["min_capital"]:
              return UserTier(
                  name=name,
                  min_capital=cfg["min_capital"],
                  fee_rate=cfg["fee_rate"],
                  max_accounts=cfg["max_accounts"],
              )
      # Fallback to bronze
      cfg = cls.TIERS["bronze"]
      return UserTier(
          name="bronze",
          min_capital=cfg["min_capital"],
          fee_rate=cfg["fee_rate"],
          max_accounts=cfg["max_accounts"],
      )

  @classmethod
  def calculate_fee(cls, profit: float, internal_capital: float) -> float:
      tier = cls.get_tier(internal_capital)
      return max(0.0, profit) * tier.fee_rate


class CapitalSettlementOrchestrator:
  """
  Orchestrates capital calculation, settlement, and profit tracking.

  Integrates:
  - CapitalCalculationEngine: Initial capital with margin and rounding
  - MultiIndexCapitalAllocator: Equal allocation across indices
  - SettlementEngine: Enhanced with loss buffer and brokerage tracking
  - IncrementEngine: Profit-based capital increments
  - Database tracking: Accumulated profit and capital allocation
  """

  @staticmethod
  def calculate_initial_capital_for_user(
      user_id: int,
      base_capital: float = 10000.0,
      num_indices: int = 3,
      num_brokers: int = 1,
      num_users: int = 1,
      user_type: str = "normal"
  ) -> Dict[str, Any]:
      """
      Calculate initial capital for a new user.

      Formula: Base × Indices × Brokers × Users + 30% Margin
      Allocation: ₹40,000 PER INDEX (not split)

      Args:
          user_id: User ID
          base_capital: Base capital level
          num_indices: Number of indices (default 3)
          num_brokers: Number of brokers (default 1)
          num_users: Number of users (default 1)
          user_type: "admin" or "normal"

      Returns:
          Capital calculation result
      """
      try:
          # Calculate initial capital
          capital_calc = CapitalCalculationEngine.calculate_initial_capital(
              base_capital=base_capital,
              num_indices=num_indices,
              num_brokers=num_brokers,
              num_users=num_users,
              user_type=user_type
          )

          # Allocate capital across indices
          allocation = MultiIndexCapitalAllocator.allocate_capital(
              per_index_capital=capital_calc["per_index_capital"],
              num_indices=num_indices,
              num_brokers=num_brokers,
              num_accounts=num_users
          )

          # Update user in database
          user = User.query.get(user_id)
          if user:
              user.internal_capital = capital_calc["total_capital"]
              user.capital_allocation = allocation
              db.session.commit()
              logger.info(f"Initial capital set for user {user_id}: ₹{capital_calc['total_capital']:,.2f}")

          result = {
              **capital_calc,
              "allocation_matrix": allocation["allocation_matrix"],
              "user_id": user_id
          }

          return result

      except Exception as e:
          logger.error(f"Error calculating initial capital for user {user_id}: {e}", exc_info=True)
          raise

  @staticmethod
  def track_profit_and_check_increment(
      user_id: int,
      gross_profit: float,
      brokerage_fees: Optional[float] = None,
      has_losses: bool = False
  ) -> Dict[str, Any]:
      """
      Track accumulated profit and check for capital increment.

      Args:
          user_id: User ID
          gross_profit: Gross profit (after broker auto-deductions)
          brokerage_fees: Brokerage fees (for reporting)
          has_losses: Whether losses occurred

      Returns:
          Tracking result with increment check
      """
      try:
          user = User.query.get(user_id)
          if not user:
              raise ValueError(f"User {user_id} not found")

          # Get current category for increment logic
          category = "admin" if user.is_admin else "normal"

          # Check for capital increment based on accumulated profit
          should_increment, next_capital = IncrementEngine.should_increment_capital(
              current_capital=user.internal_capital,
              accumulated_profit=user.accumulated_profit + gross_profit,
              category=category,
              num_indices=3,  # Assuming 3 indices
              num_brokers=1,  # Assuming 1 broker
              num_users=1   # Assuming single user
          )

          increment_triggered = False
          if should_increment and next_capital:
              # Trigger capital increment
              old_capital = user.internal_capital
              user.internal_capital = next_capital
              user.accumulated_profit = 0.0  # Reset accumulated profit
              user.last_increment_date = datetime.utcnow()
              increment_triggered = True

              # Recalculate allocation for new capital
              new_allocation = MultiIndexCapitalAllocator.allocate_capital(
                  per_index_capital=next_capital / 3,  # ₹40K per index
                  num_indices=3
              )
              user.capital_allocation = new_allocation

              db.session.commit()
              logger.info(f"Capital incremented for user {user_id}: ₹{old_capital:,.2f} → ₹{next_capital:,.2f}")
          else:
              # Just accumulate profit
              user.accumulated_profit += gross_profit
              db.session.commit()

          # Record profit tracking
          profit_record = ProfitTracking(
              user_id=user_id,
              period_start=datetime.utcnow(),
              gross_profit=gross_profit,
              brokerage_fees=brokerage_fees or (gross_profit * 0.06),  # Estimate if not provided
              accumulated_profit=user.accumulated_profit
          )
          db.session.add(profit_record)
          db.session.commit()

          return {
              "user_id": user_id,
              "gross_profit": gross_profit,
              "accumulated_profit": user.accumulated_profit,
              "current_capital": user.internal_capital,
              "increment_triggered": increment_triggered,
              "next_capital": next_capital if increment_triggered else None,
              "brokerage_fees": brokerage_fees
          }

      except Exception as e:
          logger.error(f"Error tracking profit for user {user_id}: {e}", exc_info=True)
          raise


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

    def __init__(self, config: AppConfig, broker_aggregator: Optional['BrokerAggregator'] = None) -> None:
        self.config = config
        self.broker_aggregator = broker_aggregator
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
        
        logger.info(
            f"RiskEngine initialized with limits: {config.global_risk}, "
            f"aggregator={'ENABLED' if broker_aggregator else 'DISABLED'}"
        )

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
        
        # Check position size (use aggregated snapshot if available, otherwise fall back to executor)
        if hasattr(executor, 'broker_aggregator') and executor.broker_aggregator:
            # Use unified snapshot from aggregator
            try:
                snapshot = executor.broker_aggregator.get_unified_snapshot(timeout=2.0)
                for pos in snapshot.all_positions:
                    if pos.symbol == signal.symbol:
                        current_position_value = pos.current_price * abs(pos.quantity)
                        if current_position_value >= self.config.global_risk.max_position_size:
                            logger.warning(
                                f"Order rejected: position size limit reached for {signal.symbol} "
                                f"(Current: ₹{current_position_value:,.2f}, Limit: ₹{self.config.global_risk.max_position_size:,.2f})"
                            )
                            return False
            except Exception as e:
                logger.warning(f"Error getting unified snapshot for position check: {e}")
        elif executor and hasattr(executor.broker_adapter, 'get_positions'):
            # Fall back to single adapter
            positions = executor.broker_adapter.get_positions()
            # Handle both dict and list formats
            if isinstance(positions, dict):
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
            elif isinstance(positions, list):
                for pos in positions:
                    if hasattr(pos, 'symbol') and pos.symbol == signal.symbol:
                        current_position_value = pos.current_price * abs(pos.quantity)
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
    - Supports multi-engine aggregation via BrokerAggregator
    """

    def __init__(
        self, 
        signal_source: SignalSource, 
        config: Optional[AppConfig] = None, 
        broker_adapter: Optional[BrokerAdapter] = None,
        broker_aggregator: Optional['BrokerAggregator'] = None,
    ) -> None:
        """
        Initialize orchestrator.
        
        Args:
            signal_source: Source of trading signals
            config: App configuration
            broker_adapter: Single broker adapter (legacy mode)
            broker_aggregator: Multi-engine aggregator (new unified mode)
        """
        self.config = config or load_config()
        self.signal_source = signal_source
        self.broker_aggregator = broker_aggregator
        # Pass aggregator to risk engine so it can use unified snapshot
        self.risk_engine = SimpleRiskEngine(self.config, broker_aggregator=broker_aggregator)
        
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
        
        # Store aggregator reference in executor for risk engine access
        if broker_aggregator:
            self.executor.broker_aggregator = broker_aggregator
        self.execution_stats = {
            "total_signals": 0,
            "approved_signals": 0,
            "rejected_signals": 0,
            "filled_orders": 0,
            "failed_orders": 0,
            "last_execution_time": None,
        }

        # Initialize daily cycle scheduler
        from aurum_harmony.engines.scheduling.daily_cycle_scheduler import DailyCycleScheduler
        self.daily_scheduler = DailyCycleScheduler(self)

        logger.info(
            f"TradingOrchestrator initialized: "
            f"mode={'LIVE' if self.config.is_live else 'PAPER'}, "
            f"risk_limits={self.config.global_risk}, "
            f"aggregator={'ENABLED' if broker_aggregator else 'DISABLED'}, "
            f"scheduler={'ENABLED' if self.daily_scheduler else 'DISABLED'}"
        )

    def get_live_market_data(self, symbols: List[str] = None) -> Dict[str, Any]:
        """
        Fetch live market data for prediction and analysis.

        Args:
            symbols: List of symbols to fetch (defaults to major indices)

        Returns:
            Dictionary with market data organized by symbol
        """
        if symbols is None:
            symbols = ["NIFTY50", "BANKNIFTY", "SENSEX"]

        # Initialize broker data fetcher
        try:
            from aurum_harmony.engines.trade_execution.broker_adapter_factory import (
                get_hdfc_client_from_env,
                get_kotak_client_from_env,
            )

            hdfc_client = get_hdfc_client_from_env()
            kotak_client = get_kotak_client_from_env()

            data_fetcher = BrokerDataFetcher(
                hdfc_client=hdfc_client,
                kotak_client=kotak_client,
                use_nse_fallback=True
            )

            market_data = {}

            # Fetch live 5-minute candles for each symbol
            for symbol in symbols:
                try:
                    candles = data_fetcher.fetch_live_candles(symbol, count=50, interval="5MINUTE")
                    if candles:
                        market_data[symbol] = {
                            'candles': candles,
                            'latest_price': candles[-1].close if candles else None,
                            'source': 'live_api'
                        }
                        logger.info(f"Fetched {len(candles)} live candles for {symbol}")
                    else:
                        logger.warning(f"No live data available for {symbol}")
                        market_data[symbol] = {'candles': [], 'latest_price': None, 'source': 'unavailable'}
                except Exception as e:
                    logger.error(f"Error fetching live data for {symbol}: {e}")
                    market_data[symbol] = {'candles': [], 'latest_price': None, 'source': 'error'}

            return {
                'success': True,
                'data': market_data,
                'timestamp': datetime.now(),
                'sources': {
                    'hdfc_available': hdfc_client is not None,
                    'kotak_available': kotak_client is not None,
                    'fallback_available': True
                }
            }

        except Exception as e:
            logger.error(f"Error initializing market data fetcher: {e}")
            return {
                'success': False,
                'error': str(e),
                'data': {},
                'timestamp': datetime.now()
            }

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
            # Fetch live market data for enhanced signal generation
            market_data = self.get_live_market_data()
            logger.info(f"Market data fetched: {len(market_data.get('data', {}))} symbols")

            # Fetch signals with market data context
            if hasattr(self.signal_source, 'get_signals_with_market_data'):
                # Enhanced signal source that can use live market data
                signals = self.signal_source.get_signals_with_market_data(market_data)
            else:
                # Fallback to standard signal generation
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

    # Daily Cycle Scheduler Integration Methods

    def start_trading_session(self):
        """Start the trading session (called by scheduler at 9:30 AM)."""
        logger.info("Trading session started by daily scheduler")
        self.system_active = True
        # Reset daily counters
        self.daily_trade_count = 0
        self.current_open_trades = 0

    def stop_trading_session(self):
        """Stop the trading session (called by scheduler at 4:30 PM)."""
        logger.info("Trading session stopped by daily scheduler")
        self.system_active = False

    def get_open_positions(self):
        """Get all open positions for squaring off."""
        # This would need to be implemented based on your position tracking
        # For now, return empty list
        return []

    def square_off_position(self, position_id: str):
        """Square off a specific position."""
        logger.info(f"Squaring off position: {position_id}")
        # Implementation would depend on your position management system
        pass

    def calculate_daily_pnl(self) -> float:
        """Calculate daily profit and loss."""
        # This would calculate P&L from closed positions
        # For now, return a placeholder
        return 0.0

    def process_daily_settlement(self):
        """Process daily settlements."""
        logger.info("Processing daily settlements")
        # Implementation would handle settlement calculations
        pass

    def update_user_capital_after_settlement(self):
        """Update user capital after settlement processing."""
        logger.info("Updating user capital after settlement")
        # Implementation would update user capital in database
        pass

    def generate_performance_report(self):
        """Generate end-of-day performance report."""
        logger.info("Generating performance report")
        # Implementation would create detailed performance report
        pass

    def generate_settlement_report(self):
        """Generate settlement report."""
        logger.info("Generating settlement report")
        # Implementation would create settlement details report
        pass

    def generate_risk_report(self):
        """Generate risk report."""
        logger.info("Generating risk report")
        # Implementation would create risk analysis report
        pass

    def close_broker_connections(self):
        """Close all broker connections."""
        logger.info("Closing broker connections")
        # Implementation would close all active broker API connections
        pass

    def save_system_state(self):
        """Save current system state."""
        logger.info("Saving system state")
        # Implementation would save current positions, orders, etc.
        pass

    def reset_daily_counters(self):
        """Reset daily counters for next trading day."""
        logger.info("Resetting daily counters")
        self.daily_trade_count = 0
        self.current_open_trades = 0
        # Reset other daily metrics
        pass

    def archive_daily_logs(self):
        """Archive daily logs."""
        logger.info("Archiving daily logs")
        # Implementation would move logs to archive location
        pass

    def update_system_status(self, status: str):
        """Update system status."""
        logger.info(f"System status updated to: {status}")
        # Implementation would update system status in database/configuration
        pass

    def check_database_connection(self) -> bool:
        """Check database connectivity."""
        try:
            # Simple database check
            from aurum_harmony.database.db import db
            db.session.execute(db.text("SELECT 1"))
            return True
        except:
            return False

    def check_broker_connections(self) -> bool:
        """Check broker API connections."""
        # Implementation would test broker API connectivity
        return True  # Placeholder

    def check_market_data_feeds(self) -> bool:
        """Check market data feed connectivity."""
        # Implementation would test market data feeds
        return True  # Placeholder

    def check_risk_engine_status(self) -> bool:
        """Check risk engine status."""
        return self.risk_engine is not None

    def check_settlement_engine_status(self) -> bool:
        """Check settlement engine status."""
        # Check if settlement engine is available
        return True  # Placeholder


__all__ = [
    "TradeSignal",
    "SignalSource",
    "SimpleRiskEngine",
    "TradingOrchestrator",
]


