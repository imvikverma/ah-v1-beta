"""
Trade Direction Switcher
Preemptively switches trade direction (Bullish ↔ Bearish) to prevent losses.

Uses ML/AI to:
- Detect early trend reversal signals
- Predict direction changes before they occur
- Automatically switch positions to prevent losses
- Maximize profit by catching reversals early
"""

from __future__ import annotations

import logging
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from collections import deque
import numpy as np

logger = logging.getLogger(__name__)


class TradeDirection(str, Enum):
    """Trade direction."""
    BULLISH = "BULLISH"  # Expecting price to go up
    BEARISH = "BEARISH"  # Expecting price to go down
    NEUTRAL = "NEUTRAL"  # No clear direction


class ReversalSignal(str, Enum):
    """Reversal signal types."""
    TREND_REVERSAL = "TREND_REVERSAL"  # Strong trend reversal detected
    MOMENTUM_SHIFT = "MOMENTUM_SHIFT"  # Momentum changing direction
    SUPPORT_RESISTANCE = "SUPPORT_RESISTANCE"  # Hit support/resistance levels
    VOLUME_SPIKE = "VOLUME_SPIKE"  # Volume spike indicating reversal
    DIVERGENCE = "DIVERGENCE"  # Price/indicator divergence
    EARLY_WARNING = "EARLY_WARNING"  # Early warning before full reversal


@dataclass
class DirectionSwitchRecommendation:
    """Recommendation to switch trade direction."""
    current_direction: TradeDirection
    recommended_direction: TradeDirection
    confidence: float  # 0.0 to 1.0
    urgency: str  # "LOW", "MEDIUM", "HIGH", "CRITICAL"
    reversal_signal: ReversalSignal
    reasoning: str
    expected_loss_prevention: float  # Expected loss prevented by switching
    factors: Dict[str, Any] = field(default_factory=dict)
    detected_at: datetime = field(default_factory=datetime.now)


@dataclass
class TrendAnalysis:
    """Analysis of current trend."""
    direction: TradeDirection
    strength: float  # 0.0 to 1.0
    momentum: float  # -1.0 to 1.0 (negative = bearish, positive = bullish)
    reversal_probability: float  # 0.0 to 1.0
    support_level: Optional[float] = None
    resistance_level: Optional[float] = None
    factors: Dict[str, Any] = field(default_factory=dict)


class TradeDirectionSwitcher:
    """
    Preemptively switches trade direction to prevent losses.
    
    Features:
    - Early reversal detection
    - Trend analysis
    - Momentum shift identification
    - Support/resistance level detection
    - Volume analysis
    - Automatic direction switching
    """
    
    def __init__(self, lookback_period: int = 20):
        """
        Initialize trade direction switcher.
        
        Args:
            lookback_period: Number of periods to analyze for trends
        """
        self.lookback_period = lookback_period
        self.price_history: deque[float] = deque(maxlen=lookback_period * 2)
        self.volume_history: deque[float] = deque(maxlen=lookback_period * 2)
        self.direction_history: deque[TradeDirection] = deque(maxlen=50)
        self.switch_recommendations: deque[DirectionSwitchRecommendation] = deque(maxlen=100)
        self.current_direction: Optional[TradeDirection] = None
        self.last_switch_time: Optional[datetime] = None
        self.switch_cooldown: timedelta = timedelta(minutes=2)  # Reduced for more responsive preemptive switching
        
        logger.info(f"TradeDirectionSwitcher initialized (lookback: {lookback_period})")
    
    def analyze_trend(
        self,
        prices: List[float],
        volumes: Optional[List[float]] = None,
        indicators: Optional[Dict[str, Any]] = None
    ) -> TrendAnalysis:
        """
        Analyze current trend and predict reversals.
        
        Args:
            prices: Recent price data
            volumes: Recent volume data (optional)
            indicators: Technical indicators (RSI, MACD, etc.)
            
        Returns:
            TrendAnalysis with direction and reversal probability
        """
        if len(prices) < 5:
            return TrendAnalysis(
                direction=TradeDirection.NEUTRAL,
                strength=0.0,
                momentum=0.0,
                reversal_probability=0.5
            )
        
        # Calculate trend direction
        recent_prices = prices[-self.lookback_period:] if len(prices) >= self.lookback_period else prices
        
        # Simple moving average
        short_ma = np.mean(recent_prices[-5:]) if len(recent_prices) >= 5 else recent_prices[-1]
        long_ma = np.mean(recent_prices[-10:]) if len(recent_prices) >= 10 else short_ma
        
        # Price momentum
        price_changes = [prices[i] - prices[i-1] for i in range(1, len(prices))]
        momentum = np.mean(price_changes[-5:]) if len(price_changes) >= 5 else 0.0
        
        # Determine direction
        if short_ma > long_ma * 1.01 and momentum > 0:  # 1% above long MA with positive momentum
            direction = TradeDirection.BULLISH
            strength = min(abs(momentum) / (long_ma * 0.01), 1.0)  # Normalize strength
        elif short_ma < long_ma * 0.99 and momentum < 0:  # 1% below long MA with negative momentum
            direction = TradeDirection.BEARISH
            strength = min(abs(momentum) / (long_ma * 0.01), 1.0)
        else:
            direction = TradeDirection.NEUTRAL
            strength = 0.3
        
        # Calculate reversal probability
        reversal_factors = []
        
        # Factor 1: Momentum weakening
        if len(price_changes) >= 10:
            recent_momentum = np.mean(price_changes[-3:])
            earlier_momentum = np.mean(price_changes[-6:-3])
            momentum_weakening = abs(recent_momentum) < abs(earlier_momentum) * 0.7
            if momentum_weakening:
                reversal_factors.append(0.3)
        
        # Factor 2: Price approaching support/resistance
        current_price = prices[-1]
        support = min(recent_prices) * 0.998  # 0.2% below recent low
        resistance = max(recent_prices) * 1.002  # 0.2% above recent high
        
        if direction == TradeDirection.BULLISH:
            # Approaching resistance = reversal risk
            if current_price >= resistance * 0.995:
                reversal_factors.append(0.4)
        elif direction == TradeDirection.BEARISH:
            # Approaching support = reversal risk
            if current_price <= support * 1.005:
                reversal_factors.append(0.4)
        
        # Factor 3: Volume analysis (if available)
        if volumes and len(volumes) >= 5:
            recent_volume = np.mean(volumes[-3:])
            avg_volume = np.mean(volumes[-10:]) if len(volumes) >= 10 else recent_volume
            volume_spike = recent_volume > avg_volume * 1.5
            if volume_spike:
                # High volume can indicate reversal
                reversal_factors.append(0.3)
        
        # Factor 4: Technical indicators (if available)
        if indicators:
            rsi = indicators.get("rsi")
            if rsi:
                # RSI overbought (>70) or oversold (<30) suggests reversal
                if rsi > 70:
                    reversal_factors.append(0.4)  # Overbought, expect bearish reversal
                elif rsi < 30:
                    reversal_factors.append(0.4)  # Oversold, expect bullish reversal
            
            macd = indicators.get("macd")
            macd_signal = indicators.get("macd_signal")
            if macd and macd_signal:
                # MACD crossing signal line indicates reversal
                if (macd > macd_signal and direction == TradeDirection.BEARISH) or \
                   (macd < macd_signal and direction == TradeDirection.BULLISH):
                    reversal_factors.append(0.5)  # Strong reversal signal
        
        # Calculate overall reversal probability
        reversal_probability = min(sum(reversal_factors), 1.0) if reversal_factors else 0.2
        
        # Normalize momentum to -1.0 to 1.0
        normalized_momentum = np.tanh(momentum / (long_ma * 0.01)) if long_ma > 0 else 0.0
        
        analysis = TrendAnalysis(
            direction=direction,
            strength=strength,
            momentum=normalized_momentum,
            reversal_probability=reversal_probability,
            support_level=support,
            resistance_level=resistance,
            factors={
                "short_ma": short_ma,
                "long_ma": long_ma,
                "momentum": momentum,
                "reversal_factors_count": len(reversal_factors),
                "indicators": indicators or {}
            }
        )
        
        return analysis
    
    def detect_reversal(
        self,
        current_direction: TradeDirection,
        trend_analysis: TrendAnalysis,
        current_position_pnl: float,
        position_entry_price: float,
        current_price: float
    ) -> Optional[DirectionSwitchRecommendation]:
        """
        Detect if direction should be switched to prevent losses.
        
        Args:
            current_direction: Current trade direction
            trend_analysis: Current trend analysis
            current_position_pnl: Current PnL of open position
            position_entry_price: Entry price of current position
            current_price: Current market price
            
        Returns:
            DirectionSwitchRecommendation if switch recommended, None otherwise
        """
        # Check cooldown period
        if self.last_switch_time:
            time_since_switch = datetime.now() - self.last_switch_time
            if time_since_switch < self.switch_cooldown:
                return None  # Too soon to switch again
        
        # If no current direction, set based on trend
        if current_direction is None:
            self.current_direction = trend_analysis.direction
            return None
        
        # Check if trend direction has changed
        direction_changed = trend_analysis.direction != current_direction
        
        # Calculate expected loss if we don't switch
        if current_position_pnl < 0:
            # Already in loss - calculate potential further loss
            if current_direction == TradeDirection.BULLISH and trend_analysis.direction == TradeDirection.BEARISH:
                # Bullish position but trend turned bearish
                potential_loss = abs(current_price - position_entry_price) * 0.02  # Estimate 2% further loss
                expected_loss_prevention = abs(current_position_pnl) + potential_loss
            elif current_direction == TradeDirection.BEARISH and trend_analysis.direction == TradeDirection.BULLISH:
                # Bearish position but trend turned bullish
                potential_loss = abs(position_entry_price - current_price) * 0.02
                expected_loss_prevention = abs(current_position_pnl) + potential_loss
            else:
                expected_loss_prevention = abs(current_position_pnl)  # Prevent current loss
        else:
            # In profit but trend reversing - protect profits
            if direction_changed and trend_analysis.reversal_probability > 0.6:
                expected_loss_prevention = current_position_pnl * 0.5  # Protect 50% of profit
            else:
                expected_loss_prevention = 0.0
        
        # Determine if switch is recommended
        should_switch = False
        urgency = "LOW"
        reversal_signal = ReversalSignal.EARLY_WARNING
        reasoning_parts = []
        
        # ENHANCED PREEMPTIVE CONDITIONS (More aggressive loss prevention)
        
        # Condition 1: Early warning - momentum weakening (PREEMPTIVE)
        if len(self.price_history) >= 10:
            recent_momentum = np.mean([self.price_history[-i] - self.price_history[-i-1] for i in range(1, min(4, len(self.price_history)))])
            earlier_momentum = np.mean([self.price_history[-i] - self.price_history[-i-1] for i in range(4, min(8, len(self.price_history)))])
            momentum_weakening = abs(recent_momentum) < abs(earlier_momentum) * 0.6  # 40% momentum loss
            
            if momentum_weakening and trend_analysis.reversal_probability >= 0.4:
                should_switch = True
                urgency = "MEDIUM"
                reversal_signal = ReversalSignal.EARLY_WARNING
                reasoning_parts.append(
                    f"PREEMPTIVE: Momentum weakening (40% loss detected). "
                    f"Early switch to prevent losses before reversal completes."
                )
        
        # Condition 2: Strong reversal signal with high probability
        if direction_changed and trend_analysis.reversal_probability >= 0.65:  # Lowered from 0.7 for earlier detection
            should_switch = True
            urgency = "HIGH"
            reversal_signal = ReversalSignal.TREND_REVERSAL
            reasoning_parts.append(f"Strong trend reversal detected (probability: {trend_analysis.reversal_probability:.1%})")
        
        # Condition 3: Position in loss and trend reversing (MORE AGGRESSIVE)
        elif current_position_pnl < -200 and direction_changed:  # Lowered from -500 for earlier intervention
            should_switch = True
            urgency = "CRITICAL" if current_position_pnl < -1000 else "HIGH"  # More aggressive thresholds
            reversal_signal = ReversalSignal.MOMENTUM_SHIFT
            reasoning_parts.append(
                f"PREEMPTIVE: Position in loss (₹{current_position_pnl:,.2f}) and trend reversing. "
                f"Early switch to prevent further losses."
            )
        
        # Condition 4: High reversal probability with ANY position (not just loss)
        elif trend_analysis.reversal_probability >= 0.55:  # Lowered from 0.6 for earlier detection
            if current_position_pnl < 0:
                should_switch = True
                urgency = "MEDIUM" if current_position_pnl > -500 else "HIGH"
                reversal_signal = ReversalSignal.EARLY_WARNING
                reasoning_parts.append(
                    f"PREEMPTIVE: High reversal probability ({trend_analysis.reversal_probability:.1%}) detected. "
                    f"Switching early to prevent losses."
                )
            elif current_position_pnl > 0 and trend_analysis.reversal_probability >= 0.65:
                # Protect profits if reversal is very likely
                should_switch = True
                urgency = "MEDIUM"
                reversal_signal = ReversalSignal.EARLY_WARNING
                reasoning_parts.append(
                    f"PREEMPTIVE: High reversal probability ({trend_analysis.reversal_probability:.1%}) with profit position. "
                    f"Switching to protect gains."
                )
        
        # Condition 5: Approaching support/resistance with momentum shift (MORE SENSITIVE)
        elif trend_analysis.reversal_probability >= 0.45:  # Lowered from 0.5
            if current_direction == TradeDirection.BULLISH and current_price >= trend_analysis.resistance_level * 0.998:  # More sensitive (0.998 vs 0.995)
                should_switch = True
                urgency = "MEDIUM"
                reversal_signal = ReversalSignal.SUPPORT_RESISTANCE
                reasoning_parts.append("PREEMPTIVE: Approaching resistance level (within 0.2%) with reversal signals")
            elif current_direction == TradeDirection.BEARISH and current_price <= trend_analysis.support_level * 1.002:  # More sensitive
                should_switch = True
                urgency = "MEDIUM"
                reversal_signal = ReversalSignal.SUPPORT_RESISTANCE
                reasoning_parts.append("PREEMPTIVE: Approaching support level (within 0.2%) with reversal signals")
        
        # Condition 6: Volume spike indicating reversal (NEW - PREEMPTIVE)
        if len(self.volume_history) >= 5:
            recent_volume = np.mean(list(self.volume_history)[-3:])
            avg_volume = np.mean(list(self.volume_history)[-10:]) if len(self.volume_history) >= 10 else recent_volume
            volume_spike = recent_volume > avg_volume * 1.8  # 80% volume increase
            
            if volume_spike and trend_analysis.reversal_probability >= 0.4:
                should_switch = True
                urgency = "MEDIUM"
                reversal_signal = ReversalSignal.VOLUME_SPIKE
                reasoning_parts.append(
                    f"PREEMPTIVE: Volume spike detected ({recent_volume/avg_volume:.1f}× average). "
                    f"Early reversal signal - switching to prevent losses."
                )
        
        # Condition 7: Divergence detection (NEW - PREEMPTIVE)
        # Get indicators from trend_analysis factors if available
        indicators = trend_analysis.factors.get("indicators", {}) if trend_analysis.factors else {}
        if indicators:
            rsi = indicators.get("rsi")
            if rsi:
                # RSI divergence: price making new highs but RSI not, or vice versa
                if current_direction == TradeDirection.BULLISH and rsi < 50 and trend_analysis.momentum < 0.2:
                    # Bullish position but RSI weakening
                    should_switch = True
                    urgency = "MEDIUM"
                    reversal_signal = ReversalSignal.DIVERGENCE
                    reasoning_parts.append(
                        f"PREEMPTIVE: RSI divergence detected (RSI: {rsi:.1f}, momentum weakening). "
                        f"Early switch to prevent losses."
                    )
                elif current_direction == TradeDirection.BEARISH and rsi > 50 and trend_analysis.momentum > -0.2:
                    # Bearish position but RSI strengthening
                    should_switch = True
                    urgency = "MEDIUM"
                    reversal_signal = ReversalSignal.DIVERGENCE
                    reasoning_parts.append(
                        f"PREEMPTIVE: RSI divergence detected (RSI: {rsi:.1f}, momentum strengthening). "
                        f"Early switch to prevent losses."
                    )
        
        if not should_switch:
            return None
        
        # Calculate confidence
        confidence = min(
            trend_analysis.reversal_probability * 0.7 +  # Base on reversal probability
            (trend_analysis.strength * 0.2) +  # Trend strength
            (0.1 if abs(current_position_pnl) > 1000 else 0.0),  # Higher confidence if significant loss
            1.0
        )
        
        # Determine recommended direction
        recommended_direction = trend_analysis.direction
        
        recommendation = DirectionSwitchRecommendation(
            current_direction=current_direction,
            recommended_direction=recommended_direction,
            confidence=confidence,
            urgency=urgency,
            reversal_signal=reversal_signal,
            reasoning="; ".join(reasoning_parts),
            expected_loss_prevention=expected_loss_prevention,
            factors={
                "trend_strength": trend_analysis.strength,
                "momentum": trend_analysis.momentum,
                "reversal_probability": trend_analysis.reversal_probability,
                "current_pnl": current_position_pnl,
                "support_level": trend_analysis.support_level,
                "resistance_level": trend_analysis.resistance_level
            }
        )
        
        self.switch_recommendations.append(recommendation)
        logger.warning(
            f"Direction switch recommended: {current_direction.value} → {recommended_direction.value} "
            f"(confidence: {confidence:.2f}, urgency: {urgency}, "
            f"expected loss prevention: ₹{expected_loss_prevention:,.2f})"
        )
        
        return recommendation
    
    def should_switch_direction(
        self,
        current_direction: TradeDirection,
        prices: List[float],
        volumes: Optional[List[float]] = None,
        indicators: Optional[Dict[str, Any]] = None,
        current_position_pnl: float = 0.0,
        position_entry_price: Optional[float] = None,
        current_price: Optional[float] = None,
        ai_direction_prediction: Optional[Dict[str, Any]] = None
    ) -> Optional[DirectionSwitchRecommendation]:
        """
        Main method to determine if direction should be switched.
        
        Args:
            current_direction: Current trade direction
            prices: Recent price data
            volumes: Recent volume data
            indicators: Technical indicators
            current_position_pnl: Current position PnL
            position_entry_price: Entry price of position
            current_price: Current market price
            
        Returns:
            DirectionSwitchRecommendation if switch recommended, None otherwise
        """
        # Update price history
        self.price_history.extend(prices[-self.lookback_period:])
        if volumes:
            self.volume_history.extend(volumes[-self.lookback_period:])
        
        # Use AI direction prediction if available (from PredictiveAIEngine)
        if ai_direction_prediction:
            ai_direction_str = ai_direction_prediction.get("direction", "neutral").upper()
            ai_confidence = ai_direction_prediction.get("confidence", 0.5)
            
            # Map AI direction to TradeDirection enum
            if ai_direction_str == "BULLISH":
                ai_direction = TradeDirection.BULLISH
            elif ai_direction_str == "BEARISH":
                ai_direction = TradeDirection.BEARISH
            else:
                ai_direction = TradeDirection.NEUTRAL
            
            # If AI prediction differs from current direction and confidence is high, prioritize AI
            if ai_direction != current_direction and ai_confidence >= 0.7:
                logger.info(
                    f"AI direction prediction differs: {current_direction.value} → {ai_direction.value} "
                    f"(confidence: {ai_confidence:.2f})"
                )
                # Use AI direction as primary signal
                trend_analysis = TrendAnalysis(
                    direction=ai_direction,
                    strength=ai_confidence,
                    momentum=0.5 if ai_direction == TradeDirection.BULLISH else -0.5,
                    reversal_probability=0.8 if ai_direction != current_direction else 0.2,
                    factors={"ai_prediction": ai_direction_prediction}
                )
            else:
                # Analyze trend normally, but incorporate AI prediction
                trend_analysis = self.analyze_trend(
                    prices=list(self.price_history) if self.price_history else prices,
                    volumes=list(self.volume_history) if self.volume_history else volumes,
                    indicators=indicators
                )
                # Adjust reversal probability based on AI prediction
                if ai_direction != current_direction:
                    trend_analysis.reversal_probability = min(
                        trend_analysis.reversal_probability + (ai_confidence * 0.3),
                        1.0
                    )
        else:
            # Analyze trend normally
            trend_analysis = self.analyze_trend(
                prices=list(self.price_history) if self.price_history else prices,
                volumes=list(self.volume_history) if self.volume_history else volumes,
                indicators=indicators
            )
        
        # Use current price from prices if not provided
        if current_price is None and prices:
            current_price = prices[-1]
        
        # Use current price as entry if not provided (for testing)
        if position_entry_price is None:
            position_entry_price = current_price if current_price else prices[-1] if prices else 0.0
        
        # Detect reversal
        recommendation = self.detect_reversal(
            current_direction=current_direction,
            trend_analysis=trend_analysis,
            current_position_pnl=current_position_pnl,
            position_entry_price=position_entry_price,
            current_price=current_price or prices[-1] if prices else 0.0
        )
        
        # Update current direction if switch recommended
        if recommendation:
            self.current_direction = recommendation.recommended_direction
            self.last_switch_time = datetime.now()
            self.direction_history.append(self.current_direction)
        
        return recommendation
    
    def get_current_direction(self) -> Optional[TradeDirection]:
        """Get current trade direction."""
        return self.current_direction
    
    def get_switch_history(self, limit: int = 20) -> List[DirectionSwitchRecommendation]:
        """Get recent switch recommendations."""
        return list(self.switch_recommendations)[-limit:]


# Default instance
trade_direction_switcher = TradeDirectionSwitcher()

__all__ = [
    "TradeDirectionSwitcher",
    "TradeDirection",
    "ReversalSignal",
    "DirectionSwitchRecommendation",
    "TrendAnalysis",
    "trade_direction_switcher",
]
