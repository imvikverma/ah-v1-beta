"""
Reporting Engine for AurumHarmony

Generates comprehensive trading reports, analytics, and insights.
"""

from __future__ import annotations

import logging
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta
from decimal import Decimal

# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class TradingReport:
    """Trading performance report."""
    user_id: str
    period_start: datetime
    period_end: datetime
    total_trades: int
    winning_trades: int
    losing_trades: int
    total_pnl: float
    realized_pnl: float
    unrealized_pnl: float
    win_rate: float
    average_win: float
    average_loss: float
    largest_win: float
    largest_loss: float
    total_volume: float
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


class ReportingEngine:
    """
    Comprehensive reporting and analytics engine.
    
    Generates:
    - Trading performance reports
    - P&L analysis
    - Risk metrics
    - Settlement reports
    - Compliance reports
    """
    
    def __init__(self):
        """Initialize reporting engine."""
        self.report_cache: Dict[str, TradingReport] = {}
        logger.info("ReportingEngine initialized")
    
    def generate_trading_report(
        self,
        user_id: str,
        period_start: datetime,
        period_end: datetime,
        trades: List[Dict[str, Any]],
        positions: Optional[Dict[str, Any]] = None
    ) -> TradingReport:
        """
        Generate comprehensive trading report.
        
        Args:
            user_id: User identifier
            period_start: Report period start
            period_end: Report period end
            trades: List of trade records
            positions: Current positions (optional)
            
        Returns:
            TradingReport object
        """
        try:
            if not trades:
                return TradingReport(
                    user_id=user_id,
                    period_start=period_start,
                    period_end=period_end,
                    total_trades=0,
                    winning_trades=0,
                    losing_trades=0,
                    total_pnl=0.0,
                    realized_pnl=0.0,
                    unrealized_pnl=0.0,
                    win_rate=0.0,
                    average_win=0.0,
                    average_loss=0.0,
                    largest_win=0.0,
                    largest_loss=0.0,
                    total_volume=0.0,
                )
            
            # Calculate metrics
            total_trades = len(trades)
            winning_trades = sum(1 for t in trades if t.get("pnl", 0) > 0)
            losing_trades = sum(1 for t in trades if t.get("pnl", 0) < 0)
            
            pnls = [t.get("pnl", 0) for t in trades]
            total_pnl = sum(pnls)
            realized_pnl = sum(p for p in pnls if p != 0)  # Only closed positions
            
            # Calculate unrealized P&L from positions
            unrealized_pnl = 0.0
            if positions:
                unrealized_pnl = sum(
                    pos.get("unrealized_pnl", 0) for pos in positions.values()
                )
            
            win_rate = (winning_trades / total_trades * 100) if total_trades > 0 else 0.0
            
            winning_pnls = [p for p in pnls if p > 0]
            losing_pnls = [p for p in pnls if p < 0]
            
            average_win = sum(winning_pnls) / len(winning_pnls) if winning_pnls else 0.0
            average_loss = sum(losing_pnls) / len(losing_pnls) if losing_pnls else 0.0
            largest_win = max(winning_pnls) if winning_pnls else 0.0
            largest_loss = min(losing_pnls) if losing_pnls else 0.0
            
            total_volume = sum(t.get("value", 0) for t in trades)
            
            report = TradingReport(
                user_id=user_id,
                period_start=period_start,
                period_end=period_end,
                total_trades=total_trades,
                winning_trades=winning_trades,
                losing_trades=losing_trades,
                total_pnl=total_pnl,
                realized_pnl=realized_pnl,
                unrealized_pnl=unrealized_pnl,
                win_rate=win_rate,
                average_win=average_win,
                average_loss=average_loss,
                largest_win=largest_win,
                largest_loss=largest_loss,
                total_volume=total_volume,
                metadata={
                    "generated_at": datetime.now().isoformat(),
                    "period_days": (period_end - period_start).days,
                }
            )
            
            # Cache report
            cache_key = f"{user_id}_{period_start.date()}_{period_end.date()}"
            self.report_cache[cache_key] = report
            
            logger.info(
                f"Trading report generated for {user_id}: "
                f"{total_trades} trades, P&L: ₹{total_pnl:,.2f}, Win rate: {win_rate:.1f}%"
            )
            
            return report
            
        except Exception as e:
            logger.error(f"Error generating trading report: {e}", exc_info=True)
            raise
    
    def generate_settlement_report(
        self,
        user_id: str,
        settlement_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Generate settlement report.
        
        Args:
            user_id: User identifier
            settlement_data: Settlement calculation data
            
        Returns:
            Settlement report dictionary
        """
        try:
            report = {
                "user_id": user_id,
                "settlement_date": datetime.now().isoformat(),
                "gross_profit": settlement_data.get("gross_profit", 0),
                "platform_fee": settlement_data.get("platform_fee", 0),
                "saffronbolt_share": settlement_data.get("saffronbolt_share", 0),
                "zenithpulse_share": settlement_data.get("zenithpulse_share", 0),
                "tax_locked": settlement_data.get("tax_locked_savings", 0),
                "net_to_savings": settlement_data.get("net_to_savings", 0),
                "rounding_buffer": settlement_data.get("rounding_buffer_in_demat", 0),
                "current_capital": settlement_data.get("current_capital", 0),
                "next_capital": settlement_data.get("next_capital", 0),
                "category": settlement_data.get("category", "unknown"),
            }
            
            logger.info(f"Settlement report generated for {user_id}")
            return report
            
        except Exception as e:
            logger.error(f"Error generating settlement report: {e}", exc_info=True)
            raise
    
    def generate_risk_report(
        self,
        user_id: str,
        risk_metrics: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Generate risk analysis report.
        
        Args:
            user_id: User identifier
            risk_metrics: Risk engine metrics
            
        Returns:
            Risk report dictionary
        """
        try:
            report = {
                "user_id": user_id,
                "report_date": datetime.now().isoformat(),
                "current_open_trades": risk_metrics.get("current_open_trades", 0),
                "max_open_trades": risk_metrics.get("max_open_trades", 0),
                "daily_pnl": risk_metrics.get("daily_pnl", 0),
                "max_daily_loss": risk_metrics.get("max_daily_loss", 0),
                "daily_trade_count": risk_metrics.get("daily_trade_count", 0),
                "risk_utilization": {
                    "trades": (risk_metrics.get("current_open_trades", 0) / 
                              max(risk_metrics.get("max_open_trades", 1), 1) * 100),
                    "loss": abs(risk_metrics.get("daily_pnl", 0) / 
                               max(risk_metrics.get("max_daily_loss", 1), 1) * 100),
                }
            }
            
            logger.info(f"Risk report generated for {user_id}")
            return report
            
        except Exception as e:
            logger.error(f"Error generating risk report: {e}", exc_info=True)
            raise
    
    def get_cached_report(self, user_id: str, period_start: datetime, period_end: datetime) -> Optional[TradingReport]:
        """Get cached report if available."""
        cache_key = f"{user_id}_{period_start.date()}_{period_end.date()}"
        return self.report_cache.get(cache_key)
    
    def clear_cache(self, user_id: Optional[str] = None) -> None:
        """Clear report cache."""
        if user_id:
            keys_to_remove = [k for k in self.report_cache.keys() if k.startswith(f"{user_id}_")]
            for key in keys_to_remove:
                del self.report_cache[key]
            logger.debug(f"Cleared cache for user {user_id}")
        else:
            self.report_cache.clear()
            logger.debug("Cleared all report cache")


# Default instance
reporting_engine = ReportingEngine()

__all__ = [
    "ReportingEngine",
    "TradingReport",
    "reporting_engine",
]
