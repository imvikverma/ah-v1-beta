"""
Integration Layer for AurumHarmony Engines

Provides seamless integration between all engines, ensuring they work
together as a cohesive, world-class trading system.
"""

from __future__ import annotations

import logging
from typing import Dict, Any, Optional, List
from datetime import datetime

# Import all engines
from aurum_harmony.engines.trade_execution.trade_execution import (
    TradeExecutor,
    Order,
    OrderStatus,
)
from aurum_harmony.engines.predictive_ai.predictive_ai import PredictiveAIEngine
from aurum_harmony.engines.compliance.compliance_engine import ComplianceEngine
from aurum_harmony.engines.settlement.Settlement_Engine import SettlementEngine
from aurum_harmony.engines.fund_push_pull.fund_push_pull import FundPushPullEngine
from aurum_harmony.engines.notifications.notifications import NotificationEngine, NotificationType, NotificationPriority
from aurum_harmony.engines.reporting.reporting import ReportingEngine
from aurum_harmony.blockchain.blockchain_trade import record_trade_on_chain, TradeRecord
from aurum_harmony.blockchain.blockchain_settlement import record_settlement_on_chain, SettlementRecord

# Configure logging
logger = logging.getLogger(__name__)


class TradingSystemIntegration:
    """
    Central integration layer that orchestrates all engines.
    
    Ensures seamless communication between:
    - Trade execution and compliance
    - Settlement and fund management
    - Reporting and notifications
    - Blockchain recording
    """
    
    def __init__(
        self,
        trade_executor: Optional[TradeExecutor] = None,
        compliance_engine: Optional[ComplianceEngine] = None,
        fund_engine: Optional[FundPushPullEngine] = None,
        notification_engine: Optional[NotificationEngine] = None,
        reporting_engine: Optional[ReportingEngine] = None,
        enable_blockchain: bool = True,
    ):
        """
        Initialize trading system integration.
        
        Args:
            trade_executor: Trade executor instance
            compliance_engine: Compliance engine instance
            fund_engine: Fund management engine instance
            notification_engine: Notification engine instance
            reporting_engine: Reporting engine instance
            enable_blockchain: Enable blockchain recording
        """
        from aurum_harmony.engines.compliance.compliance_engine import compliance_engine as default_compliance
        from aurum_harmony.engines.fund_push_pull.fund_push_pull import fund_engine as default_fund
        from aurum_harmony.engines.notifications.notifications import notifier as default_notifier
        from aurum_harmony.engines.reporting.reporting import reporting_engine as default_reporting
        
        self.trade_executor = trade_executor
        self.compliance_engine = compliance_engine or default_compliance
        self.fund_engine = fund_engine or default_fund
        self.notification_engine = notification_engine or default_notifier
        self.reporting_engine = reporting_engine or default_reporting
        self.enable_blockchain = enable_blockchain
        
        logger.info("TradingSystemIntegration initialized")
    
    def execute_trade_with_compliance(
        self,
        user_id: str,
        symbol: str,
        side: str,
        quantity: float,
        price: float,
        user_category: str = "restricted",
        strategy: str = ""
    ) -> Dict[str, Any]:
        """
        Execute a trade with full compliance and integration checks.
        
        Flow:
        1. Compliance check
        2. Trade execution
        3. Blockchain recording
        4. Notification
        5. Reporting update
        
        Args:
            user_id: User identifier
            symbol: Trading symbol
            side: BUY or SELL
            quantity: Order quantity
            price: Order price
            user_category: User category
            strategy: Trading strategy name
            
        Returns:
            Execution result dictionary
        """
        try:
            order_value = price * quantity
            
            # Step 1: Compliance check
            compliance_check = self.compliance_engine.check_trade_compliance(
                user_id=user_id,
                symbol=symbol,
                quantity=quantity,
                order_value=order_value,
                user_category=user_category
            )
            
            if compliance_check.status != "APPROVED":
                logger.warning(
                    f"Trade rejected by compliance: {user_id}, {symbol} - {compliance_check.message}"
                )
                return {
                    "status": "REJECTED",
                    "reason": "compliance",
                    "message": compliance_check.message,
                    "compliance_check": compliance_check.details,
                }
            
            # Step 2: Execute trade (if executor available)
            order = None
            if self.trade_executor:
                from aurum_harmony.engines.trade_execution.trade_execution import OrderSide, OrderType
                
                order_side = OrderSide.BUY if side.upper() == "BUY" else OrderSide.SELL
                order = self.trade_executor.execute_order(
                    symbol=symbol,
                    side=order_side,
                    quantity=quantity,
                    order_type=OrderType.MARKET,
                    risk_approved=True,
                    reason=strategy
                )
                
                if order.status != OrderStatus.FILLED:
                    return {
                        "status": order.status.value,
                        "reason": order.metadata.get("reason", "Unknown"),
                        "order": order.to_dict() if hasattr(order, 'to_dict') else str(order),
                    }
            
            # Step 3: Record on blockchain
            if self.enable_blockchain and order:
                try:
                    trade_record = TradeRecord(
                        trade_id=order.broker_order_id or order.client_order_id,
                        user_id=user_id,
                        symbol=symbol,
                        side=side.upper(),
                        quantity=quantity,
                        price=price,
                        timestamp=order.metadata.get("filled_at", 0),
                        strategy=strategy,
                        extra={
                            "order_type": order.order_type.value if hasattr(order, 'order_type') else "MARKET",
                            "category": user_category,
                        }
                    )
                    blockchain_result = record_trade_on_chain(trade_record)
                    logger.debug(f"Blockchain recording result: {blockchain_result.get('status')}")
                except Exception as e:
                    logger.error(f"Error recording trade on blockchain: {e}", exc_info=True)
                    # Don't fail the trade if blockchain recording fails
            
            # Step 4: Send notification
            try:
                self.notification_engine.send_notification(
                    user_id=user_id,
                    notification_type=NotificationType.IN_APP,
                    subject=f"Trade Executed: {symbol}",
                    message=f"Your {side} order for {quantity} {symbol} @ ₹{price:,.2f} has been executed.",
                    priority=NotificationPriority.NORMAL,
                    metadata={"order_id": order.broker_order_id if order else None}
                )
            except Exception as e:
                logger.warning(f"Error sending notification: {e}")
            
            # Step 5: Return result
            result = {
                "status": "SUCCESS",
                "order": order.to_dict() if order and hasattr(order, 'to_dict') else None,
                "compliance": "APPROVED",
                "blockchain_recorded": self.enable_blockchain,
            }
            
            logger.info(
                f"Trade executed successfully: {user_id}, {symbol} {side} {quantity} @ ₹{price:,.2f}"
            )
            
            return result
            
        except Exception as e:
            logger.error(f"Error in execute_trade_with_compliance: {e}", exc_info=True)
            return {
                "status": "ERROR",
                "message": str(e)
            }
    
    def process_settlement_with_integration(
        self,
        user_id: str,
        gross_profit: float,
        category: str,
        current_capital: float
    ) -> Dict[str, Any]:
        """
        Process settlement with full integration.
        
        Flow:
        1. Calculate settlement
        2. Update fund balances
        3. Record on blockchain
        4. Generate report
        5. Send notifications
        
        Args:
            user_id: User identifier
            gross_profit: Gross profit amount
            category: User category
            current_capital: Current capital
            
        Returns:
            Settlement result dictionary
        """
        try:
            from aurum_harmony.engines.settlement.Settlement_Engine import settlement_engine
            
            # Step 1: Calculate settlement
            settlement_data = settlement_engine.settle(
                user_id=user_id,
                gross_profit=gross_profit,
                category=category,
                current_capital=current_capital
            )
            
            # Step 2: Update fund balances
            # Net profit is PUSHED from Demat to Savings (withdraw from trading account)
            net_to_savings = settlement_data.get("net_to_savings", 0)
            if net_to_savings > 0:
                self.fund_engine.push_funds(
                    user_id=user_id,
                    amount=net_to_savings,
                    reason="Settlement: Net profit to savings",
                    destination="savings"
                )
            
            # Handle capital increment
            next_capital = settlement_data.get("next_capital", current_capital)
            if next_capital > current_capital:
                increment_amount = next_capital - current_capital
                self.fund_engine.increment_capital(
                    user_id=user_id,
                    current_capital=current_capital,
                    next_capital=next_capital,
                    category=category
                )
            
            # Step 3: Record on blockchain
            if self.enable_blockchain:
                try:
                    settlement_record = SettlementRecord(
                        settlement_id=f"settlement_{user_id}_{int(datetime.now().timestamp())}",
                        trade_id="batch_settlement",
                        status="SUCCESS",
                        timestamp=datetime.now().timestamp(),
                        user_id=user_id,
                        profit=gross_profit,
                        details=settlement_data
                    )
                    blockchain_result = record_settlement_on_chain(settlement_record)
                    logger.debug(f"Blockchain settlement recording result: {blockchain_result.get('status')}")
                except Exception as e:
                    logger.error(f"Error recording settlement on blockchain: {e}", exc_info=True)
            
            # Step 4: Generate report
            try:
                report = self.reporting_engine.generate_settlement_report(
                    user_id=user_id,
                    settlement_data=settlement_data
                )
            except Exception as e:
                logger.warning(f"Error generating settlement report: {e}")
                report = None
            
            # Step 5: Send notification
            try:
                self.notification_engine.send_notification(
                    user_id=user_id,
                    notification_type=NotificationType.EMAIL,
                    subject="Settlement Completed",
                    message=(
                        f"Your settlement has been processed.\n"
                        f"Gross Profit: ₹{gross_profit:,.2f}\n"
                        f"Net to Savings: ₹{net_to_savings:,.2f}\n"
                        f"Next Capital Level: ₹{next_capital:,.2f}"
                    ),
                    priority=NotificationPriority.HIGH,
                    metadata={"settlement_data": settlement_data}
                )
            except Exception as e:
                logger.warning(f"Error sending settlement notification: {e}")
            
            return {
                "status": "SUCCESS",
                "settlement": settlement_data,
                "report": report,
                "blockchain_recorded": self.enable_blockchain,
            }
            
        except Exception as e:
            logger.error(f"Error in process_settlement_with_integration: {e}", exc_info=True)
            return {
                "status": "ERROR",
                "message": str(e)
            }
    
    def get_system_status(self) -> Dict[str, Any]:
        """Get comprehensive system status."""
        return {
            "trade_executor": "available" if self.trade_executor else "not_configured",
            "compliance_engine": self.compliance_engine.get_compliance_report() if self.compliance_engine else None,
            "fund_engine": self.fund_engine.get_statistics() if self.fund_engine else None,
            "notification_engine": self.notification_engine.get_statistics() if self.notification_engine else None,
            "reporting_engine": "available" if self.reporting_engine else "not_configured",
            "blockchain_enabled": self.enable_blockchain,
        }


# Default integration instance
trading_system = TradingSystemIntegration()

__all__ = [
    "TradingSystemIntegration",
    "trading_system",
]

