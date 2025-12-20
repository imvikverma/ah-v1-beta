"""
Leverage Engine for AurumHarmony

Implements leverage multiplier based on user category:
- NGD: 1.5× leverage
- All other categories: 3× leverage
"""

from __future__ import annotations

import logging
from typing import Dict, Any, Optional
from dataclasses import dataclass

# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class LeverageConfig:
    """Leverage configuration for a user category."""
    category: str
    leverage_multiplier: float
    max_exposure_multiplier: float  # Max exposure = capital × this multiplier


class LeverageEngine:
    """
    Leverage management engine.
    
    Leverage Rules (from rules.md):
    - NGD: 1.5× leverage
    - All other categories: 3× leverage
    """
    
    # Leverage multipliers per category
    LEVERAGE_MULTIPLIERS = {
        "NGD": 1.5,
        "restricted": 3.0,
        "semi": 3.0,
        "admin": 3.0,
    }
    
    @classmethod
    def get_leverage_multiplier(cls, category: str) -> float:
        """
        Get leverage multiplier for a user category.
        
        Args:
            category: User category (NGD, restricted, semi, admin)
            
        Returns:
            Leverage multiplier (1.5 for NGD, 3.0 for others)
        """
        multiplier = cls.LEVERAGE_MULTIPLIERS.get(category, 3.0)
        logger.debug(f"Leverage multiplier for {category}: {multiplier}×")
        return multiplier
    
    @classmethod
    def calculate_max_exposure(cls, capital: float, category: str) -> float:
        """
        Calculate maximum exposure based on capital and leverage.
        
        Args:
            capital: User's trading capital
            category: User category
            
        Returns:
            Maximum exposure (capital × leverage)
        """
        leverage = cls.get_leverage_multiplier(category)
        max_exposure = capital * leverage
        
        logger.debug(
            f"Max exposure for {category}: ₹{capital:,.2f} × {leverage}× = ₹{max_exposure:,.2f}"
        )
        
        return max_exposure
    
    @classmethod
    def validate_exposure(cls, current_exposure: float, capital: float, category: str) -> tuple[bool, str]:
        """
        Validate if current exposure is within leverage limits.
        
        Args:
            current_exposure: Current total exposure
            capital: User's trading capital
            category: User category
            
        Returns:
            Tuple of (is_valid, message)
        """
        max_exposure = cls.calculate_max_exposure(capital, category)
        leverage = cls.get_leverage_multiplier(category)
        
        if current_exposure > max_exposure:
            return False, (
                f"Exposure limit exceeded: ₹{current_exposure:,.2f} > "
                f"₹{max_exposure:,.2f} (Capital: ₹{capital:,.2f} × {leverage}× leverage)"
            )
        
        utilization = (current_exposure / max_exposure * 100) if max_exposure > 0 else 0
        
        return True, (
            f"Exposure within limits: ₹{current_exposure:,.2f} / "
            f"₹{max_exposure:,.2f} ({utilization:.1f}% utilization)"
        )
    
    @classmethod
    def get_leverage_config(cls, category: str) -> LeverageConfig:
        """
        Get complete leverage configuration for a category.
        
        Args:
            category: User category
            
        Returns:
            LeverageConfig object
        """
        multiplier = cls.get_leverage_multiplier(category)
        
        return LeverageConfig(
            category=category,
            leverage_multiplier=multiplier,
            max_exposure_multiplier=multiplier
        )


# Default instance
leverage_engine = LeverageEngine()

__all__ = [
    "LeverageEngine",
    "LeverageConfig",
    "leverage_engine",
]

