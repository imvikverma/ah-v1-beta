"""
Live Market Burn-In Test
Runs comprehensive testing with REAL market data during market hours (09:15-15:30 IST)

This test:
1. Uses live Kotak Neo prices (if authenticated)
2. Places realistic orders that fit within capital limits
3. Tests all phases continuously
4. Generates comprehensive reports
5. Runs for 2 hours (13:30-15:30 IST)
"""

import os
import sys
import logging
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Dict, List, Any, Optional
import json
import time

# Add project root to path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

# Configure logging with UTF-8 encoding to avoid Unicode errors
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(
            os.path.join(project_root, '_local', 'logs', f'live_market_test_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
            encoding='utf-8'
        ),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Import AurumHarmony components
from aurum_harmony.engines.trade_execution.trade_execution import (
    PaperBrokerAdapter,
    Order,
    OrderSide,
    OrderType,
    OrderStatus,
    Position
)
from aurum_harmony.engines.trade_execution.leverage_aware_adapter import LeverageAwareAdapter
from aurum_harmony.engines.compliance.compliance_engine import ComplianceEngine, ComplianceStatus
from aurum_harmony.engines.settlement.Settlement_Engine import SettlementEngine
from aurum_harmony.engines.fund_push_pull.fund_push_pull import FundPushPullEngine
from aurum_harmony.engines.reporting.reporting import reporting_engine
from aurum_harmony.engines.capital_progression import CapitalProgressionManager
from aurum_harmony.engines.adaptive_intelligence.trading_formula_guidelines import trading_formula_guidelines_engine
from aurum_harmony.engines.adaptive_intelligence.trade_direction_switcher import TradeDirectionSwitcher, TradeDirection

# Try to import Kotak Neo for live data
try:
    from api.kotak_neo import KotakNeoAPI
    from dotenv import load_dotenv
    load_dotenv()
    KOTAK_AVAILABLE = True
except Exception as e:
    logger.warning(f"Kotak Neo not available: {e}")
    KOTAK_AVAILABLE = False


class LiveMarketBurnInTest:
    """
    Live market burn-in test with real data.
    """
    
    def __init__(self, user_id: str = "live_test_user", user_category: str = "admin"):
        self.user_id = user_id
        self.user_category = user_category
        self.start_time = datetime.now()
        self.test_results: Dict[str, Any] = {
            "start_time": self.start_time.isoformat(),
            "user_id": user_id,
            "user_category": user_category,
            "trades": [],
            "positions": {},
            "reports": [],
            "errors": [],
            "warnings": []
        }
        
        # Initialize components
        logger.info("=" * 80)
        logger.info("INITIALIZING LIVE MARKET BURN-IN TEST")
        logger.info("=" * 80)
        
        # 1. Paper Trading Adapter
        initial_capital = 10000.0
        self.paper_adapter = PaperBrokerAdapter(initial_balance=initial_capital)
        logger.info(f"[OK] PaperBrokerAdapter initialized with Rs {initial_capital:,.2f}")
        
        # 2. Leverage-Aware Adapter (3× leverage)
        self.leverage_adapter = LeverageAwareAdapter(
            broker_adapter=self.paper_adapter,
            capital=initial_capital,
            user_category=user_category,
            leverage_multiplier=3.0
        )
        logger.info(f"[OK] LeverageAwareAdapter initialized (3× leverage)")
        
        # 3. Compliance Engine
        self.compliance_engine = ComplianceEngine()
        self.compliance_engine.kyc_verified_users.add(user_id)
        logger.info(f"[OK] ComplianceEngine initialized")
        
        # 4. Settlement Engine
        self.settlement_engine = SettlementEngine()
        logger.info(f"[OK] SettlementEngine initialized")
        
        # 5. Fund Push/Pull Engine
        self.fund_engine = FundPushPullEngine()
        self.fund_engine.user_balances[user_id] = Decimal("10000.0")
        logger.info(f"[OK] FundPushPullEngine initialized")
        
        # 6. Capital Progression Manager
        self.capital_manager = CapitalProgressionManager()
        logger.info(f"[OK] CapitalProgressionManager initialized")
        
        # 7. Trade Direction Switcher
        self.direction_switcher = TradeDirectionSwitcher()
        self.current_direction = TradeDirection.NEUTRAL
        logger.info(f"[OK] TradeDirectionSwitcher initialized")
        
        # 8. Kotak Neo (for live prices)
        self.kotak_client = None
        if KOTAK_AVAILABLE:
            try:
                access_token = os.getenv("KOTAK_ACCESS_TOKEN")
                mobile_number = os.getenv("KOTAK_MOBILE_NUMBER")
                client_code = os.getenv("KOTAK_CLIENT_CODE")
                
                if access_token and mobile_number and client_code:
                    self.kotak_client = KotakNeoAPI(
                        access_token=access_token,
                        mobile_number=mobile_number,
                        client_code=client_code
                    )
                    if self.kotak_client.is_authenticated():
                        logger.info(f"[OK] Kotak Neo connected (LIVE DATA AVAILABLE)")
                    else:
                        logger.warning(f"[WARNING] Kotak Neo not authenticated (using simulated prices)")
                        self.kotak_client = None
                else:
                    logger.warning(f"[WARNING] Kotak Neo credentials not found (using simulated prices)")
            except Exception as e:
                logger.warning(f"[WARNING] Kotak Neo initialization failed: {e} (using simulated prices)")
        
        # Trading indices
        self.trading_indices = ["NIFTY50", "BANKNIFTY", "SENSEX"]
        
        # Test data
        self.trades_executed: List[Dict[str, Any]] = []
        self.positions_tracked: Dict[str, Position] = {}
        
        logger.info("=" * 80)
        logger.info("INITIALIZATION COMPLETE")
        logger.info("=" * 80)
    
    def get_live_price(self, symbol: str) -> float:
        """Get live price from Kotak Neo or use simulated price."""
        if self.kotak_client and self.kotak_client.is_authenticated():
            try:
                # Map symbol to Kotak format
                kotak_symbol = symbol
                if symbol == "NIFTY50":
                    kotak_symbol = "NIFTY"
                
                quotes = self.kotak_client.get_quotes("nse_cm", kotak_symbol)
                if isinstance(quotes, dict):
                    price = quotes.get("ltp") or quotes.get("lastPrice") or quotes.get("price")
                    if price:
                        logger.info(f"[LIVE] {symbol} price: Rs {float(price):,.2f}")
                        return float(price)
            except Exception as e:
                logger.debug(f"Failed to get live price for {symbol}: {e}")
        
        # Simulated prices (for testing without live data)
        simulated_prices = {
            "NIFTY50": 24500.0,
            "BANKNIFTY": 48500.0,
            "SENSEX": 72500.0
        }
        price = simulated_prices.get(symbol, 1000.0)
        logger.info(f"[SIMULATED] {symbol} price: Rs {price:,.2f}")
        return price
    
    def execute_trading_cycle(self) -> Dict[str, Any]:
        """Execute one trading cycle with live data."""
        cycle_results = {
            "timestamp": datetime.now().isoformat(),
            "orders_placed": 0,
            "orders_filled": 0,
            "orders_rejected": 0,
            "positions_opened": 0,
            "positions_closed": 0,
            "pnl": 0.0
        }
        
        try:
            # Get current exposure status
            exposure_status = self.leverage_adapter.get_exposure_status()
            available_exposure = exposure_status["available_exposure"]
            max_exposure = exposure_status["max_exposure"]
            
            logger.info(f"\n[Trading Cycle] Available Exposure: Rs {available_exposure:,.2f} / Rs {max_exposure:,.2f}")
            
            # Get live prices
            prices = {}
            for index in self.trading_indices:
                prices[index] = self.get_live_price(index)
            
            # Calculate order sizes based on trading targets for current capital
            from aurum_harmony.engines.trading_targets import TradingTargetsManager
            current_capital = float(self.leverage_adapter.capital)
            target_trades_per_minute = TradingTargetsManager.calculate_trades_per_minute(current_capital)
            
            # Adjust order size to achieve target trade frequency
            # Split available exposure across indices intelligently
            # Use smaller per-index allocation for high frequency (15-20% per index)
            if target_trades_per_minute > 0.5:  # High frequency target
                per_index_pct = 0.15  # 15% per index = 45% total for 3 indices
            else:
                per_index_pct = 0.20  # 20% per index = 60% total for 3 indices
            
            # Prioritize NIFTY50 and BANKNIFTY (main indices, higher liquidity)
            # Allocate more to them, less to SENSEX
            index_allocation = {
                "NIFTY50": per_index_pct * 1.2,      # 18-24% for NIFTY50
                "BANKNIFTY": per_index_pct * 1.2,    # 18-24% for BANKNIFTY
                "SENSEX": per_index_pct * 0.6        # 9-12% for SENSEX (reduced)
            }
            
            # Place orders for each index if we have available exposure
            for index in self.trading_indices:
                if available_exposure < 1000:  # Minimum order size
                    logger.info(f"[SKIP] {index}: Insufficient exposure (Rs {available_exposure:,.2f})")
                    continue
                
                # Get per-index allocation
                index_pct = index_allocation.get(index, per_index_pct)
                target_order_value = available_exposure * index_pct
                
                price = prices[index]
                # Calculate quantity that fits within target order value
                quantity = max(0.1, target_order_value / price)  # At least 0.1 lot
                
                # Determine direction (alternate or use direction switcher)
                if self.current_direction == TradeDirection.NEUTRAL:
                    side = OrderSide.BUY  # Start with BUY
                elif self.current_direction == TradeDirection.BULLISH:
                    side = OrderSide.BUY
                else:
                    side = OrderSide.SELL
                
                order = Order(
                    symbol=index,
                    side=side,
                    quantity=quantity,
                    order_type=OrderType.MARKET,
                    limit_price=price,
                    client_order_id=f"LIVE_{index}_{int(time.time())}"
                )
                
                # Check compliance
                order_value = price * quantity
                compliance_check = self.compliance_engine.check_trade_compliance(
                    user_id=self.user_id,
                    symbol=index,
                    quantity=quantity,
                    order_value=order_value,
                    user_category=self.user_category
                )
                
                if compliance_check.status == ComplianceStatus.REJECTED:
                    logger.warning(f"[COMPLIANCE] {index} order rejected: {compliance_check.message}")
                    cycle_results["orders_rejected"] += 1
                    continue
                
                # Place order
                cycle_results["orders_placed"] += 1
                result_order = self.leverage_adapter.place_order(order)
                
                if result_order.status == OrderStatus.FILLED:
                    cycle_results["orders_filled"] += 1
                    cycle_results["positions_opened"] += 1
                    
                    # Track trade
                    filled_price = result_order.metadata.get("filled_price", result_order.limit_price or 0.0)
                    trade_record = {
                        "order_id": result_order.client_order_id,
                        "symbol": result_order.symbol,
                        "side": result_order.side.value,
                        "quantity": result_order.quantity,
                        "price": filled_price,
                        "value": filled_price * abs(result_order.quantity),
                        "timestamp": datetime.now().isoformat(),
                        "pnl": 0.0
                    }
                    self.trades_executed.append(trade_record)
                    self.test_results["trades"].append(trade_record)
                    
                    filled_price = result_order.metadata.get("filled_price", result_order.limit_price or 0.0)
                    logger.info(
                        f"[FILLED] {result_order.symbol} {result_order.side.value} "
                        f"{result_order.quantity:.2f} @ Rs {filled_price:,.2f}"
                    )
                    
                    # Check for direction switch recommendation
                    positions = self.leverage_adapter.get_positions()
                    if result_order.symbol in positions:
                        position = positions[result_order.symbol]
                        # Build price history for direction switcher
                        price_history = [position.avg_price, position.current_price]
                        if len(price_history) < 5:
                            # Add some historical prices for trend analysis
                            for i in range(5 - len(price_history)):
                                price_history.insert(0, position.avg_price * (1 - 0.01 * (i + 1)))
                        
                        switch_rec = self.direction_switcher.should_switch_direction(
                            current_direction=self.current_direction,
                            prices=price_history,
                            volumes=None,
                            indicators=None,
                            current_position_pnl=position.unrealized_pnl,
                            position_entry_price=position.avg_price,
                            current_price=position.current_price
                        )
                        
                        if switch_rec:
                            logger.warning(
                                f"[DIRECTION SWITCH] {switch_rec.urgency}: "
                                f"{self.current_direction.value} -> {switch_rec.recommended_direction.value} "
                                f"(confidence: {switch_rec.confidence:.2f})"
                            )
                            self.current_direction = switch_rec.recommended_direction
                
                elif result_order.status == OrderStatus.REJECTED:
                    cycle_results["orders_rejected"] += 1
                    logger.warning(f"[REJECTED] {index}: {result_order.metadata.get('reason', 'Unknown')}")
            
            # Update positions and calculate PnL
            positions = self.leverage_adapter.get_positions()
            self.positions_tracked = positions
            
            total_pnl = sum(pos.unrealized_pnl for pos in positions.values())
            cycle_results["pnl"] = total_pnl
            
            # Close some positions for profit-taking (more aggressive for testing)
            # Close positions more frequently to generate closed trade data
            if total_pnl > 500 or cycle_count % 5 == 0:  # Close if >Rs 500 profit OR every 5 cycles
                for symbol, position in list(positions.items())[:1]:  # Close one position
                    close_order = Order(
                        symbol=symbol,
                        side=OrderSide.SELL if position.side == OrderSide.BUY else OrderSide.BUY,
                        quantity=abs(position.quantity),
                        order_type=OrderType.MARKET,
                        limit_price=position.current_price * 1.01,  # Slight profit
                        client_order_id=f"CLOSE_{symbol}_{int(time.time())}"
                    )
                    
                    result = self.leverage_adapter.place_order(close_order)
                    if result.status == OrderStatus.FILLED:
                        cycle_results["positions_closed"] += 1
                        close_price = result.metadata.get("filled_price", result.limit_price or position.current_price)
                        pnl = (close_price - position.avg_price) * abs(position.quantity)
                        logger.info(f"[CLOSED] {symbol} PnL: Rs {pnl:,.2f}")
                        
                        # Update trade record
                        for trade in self.trades_executed:
                            if trade["symbol"] == symbol and trade["pnl"] == 0.0:
                                trade["pnl"] = pnl
                                break
            
        except Exception as e:
            logger.error(f"[ERROR] Trading cycle failed: {e}", exc_info=True)
            self.test_results["errors"].append(f"Trading cycle: {str(e)}")
        
        return cycle_results
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate comprehensive trading report."""
        try:
            period_end = datetime.now()
            period_start = self.start_time
            
            report = reporting_engine.generate_trading_report(
                user_id=self.user_id,
                period_start=period_start,
                period_end=period_end,
                trades=self.trades_executed,
                positions={symbol: {"unrealized_pnl": pos.unrealized_pnl} for symbol, pos in self.positions_tracked.items()}
            )
            
            # Get leverage statistics
            leverage_stats = self.leverage_adapter.get_statistics()
            
            # Get trading formula guidelines
            guideline = trading_formula_guidelines_engine.get_guideline_for_user(
                user_id=self.user_id,
                user_category=self.user_category,
                vix_level=18.0,  # Simulated VIX
                current_trades_today=len(self.trades_executed)
            )
            
            report_data = {
                "period_start": period_start.isoformat(),
                "period_end": period_end.isoformat(),
                "duration_minutes": (period_end - period_start).total_seconds() / 60,
                "trading_performance": {
                    "total_trades": report.total_trades,
                    "winning_trades": report.winning_trades,
                    "losing_trades": report.losing_trades,
                    "win_rate": report.win_rate,
                    "total_pnl": report.total_pnl,
                    "realized_pnl": report.realized_pnl,
                    "unrealized_pnl": report.unrealized_pnl,
                    "average_win": report.average_win,
                    "average_loss": report.average_loss,
                    "largest_win": report.largest_win,
                    "largest_loss": report.largest_loss,
                    "total_volume": report.total_volume
                },
                "leverage_status": leverage_stats.get("leverage_info", {}),
                "exposure_by_index": leverage_stats.get("exposure_by_index", {}),
                "trading_formula": {
                    "base_trades_per_day": guideline.base_trades_per_day,
                    "current_trades_per_day": guideline.current_trades_per_day,
                    "trades_per_index": guideline.current_trades_per_index
                },
                "positions": {
                    symbol: {
                        "quantity": pos.quantity,
                        "avg_price": pos.avg_price,
                        "current_price": pos.current_price,
                        "unrealized_pnl": pos.unrealized_pnl
                    }
                    for symbol, pos in self.positions_tracked.items()
                }
            }
            
            self.test_results["reports"].append(report_data)
            
            logger.info("\n" + "=" * 80)
            logger.info("TRADING REPORT")
            logger.info("=" * 80)
            logger.info(f"Period: {period_start.strftime('%Y-%m-%d %H:%M')} to {period_end.strftime('%Y-%m-%d %H:%M')}")
            logger.info(f"Duration: {report_data['duration_minutes']:.1f} minutes")
            logger.info(f"Total Trades: {report.total_trades}")
            logger.info(f"Win Rate: {report.win_rate:.2f}%")
            logger.info(f"Total PnL: Rs {report.total_pnl:,.2f}")
            logger.info(f"Realized PnL: Rs {report.realized_pnl:,.2f}")
            logger.info(f"Unrealized PnL: Rs {report.unrealized_pnl:,.2f}")
            logger.info(f"Current Exposure: Rs {leverage_stats.get('leverage_info', {}).get('current_exposure', 0):,.2f}")
            logger.info(f"Exposure Utilization: {leverage_stats.get('leverage_info', {}).get('utilization_percent', 0):.2f}%")
            logger.info("=" * 80)
            
            return report_data
            
        except Exception as e:
            logger.error(f"[ERROR] Report generation failed: {e}", exc_info=True)
            self.test_results["errors"].append(f"Report generation: {str(e)}")
            return {}
    
    def _square_off_all_positions(self):
        """Square off all open positions (called at market close 15:30 IST)."""
        positions = self.leverage_adapter.get_positions()
        if not positions:
            logger.info("[SQUARE-OFF] No positions to square off")
            return
        
        logger.info(f"[SQUARE-OFF] Squaring off {len(positions)} position(s)...")
        squared_count = 0
        
        for symbol, position in positions.items():
            try:
                # Close position by placing opposite order
                close_side = OrderSide.SELL if position.quantity > 0 else OrderSide.BUY
                close_order = Order(
                    symbol=symbol,
                    side=close_side,
                    quantity=abs(position.quantity),
                    order_type=OrderType.MARKET,
                    limit_price=position.current_price,
                    client_order_id=f"SQUARE_OFF_{symbol}_{int(time.time())}"
                )
                
                result = self.leverage_adapter.place_order(close_order)
                if result.status == OrderStatus.FILLED:
                    squared_count += 1
                    close_price = result.metadata.get("filled_price", result.limit_price or position.current_price)
                    pnl = (close_price - position.avg_price) * abs(position.quantity) if position.quantity > 0 else (position.avg_price - close_price) * abs(position.quantity)
                    
                    # Update trade record
                    for trade in self.trades_executed:
                        if trade["symbol"] == symbol and trade.get("pnl", 0) == 0.0:
                            trade["pnl"] = pnl
                            trade["close_price"] = close_price
                            trade["close_timestamp"] = datetime.now().isoformat()
                            break
                    
                    logger.info(f"[SQUARE-OFF] {symbol} @ Rs {close_price:,.2f}, PnL: Rs {pnl:,.2f}")
                else:
                    logger.warning(f"[SQUARE-OFF FAILED] {symbol} - {result.metadata.get('reason', 'Unknown')}")
            except Exception as e:
                logger.error(f"[SQUARE-OFF ERROR] {symbol}: {e}", exc_info=True)
        
        logger.info(f"[SQUARE-OFF] Squared off {squared_count} of {len(positions)} positions")
    
    def run_continuous_test(self, duration_minutes: int = 120):
        """
        Run continuous test for specified duration.
        
        Args:
            duration_minutes: Test duration in minutes (default: 120 for 2 hours)
        """
        logger.info("\n" + "=" * 80)
        logger.info(f"STARTING CONTINUOUS LIVE MARKET TEST")
        logger.info(f"Duration: {duration_minutes} minutes ({duration_minutes/60:.1f} hours)")
        logger.info(f"Start Time: {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}")
        logger.info("=" * 80)
        
        end_time = self.start_time + timedelta(minutes=duration_minutes)
        cycle_count = 0
        # Calculate cycle interval based on trading targets
        from aurum_harmony.engines.trading_targets import TradingTargetsManager
        current_capital = float(self.leverage_adapter.capital)
        target_trades_per_minute = TradingTargetsManager.calculate_trades_per_minute(current_capital)
        
        # Calculate cycle interval to achieve target
        # Aim for 2-3 trades per cycle across 3 indices
        trades_per_cycle = 2.5  # Average
        if target_trades_per_minute > 0:
            cycle_interval_seconds = int((trades_per_cycle / target_trades_per_minute) * 60)
            cycle_interval_seconds = max(15, min(cycle_interval_seconds, 60))  # Between 15s and 60s (high frequency)
            cycle_interval = cycle_interval_seconds / 60  # Convert to minutes
        else:
            cycle_interval = 0.25  # Default: 15 seconds (0.25 minutes)
        
        try:
            # Market close and session end times
            current_date = datetime.now().date()
            market_close_time = datetime.combine(current_date, datetime.min.time().replace(hour=15, minute=30))
            session_end_time = datetime.combine(current_date, datetime.min.time().replace(hour=16, minute=30))
            
            # Adjust end_time to be at most session_end_time (16:30 IST)
            if end_time > session_end_time:
                end_time = session_end_time
                logger.info(f"[SESSION] Session will end at 16:30 IST (1 hour buffer after market close)")
            
            while datetime.now() < end_time:
                current_time = datetime.now()
                
                # Check if market is closed (15:30 IST) - square off positions
                if current_time >= market_close_time and current_time < session_end_time:
                    # Market closed, but session continues until 16:30
                    # Square off all positions immediately
                    if not hasattr(self, '_positions_squared_off'):
                        logger.warning(f"[MARKET CLOSE] Market closed at 15:30 IST. Squaring off all positions...")
                        self._square_off_all_positions()
                        self._positions_squared_off = True
                        logger.info(f"[SESSION] Positions squared off. Session continues until 16:30 IST for reporting/settlement")
                    
                    # After square-off, just wait until session end (no more trading)
                    if current_time < session_end_time:
                        wait_seconds = min(60, (session_end_time - current_time).total_seconds())  # Check every minute
                        if wait_seconds > 0:
                            logger.debug(f"[SESSION] Waiting until 16:30 IST session end... ({wait_seconds:.0f}s remaining)")
                            time.sleep(wait_seconds)
                        continue
                    else:
                        break  # Session ended at 16:30
                
                cycle_count += 1
                logger.info(f"\n--- Trading Cycle #{cycle_count} ---")
                
                # Execute trading cycle
                cycle_results = self.execute_trading_cycle()
                
                # Generate report every 10 cycles (50 minutes)
                if cycle_count % 10 == 0:
                    self.generate_report()
                
                # Wait for next cycle (15-20 seconds for high frequency)
                if datetime.now() < end_time:
                    wait_seconds = min(cycle_interval * 60, (end_time - datetime.now()).total_seconds())
                    # Use 15-20 seconds for high frequency trading
                    wait_seconds = min(wait_seconds, 20)  # Cap at 20 seconds
                    wait_seconds = max(wait_seconds, 15)  # Minimum 15 seconds
                    if wait_seconds > 0:
                        logger.info(f"Waiting {wait_seconds:.1f} seconds until next cycle...")
                        time.sleep(wait_seconds)
                
        except KeyboardInterrupt:
            logger.info("\n[INTERRUPTED] Test stopped by user")
        except Exception as e:
            logger.error(f"[ERROR] Continuous test failed: {e}", exc_info=True)
            self.test_results["errors"].append(f"Continuous test: {str(e)}")
        finally:
            # CRITICAL: Close all positions at end of test (market close / EOD square-off)
            logger.info("\n[EOD] Closing all open positions (End of Day Square-Off)...")
            positions = self.leverage_adapter.get_positions()
            closed_count = 0
            
            for symbol, position in positions.items():
                try:
                    # Close position by placing opposite order
                    close_side = OrderSide.SELL if position.quantity > 0 else OrderSide.BUY
                    close_order = Order(
                        symbol=symbol,
                        side=close_side,
                        quantity=abs(position.quantity),
                        order_type=OrderType.MARKET,
                        limit_price=position.current_price,  # Market order at current price
                        client_order_id=f"EOD_CLOSE_{symbol}_{int(time.time())}"
                    )
                    
                    result = self.leverage_adapter.place_order(close_order)
                    if result.status == OrderStatus.FILLED:
                        closed_count += 1
                        close_price = result.metadata.get("filled_price", result.limit_price or position.current_price)
                        pnl = (close_price - position.avg_price) * abs(position.quantity) if position.quantity > 0 else (position.avg_price - close_price) * abs(position.quantity)
                        
                        # Update trade record with realized PnL
                        for trade in self.trades_executed:
                            if trade["symbol"] == symbol and trade.get("pnl", 0) == 0.0:
                                trade["pnl"] = pnl
                                trade["close_price"] = close_price
                                trade["close_timestamp"] = datetime.now().isoformat()
                                break
                        
                        logger.info(f"[EOD CLOSED] {symbol} @ ₹{close_price:,.2f}, PnL: ₹{pnl:,.2f}")
                    else:
                        logger.warning(f"[EOD FAILED] {symbol} - {result.metadata.get('reason', 'Unknown')}")
                except Exception as e:
                    logger.error(f"[EOD ERROR] Failed to close {symbol}: {e}", exc_info=True)
            
            logger.info(f"[EOD] Closed {closed_count} of {len(positions)} positions")
            
            # Final report
            logger.info("\n[FINAL] Generating final report...")
            final_report = self.generate_report()
            
            # Save results
            self.test_results["end_time"] = datetime.now().isoformat()
            self.test_results["duration_minutes"] = (datetime.now() - self.start_time).total_seconds() / 60
            self.test_results["total_cycles"] = cycle_count
            
            results_file = os.path.join(
                project_root,
                '_local',
                'logs',
                f'live_market_test_results_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
            )
            os.makedirs(os.path.dirname(results_file), exist_ok=True)
            with open(results_file, 'w', encoding='utf-8') as f:
                json.dump(self.test_results, f, indent=2, default=str)
            
            logger.info(f"\n[OK] Test results saved to: {results_file}")
            logger.info("=" * 80)
            
            return self.test_results


if __name__ == "__main__":
    # Run the test
    test = LiveMarketBurnInTest(user_id="live_test_user", user_category="admin")
    
    # Run for 2 hours (120 minutes) - markets open till 15:30 IST
    results = test.run_continuous_test(duration_minutes=120)
    
    # Exit with appropriate code
    sys.exit(0 if len(results.get("errors", [])) == 0 else 1)
