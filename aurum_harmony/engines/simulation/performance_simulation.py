"""
Performance Simulation Engine for AurumHarmony

Implements 22-day trading simulation based on verified performance data
from 22-Day_Simulation.md (verified 05 Dec 2025).

This module validates system performance against expected metrics.
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
class SimulationMetrics:
    """Performance metrics from 22-day simulation."""
    category: str
    starting_capital: float
    trades_per_day: int
    win_rate: float  # Percentage (55-58%)
    gross_profit_22days: float
    net_profit_22days: float
    monthly_net_profit: float
    annual_net_profit: float
    sharpe_ratio: float = 3.8
    max_drawdown: float = 2.1
    capital_efficiency: float = 0.0  # Monthly net return %


class PerformanceSimulation:
    """
    Performance simulation engine based on 22-day verified data.
    
    Verified Metrics (05 Dec 2025):
    - Win rate: 55-58%
    - Sharpe ratio: 3.8
    - Max drawdown: 2.1%
    - Capital efficiency: 168-270% monthly net return
    """
    
    # Verified 22-day simulation data
    VERIFIED_METRICS = {
        "NGD": SimulationMetrics(
            category="NGD",
            starting_capital=5000.0,
            trades_per_day=18,
            win_rate=55.0,
            gross_profit_22days=65340.0,
            net_profit_22days=15668.0,
            monthly_net_profit=58500.0,
            annual_net_profit=702000.0,
            capital_efficiency=1170.0  # 58500 / 5000 * 100
        ),
        "restricted": SimulationMetrics(
            category="restricted",
            starting_capital=10000.0,
            trades_per_day=27,
            win_rate=55.0,
            gross_profit_22days=87318.0,
            net_profit_22days=10793.0,
            monthly_net_profit=216000.0,
            annual_net_profit=2592000.0,
            capital_efficiency=2160.0  # 216000 / 10000 * 100
        ),
        "semi": SimulationMetrics(
            category="semi",
            starting_capital=10000.0,
            trades_per_day=27,
            win_rate=55.0,
            gross_profit_22days=87318.0,
            net_profit_22days=25715.0,
            monthly_net_profit=270000.0,
            annual_net_profit=3240000.0,
            capital_efficiency=2700.0  # 270000 / 10000 * 100
        ),
        "admin": SimulationMetrics(
            category="admin",
            starting_capital=500000.0,
            trades_per_day=180,
            win_rate=58.0,
            gross_profit_22days=1161600.0,
            net_profit_22days=457718.0,
            monthly_net_profit=1800000.0,  # 18L+
            annual_net_profit=21600000.0,  # 2.16Cr+
            capital_efficiency=360.0  # 1800000 / 500000 * 100
        ),
    }
    
    def __init__(self):
        """Initialize performance simulation engine."""
        logger.info("PerformanceSimulation initialized with verified 22-day metrics")
    
    def get_expected_metrics(self, category: str) -> Optional[SimulationMetrics]:
        """
        Get expected performance metrics for a category.
        
        Args:
            category: User category (NGD, restricted, semi, admin)
            
        Returns:
            SimulationMetrics or None if category not found
        """
        return self.VERIFIED_METRICS.get(category)
    
    def validate_performance(
        self,
        category: str,
        actual_trades_per_day: int,
        actual_win_rate: float,
        actual_monthly_net: float,
        actual_sharpe: Optional[float] = None,
        actual_drawdown: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Validate actual performance against expected metrics.
        
        Args:
            category: User category
            actual_trades_per_day: Actual trades per day
            actual_win_rate: Actual win rate percentage
            actual_monthly_net: Actual monthly net profit
            actual_sharpe: Actual Sharpe ratio (optional)
            actual_drawdown: Actual max drawdown (optional)
            
        Returns:
            Validation result dictionary
        """
        expected = self.get_expected_metrics(category)
        if not expected:
            return {
                "valid": False,
                "error": f"Category {category} not found in verified metrics"
            }
        
        # Calculate deviations
        trades_deviation = ((actual_trades_per_day - expected.trades_per_day) / expected.trades_per_day * 100) if expected.trades_per_day > 0 else 0
        win_rate_deviation = actual_win_rate - expected.win_rate
        profit_deviation = ((actual_monthly_net - expected.monthly_net_profit) / expected.monthly_net_profit * 100) if expected.monthly_net_profit > 0 else 0
        
        # Validation thresholds (allow ±20% deviation)
        trades_valid = abs(trades_deviation) <= 20
        win_rate_valid = abs(win_rate_deviation) <= 5  # ±5% win rate tolerance
        profit_valid = abs(profit_deviation) <= 20  # ±20% profit tolerance
        
        sharpe_valid = True
        if actual_sharpe is not None:
            sharpe_valid = actual_sharpe >= 3.0  # Should be close to 3.8
        
        drawdown_valid = True
        if actual_drawdown is not None:
            drawdown_valid = actual_drawdown <= 3.0  # Should be close to 2.1%
        
        overall_valid = trades_valid and win_rate_valid and profit_valid and sharpe_valid and drawdown_valid
        
        return {
            "valid": overall_valid,
            "category": category,
            "expected": {
                "trades_per_day": expected.trades_per_day,
                "win_rate": expected.win_rate,
                "monthly_net": expected.monthly_net_profit,
                "sharpe": expected.sharpe_ratio,
                "drawdown": expected.max_drawdown,
            },
            "actual": {
                "trades_per_day": actual_trades_per_day,
                "win_rate": actual_win_rate,
                "monthly_net": actual_monthly_net,
                "sharpe": actual_sharpe,
                "drawdown": actual_drawdown,
            },
            "deviations": {
                "trades_per_day": f"{trades_deviation:+.1f}%",
                "win_rate": f"{win_rate_deviation:+.1f}%",
                "monthly_net": f"{profit_deviation:+.1f}%",
            },
            "validation": {
                "trades": trades_valid,
                "win_rate": win_rate_valid,
                "profit": profit_valid,
                "sharpe": sharpe_valid,
                "drawdown": drawdown_valid,
            },
        }
    
    def get_performance_targets(self, category: str) -> Dict[str, Any]:
        """
        Get performance targets for a category.
        
        Args:
            category: User category
            
        Returns:
            Performance targets dictionary
        """
        expected = self.get_expected_metrics(category)
        if not expected:
            return {}
        
        return {
            "category": category,
            "starting_capital": expected.starting_capital,
            "target_trades_per_day": expected.trades_per_day,
            "target_win_rate": expected.win_rate,
            "target_monthly_net": expected.monthly_net_profit,
            "target_annual_net": expected.annual_net_profit,
            "target_sharpe": expected.sharpe_ratio,
            "target_max_drawdown": expected.max_drawdown,
            "target_capital_efficiency": expected.capital_efficiency,
        }
    
    def calculate_expected_profit(
        self,
        category: str,
        days: int = 22,
        actual_trades: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Calculate expected profit for a given period.
        
        Args:
            category: User category
            days: Number of trading days
            actual_trades: Actual number of trades (if different from expected)
            
        Returns:
            Expected profit calculation
        """
        expected = self.get_expected_metrics(category)
        if not expected:
            return {}
        
        trades_per_day = actual_trades or expected.trades_per_day
        total_trades = trades_per_day * days
        
        # Calculate expected profit per trade
        profit_per_trade_22days = expected.net_profit_22days / (expected.trades_per_day * 22)
        expected_profit = profit_per_trade_22days * total_trades
        
        # Scale to period
        if days == 22:
            expected_profit = expected.net_profit_22days
        elif days == 30:
            expected_profit = expected.monthly_net_profit
        else:
            # Interpolate
            daily_profit = expected.net_profit_22days / 22
            expected_profit = daily_profit * days
        
        return {
            "category": category,
            "period_days": days,
            "trades_per_day": trades_per_day,
            "total_trades": total_trades,
            "expected_profit": expected_profit,
            "expected_win_rate": expected.win_rate,
            "profit_per_trade": profit_per_trade_22days,
        }


# Default instance
performance_simulation = PerformanceSimulation()

__all__ = [
    "PerformanceSimulation",
    "SimulationMetrics",
    "performance_simulation",
]

