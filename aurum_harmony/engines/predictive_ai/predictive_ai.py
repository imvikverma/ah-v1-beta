"""
Predictive AI Engine for AurumHarmony

Provides AI-powered trading signals and predictions.
Integrates with VIX adjustment logic and market analysis.
"""

from __future__ import annotations

import logging
from typing import List, Dict, Any, Optional
from datetime import datetime
from dataclasses import dataclass

from aurum_harmony.app.orchestrator import TradeSignal, SignalSource
from aurum_harmony.engines.trade_execution.trade_execution import OrderSide

# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class MarketSignal:
    """Market analysis signal with confidence score."""
    symbol: str
    side: OrderSide
    quantity: float
    confidence: float  # 0.0 to 1.0
    reason: str
    predicted_price: Optional[float] = None
    stop_loss: Optional[float] = None
    target_price: Optional[float] = None
    timestamp: float = 0.0
    
    def __post_init__(self):
        if self.timestamp == 0.0:
            import time
            self.timestamp = time.time()
        
        # Validate confidence
        if not 0.0 <= self.confidence <= 1.0:
            logger.warning(f"Confidence out of range: {self.confidence}, clamping to [0, 1]")
            self.confidence = max(0.0, min(1.0, self.confidence))


class PredictiveAIEngine(SignalSource):
    """
    AI-powered trading signal generator for Intraday Options Trading.
    
    System Scope:
    - STRICTLY Intraday Options Trading ONLY
    - Symbols: NIFTY50, BANKNIFTY, SENSEX (NSE & BSE)
    - Low premium options only
    - NO individual stocks
    
    Features:
    - Market trend analysis (index options only)
    - VIX-adjusted signals
    - Confidence scoring (>70% required)
    - Risk-aware signal generation
    - 15-minute directional cycle
    """
    
    def __init__(
        self,
        min_confidence: float = 0.6,
        max_signals_per_cycle: int = 5,
        vix_adjustment_enabled: bool = True
    ):
        """
        Initialize Predictive AI Engine.
        
        Args:
            min_confidence: Minimum confidence threshold (0.0-1.0)
            max_signals_per_cycle: Maximum signals to generate per cycle
            vix_adjustment_enabled: Enable VIX-based adjustments
        """
        if not 0.0 <= min_confidence <= 1.0:
            raise ValueError(f"min_confidence must be between 0 and 1, got: {min_confidence}")
        if max_signals_per_cycle <= 0:
            raise ValueError(f"max_signals_per_cycle must be positive, got: {max_signals_per_cycle}")
        
        self.min_confidence = min_confidence
        self.max_signals_per_cycle = max_signals_per_cycle
        self.vix_adjustment_enabled = vix_adjustment_enabled
        self.signal_history: List[MarketSignal] = []
        
        logger.info(
            f"PredictiveAIEngine initialized: "
            f"min_confidence={min_confidence}, "
            f"max_signals={max_signals_per_cycle}, "
            f"vix_adjustment={vix_adjustment_enabled}"
        )
    
    def get_signals(self) -> List[TradeSignal]:
        """
        Generate trading signals based on AI predictions.
        
        Returns:
            List of TradeSignal objects
        """
        try:
            # Generate market signals
            market_signals = self._generate_market_signals()
            
            # Filter by confidence
            filtered_signals = [
                s for s in market_signals
                if s.confidence >= self.min_confidence
            ]
            
            # Apply VIX adjustment if enabled
            if self.vix_adjustment_enabled:
                filtered_signals = self._apply_vix_adjustment(filtered_signals)
            
            # Limit number of signals
            filtered_signals = filtered_signals[:self.max_signals_per_cycle]
            
            # Convert to TradeSignal format
            trade_signals = [
                TradeSignal(
                    symbol=s.symbol,
                    side=s.side,
                    quantity=s.quantity,
                    reason=f"{s.reason} (confidence: {s.confidence:.2%})"
                )
                for s in filtered_signals
            ]
            
            # Store in history
            self.signal_history.extend(market_signals)
            
            logger.info(
                f"Generated {len(trade_signals)} trading signals "
                f"(from {len(market_signals)} market signals)"
            )
            
            return trade_signals
            
        except Exception as e:
            logger.error(f"Error generating signals: {e}", exc_info=True)
            return []
    
    def _generate_market_signals(self) -> List[MarketSignal]:
        """
        Generate market signals based on analysis.
        
        CRITICAL: Only generates signals for allowed symbols:
        - NIFTY50 (NSE)
        - BANKNIFTY (NSE)
        - SENSEX (BSE)
        
        This is a placeholder implementation. In production, this would:
        - Analyze index options market data (NIFTY50, BANKNIFTY, SENSEX)
        - Use ML models (Hybrid RandomForest + LSTM) for predictions
        - Consider technical indicators for index options
        - Factor in market sentiment for indices
        - Focus on low premium options
        - Generate 15-minute directional signals
        
        Returns:
            List of MarketSignal objects (only for allowed symbols)
        """
        # Placeholder: Return empty list
        # In production, implement actual AI/ML logic here
        # MUST only generate signals for NIFTY50, BANKNIFTY, SENSEX
        logger.debug(
            "Generating market signals for intraday options "
            "(NIFTY50, BANKNIFTY, SENSEX only - placeholder implementation)"
        )
        return []
    
    def _apply_vix_adjustment(self, signals: List[MarketSignal]) -> List[MarketSignal]:
        """
        Apply VIX-based adjustments to signals (INDICATIVE guidelines).
        
        NOTE: These are GUIDELINES, not hard rules. The AI can intelligently
        adjust based on signal confidence and market conditions.
        
        Indicative VIX Scaling (Implementation Guide Ver 11):
        - VIX <15: ~100% capacity (indicative), 10-18% target return
        - VIX 15-20: ~75% capacity (indicative), 8-12% target return
        - VIX 20-30: ~50% capacity (indicative), 5-8% target return
        - VIX >30: ~50% capacity (indicative), ≤5% target return
        
        The AI can intelligently exceed or reduce these based on:
        - Signal confidence levels
        - Market conditions
        - Risk assessment
        
        Args:
            signals: List of market signals
            
        Returns:
            Adjusted list of signals (AI-driven adjustments)
        """
        try:
            # Import VIX adjustment logic if available
            try:
                from aurum_harmony.engines.predictive_ai.vix_adjustment import VIXAdjustment
                vix_adjuster = VIXAdjustment()
                current_vix = vix_adjuster.get_current_vix()
                
                if current_vix is not None:
                    # Get indicative capacity multiplier based on VIX (guideline)
                    if current_vix < 15:
                        indicative_capacity = 1.0  # ~100% capacity (indicative)
                        target_return_range = "10-18%"
                    elif current_vix < 20:
                        indicative_capacity = 0.75  # ~75% capacity (indicative)
                        target_return_range = "8-12%"
                    elif current_vix < 30:
                        indicative_capacity = 0.5  # ~50% capacity (indicative)
                        target_return_range = "5-8%"
                    else:  # VIX >= 30
                        indicative_capacity = 0.5  # ~50% capacity (indicative)
                        target_return_range = "≤5%"
                    
                    # AI-driven adjustment: Consider signal confidence
                    adjusted_signals = []
                    for signal in signals:
                        # Base adjustment from VIX guideline
                        base_capacity = indicative_capacity
                        
                        # AI decision: Adjust based on confidence
                        if signal.confidence > 0.80:
                            # High confidence: Can exceed VIX guideline
                            actual_capacity = min(1.0, base_capacity * 1.2)  # Up to 20% above guideline
                            confidence_adjustment = "AI: High confidence, exceeding VIX guideline"
                        elif signal.confidence < 0.50:
                            # Low confidence: Reduce below VIX guideline
                            actual_capacity = base_capacity * 0.7  # 30% below guideline
                            confidence_adjustment = "AI: Low confidence, reducing below VIX guideline"
                        else:
                            # Normal confidence: Use VIX guideline
                            actual_capacity = base_capacity
                            confidence_adjustment = "AI: Normal confidence, following VIX guideline"
                        
                        # Adjust quantity based on AI decision
                        signal.quantity *= actual_capacity
                        
                        # Adjust confidence based on VIX (but AI can override)
                        if current_vix > 20:
                            signal.confidence *= 0.9  # Slight reduction for high VIX
                        elif current_vix < 15:
                            signal.confidence = min(1.0, signal.confidence * 1.05)  # Slight boost for low VIX
                        
                        signal.reason += (
                            f" (VIX: {current_vix:.2f}, Indicative: {indicative_capacity*100:.0f}%, "
                            f"AI Decision: {actual_capacity*100:.0f}%, {confidence_adjustment})"
                        )
                        adjusted_signals.append(signal)
                    
                    logger.debug(
                        f"Applied VIX adjustment (AI-driven): VIX={current_vix:.2f}, "
                        f"Indicative Capacity={indicative_capacity*100:.0f}%, "
                        f"AI-adjusted based on signal confidence"
                    )
                    return adjusted_signals
            except ImportError:
                logger.debug("VIX adjustment module not available, skipping adjustment")
            
            return signals
            
        except Exception as e:
            logger.warning(f"Error applying VIX adjustment: {e}")
            return signals
    
    def get_recommended_max_trades_per_day(self, vix: Optional[float] = None) -> int:
        """
        Get RECOMMENDED (indicative) maximum trades per day based on VIX.
        
        NOTE: These are GUIDELINES, not hard rules. The AI can intelligently
        exceed or reduce based on market conditions and confidence levels.
        
        Indicative Guidelines (Implementation Guide Ver 11):
        - VIX <15: ~180 trades/day (indicative)
        - VIX 15-20: ~135 trades/day (indicative)
        - VIX 20-30: ~90 trades/day (indicative)
        - VIX >30: ~90 trades/day (indicative)
        
        Args:
            vix: Current VIX value (if None, will try to fetch)
            
        Returns:
            Recommended maximum trades per day (indicative guideline)
        """
        try:
            if vix is None:
                try:
                    from aurum_harmony.engines.predictive_ai.vix_adjustment import VIXAdjustment
                    vix_adjuster = VIXAdjustment()
                    vix = vix_adjuster.get_current_vix()
                except ImportError:
                    logger.debug("VIX adjustment module not available, using default")
                    vix = 20.0  # Default to middle range
            
            if vix is None:
                return 135  # Default to middle range
            
            if vix < 15:
                return 180
            elif vix < 20:
                return 135
            elif vix < 30:
                return 90
            else:  # VIX >= 30
                return 90
        
        except Exception as e:
            logger.warning(f"Error getting recommended max trades per day: {e}")
            return 135  # Safe default
    
    def should_exceed_trade_limit(
        self,
        current_trades_today: int,
        recommended_max: int,
        average_confidence: float,
        market_conditions: Dict[str, Any]
    ) -> tuple[bool, str]:
        """
        AI-driven decision: Should we exceed the recommended trade limit?
        
        The Predictive AI makes intelligent decisions based on:
        - Signal confidence levels
        - Market conditions
        - Risk metrics
        - Historical performance
        
        Args:
            current_trades_today: Current number of trades executed today
            recommended_max: Recommended max trades (from VIX guidelines)
            average_confidence: Average confidence of pending signals
            market_conditions: Market condition metrics
            
        Returns:
            Tuple of (should_exceed, reason)
        """
        try:
            # High confidence signals (>80%) may justify exceeding limit
            if average_confidence > 0.80 and current_trades_today < recommended_max * 1.2:
                return True, (
                    f"High confidence signals ({average_confidence:.1%}) justify "
                    f"exceeding recommended limit ({recommended_max} → {int(recommended_max * 1.2)})"
                )
            
            # Very low confidence (<50%) should reduce below limit
            if average_confidence < 0.50:
                safe_limit = int(recommended_max * 0.7)
                if current_trades_today >= safe_limit:
                    return False, (
                        f"Low confidence signals ({average_confidence:.1%}) suggest "
                        f"reducing below recommended limit ({recommended_max} → {safe_limit})"
                    )
            
            # Check market volatility
            volatility = market_conditions.get("volatility", 0)
            if volatility > 0.3:  # High volatility
                return False, (
                    f"High market volatility ({volatility:.1%}) suggests "
                    f"staying within recommended limit ({recommended_max})"
                )
            
            # Default: stay within recommended limit
            if current_trades_today >= recommended_max:
                return False, (
                    f"At recommended limit ({recommended_max}). "
                    f"AI confidence ({average_confidence:.1%}) does not justify exceeding."
                )
            
            return True, f"Within recommended limit ({current_trades_today}/{recommended_max})"
        
        except Exception as e:
            logger.warning(f"Error in should_exceed_trade_limit: {e}")
            # Conservative default: don't exceed
            return False, f"Error in decision logic, staying within limit: {str(e)}"
    
    def get_adaptive_trade_capacity(
        self,
        vix: Optional[float] = None,
        current_trades: int = 0,
        average_confidence: float = 0.7,
        market_conditions: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Get adaptive trade capacity based on AI-driven decisions.
        
        This is the MAIN method that makes intelligent decisions about:
        - How many trades to allow
        - Whether to exceed or reduce from VIX guidelines
        - Per-index allocation
        
        Args:
            vix: Current VIX value
            current_trades: Current trades executed today
            average_confidence: Average confidence of signals
            market_conditions: Market condition metrics
            
        Returns:
            Dictionary with adaptive capacity recommendations
        """
        try:
            recommended_max = self.get_recommended_max_trades_per_day(vix)
            market_conditions = market_conditions or {}
            
            # AI decision: should we exceed?
            should_exceed, reason = self.should_exceed_trade_limit(
                current_trades_today=current_trades,
                recommended_max=recommended_max,
                average_confidence=average_confidence,
                market_conditions=market_conditions
            )
            
            # Calculate adaptive capacity
            if should_exceed and average_confidence > 0.75:
                # High confidence: can exceed by up to 20%
                adaptive_max = int(recommended_max * 1.2)
                capacity_multiplier = 1.2
            elif average_confidence < 0.50:
                # Low confidence: reduce by 30%
                adaptive_max = int(recommended_max * 0.7)
                capacity_multiplier = 0.7
            else:
                # Normal: use recommended
                adaptive_max = recommended_max
                capacity_multiplier = 1.0
            
            # Per-index allocation (NIFTY50, BANKNIFTY, SENSEX)
            # AI can intelligently distribute based on signal quality
            index_allocation = {
                "NIFTY50": int(adaptive_max * 0.40),  # ~40% to NIFTY50
                "BANKNIFTY": int(adaptive_max * 0.40),  # ~40% to BANKNIFTY
                "SENSEX": int(adaptive_max * 0.20),   # ~20% to SENSEX
            }
            
            return {
                "recommended_max": recommended_max,
                "adaptive_max": adaptive_max,
                "capacity_multiplier": capacity_multiplier,
                "current_trades": current_trades,
                "remaining_capacity": max(0, adaptive_max - current_trades),
                "should_exceed": should_exceed,
                "reason": reason,
                "average_confidence": average_confidence,
                "index_allocation": index_allocation,
                "vix": vix,
            }
        
        except Exception as e:
            logger.error(f"Error calculating adaptive trade capacity: {e}", exc_info=True)
            # Return safe defaults
            return {
                "recommended_max": 135,
                "adaptive_max": 135,
                "capacity_multiplier": 1.0,
                "current_trades": current_trades,
                "remaining_capacity": max(0, 135 - current_trades),
                "should_exceed": False,
                "reason": f"Error in calculation: {str(e)}",
                "average_confidence": average_confidence,
                "index_allocation": {"NIFTY50": 54, "BANKNIFTY": 54, "SENSEX": 27},
                "vix": vix,
            }
    
    def get_signal_statistics(self) -> Dict[str, Any]:
        """Get statistics about generated signals."""
        if not self.signal_history:
            return {
                "total_signals": 0,
                "average_confidence": 0.0,
                "signals_by_side": {"BUY": 0, "SELL": 0},
            }
        
        buy_count = sum(1 for s in self.signal_history if s.side == OrderSide.BUY)
        sell_count = sum(1 for s in self.signal_history if s.side == OrderSide.SELL)
        avg_confidence = sum(s.confidence for s in self.signal_history) / len(self.signal_history)
        
        return {
            "total_signals": len(self.signal_history),
            "average_confidence": avg_confidence,
            "signals_by_side": {
                "BUY": buy_count,
                "SELL": sell_count,
            },
            "high_confidence_signals": sum(1 for s in self.signal_history if s.confidence >= 0.8),
        }


# Default instance
predictive_ai_engine = PredictiveAIEngine()

__all__ = [
    "PredictiveAIEngine",
    "MarketSignal",
    "predictive_ai_engine",
]
