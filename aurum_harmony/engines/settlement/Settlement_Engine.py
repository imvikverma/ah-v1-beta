"""
Settlement & Increment engines for AurumHarmony
Final — 28 Nov 2025 (historic logic)

This module is the canonical implementation of:
- User category increment levels
- ZPT fee split for SaffronBolt / ZenithPulse
- 39% tax lock into savings
- Rounding-by-subtraction rules (buffer stays in demat)

Enhanced with:
- Input validation
- Error handling
- Logging
- Type safety
"""

import logging
from typing import Dict, Any, Tuple, Optional
from decimal import Decimal, ROUND_DOWN

# Configure logging
logger = logging.getLogger(__name__)


class IncrementEngine:
    """
    Capital progression per user category.

    Categories (historic):
    - NGD: Funded & Restricted, cyclical ₹5,000 (no increment)
    - restricted: Funded Restricted tiers
    - semi: Funded Semi-Restricted tiers (same ladder as restricted)
    - admin: Unrestricted admin / owner path
    """

    LEVELS = {
        "NGD": [5000],  # cyclical — no increment
        "restricted": [10000, 50000, 100000],
        "semi": [10000, 50000, 100000],
        "admin": [10000, 50000, 100000, 500000, 1500000],
    }

    @staticmethod
    def get_next_capital(category: str, current_capital: float) -> float:
        """
        Get next capital level for a user category.
        
        Args:
            category: User category (NGD, restricted, semi, admin)
            current_capital: Current capital amount
            
        Returns:
            Next capital level, or current_capital if at max level
        """
        if current_capital < 0:
            logger.warning(f"Invalid current_capital: {current_capital}, using 0")
            current_capital = 0.0
        
        levels = IncrementEngine.LEVELS.get(category, IncrementEngine.LEVELS["restricted"])
        
        # Check if current capital matches a level (with small tolerance for floating point)
        for i, level in enumerate(levels):
            if abs(current_capital - level) < 0.01:
                if i + 1 < len(levels):
                    next_level = levels[i + 1]
                    logger.debug(f"Category {category}: {current_capital} -> {next_level}")
                    return next_level
                else:
                    logger.debug(f"Category {category}: Already at max level {current_capital}")
                    return current_capital
        
        # Current capital doesn't match any level - return current (no increment)
        logger.debug(f"Category {category}: {current_capital} doesn't match any level, no increment")
        return current_capital
    
    @staticmethod
    def should_increment_capital(
        current_capital: float,
        accumulated_profit: float,
        category: str,
        num_indices: int = 3,
        num_brokers: int = 1,
        num_users: int = 1
    ) -> Tuple[bool, Optional[float]]:
        """
        Determine if capital should increment based on accumulated profit.
        
        Logic:
        - Track accumulated profit per user
        - When profit reaches 50% of current capital → Increment
        - Calculate next capital with margin and rounding
        - Reset profit tracking after increment
        
        Args:
            current_capital: Current capital level
            accumulated_profit: Total profit accumulated since last increment
            category: User category
            num_indices: Number of indices (default 3)
            num_brokers: Number of brokers (default 1)
            num_users: Number of users (default 1)
            
        Returns:
            (should_increment, next_capital_level)
        """
        from aurum_harmony.engines.settlement.capital_calculation_engine import CapitalCalculationEngine
        
        # Get current level index
        levels = IncrementEngine.LEVELS.get(category, [10000, 50000, 100000])
        
        # Find current base level
        current_base = None
        for level in levels:
            # Calculate what capital would be for this base
            test_calc = CapitalCalculationEngine.calculate_initial_capital(
                base_capital=level,
                num_indices=num_indices,
                num_brokers=num_brokers,
                num_users=num_users,
                user_type=category if category == "admin" else "normal"
            )
            if abs(test_calc["total_capital"] - current_capital) < 0.01:
                current_base = level
                break
        
        if current_base is None:
            logger.debug(f"Could not find current base level for capital {current_capital}")
            return False, None
        
        current_level_index = levels.index(current_base)
        
        if current_level_index + 1 >= len(levels):
            logger.debug(f"Category {category}: Already at max level {current_capital}")
            return False, None
        
        # Calculate profit threshold (50% of current capital)
        profit_threshold = current_capital * 0.5
        
        if accumulated_profit >= profit_threshold:
            next_base = levels[current_level_index + 1]
            # Calculate next capital with margin and rounding
            next_calc = CapitalCalculationEngine.calculate_initial_capital(
                base_capital=next_base,
                num_indices=num_indices,
                num_brokers=num_brokers,
                num_users=num_users,
                user_type=category if category == "admin" else "normal"
            )
            next_capital = next_calc["total_capital"]
            logger.info(
                f"Increment triggered: {category} capital {current_capital} → {next_capital} "
                f"(profit {accumulated_profit} >= threshold {profit_threshold})"
            )
            return True, next_capital
        
        logger.debug(
            f"Increment not triggered: profit {accumulated_profit} < threshold {profit_threshold}"
        )
        return False, None


class SettlementEngine:
    """
    Historic settlement logic (v1.0 Beta, 28 Nov 2025).

    Inputs:
    - gross_profit: total profit for the period
    - category: NGD / restricted / semi / admin
    - current_capital: current trading capital for increment ladder

    Outputs:
    - gross_profit
    - platform_fee, saffronbolt_share, zenithpulse_share
    - tax_locked_savings (39% of gross)
    - net_to_savings (after fee + tax, rounded down per rules)
    - rounding_buffer_in_demat (always stays in demat)
    - next_capital (per IncrementEngine)
    """

    # ZPT fee per category (beta phase)
    FEE_PCT = {
        "NGD": 0.15,
        "restricted": 0.30,
        "semi": 0.125,
        "admin": 0.30,  # admin follows platform beta fee unless changed later
    }

    TAX_LOCK_PCT = 0.39  # 39% tax locked in savings (hidden in UI)
    LOSS_BUFFER_PCT = 0.01  # 1% loss/latency buffer (only if losses occur)
    BROKERAGE_PCT = 0.06  # ~6% brokerage/exchange fees (tracked for reporting, already deducted)

    @classmethod
    def _get_fee_pct(cls, category: str) -> float:
        return cls.FEE_PCT.get(category, cls.FEE_PCT["restricted"])

    @staticmethod
    def _round_down_per_rules(amount: float) -> Tuple[float, float]:
        """
        Rounding Rule (by subtraction, balance stays in demat):

        * ≥ ₹1,00,000    → nearest ₹10,000
        * ≥ ₹10,00,000   → nearest ₹1,00,000
        * ≥ ₹1,00,00,000 → nearest ₹10,00,000

        Anything below ₹1,00,000 rounds down to nearest ₹1,000.
        
        Args:
            amount: Amount to round
            
        Returns:
            Tuple of (rounded_amount, buffer_amount)
        """
        if amount <= 0:
            return 0.0, amount

        # Use Decimal for precise calculations
        amount_decimal = Decimal(str(amount))
        
        if amount >= 1_00_00_000:      # 1,00,00,000
            unit = Decimal("1000000")  # 10,00,000
        elif amount >= 10_00_000:      # 10,00,000
            unit = Decimal("100000")   # 1,00,000
        elif amount >= 1_00_000:       # 1,00,000
            unit = Decimal("10000")    # 10,000
        else:
            unit = Decimal("1000")     # 1,000

        rounded = (amount_decimal // unit) * unit
        buffer = amount_decimal - rounded
        
        return float(rounded), float(buffer)

    @classmethod
    def settle(
        cls,
        gross_profit: float,
        category: str,
        current_capital: float,
        has_losses: bool = False,
            brokerage_fees: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Calculate settlement breakdown for a user.
        
        Settlement Flow:
        1. Gross Profit (already excludes ~6% brokerage/exchange fees)
        2. IF Losses Occur: Deduct 1% loss/latency buffer
        3. Deduct Platform Fee (30% → ZenithPulse Tech Account)
        4. Lock Tax Reserve (39% → Savings Account)
        5. Apply Rounding Logic (excess stays in Demat)
        6. Net to Savings
        
        Args:
            gross_profit: Total profit for the period (after broker auto-deductions)
            category: User category (NGD, restricted, semi, admin)
            current_capital: Current trading capital
            has_losses: Whether losses occurred (triggers 1% buffer)
            brokerage_fees: Brokerage fees (for reporting, already deducted from gross)
            
        Returns:
            Dictionary with settlement breakdown
            
        Raises:
            ValueError: If inputs are invalid
        """
        
        # Validate inputs
        if gross_profit < 0:
            logger.warning(f"Negative gross_profit: {gross_profit}, treating as 0")
            gross_profit = 0.0
        
        if current_capital < 0:
            logger.warning(f"Negative current_capital: {current_capital}, treating as 0")
            current_capital = 0.0
        
        if category not in cls.FEE_PCT:
            logger.warning(f"Unknown category '{category}', using 'restricted'")
            category = "restricted"
        
        try:
            # Use Decimal for precise financial calculations
            gross_decimal = Decimal(str(gross_profit))
            
            # Step 1: Loss/Latency Buffer (only if losses occur)
            loss_buffer = 0.0
            if has_losses:
                loss_buffer = float(gross_decimal * Decimal(str(cls.LOSS_BUFFER_PCT)))
                gross_after_buffer = float(gross_decimal) - loss_buffer
                logger.debug(f"Loss buffer applied: ₹{loss_buffer:,.2f}")
            else:
                gross_after_buffer = float(gross_decimal)
            
            # Step 2: Platform Fee (30% → ZenithPulse Tech Account)
            fee_pct = cls._get_fee_pct(category)
            platform_fee = float(Decimal(str(gross_after_buffer)) * Decimal(str(fee_pct)))
            saffronbolt = platform_fee * 0.70
            zenithpulse = platform_fee * 0.30  # 30% → ZenithPulse Tech Account

            # Step 3: Tax Lock (39% → Savings Account)
            tax_lock = float(Decimal(str(gross_after_buffer)) * Decimal(str(cls.TAX_LOCK_PCT)))
            
            # Step 4: Net before rounding
            net_before_rounding = gross_after_buffer - platform_fee - tax_lock

            # Step 5: Rounding — excess stays in demat (historic rules)
            rounded_net, rounding_buffer = cls._round_down_per_rules(net_before_rounding)
            
            # Step 6: Brokerage tracking (for reporting, already deducted)
            if brokerage_fees is None:
                # Estimate if not provided (6% of gross)
                brokerage_fees = float(gross_decimal * Decimal(str(cls.BROKERAGE_PCT)))
            
            # Step 7: Next capital increment
            next_capital = IncrementEngine.get_next_capital(category, current_capital)

            result = {
                "gross_profit": gross_profit,
                "brokerage_fees": brokerage_fees,  # For reporting (already deducted)
                "loss_buffer": loss_buffer,  # Only if losses occurred
                "gross_after_buffer": gross_after_buffer,
                "platform_fee": platform_fee,
                "saffronbolt_share": saffronbolt,
                "zenithpulse_share": zenithpulse,  # 30% → ZenithPulse Tech Account
                "tax_locked_savings": tax_lock,  # 39% → Savings Account
                "net_before_rounding": net_before_rounding,
                "net_to_savings": rounded_net,  # After rounding
                "rounding_buffer_in_demat": rounding_buffer,  # Stays in demat
                "next_capital": next_capital,
                "category": category,
            }
            
            logger.info(
                f"Settlement calculated: category={category}, "
                f"gross=₹{gross_profit:,.2f}, buffer=₹{loss_buffer:,.2f}, "
                f"platform_fee=₹{platform_fee:,.2f}, tax_lock=₹{tax_lock:,.2f}, "
                f"net=₹{rounded_net:,.2f}, buffer_in_demat=₹{rounding_buffer:,.2f}"
            )
            
            return result
            
        except Exception as e:
            logger.error(f"Error calculating settlement: {e}", exc_info=True)
            raise ValueError(f"Settlement calculation failed: {e}") from e


class _SettlementService:
    """
    Thin façade used by the Flask app.

    Keeps the public API aligned with the Flask route while
    delegating the actual maths to SettlementEngine.
    Enhanced with validation and error handling.
    """

    def settle(
        self,
        user_id: str,
        gross_profit: float,
        category: str,
        current_capital: float,
        has_losses: bool = False,
        brokerage_fees: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Calculate settlement for a user.
        
        Args:
            user_id: User identifier
            gross_profit: Total profit for the period (after broker auto-deductions)
            category: User category
            current_capital: Current trading capital
            has_losses: Whether losses occurred (triggers 1% buffer)
            brokerage_fees: Brokerage fees (for reporting, already deducted)
            
        Returns:
            Settlement breakdown dictionary with user context
        """
        if not user_id:
            raise ValueError("user_id is required")
        
        try:
            core = SettlementEngine.settle(
                gross_profit=gross_profit,
                category=category,
                current_capital=current_capital,
                has_losses=has_losses,
                brokerage_fees=brokerage_fees
            )
            # Attach identity/context for the caller (admin UI / reporting)
            core["user_id"] = user_id
            core["current_capital"] = current_capital
            return core
        except Exception as e:
            logger.error(f"Error in settlement service for user {user_id}: {e}", exc_info=True)
            raise


# Default instance imported by the master core
settlement_engine = _SettlementService()


