"""
Unified Snapshot Validator

Validates unified snapshot data for consistency and correctness.
"""

from __future__ import annotations

import logging
from typing import List, Dict, Any, Optional
from aurum_harmony.engines.trade_execution.unified_snapshot import (
    UnifiedSnapshot,
    UnifiedPosition,
    UnifiedBalance,
    Exchange,
)

logger = logging.getLogger(__name__)


class SnapshotValidator:
    """Validates unified snapshot data for consistency."""
    
    @staticmethod
    def validate_snapshot(snapshot: UnifiedSnapshot) -> Dict[str, Any]:
        """
        Validate a unified snapshot and return validation results.
        
        Returns:
            Dictionary with validation results:
            - valid: bool
            - warnings: List[str]
            - errors: List[str]
        """
        warnings: List[str] = []
        errors: List[str] = []
        
        # Check engine availability
        if snapshot.available_engines == 0:
            warnings.append("No engines are available")
        elif snapshot.available_engines < snapshot.total_engines:
            warnings.append(
                f"Only {snapshot.available_engines}/{snapshot.total_engines} engines are available"
            )
        
        # Validate positions
        for pos in snapshot.all_positions:
            pos_validation = SnapshotValidator.validate_position(pos)
            warnings.extend(pos_validation.get("warnings", []))
            errors.extend(pos_validation.get("errors", []))
        
        # Validate balance
        if snapshot.aggregated_balance:
            balance_validation = SnapshotValidator.validate_balance(snapshot.aggregated_balance)
            warnings.extend(balance_validation.get("warnings", []))
            errors.extend(balance_validation.get("errors", []))
        
        # Check for duplicate positions (same symbol+exchange from multiple engines)
        symbol_exchange_map: Dict[str, List[UnifiedPosition]] = {}
        for pos in snapshot.all_positions:
            key = f"{pos.symbol}_{pos.exchange.value}"
            if key not in symbol_exchange_map:
                symbol_exchange_map[key] = []
            symbol_exchange_map[key].append(pos)
        
        for key, positions in symbol_exchange_map.items():
            if len(positions) > 1:
                engines = [p.engine_source.value for p in positions]
                warnings.append(
                    f"Duplicate position {key} from multiple engines: {', '.join(engines)}"
                )
        
        # Check balance consistency
        if snapshot.aggregated_balance:
            calculated_equity = (
                snapshot.aggregated_balance.available + 
                snapshot.aggregated_balance.margin_used
            )
            if abs(calculated_equity - snapshot.aggregated_balance.total_equity) > 0.01:
                warnings.append(
                    f"Balance inconsistency: available + margin_used ({calculated_equity:.2f}) "
                    f"!= total_equity ({snapshot.aggregated_balance.total_equity:.2f})"
                )
        
        return {
            "valid": len(errors) == 0,
            "warnings": warnings,
            "errors": errors,
            "summary": {
                "total_positions": len(snapshot.all_positions),
                "available_engines": snapshot.available_engines,
                "total_engines": snapshot.total_engines,
            },
        }
    
    @staticmethod
    def validate_position(pos: UnifiedPosition) -> Dict[str, List[str]]:
        """Validate a single position."""
        warnings: List[str] = []
        errors: List[str] = []
        
        # Check symbol
        if not pos.symbol or len(pos.symbol.strip()) == 0:
            errors.append(f"Position has empty symbol")
        
        # Check quantity
        if pos.quantity == 0:
            warnings.append(f"Position {pos.symbol} has zero quantity")
        
        # Check prices
        if pos.avg_price < 0:
            errors.append(f"Position {pos.symbol} has negative avg_price: {pos.avg_price}")
        
        if pos.current_price < 0:
            errors.append(f"Position {pos.symbol} has negative current_price: {pos.current_price}")
        
        # Check side consistency
        if pos.side == "BUY" and pos.quantity < 0:
            warnings.append(f"Position {pos.symbol}: BUY side but negative quantity")
        elif pos.side == "SELL" and pos.quantity > 0:
            warnings.append(f"Position {pos.symbol}: SELL side but positive quantity")
        
        # Check P&L calculation
        if pos.side == "BUY":
            expected_pnl = (pos.current_price - pos.avg_price) * abs(pos.quantity)
        else:  # SELL
            expected_pnl = (pos.avg_price - pos.current_price) * abs(pos.quantity)
        
        pnl_diff = abs(expected_pnl - pos.unrealized_pnl)
        if pnl_diff > 0.01:  # Allow small floating point differences
            warnings.append(
                f"Position {pos.symbol}: P&L mismatch. "
                f"Expected: {expected_pnl:.2f}, Got: {pos.unrealized_pnl:.2f}"
            )
        
        return {"warnings": warnings, "errors": errors}
    
    @staticmethod
    def validate_balance(balance: UnifiedBalance) -> Dict[str, List[str]]:
        """Validate a balance object."""
        warnings: List[str] = []
        errors: List[str] = []
        
        # Check for negative values
        if balance.available < 0:
            warnings.append(f"Negative available balance: {balance.available}")
        
        if balance.margin_used < 0:
            warnings.append(f"Negative margin_used: {balance.margin_used}")
        
        # Check equity calculation
        calculated_equity = balance.available + balance.margin_used
        if abs(calculated_equity - balance.total_equity) > 0.01:
            warnings.append(
                f"Equity mismatch: available + margin_used ({calculated_equity:.2f}) "
                f"!= total_equity ({balance.total_equity:.2f})"
            )
        
        return {"warnings": warnings, "errors": errors}


__all__ = ["SnapshotValidator"]

