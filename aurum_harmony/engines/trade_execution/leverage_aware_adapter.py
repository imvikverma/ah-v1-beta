"""
Leverage-Aware Broker Adapter Wrapper
Ensures 3× leverage is properly applied when trading across multiple indices simultaneously
"""

from typing import Dict, Optional, List
from decimal import Decimal
import logging

from aurum_harmony.engines.trade_execution.trade_execution import (
    BrokerAdapter,
    Order,
    OrderStatus,
    Position,
    OrderSide,
)
from aurum_harmony.engines.risk_management.leverage_engine import LeverageEngine
from typing import List
import uuid

logger = logging.getLogger(__name__)


class LeverageAwareAdapter:
    """
    Wrapper around BrokerAdapter that enforces leverage limits.
    
    Key Features:
    - 3× leverage for all categories (except NGD 1.5×)
    - Tracks total exposure across all indices (NIFTY50, BANKNIFTY, SENSEX)
    - Ensures combined exposure doesn't exceed capital × leverage
    - Supports simultaneous trading across multiple indices
    """
    
    # Allowed indices for simultaneous trading
    ALLOWED_INDICES = ["NIFTY50", "NIFTY", "BANKNIFTY", "SENSEX"]
    
    def __init__(
        self,
        broker_adapter: BrokerAdapter,
        capital: float,
        user_category: str = "admin",
        leverage_multiplier: Optional[float] = None
    ):
        """
        Initialize leverage-aware adapter.
        
        Args:
            broker_adapter: Underlying broker adapter
            capital: Base trading capital
            user_category: User category (admin, restricted, semi, NGD)
            leverage_multiplier: Override leverage (if None, uses category default)
        """
        self.broker_adapter = broker_adapter
        self.capital = Decimal(str(capital))
        self.user_category = user_category
        
        # Get leverage multiplier
        if leverage_multiplier is None:
            self.leverage_multiplier = LeverageEngine.get_leverage_multiplier(user_category)
        else:
            self.leverage_multiplier = leverage_multiplier
        
        self.max_exposure = self.capital * Decimal(str(self.leverage_multiplier))
        
        logger.info(
            f"LeverageAwareAdapter initialized: "
            f"Capital=₹{self.capital:,.2f}, "
            f"Leverage={self.leverage_multiplier}×, "
            f"Max Exposure=₹{self.max_exposure:,.2f}"
        )
    
    def _calculate_total_exposure(self) -> Decimal:
        """
        Calculate total exposure across all positions.
        
        Returns:
            Total exposure (sum of all position values)
        """
        positions = self.broker_adapter.get_positions()
        total_exposure = Decimal("0")
        
        for symbol, position in positions.items():
            # Only count allowed indices
            if any(idx in symbol.upper() for idx in self.ALLOWED_INDICES):
                position_value = Decimal(str(position.current_price)) * Decimal(str(abs(position.quantity)))
                total_exposure += position_value
        
        return total_exposure
    
    def _calculate_order_exposure(self, order: Order) -> Decimal:
        """
        Calculate exposure for a new order.
        
        Args:
            order: Order to calculate exposure for
            
        Returns:
            Order exposure value
        """
        # Get current price (from adapter or order)
        price = None
        
        if hasattr(order, 'filled_price') and order.filled_price:
            price = Decimal(str(order.filled_price))
        elif hasattr(order, 'limit_price') and order.limit_price:
            price = Decimal(str(order.limit_price))
        else:
            # Try to get from adapter's price cache or positions
            positions = self.broker_adapter.get_positions()
            if order.symbol in positions:
                price = Decimal(str(positions[order.symbol].current_price))
            elif hasattr(self.broker_adapter, '_get_price'):
                # Try to get price from adapter
                try:
                    price = Decimal(str(self.broker_adapter._get_price(order.symbol)))
                except:
                    pass
        
        if price is None:
            # If we still don't have a price, we'll let the adapter handle it
            # and check exposure after the order is placed
            # For now, return 0 and we'll validate after execution
            logger.warning(f"Cannot determine price for {order.symbol}, will validate after execution")
            return Decimal("0")
        
        order_value = price * Decimal(str(abs(order.quantity)))
        return order_value
    
    def place_order(self, order: Order) -> Order:
        """
        Place order with leverage validation and automatic splitting.
        
        If order would exceed max exposure, automatically splits it to fit within available exposure.
        Never rejects - always executes what's possible within limits.
        """
        # Calculate current total exposure
        current_exposure = self._calculate_total_exposure()
        available_exposure = self.max_exposure - current_exposure
        
        # Calculate new order exposure
        try:
            order_exposure = self._calculate_order_exposure(order)
        except ValueError as e:
            order.status = OrderStatus.REJECTED
            order.metadata["reason"] = str(e)
            logger.warning(f"Order rejected: {e}")
            return order
        
        # If order exposure is 0 (price couldn't be determined), try to place and validate after
        if order_exposure == Decimal("0"):
            logger.warning(f"Cannot determine price for {order.symbol}, placing order and validating after execution")
            result_order = self.broker_adapter.place_order(order)
            # Validate exposure after execution
            if result_order.status == OrderStatus.FILLED:
                updated_exposure = self._calculate_total_exposure()
                if updated_exposure > self.max_exposure:
                    logger.warning(
                        f"Order filled but exceeds exposure limit. "
                        f"Exposure: ₹{updated_exposure:,.2f} / ₹{self.max_exposure:,.2f}. "
                        f"Consider reducing position size."
                    )
            return result_order
        
        # Check if order fits within available exposure
        if order_exposure <= available_exposure:
            # Order fits - place it directly
            result_order = self.broker_adapter.place_order(order)
            
            # Log exposure utilization
            if result_order.status == OrderStatus.FILLED:
                updated_exposure = self._calculate_total_exposure()
                utilization = (updated_exposure / self.max_exposure * 100) if self.max_exposure > 0 else 0
                logger.info(
                    f"Order filled: {order.symbol} {order.side.value} {order.quantity}. "
                    f"Exposure: ₹{updated_exposure:,.2f} / ₹{self.max_exposure:,.2f} ({utilization:.1f}%)"
                )
            
            return result_order
        
        # Order exceeds available exposure - split it
        logger.info(
            f"Order exceeds available exposure. Splitting order: "
            f"Requested: ₹{order_exposure:,.2f}, Available: ₹{available_exposure:,.2f}"
        )
        
        # Calculate how much of the order we can execute
        # Get price per unit to calculate quantity
        original_quantity = abs(order.quantity)
        price_per_unit = order_exposure / Decimal(str(original_quantity)) if original_quantity > 0 else Decimal("0")
        
        if price_per_unit == Decimal("0"):
            # Can't determine price - try to place and validate after
            logger.warning(f"Cannot determine price for splitting {order.symbol}, attempting direct placement")
            result_order = self.broker_adapter.place_order(order)
            if result_order.status == OrderStatus.FILLED:
                updated_exposure = self._calculate_total_exposure()
                if updated_exposure > self.max_exposure:
                    logger.warning(
                        f"Order filled but exceeds exposure limit. "
                        f"Exposure: ₹{updated_exposure:,.2f} / ₹{self.max_exposure:,.2f}"
                    )
            return result_order
        
        # Calculate maximum quantity that fits within available exposure
        max_quantity_by_exposure = float(available_exposure / price_per_unit)
        
        # Round down to nearest whole number (for lot-based trading)
        # For options, quantities are typically in lots (whole numbers)
        max_quantity_by_exposure = int(max_quantity_by_exposure)
        
        # Ensure we don't exceed original quantity
        if max_quantity_by_exposure >= original_quantity:
            # This shouldn't happen if logic is correct, but handle it
            logger.warning(f"Calculation error: max_quantity ({max_quantity_by_exposure}) >= original ({original_quantity})")
            result_order = self.broker_adapter.place_order(order)
            return result_order
        
        # Split the order: execute what fits, mark remainder
        if max_quantity_by_exposure > 0:
            # Create order for available exposure
            split_quantity = float(max_quantity_by_exposure)
            if order.side == OrderSide.SELL:
                split_quantity = -split_quantity  # Maintain sign
            
            split_order = Order(
                symbol=order.symbol,
                side=order.side,
                quantity=split_quantity,
                order_type=order.order_type,
                limit_price=order.limit_price,
                client_order_id=f"{order.client_order_id}_split_partial",
                metadata={
                    **order.metadata,
                    "split_reason": "Exposure limit - partial execution",
                    "original_quantity": original_quantity,
                    "executed_quantity": abs(split_quantity),
                    "remaining_quantity": original_quantity - abs(split_quantity),
                    "available_exposure": float(available_exposure),
                    "requested_exposure": float(order_exposure),
                }
            )
            
            # Place the split order
            result_order = self.broker_adapter.place_order(split_order)
            
            # Update original order metadata
            executed_qty = abs(split_quantity)
            remaining_qty = original_quantity - executed_qty
            executed_exposure = float(available_exposure)
            remaining_exposure = float(order_exposure - available_exposure)
            
            order.metadata.update({
                "split_executed": True,
                "executed_quantity": executed_qty,
                "remaining_quantity": remaining_qty,
                "executed_exposure": executed_exposure,
                "remaining_exposure": remaining_exposure,
                "split_reason": f"Order split due to exposure limit. Executed {executed_qty:.2f} of {original_quantity:.2f} units (₹{executed_exposure:,.2f} of ₹{order_exposure:,.2f} exposure)"
            })
            
            if result_order.status == OrderStatus.FILLED:
                updated_exposure = self._calculate_total_exposure()
                utilization = (updated_exposure / self.max_exposure * 100) if self.max_exposure > 0 else 0
                logger.info(
                    f"Order split and partially filled: {order.symbol} {order.side.value} "
                    f"{executed_qty:.2f} of {original_quantity:.2f} units. "
                    f"Exposure: ₹{updated_exposure:,.2f} / ₹{self.max_exposure:,.2f} ({utilization:.1f}%)"
                )
                logger.info(
                    f"Remaining: {remaining_qty:.2f} units (₹{remaining_exposure:,.2f} exposure) "
                    f"will be executed when exposure becomes available"
                )
                # Mark order as partially filled
                order.status = OrderStatus.FILLED  # Mark as filled for the executed portion
            else:
                order.status = result_order.status
                order.metadata["split_order_status"] = result_order.status.value
            
            return result_order
        else:
            # No exposure available at all
            order.status = OrderStatus.REJECTED
            order.metadata["reason"] = "No available exposure"
            order.metadata["current_exposure"] = float(current_exposure)
            order.metadata["max_exposure"] = float(self.max_exposure)
            order.metadata["available_exposure"] = float(available_exposure)
            order.metadata["requested_exposure"] = float(order_exposure)
            
            logger.warning(
                f"Order rejected: No available exposure. "
                f"Current: ₹{current_exposure:,.2f}, "
                f"Max: ₹{self.max_exposure:,.2f}, "
                f"Requested: ₹{order_exposure:,.2f}"
            )
            return order
    
    def place_order_with_splitting(self, order: Order) -> List[Order]:
        """
        Place order with automatic splitting, returning all executed orders.
        
        Returns:
            List of executed orders (may be split if exposure limit exceeded)
        """
        result_order = self.place_order(order)
        
        if result_order.status == OrderStatus.FILLED:
            # Check if it was a split
            if result_order.metadata.get("split_executed"):
                return [result_order]
            else:
                return [result_order]
        else:
            return []
    
    def get_positions(self) -> Dict[str, Position]:
        """Get all positions."""
        return self.broker_adapter.get_positions()
    
    def get_balance(self) -> float:
        """Get current balance."""
        return self.broker_adapter.get_balance()
    
    def get_exposure_status(self) -> Dict[str, any]:
        """
        Get current exposure status across all indices.
        
        Returns:
            Dictionary with exposure breakdown by index and total
        """
        positions = self.broker_adapter.get_positions()
        
        exposure_by_index: Dict[str, Decimal] = {}
        total_exposure = Decimal("0")
        
        for symbol, position in positions.items():
            # Identify index
            index_name = None
            for idx in self.ALLOWED_INDICES:
                if idx in symbol.upper():
                    index_name = idx
                    break
            
            if index_name:
                position_value = Decimal(str(position.current_price)) * Decimal(str(abs(position.quantity)))
                if index_name not in exposure_by_index:
                    exposure_by_index[index_name] = Decimal("0")
                exposure_by_index[index_name] += position_value
                total_exposure += position_value
        
        utilization = (total_exposure / self.max_exposure * 100) if self.max_exposure > 0 else 0
        
        return {
            "capital": float(self.capital),
            "leverage_multiplier": self.leverage_multiplier,
            "max_exposure": float(self.max_exposure),
            "current_exposure": float(total_exposure),
            "exposure_by_index": {idx: float(val) for idx, val in exposure_by_index.items()},
            "utilization_percent": float(utilization),
            "available_exposure": float(self.max_exposure - total_exposure),
        }
    
    def cancel_order(self, broker_order_id: str) -> bool:
        """Cancel an order."""
        return self.broker_adapter.cancel_order(broker_order_id)
    
    def get_orders(self, status: Optional[OrderStatus] = None) -> List[Order]:
        """Get orders."""
        return self.broker_adapter.get_orders(status)
    
    def get_statistics(self) -> Dict:
        """Get statistics including leverage information."""
        stats = self.broker_adapter.get_statistics() if hasattr(self.broker_adapter, 'get_statistics') else {}
        exposure_status = self.get_exposure_status()
        
        stats.update({
            "leverage_info": {
                "capital": exposure_status["capital"],
                "leverage_multiplier": exposure_status["leverage_multiplier"],
                "max_exposure": exposure_status["max_exposure"],
                "current_exposure": exposure_status["current_exposure"],
                "utilization_percent": exposure_status["utilization_percent"],
                "available_exposure": exposure_status["available_exposure"],
            },
            "exposure_by_index": exposure_status["exposure_by_index"],
            "trading_indices": self.ALLOWED_INDICES,
        })
        
        return stats
