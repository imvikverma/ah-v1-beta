"""
Adaptive Intelligence Engine
Converts hard trading rules into ML/AI-driven adaptive guidelines.

Modules:
- adaptive_parameter_engine: Converts rules to adaptive guidelines
- preemptive_risk_manager: Prevents losses through early detection
"""

from aurum_harmony.engines.adaptive_intelligence.adaptive_parameter_engine import (
    AdaptiveParameterEngine,
    ParameterGuideline,
    OpportunityAssessment,
    AdjustmentDirection,
    adaptive_parameter_engine,
)

from aurum_harmony.engines.adaptive_intelligence.preemptive_risk_manager import (
    PreemptiveRiskManager,
    RiskSignal,
    LossPreventionAction,
    preemptive_risk_manager,
)

from aurum_harmony.engines.adaptive_intelligence.trade_direction_switcher import (
    TradeDirectionSwitcher,
    TradeDirection,
    ReversalSignal,
    DirectionSwitchRecommendation,
    TrendAnalysis,
    trade_direction_switcher,
)

__all__ = [
    "AdaptiveParameterEngine",
    "ParameterGuideline",
    "OpportunityAssessment",
    "AdjustmentDirection",
    "adaptive_parameter_engine",
    "PreemptiveRiskManager",
    "RiskSignal",
    "LossPreventionAction",
    "preemptive_risk_manager",
    "TradeDirectionSwitcher",
    "TradeDirection",
    "ReversalSignal",
    "DirectionSwitchRecommendation",
    "TrendAnalysis",
    "trade_direction_switcher",
]
