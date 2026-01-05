"""
Trading Formula Guidelines Engine
Converts trading formula values into AI-driven adaptive guidelines (not hard stops).

Based on rules.md:
- Trades/Day: 27–180 (scales with tier & VIX) - GUIDELINE
- Per Index: Distributed across NIFTY50, BANKNIFTY, SENSEX - GUIDELINE
- Per Broker: Can use multiple brokers - GUIDELINE
- Per User: Based on user category - GUIDELINE

AI has full discretion to:
- Increase above guidelines with high confidence
- Decrease below guidelines with low confidence
- Adjust per index based on signal quality
- Adjust per broker based on data quality
"""

from __future__ import annotations

import logging
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass, field
from datetime import datetime, date
from enum import Enum
from decimal import Decimal

logger = logging.getLogger(__name__)


class UserCategory(str, Enum):
    """User categories from rules.md"""
    NGD = "NGD"
    RESTRICTED = "restricted"
    SEMI = "semi"
    ADMIN = "admin"


@dataclass
class TradingFormulaGuideline:
    """
    Trading formula guideline (not a hard stop).
    
    From rules.md:
    - Trades/Day: 27–180 (scales with tier & VIX)
    - Per Index: Distributed across NIFTY50, BANKNIFTY, SENSEX
    - Per Broker: Can use multiple brokers
    - Per User: Based on user category
    """
    # Base values (guidelines from rules.md)
    base_trades_per_day: int  # 27-180 based on tier & VIX
    base_trades_per_index: Dict[str, int]  # Per index allocation
    base_trades_per_broker: Dict[str, int]  # Per broker allocation
    
    # Current values (AI-adjusted)
    current_trades_per_day: int
    current_trades_per_index: Dict[str, int]
    current_trades_per_broker: Dict[str, int]
    
    # AI adjustment factors
    ai_confidence: float = 0.5  # 0.0 to 1.0
    adjustment_reason: str = ""
    last_adjusted: Optional[datetime] = None
    
    # Min/Max bounds (safety limits)
    min_trades_per_day: int = 10
    max_trades_per_day: int = 250  # Safety cap (above guideline max)
    min_trades_per_index: int = 5
    max_trades_per_index: int = 100
    
    def get_ai_adjusted_trades_per_day(self, ai_confidence: float, direction: str) -> int:
        """
        Get AI-adjusted trades per day.
        
        Args:
            ai_confidence: AI confidence (0.0 to 1.0)
            direction: "INCREASE", "DECREASE", or "MAINTAIN"
            
        Returns:
            Adjusted trades per day
        """
        if direction == "MAINTAIN":
            return self.current_trades_per_day
        
        # Calculate adjustment magnitude (0% to 50% based on confidence)
        adjustment_pct = (ai_confidence - 0.5) * 1.0  # -50% to +50%
        
        if direction == "INCREASE":
            adjustment = int(self.base_trades_per_day * adjustment_pct)
            new_value = self.current_trades_per_day + adjustment
            return min(new_value, self.max_trades_per_day)
        else:  # DECREASE
            adjustment = int(self.base_trades_per_day * abs(adjustment_pct))
            new_value = self.current_trades_per_day - adjustment
            return max(new_value, self.min_trades_per_day)
    
    def get_ai_adjusted_trades_per_index(
        self,
        index: str,
        ai_confidence: float,
        signal_quality: float
    ) -> int:
        """
        Get AI-adjusted trades per index.
        
        Args:
            index: Index name (NIFTY50, BANKNIFTY, SENSEX)
            ai_confidence: AI confidence (0.0 to 1.0)
            signal_quality: Signal quality for this index (0.0 to 1.0)
            
        Returns:
            Adjusted trades per index
        """
        base = self.current_trades_per_index.get(index, 0)
        
        # Adjust based on signal quality
        quality_factor = signal_quality  # 0.0 to 1.0
        adjustment = int(base * (quality_factor - 0.5) * 0.5)  # ±25% based on quality
        
        new_value = base + adjustment
        return max(self.min_trades_per_index, min(new_value, self.max_trades_per_index))


@dataclass
class VIXGuideline:
    """
    VIX-based capacity guidelines (from rules.md).
    
    These are INDICATIVE guidelines, not hard stops.
    AI can exceed or reduce based on confidence.
    """
    vix_level: float
    capacity_pct: float  # 50-100% (indicative)
    target_return_pct: float  # 5-10% (indicative)
    win_rate_pct: float  # 45-66% (indicative)
    guideline_max_trades: int  # Indicative max trades/day
    
    @classmethod
    def from_vix(cls, vix: float) -> "VIXGuideline":
        """
        Get VIX guideline from VIX level.
        
        From rules.md:
        - VIX <15: 100% capacity, 10% target return, 60–66% win rate
        - VIX 15–20: 75% capacity, 8% target return, 55–60% win rate
        - VIX 20–30: 50% capacity, 7% target return, 50–55% win rate
        - VIX >30: 50% capacity, 5% target return, 45–50% win rate
        """
        if vix < 15:
            return cls(
                vix_level=vix,
                capacity_pct=100.0,
                target_return_pct=10.0,
                win_rate_pct=63.0,  # Average of 60-66%
                guideline_max_trades=180  # Indicative for admin tier
            )
        elif vix < 20:
            return cls(
                vix_level=vix,
                capacity_pct=75.0,
                target_return_pct=8.0,
                win_rate_pct=57.5,  # Average of 55-60%
                guideline_max_trades=135  # 75% of 180
            )
        elif vix < 30:
            return cls(
                vix_level=vix,
                capacity_pct=50.0,
                target_return_pct=7.0,
                win_rate_pct=52.5,  # Average of 50-55%
                guideline_max_trades=90  # 50% of 180
            )
        else:  # VIX >= 30
            return cls(
                vix_level=vix,
                capacity_pct=50.0,
                target_return_pct=5.0,
                win_rate_pct=47.5,  # Average of 45-50%
                guideline_max_trades=90  # 50% of 180
            )


class TradingFormulaGuidelinesEngine:
    """
    Manages trading formula guidelines as adaptive parameters.
    
    Key Features:
    - Trades per day per index per broker per user (guidelines)
    - VIX-based capacity scaling (indicative)
    - AI-driven adjustments based on confidence
    - Per-index allocation based on signal quality
    - Per-broker allocation based on data quality
    """
    
    # Base trades per day by user category (from rules.md)
    BASE_TRADES_PER_DAY = {
        UserCategory.NGD: 18,  # Lower for NGD
        UserCategory.RESTRICTED: 27,  # Base level
        UserCategory.SEMI: 27,  # Same as restricted
        UserCategory.ADMIN: 180,  # Highest for admin
    }
    
    # Trading indices
    TRADING_INDICES = ["NIFTY50", "BANKNIFTY", "SENSEX"]
    
    # Default index allocation (can be adjusted by AI)
    DEFAULT_INDEX_ALLOCATION = {
        "NIFTY50": 0.40,  # 40%
        "BANKNIFTY": 0.40,  # 40%
        "SENSEX": 0.20,  # 20%
    }
    
    def __init__(self):
        """Initialize trading formula guidelines engine."""
        self.user_guidelines: Dict[str, TradingFormulaGuideline] = {}
        self.vix_guidelines: Dict[float, VIXGuideline] = {}
        self.adjustment_history: List[Dict[str, Any]] = []
        logger.info("TradingFormulaGuidelinesEngine initialized")
    
    def get_guideline_for_user(
        self,
        user_id: str,
        user_category: str,
        vix_level: float,
        current_trades_today: int = 0,
        trades_by_index: Optional[Dict[str, int]] = None,
        trades_by_broker: Optional[Dict[str, int]] = None
    ) -> TradingFormulaGuideline:
        """
        Get trading formula guideline for a user.
        
        Args:
            user_id: User identifier
            user_category: User category (NGD, restricted, semi, admin)
            vix_level: Current VIX level
            current_trades_today: Current trades executed today
            trades_by_index: Current trades per index
            trades_by_broker: Current trades per broker
            
        Returns:
            TradingFormulaGuideline with base and current values
        """
        # Get base trades per day for category
        category_enum = UserCategory(user_category.lower())
        base_trades = self.BASE_TRADES_PER_DAY.get(category_enum, 27)
        
        # Get VIX guideline
        vix_guideline = VIXGuideline.from_vix(vix_level)
        
        # Adjust base trades by VIX capacity (indicative)
        vix_adjusted_base = int(base_trades * (vix_guideline.capacity_pct / 100.0))
        
        # Calculate per-index allocation
        base_trades_per_index = {}
        for index in self.TRADING_INDICES:
            allocation_pct = self.DEFAULT_INDEX_ALLOCATION.get(index, 0.33)
            base_trades_per_index[index] = int(vix_adjusted_base * allocation_pct)
        
        # Calculate per-broker allocation (default: equal if multiple brokers)
        base_trades_per_broker = {}
        brokers = trades_by_broker.keys() if trades_by_broker else ["default"]
        trades_per_broker = vix_adjusted_base // len(brokers)
        for broker in brokers:
            base_trades_per_broker[broker] = trades_per_broker
        
        # Get or create guideline
        if user_id not in self.user_guidelines:
            self.user_guidelines[user_id] = TradingFormulaGuideline(
                base_trades_per_day=vix_adjusted_base,
                base_trades_per_index=base_trades_per_index,
                base_trades_per_broker=base_trades_per_broker,
                current_trades_per_day=vix_adjusted_base,
                current_trades_per_index=base_trades_per_index.copy(),
                current_trades_per_broker=base_trades_per_broker.copy(),
            )
        else:
            # Update base values if VIX changed significantly
            guideline = self.user_guidelines[user_id]
            if abs(guideline.base_trades_per_day - vix_adjusted_base) > 5:
                guideline.base_trades_per_day = vix_adjusted_base
                guideline.base_trades_per_index = base_trades_per_index
                guideline.base_trades_per_broker = base_trades_per_broker
        
        return self.user_guidelines[user_id]
    
    def get_ai_adjusted_guideline(
        self,
        user_id: str,
        user_category: str,
        vix_level: float,
        ai_confidence: float,
        signal_quality_by_index: Dict[str, float],
        market_conditions: Dict[str, Any],
        current_trades_today: int = 0
    ) -> TradingFormulaGuideline:
        """
        Get AI-adjusted trading formula guideline.
        
        AI can:
        - INCREASE above guideline with high confidence (>75%)
        - DECREASE below guideline with low confidence (<50%)
        - MAINTAIN guideline with medium confidence (50-75%)
        
        Args:
            user_id: User identifier
            user_category: User category
            vix_level: Current VIX level
            ai_confidence: AI confidence (0.0 to 1.0)
            signal_quality_by_index: Signal quality per index (0.0 to 1.0)
            market_conditions: Market conditions dict
            current_trades_today: Current trades executed today
            
        Returns:
            AI-adjusted TradingFormulaGuideline
        """
        # Get base guideline
        guideline = self.get_guideline_for_user(
            user_id=user_id,
            user_category=user_category,
            vix_level=vix_level,
            current_trades_today=current_trades_today
        )
        
        # Determine adjustment direction
        if ai_confidence >= 0.75:
            direction = "INCREASE"
            reason = f"High AI confidence ({ai_confidence:.1%}) - increasing above guideline"
        elif ai_confidence < 0.50:
            direction = "DECREASE"
            reason = f"Low AI confidence ({ai_confidence:.1%}) - reducing below guideline"
        else:
            direction = "MAINTAIN"
            reason = f"Medium AI confidence ({ai_confidence:.1%}) - maintaining guideline"
        
        # Check market conditions
        if market_conditions.get("risk_level", "NORMAL") == "HIGH":
            direction = "DECREASE"
            reason = "High risk market conditions - reducing trades"
        elif market_conditions.get("opportunity_level", "NORMAL") == "HIGH":
            if direction == "MAINTAIN":
                direction = "INCREASE"
                reason = "High opportunity detected - increasing trades"
        
        # Get AI-adjusted trades per day
        adjusted_trades_per_day = guideline.get_ai_adjusted_trades_per_day(
            ai_confidence=ai_confidence,
            direction=direction
        )
        
        # Get AI-adjusted trades per index
        adjusted_trades_per_index = {}
        for index in self.TRADING_INDICES:
            signal_quality = signal_quality_by_index.get(index, 0.5)
            adjusted_trades_per_index[index] = guideline.get_ai_adjusted_trades_per_index(
                index=index,
                ai_confidence=ai_confidence,
                signal_quality=signal_quality
            )
        
        # Update guideline
        old_trades = guideline.current_trades_per_day
        guideline.current_trades_per_day = adjusted_trades_per_day
        guideline.current_trades_per_index = adjusted_trades_per_index
        guideline.ai_confidence = ai_confidence
        guideline.adjustment_reason = reason
        guideline.last_adjusted = datetime.now()
        
        # Log adjustment
        if abs(adjusted_trades_per_day - old_trades) > 0:
            adjustment_record = {
                "timestamp": datetime.now().isoformat(),
                "user_id": user_id,
                "old_trades_per_day": old_trades,
                "new_trades_per_day": adjusted_trades_per_day,
                "adjustment_pct": ((adjusted_trades_per_day - old_trades) / old_trades * 100) if old_trades > 0 else 0,
                "direction": direction,
                "ai_confidence": ai_confidence,
                "reason": reason,
                "vix_level": vix_level,
                "trades_per_index": adjusted_trades_per_index
            }
            self.adjustment_history.append(adjustment_record)
            
            logger.info(
                f"Trading formula adjusted for {user_id}: "
                f"{old_trades} → {adjusted_trades_per_day} trades/day "
                f"({adjustment_record['adjustment_pct']:+.1f}%) "
                f"[{direction}, confidence: {ai_confidence:.2f}]"
            )
        
        return guideline
    
    def can_execute_trade(
        self,
        user_id: str,
        index: str,
        broker: str,
        current_trades_today: int,
        trades_by_index: Dict[str, int],
        trades_by_broker: Dict[str, int],
        guideline: TradingFormulaGuideline
    ) -> Tuple[bool, str]:
        """
        Check if a trade can be executed based on guidelines.
        
        This is a GUIDELINE check, not a hard stop.
        AI can override with high confidence.
        
        Args:
            user_id: User identifier
            index: Index name (NIFTY50, BANKNIFTY, SENSEX)
            broker: Broker name
            current_trades_today: Current trades today
            trades_by_index: Trades per index
            trades_by_broker: Trades per broker
            guideline: Current guideline
            
        Returns:
            Tuple of (can_execute, reason)
        """
        # Check daily limit (guideline)
        if current_trades_today >= guideline.current_trades_per_day:
            return False, f"Daily guideline limit reached ({guideline.current_trades_per_day} trades)"
        
        # Check per-index limit (guideline)
        index_trades = trades_by_index.get(index, 0)
        index_limit = guideline.current_trades_per_index.get(index, 0)
        if index_trades >= index_limit:
            return False, f"Index guideline limit reached ({index}: {index_limit} trades)"
        
        # Check per-broker limit (guideline)
        broker_trades = trades_by_broker.get(broker, 0)
        broker_limit = guideline.current_trades_per_broker.get(broker, 0)
        if broker_trades >= broker_limit:
            return False, f"Broker guideline limit reached ({broker}: {broker_limit} trades)"
        
        return True, "Within guidelines"
    
    def get_guideline_summary(self, user_id: str) -> Dict[str, Any]:
        """Get summary of guidelines for a user."""
        if user_id not in self.user_guidelines:
            return {"error": "No guidelines found for user"}
        
        guideline = self.user_guidelines[user_id]
        return {
            "user_id": user_id,
            "base_trades_per_day": guideline.base_trades_per_day,
            "current_trades_per_day": guideline.current_trades_per_day,
            "trades_per_index": guideline.current_trades_per_index,
            "trades_per_broker": guideline.current_trades_per_broker,
            "ai_confidence": guideline.ai_confidence,
            "adjustment_reason": guideline.adjustment_reason,
            "last_adjusted": guideline.last_adjusted.isoformat() if guideline.last_adjusted else None,
            "adjustment_pct": ((guideline.current_trades_per_day - guideline.base_trades_per_day) / guideline.base_trades_per_day * 100) if guideline.base_trades_per_day > 0 else 0
        }


# Default instance
trading_formula_guidelines_engine = TradingFormulaGuidelinesEngine()

__all__ = [
    "TradingFormulaGuidelinesEngine",
    "TradingFormulaGuideline",
    "VIXGuideline",
    "UserCategory",
    "trading_formula_guidelines_engine",
]
