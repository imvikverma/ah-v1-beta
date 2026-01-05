"""
Trading Targets by Capital Level
Defines target trades per day per capital level as guidelines (not hard stops)
"""

from dataclasses import dataclass
from typing import Dict


@dataclass
class CapitalTradingTargets:
    """Trading targets for a specific capital level."""
    capital: float
    total_trades_per_day: int
    trades_per_index: int  # Average across 3 indices
    trades_per_index_per_day: Dict[str, int]  # Per index breakdown
    
    def __post_init__(self):
        """Calculate per-index targets if not provided."""
        if not self.trades_per_index_per_day:
            # Distribute evenly across 3 indices
            base = self.trades_per_index
            self.trades_per_index_per_day = {
                "NIFTY50": base,
                "BANKNIFTY": base,
                "SENSEX": base
            }


class TradingTargetsManager:
    """
    Manages trading targets by capital level.
    
    Targets (guidelines, not hard stops):
    - ₹10,000: 27 trades/day (~9 per index)
    - ₹50,000: 45 trades/day (~15 per index)
    - ₹1,00,000: 90 trades/day (~30 per index)
    - ₹5,00,000: 150 trades/day (~50 per index)
    - ₹15,00,000: 180 trades/day (~60 per index)
    """
    
    TARGETS = [
        CapitalTradingTargets(
            capital=10000.0,
            total_trades_per_day=27,
            trades_per_index=9,
            trades_per_index_per_day={}
        ),
        CapitalTradingTargets(
            capital=50000.0,
            total_trades_per_day=45,
            trades_per_index=15,
            trades_per_index_per_day={}
        ),
        CapitalTradingTargets(
            capital=100000.0,
            total_trades_per_day=90,
            trades_per_index=30,
            trades_per_index_per_day={}
        ),
        CapitalTradingTargets(
            capital=500000.0,
            total_trades_per_day=150,
            trades_per_index=50,
            trades_per_index_per_day={}
        ),
        CapitalTradingTargets(
            capital=1500000.0,
            total_trades_per_day=180,
            trades_per_index=60,
            trades_per_index_per_day={}
        ),
    ]
    
    @classmethod
    def get_targets_for_capital(cls, capital: float) -> CapitalTradingTargets:
        """
        Get trading targets for a specific capital level.
        
        Args:
            capital: Capital amount
            
        Returns:
            CapitalTradingTargets for the capital level
        """
        # Find matching target (exact match or closest)
        for target in cls.TARGETS:
            if target.capital == capital:
                return target
        
        # Find closest target
        closest = min(cls.TARGETS, key=lambda t: abs(t.capital - capital))
        return closest
    
    @classmethod
    def get_target_trades_per_day(cls, capital: float) -> int:
        """Get target total trades per day for capital level."""
        targets = cls.get_targets_for_capital(capital)
        return targets.total_trades_per_day
    
    @classmethod
    def get_target_trades_per_index(cls, capital: float) -> int:
        """Get target trades per index per day for capital level."""
        targets = cls.get_targets_for_capital(capital)
        return targets.trades_per_index
    
    @classmethod
    def get_target_trades_per_index_breakdown(cls, capital: float) -> Dict[str, int]:
        """Get target trades per index breakdown for capital level."""
        targets = cls.get_targets_for_capital(capital)
        return targets.trades_per_index_per_day
    
    @classmethod
    def calculate_trades_per_hour(cls, capital: float, trading_hours: float = 6.25) -> float:
        """
        Calculate target trades per hour.
        
        Args:
            capital: Capital amount
            trading_hours: Trading hours per day (default: 6.25 hours = 09:15-15:30 IST)
            
        Returns:
            Target trades per hour
        """
        total_trades = cls.get_target_trades_per_day(capital)
        return total_trades / trading_hours
    
    @classmethod
    def calculate_trades_per_minute(cls, capital: float, trading_hours: float = 6.25) -> float:
        """
        Calculate target trades per minute.
        
        Args:
            capital: Capital amount
            trading_hours: Trading hours per day
            
        Returns:
            Target trades per minute
        """
        trades_per_hour = cls.calculate_trades_per_hour(capital, trading_hours)
        return trades_per_hour / 60
    
    @classmethod
    def get_all_targets_summary(cls) -> Dict:
        """Get summary of all trading targets."""
        return {
            "targets": [
                {
                    "capital": t.capital,
                    "total_trades_per_day": t.total_trades_per_day,
                    "trades_per_index": t.trades_per_index,
                    "trades_per_hour": cls.calculate_trades_per_hour(t.capital),
                    "trades_per_minute": cls.calculate_trades_per_minute(t.capital)
                }
                for t in cls.TARGETS
            ],
            "trading_hours_per_day": 6.25,
            "indices": ["NIFTY50", "BANKNIFTY", "SENSEX"]
        }
