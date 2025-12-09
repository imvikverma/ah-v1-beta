"""
Central configuration and safety limits for AurumHarmony.

This is the single place to control:
- paper vs live trading
- per-user and global risk caps
- which strategies are allowed to run handsfree
- Configuration validation and environment variable handling
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, Optional
import os
import logging

# Configure logging
logger = logging.getLogger(__name__)


class TradingMode(str, Enum):
    PAPER = "PAPER"
    LIVE = "LIVE"


@dataclass
class RiskLimits:
    """Risk limits with validation."""
    max_daily_loss: float
    max_position_size: float
    max_open_trades: int
    
    def __post_init__(self) -> None:
        """Validate risk limits."""
        if self.max_daily_loss <= 0:
            raise ValueError(f"max_daily_loss must be positive, got: {self.max_daily_loss}")
        if self.max_position_size <= 0:
            raise ValueError(f"max_position_size must be positive, got: {self.max_position_size}")
        if self.max_open_trades <= 0:
            raise ValueError(f"max_open_trades must be positive, got: {self.max_open_trades}")
    
    def to_dict(self) -> Dict[str, float | int]:
        """Convert to dictionary."""
        return {
            "max_daily_loss": self.max_daily_loss,
            "max_position_size": self.max_position_size,
            "max_open_trades": self.max_open_trades,
        }


@dataclass
class AppConfig:
    """Application configuration with validation and safety defaults."""
    trading_mode: TradingMode
    global_risk: RiskLimits
    per_user_risk: Dict[str, RiskLimits] = field(default_factory=dict)
    use_live_data_for_paper: bool = True  # Use live market data for paper trading if available
    
    def __post_init__(self) -> None:
        """Validate configuration."""
        if not isinstance(self.trading_mode, TradingMode):
            raise ValueError(f"Invalid trading_mode: {self.trading_mode}")
        if not isinstance(self.global_risk, RiskLimits):
            raise ValueError(f"Invalid global_risk: {self.global_risk}")

    @property
    def is_live(self) -> bool:
        """Check if live trading is enabled."""
        return self.trading_mode == TradingMode.LIVE
    
    def get_user_risk_limits(self, user_id: str) -> RiskLimits:
        """Get risk limits for a specific user, falling back to global limits."""
        return self.per_user_risk.get(user_id, self.global_risk)
    
    def to_dict(self) -> Dict[str, any]:
        """Convert configuration to dictionary."""
        return {
            "trading_mode": self.trading_mode.value,
            "is_live": self.is_live,
            "global_risk": self.global_risk.to_dict(),
            "per_user_risk": {k: v.to_dict() for k, v in self.per_user_risk.items()},
        }


def load_config() -> AppConfig:
    """
    Reads environment variables and returns a validated AppConfig.
    Defaults to safe PAPER mode with conservative limits.
    
    Environment Variables:
        AURUM_TRADING_MODE: PAPER (default) or LIVE
        AURUM_MAX_DAILY_LOSS: Maximum daily loss limit (default: 5000)
        AURUM_MAX_POSITION_SIZE: Maximum position size (default: 50000)
        AURUM_MAX_OPEN_TRADES: Maximum open trades (default: 5)
    
    Returns:
        Validated AppConfig instance
        
    Raises:
        ValueError: If configuration values are invalid
    """
    try:
        # Load trading mode
        mode_str = os.getenv("AURUM_TRADING_MODE", "PAPER").upper().strip()
        if mode_str not in TradingMode.__members__:
            logger.warning(f"Invalid trading mode '{mode_str}', defaulting to PAPER")
            trading_mode = TradingMode.PAPER
        else:
            trading_mode = TradingMode(mode_str)
        
        # Load global risk limits with validation
        try:
            max_daily_loss = float(os.getenv("AURUM_MAX_DAILY_LOSS", "5000"))
            if max_daily_loss <= 0:
                raise ValueError("AURUM_MAX_DAILY_LOSS must be positive")
        except (ValueError, TypeError) as e:
            logger.warning(f"Invalid AURUM_MAX_DAILY_LOSS, using default 5000: {e}")
            max_daily_loss = 5000.0
        
        try:
            max_position_size = float(os.getenv("AURUM_MAX_POSITION_SIZE", "50000"))
            if max_position_size <= 0:
                raise ValueError("AURUM_MAX_POSITION_SIZE must be positive")
        except (ValueError, TypeError) as e:
            logger.warning(f"Invalid AURUM_MAX_POSITION_SIZE, using default 50000: {e}")
            max_position_size = 50000.0
        
        try:
            max_open_trades = int(os.getenv("AURUM_MAX_OPEN_TRADES", "5"))
            if max_open_trades <= 0:
                raise ValueError("AURUM_MAX_OPEN_TRADES must be positive")
        except (ValueError, TypeError) as e:
            logger.warning(f"Invalid AURUM_MAX_OPEN_TRADES, using default 5: {e}")
            max_open_trades = 5

        # Create risk limits
        global_risk = RiskLimits(
            max_daily_loss=max_daily_loss,
            max_position_size=max_position_size,
            max_open_trades=max_open_trades,
        )

        # Per-user overrides can be added later (from DB or config file)
        per_user_risk: Dict[str, RiskLimits] = {}

        # Load live data preference
        use_live_data = os.getenv("AURUM_USE_LIVE_DATA", "true").lower() in ("true", "1", "yes")
        
        config = AppConfig(
            trading_mode=trading_mode,
            global_risk=global_risk,
            per_user_risk=per_user_risk,
            use_live_data_for_paper=use_live_data,
        )
        
        logger.info(
            f"Configuration loaded: mode={trading_mode.value}, "
            f"limits={global_risk.to_dict()}"
        )
        
        return config
        
    except Exception as e:
        logger.error(f"Error loading configuration: {e}", exc_info=True)
        # Return safe defaults on error
        logger.warning("Using safe default configuration due to error")
        return AppConfig(
            trading_mode=TradingMode.PAPER,
            global_risk=RiskLimits(
                max_daily_loss=5000.0,
                max_position_size=50000.0,
                max_open_trades=5,
            ),
            per_user_risk={},
        )


__all__ = ["TradingMode", "RiskLimits", "AppConfig", "load_config"]


