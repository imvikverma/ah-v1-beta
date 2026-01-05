"""
Adaptive Parameter Engine
Converts hard trading rules into ML/AI-driven adaptive guidelines.

The system uses intelligence to:
- Preemptively adjust parameters based on opportunities
- Increase/decrease capital allocation intelligently
- Modify trade frequency based on market conditions
- Save losses to maximum by early detection and adjustment
"""

from __future__ import annotations

import logging
from typing import Dict, Any, Optional, Tuple
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
import numpy as np

logger = logging.getLogger(__name__)


class AdjustmentDirection(str, Enum):
    """Direction of parameter adjustment."""
    INCREASE = "INCREASE"
    DECREASE = "DECREASE"
    MAINTAIN = "MAINTAIN"


@dataclass
class ParameterGuideline:
    """A trading parameter guideline (not a hard stop)."""
    base_value: float
    current_value: float
    min_value: float
    max_value: float
    adjustment_factor: float = 1.0  # Multiplier for AI adjustments
    confidence_threshold: float = 0.7  # Min confidence to adjust
    last_adjusted: Optional[datetime] = None
    
    def get_adjusted_value(self, ai_confidence: float, direction: AdjustmentDirection) -> float:
        """
        Get adjusted value based on AI confidence and direction.
        
        Args:
            ai_confidence: AI confidence score (0.0 to 1.0)
            direction: Direction of adjustment
            
        Returns:
            Adjusted parameter value
        """
        if ai_confidence < self.confidence_threshold:
            return self.current_value  # No adjustment if confidence too low
        
        # Calculate adjustment magnitude based on confidence
        # Higher confidence = larger adjustment (up to 50% increase/decrease)
        adjustment_magnitude = (ai_confidence - self.confidence_threshold) / (1.0 - self.confidence_threshold)
        max_adjustment = 0.5  # Max 50% adjustment
        adjustment = adjustment_magnitude * max_adjustment
        
        if direction == AdjustmentDirection.INCREASE:
            new_value = self.current_value * (1.0 + adjustment)
            return min(new_value, self.max_value)
        elif direction == AdjustmentDirection.DECREASE:
            new_value = self.current_value * (1.0 - adjustment)
            return max(new_value, self.min_value)
        else:
            return self.current_value


@dataclass
class OpportunityAssessment:
    """Assessment of trading opportunity."""
    opportunity_score: float  # 0.0 to 1.0
    risk_score: float  # 0.0 to 1.0 (higher = more risk)
    market_condition: str  # "FAVORABLE", "NEUTRAL", "UNFAVORABLE"
    recommended_action: str  # "INCREASE", "DECREASE", "MAINTAIN", "AVOID"
    confidence: float  # 0.0 to 1.0
    reasoning: str
    factors: Dict[str, Any] = field(default_factory=dict)


class AdaptiveParameterEngine:
    """
    Converts hard trading rules into adaptive ML/AI-driven guidelines.
    
    Key Features:
    - Preemptive parameter adjustment based on opportunities
    - Intelligent capital allocation
    - Dynamic trade frequency adjustment
    - Loss prevention through early detection
    - Market condition awareness
    """
    
    def __init__(self):
        """Initialize adaptive parameter engine."""
        self.guidelines: Dict[str, ParameterGuideline] = {}
        self.opportunity_history: list[OpportunityAssessment] = []
        self.adjustment_history: list[Dict[str, Any]] = []
        self._initialize_guidelines()
        logger.info("AdaptiveParameterEngine initialized")
    
    def _initialize_guidelines(self):
        """Initialize parameter guidelines from base rules."""
        # Capital allocation guidelines
        self.guidelines["capital_allocation"] = ParameterGuideline(
            base_value=10000.0,
            current_value=10000.0,
            min_value=5000.0,  # Can reduce to 50% of base
            max_value=50000.0,  # Can increase to 5x base (with high confidence)
            adjustment_factor=1.0,
            confidence_threshold=0.75
        )
        
        # Trade frequency guidelines (trades per day)
        self.guidelines["trades_per_day"] = ParameterGuideline(
            base_value=27.0,
            current_value=27.0,
            min_value=10.0,  # Can reduce to 10 trades/day in bad conditions
            max_value=180.0,  # Can increase to 180 trades/day with high confidence
            adjustment_factor=1.0,
            confidence_threshold=0.7
        )
        
        # Position size guidelines
        self.guidelines["position_size"] = ParameterGuideline(
            base_value=1000.0,
            current_value=1000.0,
            min_value=500.0,  # Can reduce to 50% of base
            max_value=5000.0,  # Can increase to 5x base
            adjustment_factor=1.0,
            confidence_threshold=0.75
        )
        
        # VIX-based capacity guidelines
        self.guidelines["vix_capacity"] = ParameterGuideline(
            base_value=1.0,  # 100% capacity
            current_value=1.0,
            min_value=0.3,  # Can reduce to 30% capacity
            max_value=1.2,  # Can increase to 120% capacity
            adjustment_factor=1.0,
            confidence_threshold=0.7
        )
        
        # Daily loss limit (can be tightened preemptively)
        self.guidelines["daily_loss_limit"] = ParameterGuideline(
            base_value=5000.0,
            current_value=5000.0,
            min_value=2500.0,  # Can tighten to 50% if high risk detected
            max_value=5000.0,  # Never increase loss limit (safety)
            adjustment_factor=1.0,
            confidence_threshold=0.6
        )
        
        # Leverage guidelines
        self.guidelines["leverage"] = ParameterGuideline(
            base_value=3.0,
            current_value=3.0,
            min_value=1.5,  # Can reduce to 1.5x in high risk
            max_value=3.0,  # Never exceed base leverage (safety)
            adjustment_factor=1.0,
            confidence_threshold=0.7
        )
    
    def assess_opportunity(
        self,
        market_data: Dict[str, Any],
        signal_confidence: float,
        current_pnl: float,
        recent_performance: Dict[str, Any],
        vix_level: float
    ) -> OpportunityAssessment:
        """
        Assess trading opportunity using ML/AI intelligence.
        
        Args:
            market_data: Current market data (prices, volumes, trends)
            signal_confidence: AI signal confidence (0.0 to 1.0)
            current_pnl: Current profit/loss for the day
            recent_performance: Recent trading performance metrics
            vix_level: Current VIX level
            
        Returns:
            OpportunityAssessment with recommendations
        """
        # Calculate opportunity score based on multiple factors
        factors = {}
        
        # Factor 1: Signal confidence (weight: 30%)
        signal_factor = signal_confidence
        factors["signal_confidence"] = signal_factor
        
        # Factor 2: Market volatility (VIX) - lower VIX = better opportunity (weight: 20%)
        vix_factor = 1.0 - min(vix_level / 50.0, 1.0)  # Normalize VIX to 0-1
        factors["vix_factor"] = vix_factor
        
        # Factor 3: Recent performance (weight: 20%)
        win_rate = recent_performance.get("win_rate", 0.5)
        recent_pnl = recent_performance.get("recent_pnl", 0.0)
        performance_factor = (win_rate * 0.6) + (min(recent_pnl / 10000.0, 1.0) * 0.4)
        factors["performance_factor"] = performance_factor
        
        # Factor 4: Market trend (weight: 15%)
        trend = market_data.get("trend", "NEUTRAL")
        trend_factor = {
            "BULLISH": 0.9,
            "NEUTRAL": 0.5,
            "BEARISH": 0.2
        }.get(trend, 0.5)
        factors["trend_factor"] = trend_factor
        
        # Factor 5: Current PnL status (weight: 15%)
        # If already in profit, more conservative; if in loss, more cautious
        pnl_factor = 1.0 if current_pnl >= 0 else max(0.3, 1.0 + (current_pnl / 5000.0))
        factors["pnl_factor"] = pnl_factor
        
        # Calculate weighted opportunity score
        opportunity_score = (
            signal_factor * 0.30 +
            vix_factor * 0.20 +
            performance_factor * 0.20 +
            trend_factor * 0.15 +
            pnl_factor * 0.15
        )
        
        # Calculate risk score (inverse of opportunity, with additional risk factors)
        risk_factors = []
        if vix_level > 30:
            risk_factors.append(0.3)
        if current_pnl < -2000:
            risk_factors.append(0.3)
        if win_rate < 0.4:
            risk_factors.append(0.2)
        if trend == "BEARISH":
            risk_factors.append(0.2)
        
        risk_score = min(sum(risk_factors), 1.0) if risk_factors else (1.0 - opportunity_score)
        
        # Determine market condition
        if opportunity_score >= 0.7:
            market_condition = "FAVORABLE"
        elif opportunity_score >= 0.4:
            market_condition = "NEUTRAL"
        else:
            market_condition = "UNFAVORABLE"
        
        # Determine recommended action
        if opportunity_score >= 0.75 and risk_score < 0.3:
            recommended_action = "INCREASE"
            confidence = opportunity_score
            reasoning = f"High opportunity (score: {opportunity_score:.2f}) with low risk. Increase exposure."
        elif opportunity_score < 0.4 or risk_score > 0.6:
            recommended_action = "DECREASE"
            confidence = 1.0 - opportunity_score
            reasoning = f"Low opportunity (score: {opportunity_score:.2f}) or high risk (score: {risk_score:.2f}). Reduce exposure preemptively."
        elif risk_score > 0.5:
            recommended_action = "AVOID"
            confidence = risk_score
            reasoning = f"High risk detected (score: {risk_score:.2f}). Avoid new positions."
        else:
            recommended_action = "MAINTAIN"
            confidence = 0.5
            reasoning = f"Neutral conditions. Maintain current parameters."
        
        assessment = OpportunityAssessment(
            opportunity_score=opportunity_score,
            risk_score=risk_score,
            market_condition=market_condition,
            recommended_action=recommended_action,
            confidence=confidence,
            reasoning=reasoning,
            factors=factors
        )
        
        self.opportunity_history.append(assessment)
        # Keep only last 100 assessments
        if len(self.opportunity_history) > 100:
            self.opportunity_history.pop(0)
        
        logger.info(
            f"Opportunity assessed: {recommended_action} "
            f"(opportunity: {opportunity_score:.2f}, risk: {risk_score:.2f}, confidence: {confidence:.2f})"
        )
        
        return assessment
    
    def get_adjusted_parameter(
        self,
        parameter_name: str,
        opportunity_assessment: OpportunityAssessment
    ) -> float:
        """
        Get adjusted parameter value based on opportunity assessment.
        
        Args:
            parameter_name: Name of parameter to adjust
            opportunity_assessment: Current opportunity assessment
            
        Returns:
            Adjusted parameter value
        """
        if parameter_name not in self.guidelines:
            logger.warning(f"Unknown parameter: {parameter_name}, using base value")
            return 0.0
        
        guideline = self.guidelines[parameter_name]
        
        # Determine adjustment direction
        if opportunity_assessment.recommended_action == "INCREASE":
            direction = AdjustmentDirection.INCREASE
        elif opportunity_assessment.recommended_action in ["DECREASE", "AVOID"]:
            direction = AdjustmentDirection.DECREASE
        else:
            direction = AdjustmentDirection.MAINTAIN
        
        # Special handling for safety parameters (never increase)
        if parameter_name in ["daily_loss_limit", "leverage"]:
            if direction == AdjustmentDirection.INCREASE:
                direction = AdjustmentDirection.MAINTAIN
        
        # Get adjusted value
        adjusted_value = guideline.get_adjusted_value(
            ai_confidence=opportunity_assessment.confidence,
            direction=direction
        )
        
        # Update current value
        old_value = guideline.current_value
        guideline.current_value = adjusted_value
        guideline.last_adjusted = datetime.now()
        
        # Log adjustment
        if abs(adjusted_value - old_value) > 0.01:
            adjustment_record = {
                "timestamp": datetime.now().isoformat(),
                "parameter": parameter_name,
                "old_value": old_value,
                "new_value": adjusted_value,
                "adjustment_pct": ((adjusted_value - old_value) / old_value) * 100,
                "direction": direction.value,
                "confidence": opportunity_assessment.confidence,
                "reasoning": opportunity_assessment.reasoning
            }
            self.adjustment_history.append(adjustment_record)
            
            logger.info(
                f"Parameter adjusted: {parameter_name} "
                f"{old_value:.2f} → {adjusted_value:.2f} "
                f"({adjustment_record['adjustment_pct']:+.1f}%) "
                f"[{direction.value}, confidence: {opportunity_assessment.confidence:.2f}]"
            )
        
        return adjusted_value
    
    def get_all_adjusted_parameters(
        self,
        opportunity_assessment: OpportunityAssessment
    ) -> Dict[str, float]:
        """
        Get all adjusted parameters based on opportunity assessment.
        
        Args:
            opportunity_assessment: Current opportunity assessment
            
        Returns:
            Dictionary of adjusted parameter values
        """
        adjusted = {}
        for param_name in self.guidelines:
            adjusted[param_name] = self.get_adjusted_parameter(
                param_name,
                opportunity_assessment
            )
        return adjusted
    
    def reset_to_base(self, parameter_name: Optional[str] = None):
        """
        Reset parameter(s) to base value.
        
        Args:
            parameter_name: Specific parameter to reset, or None to reset all
        """
        if parameter_name:
            if parameter_name in self.guidelines:
                self.guidelines[parameter_name].current_value = self.guidelines[parameter_name].base_value
                logger.info(f"Reset {parameter_name} to base value")
        else:
            for param_name, guideline in self.guidelines.items():
                guideline.current_value = guideline.base_value
            logger.info("Reset all parameters to base values")
    
    def get_guideline_status(self) -> Dict[str, Any]:
        """Get current status of all guidelines."""
        status = {}
        for param_name, guideline in self.guidelines.items():
            status[param_name] = {
                "base_value": guideline.base_value,
                "current_value": guideline.current_value,
                "min_value": guideline.min_value,
                "max_value": guideline.max_value,
                "adjustment_pct": ((guideline.current_value - guideline.base_value) / guideline.base_value) * 100,
                "last_adjusted": guideline.last_adjusted.isoformat() if guideline.last_adjusted else None
            }
        return status
    
    def get_adjustment_history(self, limit: int = 50) -> list[Dict[str, Any]]:
        """Get recent adjustment history."""
        return self.adjustment_history[-limit:]


# Default instance
adaptive_parameter_engine = AdaptiveParameterEngine()

__all__ = [
    "AdaptiveParameterEngine",
    "ParameterGuideline",
    "OpportunityAssessment",
    "AdjustmentDirection",
    "adaptive_parameter_engine",
]
