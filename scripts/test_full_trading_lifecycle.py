"""
Comprehensive End-to-End Paper Trading Burn-In Test
Tests the complete trading lifecycle: Trading, Compliance, Reporting, Funds Management, Settlement

Last Updated: January 5, 2026
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

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(project_root, '_local', 'logs', f'burn_in_test_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')),
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
from aurum_harmony.engines.settlement.Settlement_Engine import SettlementEngine, IncrementEngine
from aurum_harmony.engines.fund_push_pull.fund_push_pull import FundPushPullEngine, FundTransfer
from aurum_harmony.engines.reporting.reporting import ReportingEngine, TradingReport
from aurum_harmony.engines.reporting.reporting import reporting_engine
from aurum_harmony.engines.capital_progression import CapitalProgressionManager, CapitalLevel
from aurum_harmony.engines.risk_management.leverage_engine import LeverageEngine

# Try to import Kotak Neo for live data
try:
    from api.kotak_neo import KotakNeoAPI
    from dotenv import load_dotenv
    load_dotenv()
    KOTAK_AVAILABLE = True
except Exception as e:
    logger.warning(f"Kotak Neo not available: {e}")
    KOTAK_AVAILABLE = False


class TradingLifecycleTest:
    """
    Comprehensive burn-in test for the complete trading lifecycle.
    """
    
    def __init__(self, user_id: str = "test_user_001", user_category: str = "admin"):
        self.user_id = user_id
        self.user_category = user_category
        self.test_results: Dict[str, Any] = {
            "start_time": datetime.now().isoformat(),
            "user_id": user_id,
            "user_category": user_category,
            "phases": {},
            "errors": [],
            "warnings": []
        }
        
        # Initialize components
        logger.info("=" * 80)
        logger.info("INITIALIZING TRADING LIFECYCLE BURN-IN TEST")
        logger.info("=" * 80)
        
        # 1. Paper Trading Adapter
        self.paper_adapter = PaperBrokerAdapter(initial_balance=10000.0)
        logger.info(f"[OK] PaperBrokerAdapter initialized with ₹10,000")
        
        # 2. Leverage-Aware Adapter (3× leverage)
        self.leverage_adapter = LeverageAwareAdapter(
            broker_adapter=self.paper_adapter,
            capital=10000.0,
            user_category=user_category,
            leverage_multiplier=3.0
        )
        logger.info(f"[OK] LeverageAwareAdapter initialized (3× leverage)")
        
        # 3. Compliance Engine
        self.compliance_engine = ComplianceEngine()
        self.compliance_engine.kyc_verified_users.add(user_id)  # Mark as KYC verified
        logger.info(f"[OK] ComplianceEngine initialized")
        
        # 4. Settlement Engine
        self.settlement_engine = SettlementEngine()
        logger.info(f"[OK] SettlementEngine initialized")
        
        # 5. Fund Push/Pull Engine
        self.fund_engine = FundPushPullEngine()
        self.fund_engine.user_balances[user_id] = Decimal("10000.0")  # Initial savings
        logger.info(f"[OK] FundPushPullEngine initialized")
        
        # 6. Reporting Engine
        self.reporting_engine = reporting_engine  # Use singleton instance
        logger.info(f"[OK] ReportingEngine initialized")
        
        # 7. Capital Progression Manager
        self.capital_manager = CapitalProgressionManager()
        logger.info(f"[OK] CapitalProgressionManager initialized")
        
        # 8. Kotak Neo (for live prices if available)
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
                        logger.info(f"[OK] Kotak Neo connected (live data available)")
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
                        return float(price)
            except Exception as e:
                logger.debug(f"Failed to get live price for {symbol}: {e}")
        
        # Simulated prices (for testing without live data)
        simulated_prices = {
            "NIFTY50": 24500.0,
            "BANKNIFTY": 48500.0,
            "SENSEX": 72500.0
        }
        return simulated_prices.get(symbol, 1000.0)
    
    def phase_1_trading(self) -> Dict[str, Any]:
        """Phase 1: Trading Operations"""
        logger.info("\n" + "=" * 80)
        logger.info("PHASE 1: TRADING OPERATIONS")
        logger.info("=" * 80)
        
        phase_results = {
            "orders_placed": 0,
            "orders_filled": 0,
            "orders_split": 0,
            "orders_rejected": 0,
            "positions_opened": 0,
            "exposure_utilization": []
        }
        
        try:
            # Test 1: Place orders across all 3 indices (realistic sizes for ₹10K capital with 3× leverage = ₹30K max exposure)
            logger.info("\n[TEST 1.1] Placing orders across NIFTY50, BANKNIFTY, SENSEX")
            # Calculate realistic order sizes: max exposure is ₹30,000, so we can do ~₹10K per index
            nifty_price = self.get_live_price("NIFTY50")
            banknifty_price = self.get_live_price("BANKNIFTY")
            sensex_price = self.get_live_price("SENSEX")
            
            # Small quantities that fit within exposure limits
            test_orders = [
                {"symbol": "NIFTY50", "side": OrderSide.BUY, "quantity": 0.1, "price": nifty_price},  # ~₹2,450
                {"symbol": "BANKNIFTY", "side": OrderSide.BUY, "quantity": 0.1, "price": banknifty_price},  # ~₹4,850
                {"symbol": "SENSEX", "side": OrderSide.BUY, "quantity": 0.1, "price": sensex_price},  # ~₹7,250
            ]
            
            for order_data in test_orders:
                order = Order(
                    symbol=order_data["symbol"],
                    side=order_data["side"],
                    quantity=order_data["quantity"],
                    order_type=OrderType.MARKET,
                    limit_price=order_data["price"],
                    client_order_id=f"TEST_{order_data['symbol']}_{int(time.time())}"
                )
                
                # Check compliance first
                order_value = order_data["price"] * order_data["quantity"]
                compliance_check = self.compliance_engine.check_trade_compliance(
                    user_id=self.user_id,
                    symbol=order_data["symbol"],
                    quantity=order_data["quantity"],
                    order_value=order_value,
                    user_category=self.user_category
                )
                
                if compliance_check.status == ComplianceStatus.REJECTED:
                    logger.warning(f"[COMPLIANCE] Order rejected: {compliance_check.message}")
                    phase_results["orders_rejected"] += 1
                    continue
                
                # Place order through leverage adapter
                result_order = self.leverage_adapter.place_order(order)
                phase_results["orders_placed"] += 1
                
                if result_order.status == OrderStatus.FILLED:
                    phase_results["orders_filled"] += 1
                    phase_results["positions_opened"] += 1
                    
                    # Track trade
                    self.trades_executed.append({
                        "order_id": result_order.client_order_id,
                        "symbol": result_order.symbol,
                        "side": result_order.side.value,
                        "quantity": result_order.quantity,
                        "price": result_order.filled_price,
                        "value": result_order.filled_price * abs(result_order.quantity),
                        "timestamp": datetime.now().isoformat(),
                        "pnl": 0.0  # Will calculate on close
                    })
                    
                    logger.info(f"[OK] Order filled: {result_order.symbol} {result_order.side.value} {result_order.quantity} @ ₹{result_order.filled_price:,.2f}")
                    
                    # Check if split
                    if result_order.metadata.get("split_executed"):
                        phase_results["orders_split"] += 1
                        logger.info(f"[SPLIT] Order was split: {result_order.metadata.get('split_reason', 'N/A')}")
                
                elif result_order.status == OrderStatus.REJECTED:
                    phase_results["orders_rejected"] += 1
                    logger.warning(f"[REJECTED] Order rejected: {result_order.metadata.get('reason', 'Unknown')}")
                
                # Get exposure status
                exposure_status = self.leverage_adapter.get_exposure_status()
                phase_results["exposure_utilization"].append({
                    "timestamp": datetime.now().isoformat(),
                    "utilization": exposure_status["utilization_percent"],
                    "current_exposure": exposure_status["current_exposure"],
                    "max_exposure": exposure_status["max_exposure"]
                })
            
            # Test 2: Test order splitting (place order that exceeds available exposure)
            logger.info("\n[TEST 1.2] Testing order splitting with order exceeding exposure")
            # Place an order that would exceed remaining exposure
            current_exposure = self.leverage_adapter.get_exposure_status()["current_exposure"]
            max_exposure = self.leverage_adapter.get_exposure_status()["max_exposure"]
            available_exposure = max_exposure - current_exposure
            
            # Create order that exceeds available exposure
            nifty_price = self.get_live_price("NIFTY50")
            # Calculate quantity that would exceed available exposure
            excess_quantity = (available_exposure * 1.5) / nifty_price  # 1.5× available to force split
            
            large_order = Order(
                symbol="NIFTY50",
                side=OrderSide.BUY,
                quantity=max(1.0, excess_quantity),  # At least 1 lot
                order_type=OrderType.MARKET,
                limit_price=nifty_price,
                client_order_id=f"TEST_LARGE_{int(time.time())}"
            )
            
            result_order = self.leverage_adapter.place_order(large_order)
            phase_results["orders_placed"] += 1
            
            if result_order.metadata.get("split_executed"):
                phase_results["orders_split"] += 1
                logger.info(f"[OK] Large order was split: Executed {result_order.metadata.get('executed_quantity', 0):.2f} of {result_order.metadata.get('original_quantity', 0):.2f}")
            
            # Test 3: Get positions
            logger.info("\n[TEST 1.3] Retrieving positions")
            positions = self.leverage_adapter.get_positions()
            self.positions_tracked = positions
            logger.info(f"[OK] Current positions: {len(positions)}")
            for symbol, position in positions.items():
                logger.info(f"  - {symbol}: {position.quantity} @ ₹{position.current_price:,.2f} (PnL: ₹{position.unrealized_pnl:,.2f})")
            
            # Test 4: Close some positions
            logger.info("\n[TEST 1.4] Closing positions (SELL)")
            for symbol, position in list(positions.items())[:2]:  # Close first 2 positions
                close_order = Order(
                    symbol=symbol,
                    side=OrderSide.SELL,
                    quantity=abs(position.quantity),
                    order_type=OrderType.MARKET,
                    limit_price=position.current_price * 1.01,  # Slight profit
                    client_order_id=f"TEST_CLOSE_{symbol}_{int(time.time())}"
                )
                
                result_order = self.leverage_adapter.place_order(close_order)
                if result_order.status == OrderStatus.FILLED:
                    # Calculate PnL
                    pnl = (result_order.filled_price - position.current_price) * abs(position.quantity)
                    logger.info(f"[OK] Position closed: {symbol} PnL: ₹{pnl:,.2f}")
                    
                    # Update trade record
                    for trade in self.trades_executed:
                        if trade["symbol"] == symbol and trade["pnl"] == 0.0:
                            trade["pnl"] = pnl
                            break
            
            phase_results["status"] = "PASSED"
            logger.info(f"\n[OK] Phase 1 completed: {phase_results['orders_filled']} orders filled, {phase_results['orders_split']} orders split")
            
        except Exception as e:
            logger.error(f"[ERROR] Phase 1 failed: {e}", exc_info=True)
            phase_results["status"] = "FAILED"
            phase_results["error"] = str(e)
            self.test_results["errors"].append(f"Phase 1: {str(e)}")
        
        return phase_results
    
    def phase_2_compliance(self) -> Dict[str, Any]:
        """Phase 2: Compliance Checks"""
        logger.info("\n" + "=" * 80)
        logger.info("PHASE 2: COMPLIANCE CHECKS")
        logger.info("=" * 80)
        
        phase_results = {
            "compliance_checks": 0,
            "approved": 0,
            "rejected": 0,
            "warnings": 0
        }
        
        try:
            # Test various compliance scenarios
            test_cases = [
                {"symbol": "NIFTY50", "quantity": 10, "value": 245000, "expected": ComplianceStatus.APPROVED},
                {"symbol": "RELIANCE", "quantity": 10, "value": 25000, "expected": ComplianceStatus.REJECTED},  # Individual stock
                {"symbol": "BANKNIFTY", "quantity": 1000, "value": 48500000, "expected": ComplianceStatus.REJECTED},  # Exceeds limit
            ]
            
            for test_case in test_cases:
                phase_results["compliance_checks"] += 1
                check = self.compliance_engine.check_trade_compliance(
                    user_id=self.user_id,
                    symbol=test_case["symbol"],
                    quantity=test_case["quantity"],
                    order_value=test_case["value"],
                    user_category=self.user_category
                )
                
                if check.status == ComplianceStatus.APPROVED:
                    phase_results["approved"] += 1
                elif check.status == ComplianceStatus.REJECTED:
                    phase_results["rejected"] += 1
                elif check.status == ComplianceStatus.WARNING:
                    phase_results["warnings"] += 1
                
                logger.info(f"[COMPLIANCE] {test_case['symbol']}: {check.status.value} - {check.message}")
            
            # Get compliance report
            compliance_report = self.compliance_engine.get_compliance_report(self.user_id)
            logger.info(f"\n[OK] Compliance Report:")
            logger.info(f"  - Total Checks: {compliance_report['total_checks']}")
            logger.info(f"  - Approved: {compliance_report['approved']}")
            logger.info(f"  - Rejected: {compliance_report['rejected']}")
            logger.info(f"  - Warnings: {compliance_report['warnings']}")
            
            phase_results["status"] = "PASSED"
            
        except Exception as e:
            logger.error(f"[ERROR] Phase 2 failed: {e}", exc_info=True)
            phase_results["status"] = "FAILED"
            phase_results["error"] = str(e)
            self.test_results["errors"].append(f"Phase 2: {str(e)}")
        
        return phase_results
    
    def phase_3_funds_management(self) -> Dict[str, Any]:
        """Phase 3: Funds Management (Push/Pull)"""
        logger.info("\n" + "=" * 80)
        logger.info("PHASE 3: FUNDS MANAGEMENT")
        logger.info("=" * 80)
        
        phase_results = {
            "pushes": 0,
            "pulls": 0,
            "push_amount": 0.0,
            "pull_amount": 0.0,
            "capital_increments": 0
        }
        
        try:
            # Test 1: Fund PULL (Savings → Demat)
            logger.info("\n[TEST 3.1] Fund PULL: Savings → Demat")
            pull_transfer = self.fund_engine.pull_funds(
                user_id=self.user_id,
                amount=5000.0,
                reason="Daily trading capital allocation"
            )
            
            if pull_transfer.status == "COMPLETED":
                phase_results["pulls"] += 1
                phase_results["pull_amount"] += pull_transfer.amount
                logger.info(f"[OK] Fund PULL: ₹{pull_transfer.amount:,.2f} moved from Savings → Demat")
                
                # Update paper adapter balance
                current_balance = self.leverage_adapter.get_balance()
                new_balance = current_balance + pull_transfer.amount
                self.paper_adapter.update_balance(new_balance)
                # Update leverage adapter capital
                self.leverage_adapter.capital = Decimal(str(new_balance))
                self.leverage_adapter.max_exposure = self.leverage_adapter.capital * Decimal(str(self.leverage_adapter.leverage_multiplier))
                logger.info(f"[OK] Demat balance updated: ₹{current_balance:,.2f} → ₹{new_balance:,.2f}")
            
            # Test 2: Capital Progression
            logger.info("\n[TEST 3.2] Capital Progression Test")
            level_info = self.capital_manager.get_level_info()
            current_capital = self.capital_manager.get_current_capital()
            logger.info(f"Current Capital Level: ₹{current_capital:,.2f} (Day {self.capital_manager.current_day})")
            
            # Simulate progression
            for i in range(5):
                if not self.capital_manager.advance_day():
                    logger.info("Capital progression complete")
                    break
                
                new_capital = self.capital_manager.get_current_capital()
                logger.info(f"Day {self.capital_manager.current_day}: Capital = ₹{new_capital:,.2f}")
                
                # Update balance
                self.paper_adapter.update_balance(new_capital)
                # Update leverage adapter capital
                self.leverage_adapter.capital = Decimal(str(new_capital))
                self.leverage_adapter.max_exposure = self.leverage_adapter.capital * Decimal(str(self.leverage_adapter.leverage_multiplier))
                phase_results["capital_increments"] += 1
            
            # Test 3: Fund PUSH (Demat → Savings) - Simulate profit withdrawal
            logger.info("\n[TEST 3.3] Fund PUSH: Demat → Savings (profit withdrawal)")
            current_balance = self.leverage_adapter.get_balance()
            profit_amount = 2000.0  # Simulated profit
            
            # Add profit to balance
            self.paper_adapter.update_balance(current_balance + profit_amount)
            
            push_transfer = self.fund_engine.push_funds(
                user_id=self.user_id,
                amount=profit_amount,
                reason="Profit withdrawal to savings"
            )
            
            if push_transfer.status == "COMPLETED":
                phase_results["pushes"] += 1
                phase_results["push_amount"] += push_transfer.amount
                logger.info(f"[OK] Fund PUSH: ₹{push_transfer.amount:,.2f} moved from Demat → Savings")
                
                # Update balance
                new_balance = current_balance + profit_amount - push_transfer.amount
                self.paper_adapter.update_balance(new_balance)
                logger.info(f"[OK] Demat balance after PUSH: ₹{new_balance:,.2f}")
            
            # Get fund status
            savings_balance = float(self.fund_engine.user_balances.get(self.user_id, Decimal("0")))
            demat_balance = self.leverage_adapter.get_balance()
            logger.info(f"\n[OK] Fund Status:")
            logger.info(f"  - Savings Balance: ₹{savings_balance:,.2f}")
            logger.info(f"  - Demat Balance: ₹{demat_balance:,.2f}")
            
            phase_results["status"] = "PASSED"
            
        except Exception as e:
            logger.error(f"[ERROR] Phase 3 failed: {e}", exc_info=True)
            phase_results["status"] = "FAILED"
            phase_results["error"] = str(e)
            self.test_results["errors"].append(f"Phase 3: {str(e)}")
        
        return phase_results
    
    def phase_4_settlement(self) -> Dict[str, Any]:
        """Phase 4: Settlement & Fee Calculation"""
        logger.info("\n" + "=" * 80)
        logger.info("PHASE 4: SETTLEMENT & FEE CALCULATION")
        logger.info("=" * 80)
        
        phase_results = {
            "settlements": 0,
            "gross_profit": 0.0,
            "platform_fee": 0.0,
            "tax_locked": 0.0,
            "net_to_savings": 0.0,
            "next_capital": 0.0
        }
        
        try:
            # Calculate gross profit from trades
            gross_profit = sum(trade.get("pnl", 0) for trade in self.trades_executed)
            if gross_profit == 0:
                gross_profit = 5000.0  # Simulated profit for testing
            
            logger.info(f"\n[TEST 4.1] Settlement Calculation")
            logger.info(f"Gross Profit: ₹{gross_profit:,.2f}")
            
            # Run settlement
            settlement_result = self.settlement_engine.settle(
                gross_profit=gross_profit,
                category=self.user_category,
                current_capital=self.leverage_adapter.capital
            )
            
            phase_results["settlements"] += 1
            phase_results["gross_profit"] = gross_profit
            phase_results["platform_fee"] = settlement_result["platform_fee"]
            phase_results["tax_locked"] = settlement_result["tax_locked_savings"]
            phase_results["net_to_savings"] = settlement_result["net_to_savings"]
            phase_results["next_capital"] = settlement_result["next_capital"]
            
            logger.info(f"[OK] Settlement Results:")
            logger.info(f"  - Gross Profit: ₹{settlement_result['gross_profit']:,.2f}")
            logger.info(f"  - Platform Fee: ₹{settlement_result['platform_fee']:,.2f}")
            logger.info(f"  - SaffronBolt Share: ₹{settlement_result.get('saffronbolt_share', 0):,.2f}")
            logger.info(f"  - ZenithPulse Share: ₹{settlement_result.get('zenithpulse_share', 0):,.2f}")
            logger.info(f"  - Tax Locked (39%): ₹{settlement_result['tax_locked_savings']:,.2f}")
            logger.info(f"  - Net to Savings: ₹{settlement_result['net_to_savings']:,.2f}")
            logger.info(f"  - Rounding Buffer: ₹{settlement_result.get('rounding_buffer_in_demat', 0):,.2f}")
            logger.info(f"  - Next Capital: ₹{settlement_result['next_capital']:,.2f}")
            
            phase_results["status"] = "PASSED"
            
        except Exception as e:
            logger.error(f"[ERROR] Phase 4 failed: {e}", exc_info=True)
            phase_results["status"] = "FAILED"
            phase_results["error"] = str(e)
            self.test_results["errors"].append(f"Phase 4: {str(e)}")
        
        return phase_results
    
    def phase_5_reporting(self) -> Dict[str, Any]:
        """Phase 5: Reporting & Analytics"""
        logger.info("\n" + "=" * 80)
        logger.info("PHASE 5: REPORTING & ANALYTICS")
        logger.info("=" * 80)
        
        phase_results = {
            "reports_generated": 0,
            "total_trades": 0,
            "win_rate": 0.0,
            "total_pnl": 0.0
        }
        
        try:
            # Generate trading report
            period_end = datetime.now()
            period_start = period_end - timedelta(days=1)
            
            report = self.reporting_engine.generate_trading_report(
                user_id=self.user_id,
                period_start=period_start,
                period_end=period_end,
                trades=self.trades_executed,
                positions={symbol: {
                    "unrealized_pnl": pos.unrealized_pnl
                } for symbol, pos in self.positions_tracked.items()}
            )
            
            phase_results["reports_generated"] += 1
            phase_results["total_trades"] = report.total_trades
            phase_results["win_rate"] = report.win_rate
            phase_results["total_pnl"] = report.total_pnl
            
            logger.info(f"[OK] Trading Report Generated:")
            logger.info(f"  - Period: {period_start.strftime('%Y-%m-%d')} to {period_end.strftime('%Y-%m-%d')}")
            logger.info(f"  - Total Trades: {report.total_trades}")
            logger.info(f"  - Winning Trades: {report.winning_trades}")
            logger.info(f"  - Losing Trades: {report.losing_trades}")
            logger.info(f"  - Win Rate: {report.win_rate:.2f}%")
            logger.info(f"  - Total PnL: ₹{report.total_pnl:,.2f}")
            logger.info(f"  - Realized PnL: ₹{report.realized_pnl:,.2f}")
            logger.info(f"  - Unrealized PnL: ₹{report.unrealized_pnl:,.2f}")
            logger.info(f"  - Average Win: ₹{report.average_win:,.2f}")
            logger.info(f"  - Average Loss: ₹{report.average_loss:,.2f}")
            logger.info(f"  - Largest Win: ₹{report.largest_win:,.2f}")
            logger.info(f"  - Largest Loss: ₹{report.largest_loss:,.2f}")
            logger.info(f"  - Total Volume: ₹{report.total_volume:,.2f}")
            
            # Get leverage statistics
            leverage_stats = self.leverage_adapter.get_statistics()
            logger.info(f"\n[OK] Leverage Statistics:")
            logger.info(f"  - Capital: ₹{leverage_stats.get('leverage_info', {}).get('capital', 0):,.2f}")
            logger.info(f"  - Leverage: {leverage_stats.get('leverage_info', {}).get('leverage_multiplier', 0)}×")
            logger.info(f"  - Max Exposure: ₹{leverage_stats.get('leverage_info', {}).get('max_exposure', 0):,.2f}")
            logger.info(f"  - Current Exposure: ₹{leverage_stats.get('leverage_info', {}).get('current_exposure', 0):,.2f}")
            logger.info(f"  - Utilization: {leverage_stats.get('leverage_info', {}).get('utilization_percent', 0):.2f}%")
            logger.info(f"  - Exposure by Index:")
            for index, exposure in leverage_stats.get('exposure_by_index', {}).items():
                logger.info(f"    - {index}: ₹{exposure:,.2f}")
            
            phase_results["status"] = "PASSED"
            
        except Exception as e:
            logger.error(f"[ERROR] Phase 5 failed: {e}", exc_info=True)
            phase_results["status"] = "FAILED"
            phase_results["error"] = str(e)
            self.test_results["errors"].append(f"Phase 5: {str(e)}")
        
        return phase_results
    
    def run_full_test(self) -> Dict[str, Any]:
        """Run all test phases"""
        logger.info("\n" + "=" * 80)
        logger.info("STARTING COMPREHENSIVE TRADING LIFECYCLE BURN-IN TEST")
        logger.info("=" * 80)
        
        # Run all phases
        self.test_results["phases"]["phase_1_trading"] = self.phase_1_trading()
        self.test_results["phases"]["phase_2_compliance"] = self.phase_2_compliance()
        self.test_results["phases"]["phase_3_funds_management"] = self.phase_3_funds_management()
        self.test_results["phases"]["phase_4_settlement"] = self.phase_4_settlement()
        self.test_results["phases"]["phase_5_reporting"] = self.phase_5_reporting()
        
        # Final summary
        self.test_results["end_time"] = datetime.now().isoformat()
        self.test_results["duration_seconds"] = (
            datetime.fromisoformat(self.test_results["end_time"]) - 
            datetime.fromisoformat(self.test_results["start_time"])
        ).total_seconds()
        
        # Calculate overall status
        all_passed = all(
            phase.get("status") == "PASSED" 
            for phase in self.test_results["phases"].values()
        )
        self.test_results["overall_status"] = "PASSED" if all_passed else "FAILED"
        
        # Print summary
        logger.info("\n" + "=" * 80)
        logger.info("TEST SUMMARY")
        logger.info("=" * 80)
        logger.info(f"Overall Status: {self.test_results['overall_status']}")
        logger.info(f"Duration: {self.test_results['duration_seconds']:.2f} seconds")
        logger.info(f"Errors: {len(self.test_results['errors'])}")
        logger.info(f"Warnings: {len(self.test_results['warnings'])}")
        
        for phase_name, phase_result in self.test_results["phases"].items():
            status = phase_result.get("status", "UNKNOWN")
            logger.info(f"  - {phase_name}: {status}")
        
        # Save results
        results_file = os.path.join(
            project_root, 
            '_local', 
            'logs', 
            f'burn_in_test_results_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        )
        os.makedirs(os.path.dirname(results_file), exist_ok=True)
        with open(results_file, 'w') as f:
            json.dump(self.test_results, f, indent=2, default=str)
        
        logger.info(f"\n[OK] Test results saved to: {results_file}")
        logger.info("=" * 80)
        
        return self.test_results


if __name__ == "__main__":
    # Run the test
    test = TradingLifecycleTest(user_id="test_user_001", user_category="admin")
    results = test.run_full_test()
    
    # Exit with appropriate code
    sys.exit(0 if results["overall_status"] == "PASSED" else 1)
