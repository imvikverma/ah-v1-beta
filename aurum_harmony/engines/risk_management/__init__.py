"""
Risk Management Module
Includes trailing stop loss and take profit management
"""

from aurum_harmony.engines.risk_management.trailing_sl_tp import (
    TrailingSLTPManager,
    PositionTracker,
    Entry,
    ExitReason
)

__all__ = [
    "TrailingSLTPManager",
    "PositionTracker",
    "Entry",
    "ExitReason"
]
