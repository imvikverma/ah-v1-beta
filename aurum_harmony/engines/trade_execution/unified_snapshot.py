"""
Unified Snapshot System for Multi-Engine Aggregation

This module provides unified data models and aggregation logic to combine
data from multiple trading engines:
- HDFC Sky (NSE & BSE)
- Kotak Neo (NSE & BSE)
- Paper Trading Engine
- Backtest Engine

All broker-specific data is normalized into a common schema for the orchestrator
and frontend to consume.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Any
import time
from decimal import Decimal

import logging

logger = logging.getLogger(__name__)


class EngineType(str, Enum):
    """Trading engine identifiers."""
    HDFC_SKY_NSE = "HDFC_SKY_NSE"
    HDFC_SKY_BSE = "HDFC_SKY_BSE"
    KOTAK_NEO_NSE = "KOTAK_NEO_NSE"
    KOTAK_NEO_BSE = "KOTAK_NEO_BSE"
    PAPER_TRADING = "PAPER_TRADING"
    BACKTEST = "BACKTEST"
    # Additional engines from 8 Golden Guardrails
    PREDICTIVE_AI = "PREDICTIVE_AI"
    COMPLIANCE = "COMPLIANCE"


class Exchange(str, Enum):
    """Exchange identifiers."""
    NSE = "NSE"
    BSE = "BSE"


@dataclass
class UnifiedPosition:
    """
    Unified position representation across all engines.
    Normalizes broker-specific position formats.
    """
    symbol: str
    exchange: Exchange
    quantity: float  # Positive for long, negative for short
    avg_price: float
    current_price: float
    side: str  # "BUY" or "SELL"
    unrealized_pnl: float = 0.0
    realized_pnl: float = 0.0
    opened_at: float = field(default_factory=time.time)
    engine_source: EngineType = EngineType.PAPER_TRADING
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __post_init__(self):
        """Normalize and validate position data."""
        # Validate and normalize symbol
        if not self.symbol or not isinstance(self.symbol, str):
            raise ValueError(f"Invalid symbol: {self.symbol}")
        self.symbol = self.symbol.strip().upper()
        
        # Validate exchange
        if not isinstance(self.exchange, Exchange):
            if isinstance(self.exchange, str):
                try:
                    self.exchange = Exchange(self.exchange.upper())
                except ValueError:
                    raise ValueError(f"Invalid exchange: {self.exchange}")
            else:
                raise ValueError(f"Invalid exchange type: {type(self.exchange)}")
        
        # Validate quantity
        if self.quantity == 0:
            logger.warning(f"Position with zero quantity: {self.symbol}")
        
        # Ensure quantity sign matches side
        if self.side == "SELL" and self.quantity > 0:
            self.quantity = -self.quantity
        elif self.side == "BUY" and self.quantity < 0:
            self.quantity = abs(self.quantity)
        
        # Validate prices
        if self.avg_price < 0:
            logger.warning(f"Negative avg_price for {self.symbol}: {self.avg_price}")
        if self.current_price < 0:
            logger.warning(f"Negative current_price for {self.symbol}: {self.current_price}")
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "symbol": self.symbol,
            "exchange": self.exchange.value,
            "quantity": float(self.quantity),
            "avg_price": float(self.avg_price),
            "current_price": float(self.current_price),
            "side": self.side,
            "unrealized_pnl": float(self.unrealized_pnl),
            "realized_pnl": float(self.realized_pnl),
            "opened_at": self.opened_at,
            "engine_source": self.engine_source.value,
            "metadata": self.metadata,
        }


@dataclass
class UnifiedBalance:
    """
    Unified balance representation across all engines.
    Combines available, margin, and used amounts.
    """
    available: float = 0.0
    margin_used: float = 0.0
    total_equity: float = 0.0
    unrealized_pnl: float = 0.0
    realized_pnl: float = 0.0
    engine_source: EngineType = EngineType.PAPER_TRADING
    exchange: Optional[Exchange] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "available": float(self.available),
            "margin_used": float(self.margin_used),
            "total_equity": float(self.total_equity),
            "unrealized_pnl": float(self.unrealized_pnl),
            "realized_pnl": float(self.realized_pnl),
            "engine_source": self.engine_source.value,
            "exchange": self.exchange.value if self.exchange else None,
            "metadata": self.metadata,
        }


@dataclass
class UnifiedQuote:
    """
    Unified market quote representation.
    Aggregates best bid/ask from multiple sources.
    """
    symbol: str
    exchange: Exchange
    bid_price: float
    ask_price: float
    last_price: float
    volume: int = 0
    timestamp: float = field(default_factory=time.time)
    engine_sources: List[EngineType] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "symbol": self.symbol,
            "exchange": self.exchange.value,
            "bid_price": float(self.bid_price),
            "ask_price": float(self.ask_price),
            "last_price": float(self.last_price),
            "volume": self.volume,
            "timestamp": self.timestamp,
            "engine_sources": [e.value for e in self.engine_sources],
            "metadata": self.metadata,
        }


@dataclass
class EngineSnapshot:
    """
    Snapshot from a single trading engine.
    Contains positions, balance, and metadata for one engine.
    """
    engine_type: EngineType
    exchange: Optional[Exchange] = None
    positions: List[UnifiedPosition] = field(default_factory=list)
    balance: Optional[UnifiedBalance] = None
    quotes: List[UnifiedQuote] = field(default_factory=list)
    is_available: bool = True
    last_update: float = field(default_factory=time.time)
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "engine_type": self.engine_type.value,
            "exchange": self.exchange.value if self.exchange else None,
            "positions": [p.to_dict() for p in self.positions],
            "balance": self.balance.to_dict() if self.balance else None,
            "quotes": [q.to_dict() for q in self.quotes],
            "is_available": self.is_available,
            "last_update": self.last_update,
            "error": self.error,
            "metadata": self.metadata,
        }


@dataclass
class UnifiedSnapshot:
    """
    Aggregated snapshot from all trading engines.
    This is the primary data structure consumed by the orchestrator and frontend.
    """
    timestamp: float = field(default_factory=time.time)
    engine_snapshots: Dict[str, EngineSnapshot] = field(default_factory=dict)
    
    # Aggregated views (computed from engine_snapshots)
    all_positions: List[UnifiedPosition] = field(default_factory=list)
    aggregated_balance: Optional[UnifiedBalance] = None
    aggregated_quotes: Dict[str, UnifiedQuote] = field(default_factory=dict)
    
    # Metadata
    total_engines: int = 0
    available_engines: int = 0
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def aggregate(self) -> None:
        """
        Aggregate data from all engine snapshots into unified views.
        Called after all engines have been queried.
        """
        # Collect all positions (with deduplication by symbol+exchange)
        position_map: Dict[str, UnifiedPosition] = {}
        for snapshot in self.engine_snapshots.values():
            if snapshot.is_available and snapshot.positions:
                for pos in snapshot.positions:
                    # Use symbol+exchange as key to handle same symbol on different exchanges
                    key = f"{pos.symbol}_{pos.exchange.value}"
                    if key not in position_map:
                        position_map[key] = pos
                    else:
                        # If same symbol+exchange from multiple engines, merge quantities
                        existing = position_map[key]
                        if existing.engine_source == pos.engine_source:
                            # Same engine, update
                            position_map[key] = pos
                        else:
                            # Different engines - aggregate quantities
                            existing.quantity += pos.quantity
                            # Use weighted average for avg_price
                            total_qty = abs(existing.quantity) + abs(pos.quantity)
                            if total_qty > 0:
                                existing.avg_price = (
                                    (existing.avg_price * abs(existing.quantity) + 
                                     pos.avg_price * abs(pos.quantity)) / total_qty
                                )
                            existing.unrealized_pnl += pos.unrealized_pnl
                            existing.realized_pnl += pos.realized_pnl
                            # Update metadata to show multiple sources
                            if "source_engines" not in existing.metadata:
                                existing.metadata["source_engines"] = [existing.engine_source.value]
                            existing.metadata["source_engines"].append(pos.engine_source.value)
        
        self.all_positions = list(position_map.values())
        
        # Aggregate balances (sum available, margin_used, etc.)
        total_available = 0.0
        total_margin_used = 0.0
        total_unrealized_pnl = 0.0
        total_realized_pnl = 0.0
        
        for snapshot in self.engine_snapshots.values():
            if snapshot.is_available and snapshot.balance:
                total_available += snapshot.balance.available
                total_margin_used += snapshot.balance.margin_used
                total_unrealized_pnl += snapshot.balance.unrealized_pnl
                total_realized_pnl += snapshot.balance.realized_pnl
        
        self.aggregated_balance = UnifiedBalance(
            available=total_available,
            margin_used=total_margin_used,
            total_equity=total_available + total_margin_used,
            unrealized_pnl=total_unrealized_pnl,
            realized_pnl=total_realized_pnl,
            engine_source=EngineType.PAPER_TRADING,  # Default, but aggregated
            metadata={"aggregated": True, "source_count": len(self.engine_snapshots)},
        )
        
        # Aggregate quotes (best bid/ask across engines)
        self.aggregated_quotes = {}
        for snapshot in self.engine_snapshots.values():
            if snapshot.is_available and snapshot.quotes:
                for quote in snapshot.quotes:
                    key = f"{quote.symbol}_{quote.exchange.value}"
                    if key not in self.aggregated_quotes:
                        self.aggregated_quotes[key] = quote
                    else:
                        # Take best bid (highest) and best ask (lowest)
                        existing = self.aggregated_quotes[key]
                        if quote.bid_price > existing.bid_price:
                            existing.bid_price = quote.bid_price
                        if quote.ask_price < existing.ask_price:
                            existing.ask_price = quote.ask_price
                        existing.engine_sources.append(quote.engine_sources[0] if quote.engine_sources else snapshot.engine_type)
        
        # Update counts
        self.total_engines = len(self.engine_snapshots)
        self.available_engines = sum(1 for s in self.engine_snapshots.values() if s.is_available)
        
        # Log aggregation summary
        total_positions = len(self.all_positions)
        total_balance = self.aggregated_balance.available if self.aggregated_balance else 0.0
        total_equity = self.aggregated_balance.total_equity if self.aggregated_balance else 0.0
        
        logger.info(
            f"UnifiedSnapshot aggregated: {self.available_engines}/{self.total_engines} engines, "
            f"{total_positions} positions, "
            f"balance=₹{total_balance:,.2f}, equity=₹{total_equity:,.2f}"
        )
        
        # Log per-engine position counts for debugging
        if logger.isEnabledFor(logging.DEBUG):
            for engine_key, engine_snap in self.engine_snapshots.items():
                if engine_snap.is_available:
                    pos_count = len(engine_snap.positions)
                    if pos_count > 0:
                        logger.debug(f"  {engine_key}: {pos_count} positions")
    
    def get_positions_by_exchange(self, exchange: Exchange) -> List[UnifiedPosition]:
        """Get all positions for a specific exchange."""
        return [p for p in self.all_positions if p.exchange == exchange]
    
    def get_positions_by_symbol(self, symbol: str) -> List[UnifiedPosition]:
        """Get all positions for a specific symbol (across all exchanges)."""
        return [p for p in self.all_positions if p.symbol.upper() == symbol.upper()]
    
    def get_positions_by_engine(self, engine_type: EngineType) -> List[UnifiedPosition]:
        """Get all positions from a specific engine."""
        return [p for p in self.all_positions if p.engine_source == engine_type]
    
    def get_total_exposure(self) -> float:
        """Calculate total exposure across all positions."""
        return sum(
            abs(pos.current_price * pos.quantity) 
            for pos in self.all_positions
        )
    
    def get_total_unrealized_pnl(self) -> float:
        """Get total unrealized P&L across all positions."""
        return sum(pos.unrealized_pnl for pos in self.all_positions)
    
    def get_total_realized_pnl(self) -> float:
        """Get total realized P&L from aggregated balance."""
        if self.aggregated_balance:
            return self.aggregated_balance.realized_pnl
        return 0.0
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "timestamp": self.timestamp,
            "engine_snapshots": {k: v.to_dict() for k, v in self.engine_snapshots.items()},
            "all_positions": [p.to_dict() for p in self.all_positions],
            "aggregated_balance": self.aggregated_balance.to_dict() if self.aggregated_balance else None,
            "aggregated_quotes": {k: v.to_dict() for k, v in self.aggregated_quotes.items()},
            "total_engines": self.total_engines,
            "available_engines": self.available_engines,
            "metadata": self.metadata,
            # Add summary stats
            "summary": {
                "total_positions": len(self.all_positions),
                "total_exposure": self.get_total_exposure(),
                "total_unrealized_pnl": self.get_total_unrealized_pnl(),
                "total_realized_pnl": self.get_total_realized_pnl(),
                "nse_positions": len(self.get_positions_by_exchange(Exchange.NSE)),
                "bse_positions": len(self.get_positions_by_exchange(Exchange.BSE)),
            },
        }


__all__ = [
    "EngineType",
    "Exchange",
    "UnifiedPosition",
    "UnifiedBalance",
    "UnifiedQuote",
    "EngineSnapshot",
    "UnifiedSnapshot",
]

