"""
Settlement & Increment engines for AurumHarmony
Final — 28 Nov 2025 (historic logic)

This module is the canonical implementation of:
- User category increment levels
- ZPT fee split for SaffronBolt / ZenithPulse
- 39% tax lock into savings
- Rounding-by-subtraction rules (buffer stays in demat)
"""


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
        levels = IncrementEngine.LEVELS.get(category, IncrementEngine.LEVELS["restricted"])
        if current_capital in levels:
            idx = levels.index(current_capital)
            if idx + 1 < len(levels):
                return levels[idx + 1]
        # No increment (NGD) or already at max level
        return current_capital


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

    @classmethod
    def _get_fee_pct(cls, category: str) -> float:
        return cls.FEE_PCT.get(category, cls.FEE_PCT["restricted"])

    @staticmethod
    def _round_down_per_rules(amount: float) -> tuple[float, float]:
        """
        Rounding Rule (by subtraction, balance stays in demat):

        * ≥ ₹1,00,000    → nearest ₹10,000
        * ≥ ₹10,00,000   → nearest ₹1,00,000
        * ≥ ₹1,00,00,000 → nearest ₹10,00,000

        Anything below ₹1,00,000 rounds down to nearest ₹1,000.
        """
        if amount <= 0:
            return 0.0, amount

        if amount >= 1_00_00_000:      # 1,00,00,000
            unit = 10_00_000          # 10,00,000
        elif amount >= 10_00_000:      # 10,00,000
            unit = 1_00_000           # 1,00,000
        elif amount >= 1_00_000:       # 1,00,000
            unit = 10_000             # 10,000
        else:
            unit = 1_000              # 1,000

        rounded = (amount // unit) * unit
        buffer = amount - rounded
        return rounded, buffer

    @classmethod
    def settle(cls, gross_profit: float, category: str, current_capital: float) -> dict:
        fee_pct = cls._get_fee_pct(category)
        platform_fee = gross_profit * fee_pct
        saffronbolt = platform_fee * 0.70
        zenithpulse = platform_fee * 0.30

        # 39% tax locked in savings (hidden in UI)
        tax_lock = gross_profit * cls.TAX_LOCK_PCT
        net_before_rounding = gross_profit - platform_fee - tax_lock

        # Rounding — excess stays in demat (historic rules)
        rounded_net, rounding_buffer = cls._round_down_per_rules(net_before_rounding)

        return {
            "gross_profit": gross_profit,
            "category": category,
            "platform_fee": platform_fee,
            "saffronbolt_share": saffronbolt,
            "zenithpulse_share": zenithpulse,
            "tax_locked_savings": tax_lock,
            "net_to_savings": rounded_net,
            "rounding_buffer_in_demat": rounding_buffer,
            "next_capital": IncrementEngine.get_next_capital(category, current_capital),
        }


class _SettlementService:
    """
    Thin façade used by the Flask app.

    Keeps the public API aligned with the Flask route while
    delegating the actual maths to SettlementEngine.
    """

    def settle(self, user_id: str, gross_profit: float, category: str, current_capital: float) -> dict:
        core = SettlementEngine.settle(gross_profit, category, current_capital)
        # Attach identity/context for the caller (admin UI / reporting)
        core["user_id"] = user_id
        core["current_capital"] = current_capital
        return core


# Default instance imported by the master core
settlement_engine = _SettlementService()


