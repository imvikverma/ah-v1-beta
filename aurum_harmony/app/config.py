"""
Central configuration and safety limits for AurumHarmony.

This is the single place to control:
- paper vs live trading
- per-user and global risk caps
- which strategies are allowed to run handsfree
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Dict
import os


class TradingMode(str, Enum):
    PAPER = "PAPER"
    LIVE = "LIVE"


@dataclass
class RiskLimits:
    max_daily_loss: float
    max_position_size: float
    max_open_trades: int


@dataclass
class AppConfig:
    trading_mode: TradingMode
    global_risk: RiskLimits
    per_user_risk: Dict[str, RiskLimits]

    @property
    def is_live(self) -> bool:
        return self.trading_mode == TradingMode.LIVE


def load_config() -> AppConfig:
    """
    Reads environment variables and returns a validated AppConfig.
    Defaults to safe PAPER mode with conservative limits.
    """
    mode_str = os.getenv("AURUM_TRADING_MODE", "PAPER").upper()
    trading_mode = TradingMode(mode_str) if mode_str in TradingMode.__members__ else TradingMode.PAPER

    # Global limits – keep these strict by default.
    max_daily_loss = float(os.getenv("AURUM_MAX_DAILY_LOSS", "5000"))
    max_position_size = float(os.getenv("AURUM_MAX_POSITION_SIZE", "50000"))
    max_open_trades = int(os.getenv("AURUM_MAX_OPEN_TRADES", "5"))

    global_risk = RiskLimits(
        max_daily_loss=max_daily_loss,
        max_position_size=max_position_size,
        max_open_trades=max_open_trades,
    )

    # Per-user overrides can be added later (from DB or config file).
    per_user_risk: Dict[str, RiskLimits] = {}

    return AppConfig(
        trading_mode=trading_mode,
        global_risk=global_risk,
        per_user_risk=per_user_risk,
    )


__all__ = ["TradingMode", "RiskLimits", "AppConfig", "load_config"]


