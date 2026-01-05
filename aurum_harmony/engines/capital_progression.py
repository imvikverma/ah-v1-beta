"""
Capital Progression Manager
Manages capital progression schedule for paper trading tests
"""

from datetime import datetime, timedelta
from typing import Dict, Optional
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)


@dataclass
class CapitalLevel:
    """Represents a capital level in the progression"""
    capital: float
    days: int
    start_day: int
    end_day: int


class CapitalProgressionManager:
    """
    Manages capital progression schedule for testing.
    
    Based on rules.md:
    - Capital amounts are BASE capital (not including leverage)
    - Leverage: 3× (all tiers except NGD 1.5×)
    - With 3× leverage, max exposure = capital × 3
    
    User's Test Schedule (5 days per level):
    - Day 1-5: ₹10,000 (base) → ₹30,000 max exposure with 3× leverage
    - Day 6-10: ₹50,000 (base) → ₹1,50,000 max exposure with 3× leverage
    - Day 11-15: ₹1,00,000 (base) → ₹3,00,000 max exposure with 3× leverage
    - Day 16-20: ₹5,00,000 (base) → ₹15,00,000 max exposure with 3× leverage
    - Day 21-25: ₹15,00,000 (base) → ₹45,00,000 max exposure with 3× leverage
    
    Note: The "30% leverage margin" in rules.md refers to margin requirements
    for options trading (typically 30-40% of notional), not a reduction in capital.
    The capital amounts listed are the BASE trading capital.
    """
    
    PROGRESSION_SCHEDULE = [
        CapitalLevel(capital=10000.0, days=5, start_day=1, end_day=5),
        CapitalLevel(capital=50000.0, days=5, start_day=6, end_day=10),
        CapitalLevel(capital=100000.0, days=5, start_day=11, end_day=15),
        CapitalLevel(capital=500000.0, days=5, start_day=16, end_day=20),
        CapitalLevel(capital=1500000.0, days=5, start_day=21, end_day=25),
    ]
    
    # Leverage multiplier (from rules.md: 3× for all tiers except NGD 1.5×)
    LEVERAGE_MULTIPLIER = 3.0
    
    def __init__(self, start_date: Optional[datetime] = None):
        """
        Initialize capital progression manager.
        
        Args:
            start_date: Start date for the progression. If None, uses current date.
        """
        self.start_date = start_date or datetime.now()
        self.current_day = 1
        self.total_days = sum(level.days for level in self.PROGRESSION_SCHEDULE)
        logger.info(f"Capital Progression Manager initialized. Start date: {self.start_date.date()}")
        logger.info(f"Total test duration: {self.total_days} days")
    
    def get_capital_for_day(self, day: int) -> float:
        """
        Get capital amount for a specific day.
        
        Args:
            day: Day number (1-based)
            
        Returns:
            Capital amount for that day
        """
        if day < 1 or day > self.total_days:
            raise ValueError(f"Day must be between 1 and {self.total_days}, got: {day}")
        
        for level in self.PROGRESSION_SCHEDULE:
            if level.start_day <= day <= level.end_day:
                return level.capital
        
        # Fallback to last level
        return self.PROGRESSION_SCHEDULE[-1].capital
    
    def get_current_capital(self) -> float:
        """
        Get capital for current day.
        
        Returns:
            Current capital amount (BASE capital, before leverage)
        """
        return self.get_capital_for_day(self.current_day)
    
    def get_max_exposure(self, day: Optional[int] = None) -> float:
        """
        Get maximum exposure for a day (capital × leverage).
        
        Args:
            day: Day number (None for current day)
            
        Returns:
            Maximum exposure with leverage applied
        """
        capital = self.get_capital_for_day(day) if day else self.get_current_capital()
        return capital * self.LEVERAGE_MULTIPLIER
    
    def get_level_info(self, day: Optional[int] = None) -> Dict:
        """
        Get information about current or specified day's level.
        
        Args:
            day: Day number (None for current day)
            
        Returns:
            Dictionary with level information including leverage calculations
        """
        if day is None:
            day = self.current_day
        
        capital = self.get_capital_for_day(day)
        max_exposure = self.get_max_exposure(day)
        
        for level in self.PROGRESSION_SCHEDULE:
            if level.start_day <= day <= level.end_day:
                return {
                    "day": day,
                    "capital": capital,
                    "capital_note": "Base capital (before leverage)",
                    "leverage_multiplier": self.LEVERAGE_MULTIPLIER,
                    "max_exposure": max_exposure,
                    "max_exposure_note": f"Maximum exposure with {self.LEVERAGE_MULTIPLIER}× leverage",
                    "level_start": level.start_day,
                    "level_end": level.end_day,
                    "days_in_level": level.days,
                    "days_remaining_in_level": level.end_day - day + 1,
                    "next_level_capital": self._get_next_level_capital(level),
                    "progress_percent": ((day - level.start_day + 1) / level.days) * 100,
                }
        
        return {
            "day": day,
            "capital": capital,
            "capital_note": "Base capital (before leverage)",
            "leverage_multiplier": self.LEVERAGE_MULTIPLIER,
            "max_exposure": max_exposure,
            "max_exposure_note": f"Maximum exposure with {self.LEVERAGE_MULTIPLIER}× leverage",
            "level_start": self.total_days,
            "level_end": self.total_days,
            "days_in_level": 0,
            "days_remaining_in_level": 0,
            "next_level_capital": None,
            "progress_percent": 100.0,
        }
    
    def _get_next_level_capital(self, current_level: CapitalLevel) -> Optional[float]:
        """Get capital for next level"""
        current_index = self.PROGRESSION_SCHEDULE.index(current_level)
        if current_index < len(self.PROGRESSION_SCHEDULE) - 1:
            return self.PROGRESSION_SCHEDULE[current_index + 1].capital
        return None
    
    def advance_day(self) -> bool:
        """
        Advance to next day.
        
        Returns:
            True if progression continues, False if completed
        """
        if self.current_day >= self.total_days:
            logger.info("Capital progression completed!")
            return False
        
        self.current_day += 1
        new_capital = self.get_current_capital()
        level_info = self.get_level_info()
        
        logger.info(
            f"Advanced to day {self.current_day}. New capital: ₹{new_capital:,.2f}. "
            f"Level: {level_info['level_start']}-{level_info['level_end']} "
            f"({level_info['days_remaining_in_level']} days remaining)"
        )
        
        return True
    
    def reset(self, start_date: Optional[datetime] = None):
        """Reset progression to day 1"""
        self.start_date = start_date or datetime.now()
        self.current_day = 1
        logger.info(f"Capital progression reset. Start date: {self.start_date.date()}")
    
    def get_progression_summary(self) -> Dict:
        """Get summary of entire progression schedule"""
        return {
            "start_date": self.start_date.isoformat(),
            "current_day": self.current_day,
            "total_days": self.total_days,
            "current_capital": self.get_current_capital(),
            "levels": [
                {
                    "level": i + 1,
                    "capital": level.capital,
                    "days": level.days,
                    "start_day": level.start_day,
                    "end_day": level.end_day,
                }
                for i, level in enumerate(self.PROGRESSION_SCHEDULE)
            ],
            "completion_percent": (self.current_day / self.total_days) * 100,
        }
