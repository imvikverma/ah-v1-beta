"""
Capital Calculation Engine for AurumHarmony

Calculates initial capital and increments based on:
- Base capital (₹10K, ₹50K, etc.)
- Number of indices (3)
- Number of brokers (1+)
- Number of users (1 for normal, multiple for admin)
- 30% margin
- Rounding rules

Key: ₹40,000 PER INDEX (not split)
Example: 3 indices × ₹40,000 = ₹120,000 total capital
"""

import math
import logging
from typing import Dict, Any, Optional
from decimal import Decimal

logger = logging.getLogger(__name__)


class CapitalCalculationEngine:
    """
    Calculates initial capital and increments with margin and rounding.
    
    Formula: Base × Indices × Brokers × Users + 30% Margin
    Allocation: ₹40,000 PER INDEX (not split)
    """
    
    BASE_LEVELS = {
        "admin": [10000, 50000, 100000, 500000, 1500000],
        "normal": [10000, 50000, 100000],  # Capped at ₹1L
    }
    
    MARGIN_PCT = 0.30  # 30% margin
    
    @staticmethod
    def calculate_initial_capital(
        base_capital: float,
        num_indices: int = 3,
        num_brokers: int = 1,
        num_users: int = 1,
        user_type: str = "normal"
    ) -> Dict[str, Any]:
        """
        Calculate initial capital with margin and rounding.
        
        Formula: Base × Indices × Brokers × Users + 30% Margin
        Then round up appropriately.
        
        Allocation: ₹40,000 PER INDEX (not split)
        Example: 3 indices × ₹40,000 = ₹120,000 total
        
        Args:
            base_capital: Base capital (₹10K, ₹50K, etc.)
            num_indices: Number of indices (default 3)
            num_brokers: Number of brokers (default 1)
            num_users: Number of users (default 1)
            user_type: "admin" or "normal"
            
        Returns:
            Dictionary with capital breakdown
        """
        # Calculate base total
        base_total = base_capital * num_indices * num_brokers * num_users
        
        # Add 30% margin
        margin_amount = base_total * CapitalCalculationEngine.MARGIN_PCT
        calculated_capital = base_total + margin_amount
        
        # Allocation: ₹40,000 PER INDEX (not split)
        per_index_capital = 40000.0  # Fixed: ₹40,000 per index

        # Total capital = per_index × num_indices
        total_capital = per_index_capital * num_indices

        # Round up logic for total capital
        rounded_capital = total_capital  # Default to total_capital
        if total_capital < calculated_capital:
            # If our fixed allocation is less than calculated, use calculated + margin
            rounded_capital = CapitalCalculationEngine._round_up_capital(calculated_capital)
            total_capital = rounded_capital
            per_index_capital = total_capital / num_indices

        per_broker_capital = total_capital / num_brokers if num_brokers > 0 else total_capital
        per_account_capital = total_capital / num_users if num_users > 0 else total_capital
        
        logger.info(
            f"Capital calculated: Base={base_capital}, "
            f"Calculated={calculated_capital}, Rounded={rounded_capital}, "
            f"Per Index={per_index_capital}, Total={total_capital}"
        )
        
        return {
            "base_capital": base_capital,
            "calculated_capital": calculated_capital,
            "rounded_capital": rounded_capital,
            "total_capital": total_capital,
            "margin_amount": margin_amount,
            "per_index_capital": per_index_capital,  # ₹40K per index (not split)
            "per_broker_capital": per_broker_capital,
            "per_account_capital": per_account_capital,
            "num_indices": num_indices,
            "num_brokers": num_brokers,
            "num_users": num_users,
            "user_type": user_type,
        }
    
    @staticmethod
    def _round_up_capital(amount: float) -> float:
        """
        Round up capital to nearest appropriate level.
        
        Examples:
        - ₹39,000 → ₹40,000 or ₹50,000
        - ₹195,000 → ₹2,00,000
        
        Args:
            amount: Amount to round
            
        Returns:
            Rounded amount
        """
        if amount <= 50000:
            # Round to nearest ₹10K
            return math.ceil(amount / 10000) * 10000
        elif amount <= 200000:
            # Round to nearest ₹50K
            return math.ceil(amount / 50000) * 50000
        elif amount <= 1000000:
            # Round to nearest ₹1L
            return math.ceil(amount / 100000) * 100000
        else:
            # Round to nearest ₹5L
            return math.ceil(amount / 500000) * 500000
    
    @staticmethod
    def get_next_capital_level(
        current_capital: float,
        num_indices: int = 3,
        num_brokers: int = 1,
        num_users: int = 1,
        user_type: str = "normal"
    ) -> Optional[Dict[str, Any]]:
        """
        Get next capital increment level based on accumulated profit.
        
        For admin: ₹10K → ₹50K → ₹1L → ₹5L → ₹15L
        For normal: ₹10K → ₹50K → ₹1L (capped)
        
        Args:
            current_capital: Current capital level
            num_indices: Number of indices
            num_brokers: Number of brokers
            num_users: Number of users
            user_type: "admin" or "normal"
            
        Returns:
            Dictionary with next capital breakdown, or None if at max level
        """
        levels = CapitalCalculationEngine.BASE_LEVELS.get(user_type, [10000, 50000, 100000])
        
        # Find current base level
        current_base = None
        for level in levels:
            # Calculate what capital would be for this base
            test_calc = CapitalCalculationEngine.calculate_initial_capital(
                base_capital=level,
                num_indices=num_indices,
                num_brokers=num_brokers,
                num_users=num_users,
                user_type=user_type
            )
            if abs(test_calc["total_capital"] - current_capital) < 0.01:
                current_base = level
                break
        
        if current_base is None:
            logger.warning(f"Could not find current base level for capital {current_capital}")
            return None
        
        # Find next level
        current_index = levels.index(current_base)
        if current_index + 1 >= len(levels):
            logger.debug(f"Already at max level for {user_type}")
            return None
        
        next_base = levels[current_index + 1]
        
        # Calculate next capital with margin and rounding
        return CapitalCalculationEngine.calculate_initial_capital(
            base_capital=next_base,
            num_indices=num_indices,
            num_brokers=num_brokers,
            num_users=num_users,
            user_type=user_type
        )

