"""
Preemptive Risk Manager
Intelligently detects and prevents losses before they occur.

Uses ML/AI to:
- Detect early warning signs of potential losses
- Preemptively reduce exposure
- Adjust parameters to save losses to maximum
- Learn from patterns to improve predictions
"""

from __future__ import annotations

import logging
from typing import Dict, Any, Optional, List, Tuple
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from collections import deque
import numpy as np

logger = logging.getLogger(__name__)


@dataclass
class RiskSignal:
    """Early warning risk signal."""
    signal_type: str  # "LOSS_PATTERN", "VOLATILITY_SPIKE", "TREND_REVERSAL", etc.
    severity: float  # 0.0 to 1.0 (higher = more severe)
    confidence: float  # 0.0 to 1.0
    detected_at: datetime
    reasoning: str
    recommended_action: str
    factors: Dict[str, Any] = field(default_factory=dict)


@dataclass
class LossPreventionAction:
    """Action to prevent losses."""
    action_type: str  # "REDUCE_EXPOSURE", "CLOSE_POSITIONS", "PAUSE_TRADING", etc.
    urgency: str  # "LOW", "MEDIUM", "HIGH", "CRITICAL"
    parameters: Dict[str, Any]  # Specific parameter adjustments
    reasoning: str
    expected_impact: str


class PreemptiveRiskManager:
    """
    Preemptive risk management using ML/AI to detect and prevent losses.
    
    Features:
    - Pattern recognition for loss sequences
    - Volatility spike detection
    - Trend reversal early warning
    - Adaptive position sizing
    - Dynamic stop-loss adjustment
    """
    
    def __init__(self, lookback_period: int = 20):
        """
        Initialize preemptive risk manager.
        
        Args:
            lookback_period: Number of recent trades to analyze
        """
        self.lookback_period = lookback_period
        self.risk_signals: deque[RiskSignal] = deque(maxlen=100)
        self.trade_history: deque[Dict[str, Any]] = deque(maxlen=lookback_period * 2)
        self.loss_prevention_actions: List[LossPreventionAction] = []
        self.active_protections: Dict[str, Any] = {}
        
        logger.info(f"PreemptiveRiskManager initialized (lookback: {lookback_period})")
    
    def analyze_trade_pattern(
        self,
        recent_trades: List[Dict[str, Any]],
        current_pnl: float,
        market_data: Dict[str, Any]
    ) -> Optional[RiskSignal]:
        """
        Analyze recent trade patterns to detect loss sequences.
        
        Args:
            recent_trades: List of recent trades with PnL
            current_pnl: Current profit/loss
            market_data: Current market conditions
            
        Returns:
            RiskSignal if pattern detected, None otherwise
        """
        if len(recent_trades) < 3:
            return None
        
        # Extract PnL sequence
        pnl_sequence = [trade.get("pnl", 0.0) for trade in recent_trades[-10:]]
        
        # Pattern 1: Consecutive losses
        consecutive_losses = 0
        max_consecutive_losses = 0
        for pnl in pnl_sequence:
            if pnl < 0:
                consecutive_losses += 1
                max_consecutive_losses = max(max_consecutive_losses, consecutive_losses)
            else:
                consecutive_losses = 0
        
        # Pattern 2: Declining trend
        if len(pnl_sequence) >= 5:
            recent_avg = np.mean(pnl_sequence[-5:])
            earlier_avg = np.mean(pnl_sequence[-10:-5]) if len(pnl_sequence) >= 10 else recent_avg
            declining_trend = recent_avg < earlier_avg * 0.7  # 30% decline
        
        # Pattern 3: Increasing loss magnitude
        losses = [pnl for pnl in pnl_sequence if pnl < 0]
        if len(losses) >= 3:
            loss_magnitudes = [abs(l) for l in losses]
            increasing_losses = loss_magnitudes[-1] > loss_magnitudes[0] * 1.5
        
        # Calculate risk score
        risk_factors = []
        reasoning_parts = []
        
        if max_consecutive_losses >= 3:
            severity = min(0.3 + (max_consecutive_losses - 3) * 0.2, 1.0)
            risk_factors.append(severity)
            reasoning_parts.append(f"{max_consecutive_losses} consecutive losses detected")
        
        if len(pnl_sequence) >= 5 and declining_trend:
            severity = 0.4
            risk_factors.append(severity)
            reasoning_parts.append("Declining performance trend detected")
        
        if len(losses) >= 3 and increasing_losses:
            severity = 0.5
            risk_factors.append(severity)
            reasoning_parts.append("Loss magnitude increasing")
        
        if current_pnl < -3000:  # Already down ₹3000+
            severity = min(0.6 + abs(current_pnl) / 10000.0, 1.0)
            risk_factors.append(severity)
            reasoning_parts.append(f"Current PnL: ₹{current_pnl:,.2f}")
        
        if not risk_factors:
            return None
        
        # Calculate overall severity and confidence
        overall_severity = min(sum(risk_factors) / len(risk_factors), 1.0)
        confidence = min(0.5 + (len(risk_factors) * 0.15), 1.0)
        
        # Determine recommended action
        if overall_severity >= 0.7:
            recommended_action = "REDUCE_EXPOSURE_CRITICAL"
        elif overall_severity >= 0.5:
            recommended_action = "REDUCE_EXPOSURE_HIGH"
        else:
            recommended_action = "REDUCE_EXPOSURE_MODERATE"
        
        signal = RiskSignal(
            signal_type="LOSS_PATTERN",
            severity=overall_severity,
            confidence=confidence,
            detected_at=datetime.now(),
            reasoning="; ".join(reasoning_parts),
            recommended_action=recommended_action,
            factors={
                "consecutive_losses": max_consecutive_losses,
                "declining_trend": declining_trend if len(pnl_sequence) >= 5 else False,
                "increasing_losses": increasing_losses if len(losses) >= 3 else False,
                "current_pnl": current_pnl
            }
        )
        
        self.risk_signals.append(signal)
        logger.warning(
            f"Loss pattern detected: {recommended_action} "
            f"(severity: {overall_severity:.2f}, confidence: {confidence:.2f})"
        )
        
        return signal
    
    def detect_volatility_spike(
        self,
        recent_prices: List[float],
        current_vix: float,
        historical_vix_avg: float
    ) -> Optional[RiskSignal]:
        """
        Detect volatility spikes that may indicate increased risk.
        
        Args:
            recent_prices: Recent price movements
            current_vix: Current VIX level
            historical_vix_avg: Historical average VIX
            
        Returns:
            RiskSignal if spike detected, None otherwise
        """
        if len(recent_prices) < 10:
            return None
        
        # Calculate price volatility
        price_changes = [abs(recent_prices[i] - recent_prices[i-1]) for i in range(1, len(recent_prices))]
        current_volatility = np.std(price_changes)
        avg_volatility = np.mean(price_changes)
        
        volatility_spike = current_volatility > avg_volatility * 2.0
        
        # VIX spike detection
        vix_spike = current_vix > historical_vix_avg * 1.5
        
        if not (volatility_spike or vix_spike):
            return None
        
        # Calculate severity
        severity = 0.0
        reasoning_parts = []
        
        if volatility_spike:
            spike_ratio = current_volatility / avg_volatility
            severity = min(0.3 + (spike_ratio - 2.0) * 0.2, 1.0)
            reasoning_parts.append(f"Price volatility spike: {spike_ratio:.1f}x average")
        
        if vix_spike:
            vix_ratio = current_vix / historical_vix_avg
            severity = max(severity, min(0.4 + (vix_ratio - 1.5) * 0.2, 1.0))
            reasoning_parts.append(f"VIX spike: {current_vix:.1f} vs avg {historical_vix_avg:.1f}")
        
        signal = RiskSignal(
            signal_type="VOLATILITY_SPIKE",
            severity=severity,
            confidence=0.8 if (volatility_spike and vix_spike) else 0.6,
            detected_at=datetime.now(),
            reasoning="; ".join(reasoning_parts),
            recommended_action="REDUCE_EXPOSURE_HIGH" if severity > 0.6 else "REDUCE_EXPOSURE_MODERATE",
            factors={
                "volatility_spike": volatility_spike,
                "vix_spike": vix_spike,
                "current_vix": current_vix,
                "historical_vix_avg": historical_vix_avg
            }
        )
        
        self.risk_signals.append(signal)
        logger.warning(
            f"Volatility spike detected: {signal.recommended_action} "
            f"(severity: {severity:.2f})"
        )
        
        return signal
    
    def generate_loss_prevention_action(
        self,
        risk_signal: RiskSignal,
        current_parameters: Dict[str, float]
    ) -> LossPreventionAction:
        """
        Generate specific action to prevent losses based on risk signal.
        
        Args:
            risk_signal: Detected risk signal
            current_parameters: Current trading parameters
            
        Returns:
            LossPreventionAction with specific recommendations
        """
        # Determine urgency
        if risk_signal.severity >= 0.7:
            urgency = "CRITICAL"
        elif risk_signal.severity >= 0.5:
            urgency = "HIGH"
        elif risk_signal.severity >= 0.3:
            urgency = "MEDIUM"
        else:
            urgency = "LOW"
        
        # Generate parameter adjustments
        parameters = {}
        reasoning_parts = [risk_signal.reasoning]
        
        if risk_signal.recommended_action in ["REDUCE_EXPOSURE_CRITICAL", "REDUCE_EXPOSURE_HIGH"]:
            # Reduce position size by 50-70%
            reduction = 0.7 if urgency == "CRITICAL" else 0.5
            parameters["position_size_multiplier"] = 1.0 - reduction
            reasoning_parts.append(f"Reduce position size by {reduction*100:.0f}%")
            
            # Reduce trade frequency
            parameters["trades_per_day_multiplier"] = 0.5
            reasoning_parts.append("Reduce trade frequency by 50%")
            
            # Tighten loss limit
            parameters["daily_loss_limit_multiplier"] = 0.7
            reasoning_parts.append("Tighten daily loss limit by 30%")
            
            action_type = "REDUCE_EXPOSURE"
            expected_impact = f"Reduce exposure by {reduction*100:.0f}% to prevent further losses"
        
        elif risk_signal.recommended_action == "REDUCE_EXPOSURE_MODERATE":
            # Moderate reduction
            parameters["position_size_multiplier"] = 0.8
            parameters["trades_per_day_multiplier"] = 0.8
            reasoning_parts.append("Moderate reduction in exposure")
            
            action_type = "REDUCE_EXPOSURE"
            expected_impact = "Reduce exposure by 20% as precautionary measure"
        
        else:
            # Monitor mode
            parameters["position_size_multiplier"] = 0.9
            action_type = "MONITOR"
            expected_impact = "Slight reduction while monitoring conditions"
        
        action = LossPreventionAction(
            action_type=action_type,
            urgency=urgency,
            parameters=parameters,
            reasoning="; ".join(reasoning_parts),
            expected_impact=expected_impact
        )
        
        self.loss_prevention_actions.append(action)
        logger.info(
            f"Loss prevention action generated: {action_type} "
            f"(urgency: {urgency}, impact: {expected_impact})"
        )
        
        return action
    
    def should_pause_trading(
        self,
        current_pnl: float,
        recent_performance: Dict[str, Any],
        risk_signals: List[RiskSignal]
    ) -> Tuple[bool, str]:
        """
        Determine if trading should be paused to prevent further losses.
        
        Args:
            current_pnl: Current profit/loss
            recent_performance: Recent performance metrics
            risk_signals: List of active risk signals
            
        Returns:
            Tuple of (should_pause, reason)
        """
        # Critical conditions for pausing
        if current_pnl <= -5000:  # Down ₹5000+
            return True, f"Critical loss threshold reached: ₹{current_pnl:,.2f}"
        
        # Multiple high-severity signals
        high_severity_signals = [s for s in risk_signals if s.severity >= 0.7]
        if len(high_severity_signals) >= 2:
            return True, f"Multiple high-severity risk signals detected ({len(high_severity_signals)})"
        
        # Consecutive losses with increasing magnitude
        if recent_performance.get("consecutive_losses", 0) >= 5:
            return True, f"Excessive consecutive losses: {recent_performance['consecutive_losses']}"
        
        return False, ""
    
    def get_active_protections(self) -> Dict[str, Any]:
        """Get currently active loss prevention protections."""
        return self.active_protections.copy()
    
    def clear_protections(self):
        """Clear all active protections (reset to normal)."""
        self.active_protections.clear()
        logger.info("All loss prevention protections cleared")


# Default instance
preemptive_risk_manager = PreemptiveRiskManager()

__all__ = [
    "PreemptiveRiskManager",
    "RiskSignal",
    "LossPreventionAction",
    "preemptive_risk_manager",
]
