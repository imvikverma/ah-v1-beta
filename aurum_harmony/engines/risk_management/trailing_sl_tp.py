"""
Dynamic Trailing Stop Loss and Take Profit System
Supports multiple entries and exits in a single trading session

Features:
- Dynamic trailing stop loss (adjusts with price movement)
- Multiple take profit levels
- Multiple entries per position
- Partial exits at profit targets
- Session-based position tracking
"""

import logging
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from enum import Enum
from decimal import Decimal

logger = logging.getLogger(__name__)


class ExitReason(str, Enum):
    """Reason for position exit."""
    TRAILING_SL_HIT = "TRAILING_SL_HIT"
    TAKE_PROFIT_HIT = "TAKE_PROFIT_HIT"
    MANUAL_CLOSE = "MANUAL_CLOSE"
    SESSION_END = "SESSION_END"
    RISK_MANAGEMENT = "RISK_MANAGEMENT"


@dataclass
class Entry:
    """Represents a single entry into a position."""
    entry_id: str
    timestamp: datetime
    price: float
    quantity: float
    side: str  # "BUY" or "SELL"
    stop_loss: Optional[float] = None
    take_profit_levels: List[float] = field(default_factory=list)  # Multiple TP levels
    trailing_sl_activated: bool = False
    trailing_sl_distance: Optional[float] = None  # Percentage or absolute
    exited: bool = False
    exit_price: Optional[float] = None
    exit_reason: Optional[ExitReason] = None
    exit_timestamp: Optional[datetime] = None


@dataclass
class PositionTracker:
    """Tracks a position with multiple entries and dynamic SL/TP."""
    symbol: str
    side: str  # "BUY" or "SELL"
    entries: List[Entry] = field(default_factory=list)
    current_price: float = 0.0
    total_quantity: float = 0.0
    weighted_avg_price: float = 0.0
    unrealized_pnl: float = 0.0
    realized_pnl: float = 0.0
    
    # Dynamic SL/TP settings
    trailing_sl_enabled: bool = True
    trailing_sl_distance_pct: float = 2.0  # 2% trailing distance
    trailing_sl_distance_absolute: Optional[float] = None  # Absolute trailing distance
    
    # Take profit levels (multiple)
    take_profit_levels: List[float] = field(default_factory=list)  # Price levels
    take_profit_percentages: List[float] = field(default_factory=list)  # % of position to exit
    take_profit_hit: List[bool] = field(default_factory=list)
    
    # Session tracking
    session_start: datetime = field(default_factory=datetime.now)
    last_update: datetime = field(default_factory=datetime.now)
    
    def add_entry(
        self,
        price: float,
        quantity: float,
        stop_loss_pct: float = 2.0,
        take_profit_levels: Optional[List[Tuple[float, float]]] = None
    ) -> Entry:
        """
        Add a new entry to the position.
        
        Args:
            price: Entry price
            quantity: Quantity
            stop_loss_pct: Initial stop loss percentage
            take_profit_levels: List of (price_level, exit_percentage) tuples
            
        Returns:
            Entry object
        """
        entry_id = f"{self.symbol}_{len(self.entries)}_{int(datetime.now().timestamp())}"
        
        # Calculate initial stop loss
        if self.side == "BUY":
            initial_sl = price * (1 - stop_loss_pct / 100)
        else:  # SELL (short)
            initial_sl = price * (1 + stop_loss_pct / 100)
        
        # Process take profit levels
        tp_levels = []
        if take_profit_levels:
            for tp_price, tp_pct in take_profit_levels:
                tp_levels.append(tp_price)
        
        entry = Entry(
            entry_id=entry_id,
            timestamp=datetime.now(),
            price=price,
            quantity=quantity,
            side=self.side,
            stop_loss=initial_sl,
            take_profit_levels=tp_levels
        )
        
        self.entries.append(entry)
        
        # Update weighted average price
        self._update_weighted_avg_price()
        self.total_quantity += quantity if self.side == "BUY" else -quantity
        
        logger.info(
            f"Entry added to {self.symbol}: {quantity} @ {price:.2f}, "
            f"SL: {initial_sl:.2f}, Total Qty: {self.total_quantity:.2f}"
        )
        
        return entry
    
    def _update_weighted_avg_price(self):
        """Update weighted average price based on all active entries."""
        if not self.entries or all(e.exited for e in self.entries):
            self.weighted_avg_price = 0.0
            return
        
        total_cost = 0.0
        total_qty = 0.0
        
        for entry in self.entries:
            if not entry.exited:
                total_cost += entry.price * entry.quantity
                total_qty += entry.quantity
        
        if total_qty > 0:
            self.weighted_avg_price = total_cost / total_qty
    
    def update_price(self, current_price: float) -> Dict[str, any]:
        """
        Update current price and check for SL/TP triggers.
        
        Args:
            current_price: Current market price
            
        Returns:
            Dictionary with exit actions if any
        """
        self.current_price = current_price
        self.last_update = datetime.now()
        
        # Update unrealized PnL
        self._calculate_unrealized_pnl()
        
        exit_actions = {
            "exits": [],
            "trailing_sl_updated": False
        }
        
        # Check each entry for SL/TP
        for entry in self.entries:
            if entry.exited:
                continue
            
            # Check trailing stop loss
            if self.trailing_sl_enabled and entry.trailing_sl_activated:
                sl_triggered = self._check_trailing_sl(entry, current_price)
                if sl_triggered:
                    exit_actions["exits"].append({
                        "entry_id": entry.entry_id,
                        "reason": ExitReason.TRAILING_SL_HIT,
                        "price": entry.stop_loss,
                        "quantity": entry.quantity
                    })
                    continue
            
            # Check take profit levels
            tp_exits = self._check_take_profit(entry, current_price)
            if tp_exits:
                exit_actions["exits"].extend(tp_exits)
            
            # Activate trailing SL if price moves favorably
            if not entry.trailing_sl_activated:
                self._activate_trailing_sl(entry, current_price)
                if entry.trailing_sl_activated:
                    exit_actions["trailing_sl_updated"] = True
        
        return exit_actions
    
    def _check_trailing_sl(self, entry: Entry, current_price: float) -> bool:
        """Check if trailing stop loss is triggered."""
        if not entry.stop_loss:
            return False
        
        if self.side == "BUY":
            # Long position: SL triggered if price falls below trailing SL
            if current_price <= entry.stop_loss:
                return True
            # Update trailing SL if price moves up
            if self.trailing_sl_distance_pct:
                new_sl = current_price * (1 - self.trailing_sl_distance_pct / 100)
                if new_sl > entry.stop_loss:
                    entry.stop_loss = new_sl
                    logger.debug(f"Trailing SL updated for {entry.entry_id}: {entry.stop_loss:.2f}")
        else:  # SELL (short)
            # Short position: SL triggered if price rises above trailing SL
            if current_price >= entry.stop_loss:
                return True
            # Update trailing SL if price moves down
            if self.trailing_sl_distance_pct:
                new_sl = current_price * (1 + self.trailing_sl_distance_pct / 100)
                if new_sl < entry.stop_loss:
                    entry.stop_loss = new_sl
                    logger.debug(f"Trailing SL updated for {entry.entry_id}: {entry.stop_loss:.2f}")
        
        return False
    
    def _activate_trailing_sl(self, entry: Entry, current_price: float):
        """Activate trailing stop loss when price moves favorably."""
        if entry.trailing_sl_activated:
            return
        
        if self.side == "BUY":
            # Activate if price is above entry (in profit)
            if current_price > entry.price:
                entry.trailing_sl_activated = True
                if self.trailing_sl_distance_pct:
                    entry.stop_loss = current_price * (1 - self.trailing_sl_distance_pct / 100)
                entry.trailing_sl_distance = self.trailing_sl_distance_pct
                logger.info(f"Trailing SL activated for {entry.entry_id} @ {entry.stop_loss:.2f}")
        else:  # SELL (short)
            # Activate if price is below entry (in profit)
            if current_price < entry.price:
                entry.trailing_sl_activated = True
                if self.trailing_sl_distance_pct:
                    entry.stop_loss = current_price * (1 + self.trailing_sl_distance_pct / 100)
                entry.trailing_sl_distance = self.trailing_sl_distance_pct
                logger.info(f"Trailing SL activated for {entry.entry_id} @ {entry.stop_loss:.2f}")
    
    def _check_take_profit(self, entry: Entry, current_price: float) -> List[Dict]:
        """Check if any take profit levels are hit."""
        exits = []
        
        if not entry.take_profit_levels:
            return exits
        
        for i, tp_level in enumerate(entry.take_profit_levels):
            if i < len(self.take_profit_percentages):
                tp_pct = self.take_profit_percentages[i]
            else:
                tp_pct = 100.0 / len(entry.take_profit_levels)  # Equal distribution
            
            if self.side == "BUY":
                # Long: TP hit if price reaches or exceeds TP level
                if current_price >= tp_level and not (i < len(self.take_profit_hit) and self.take_profit_hit[i]):
                    exit_qty = entry.quantity * (tp_pct / 100)
                    exits.append({
                        "entry_id": entry.entry_id,
                        "reason": ExitReason.TAKE_PROFIT_HIT,
                        "price": tp_level,
                        "quantity": exit_qty,
                        "tp_level": i + 1
                    })
                    if i < len(self.take_profit_hit):
                        self.take_profit_hit[i] = True
                    else:
                        while len(self.take_profit_hit) <= i:
                            self.take_profit_hit.append(False)
                        self.take_profit_hit[i] = True
            else:  # SELL (short)
                # Short: TP hit if price reaches or falls below TP level
                if current_price <= tp_level and not (i < len(self.take_profit_hit) and self.take_profit_hit[i]):
                    exit_qty = entry.quantity * (tp_pct / 100)
                    exits.append({
                        "entry_id": entry.entry_id,
                        "reason": ExitReason.TAKE_PROFIT_HIT,
                        "price": tp_level,
                        "quantity": exit_qty,
                        "tp_level": i + 1
                    })
                    if i < len(self.take_profit_hit):
                        self.take_profit_hit[i] = True
                    else:
                        while len(self.take_profit_hit) <= i:
                            self.take_profit_hit.append(False)
                        self.take_profit_hit[i] = True
        
        return exits
    
    def _calculate_unrealized_pnl(self):
        """Calculate unrealized PnL for all active entries."""
        self.unrealized_pnl = 0.0
        
        for entry in self.entries:
            if not entry.exited:
                if self.side == "BUY":
                    pnl = (self.current_price - entry.price) * entry.quantity
                else:  # SELL (short)
                    pnl = (entry.price - self.current_price) * entry.quantity
                self.unrealized_pnl += pnl
    
    def exit_entry(
        self,
        entry_id: str,
        exit_price: float,
        exit_quantity: Optional[float] = None,
        reason: ExitReason = ExitReason.MANUAL_CLOSE
    ) -> float:
        """
        Exit an entry (partial or full).
        
        Args:
            entry_id: Entry ID to exit
            exit_price: Exit price
            exit_quantity: Quantity to exit (None = full exit)
            reason: Exit reason
            
        Returns:
            Realized PnL from this exit
        """
        entry = next((e for e in self.entries if e.entry_id == entry_id), None)
        if not entry or entry.exited:
            return 0.0
        
        exit_qty = exit_quantity if exit_quantity is not None else entry.quantity
        
        # Calculate PnL
        if self.side == "BUY":
            pnl = (exit_price - entry.price) * exit_qty
        else:  # SELL (short)
            pnl = (entry.price - exit_price) * exit_qty
        
        self.realized_pnl += pnl
        
        # Update entry
        if exit_qty >= entry.quantity:
            # Full exit
            entry.exited = True
            entry.exit_price = exit_price
            entry.exit_reason = reason
            entry.exit_timestamp = datetime.now()
            self.total_quantity -= entry.quantity if self.side == "BUY" else -entry.quantity
        else:
            # Partial exit
            entry.quantity -= exit_qty
            self.total_quantity -= exit_qty if self.side == "BUY" else -exit_qty
        
        self._update_weighted_avg_price()
        
        logger.info(
            f"Entry {entry_id} exited: {exit_qty:.2f} @ {exit_price:.2f}, "
            f"PnL: {pnl:.2f}, Reason: {reason.value}"
        )
        
        return pnl


class TrailingSLTPManager:
    """
    Manages trailing stop loss and take profit for all positions.
    Supports multiple entries and exits per session.
    """
    
    def __init__(
        self,
        default_trailing_sl_pct: float = 2.0,
        default_tp_levels: Optional[List[Tuple[float, float]]] = None
    ):
        """
        Initialize trailing SL/TP manager.
        
        Args:
            default_trailing_sl_pct: Default trailing SL percentage
            default_tp_levels: Default TP levels as (price_multiplier, exit_percentage) tuples
                               e.g., [(1.02, 33.3), (1.05, 33.3), (1.10, 33.4)] for 3 levels
        """
        self.positions: Dict[str, PositionTracker] = {}
        self.default_trailing_sl_pct = default_trailing_sl_pct
        self.default_tp_levels = default_tp_levels or [
            (1.02, 33.3),  # 2% profit, exit 33.3%
            (1.05, 33.3),  # 5% profit, exit 33.3%
            (1.10, 33.4)   # 10% profit, exit remaining 33.4%
        ]
        logger.info("TrailingSLTPManager initialized")
    
    def add_position(
        self,
        symbol: str,
        side: str,
        price: float,
        quantity: float,
        stop_loss_pct: float = 2.0,
        take_profit_levels: Optional[List[Tuple[float, float]]] = None,
        trailing_sl_pct: Optional[float] = None
    ) -> Entry:
        """
        Add a new position or entry to existing position.
        
        Args:
            symbol: Symbol
            side: "BUY" or "SELL"
            price: Entry price
            quantity: Quantity
            stop_loss_pct: Initial stop loss percentage
            take_profit_levels: TP levels as (price_multiplier, exit_percentage)
            trailing_sl_pct: Trailing SL percentage (uses default if None)
            
        Returns:
            Entry object
        """
        position_key = f"{symbol}_{side}"
        
        if position_key not in self.positions:
            # Create new position tracker
            tracker = PositionTracker(
                symbol=symbol,
                side=side,
                trailing_sl_distance_pct=trailing_sl_pct or self.default_trailing_sl_pct
            )
            
            # Set default TP levels if not provided
            if take_profit_levels is None:
                take_profit_levels = self.default_tp_levels
            
            # Convert TP multipliers to absolute prices
            tp_prices = []
            tp_percentages = []
            for multiplier, exit_pct in take_profit_levels:
                if side == "BUY":
                    tp_price = price * multiplier
                else:  # SELL (short)
                    tp_price = price * (2 - multiplier)  # Inverse for short
                tp_prices.append(tp_price)
                tp_percentages.append(exit_pct)
            
            tracker.take_profit_levels = tp_prices
            tracker.take_profit_percentages = tp_percentages
            tracker.take_profit_hit = [False] * len(tp_prices)
            
            self.positions[position_key] = tracker
        
        tracker = self.positions[position_key]
        
        # Add entry
        entry = tracker.add_entry(
            price=price,
            quantity=quantity,
            stop_loss_pct=stop_loss_pct,
            take_profit_levels=list(zip(tracker.take_profit_levels, tracker.take_profit_percentages))
        )
        
        return entry
    
    def update_prices(self, prices: Dict[str, float]) -> Dict[str, List[Dict]]:
        """
        Update prices for all positions and check for SL/TP triggers.
        
        Args:
            prices: Dictionary of symbol -> current_price
            
        Returns:
            Dictionary of symbol -> list of exit actions
        """
        all_exit_actions = {}
        
        for position_key, tracker in self.positions.items():
            symbol = tracker.symbol
            if symbol not in prices:
                continue
            
            current_price = prices[symbol]
            exit_actions = tracker.update_price(current_price)
            
            if exit_actions["exits"]:
                all_exit_actions[position_key] = exit_actions["exits"]
        
        return all_exit_actions
    
    def get_position_status(self, symbol: str, side: str) -> Optional[Dict]:
        """Get current status of a position."""
        position_key = f"{symbol}_{side}"
        tracker = self.positions.get(position_key)
        
        if not tracker:
            return None
        
        return {
            "symbol": tracker.symbol,
            "side": tracker.side,
            "total_quantity": tracker.total_quantity,
            "weighted_avg_price": tracker.weighted_avg_price,
            "current_price": tracker.current_price,
            "unrealized_pnl": tracker.unrealized_pnl,
            "realized_pnl": tracker.realized_pnl,
            "active_entries": len([e for e in tracker.entries if not e.exited]),
            "total_entries": len(tracker.entries),
            "trailing_sl_active": any(e.trailing_sl_activated for e in tracker.entries if not e.exited)
        }
    
    def get_all_positions_status(self) -> Dict[str, Dict]:
        """Get status of all positions."""
        return {
            key: self.get_position_status(tracker.symbol, tracker.side)
            for key, tracker in self.positions.items()
        }
