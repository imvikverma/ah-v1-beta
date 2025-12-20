"""
Dynamic Order Splitting for SEBI Compliance

Implements automatic order splitting for large orders to comply with SEBI regulations:
- Max lots per order: 250
- Large orders automatically split — never halt trading
"""

from __future__ import annotations

import logging
from typing import List, Dict, Any
from dataclasses import dataclass

from aurum_harmony.engines.trade_execution.trade_execution import Order, OrderSide, OrderType

# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class SplitOrder:
    """Represents a split order."""
    original_order: Order
    split_orders: List[Order]
    split_count: int
    total_quantity: float
    split_quantity: float


class OrderSplittingEngine:
    """
    Dynamic order splitting engine for SEBI compliance.
    
    Rules:
    - Max lots per order: 250
    - Automatically splits orders exceeding this limit
    - Never halts trading - always executes split orders
    """
    
    MAX_LOTS_PER_ORDER = 250  # SEBI compliance limit
    
    @classmethod
    def split_order_if_needed(cls, order: Order) -> SplitOrder:
        """
        Split order if it exceeds SEBI limit (250 lots).
        
        Args:
            order: Original order to potentially split
            
        Returns:
            SplitOrder object with split orders if needed, or single order
        """
        try:
            # Check if splitting is needed
            if order.quantity <= cls.MAX_LOTS_PER_ORDER:
                # No splitting needed
                return SplitOrder(
                    original_order=order,
                    split_orders=[order],
                    split_count=1,
                    total_quantity=order.quantity,
                    split_quantity=order.quantity
                )
            
            # Calculate number of splits needed
            split_count = int((order.quantity + cls.MAX_LOTS_PER_ORDER - 1) // cls.MAX_LOTS_PER_ORDER)
            split_quantity = cls.MAX_LOTS_PER_ORDER
            remaining_quantity = order.quantity
            
            split_orders: List[Order] = []
            
            logger.info(
                f"Splitting order: {order.symbol} {order.side.value} {order.quantity} lots "
                f"into {split_count} orders (max {cls.MAX_LOTS_PER_ORDER} lots each)"
            )
            
            # Create split orders
            for i in range(split_count):
                # Last order gets remaining quantity
                if i == split_count - 1:
                    current_quantity = remaining_quantity
                else:
                    current_quantity = split_quantity
                    remaining_quantity -= split_quantity
                
                # Create split order
                split_order = Order(
                    symbol=order.symbol,
                    side=order.side,
                    quantity=current_quantity,
                    order_type=order.order_type,
                    limit_price=order.limit_price,
                    client_order_id=f"{order.client_order_id}_split_{i+1}",
                    metadata={
                        **order.metadata,
                        "split_index": i + 1,
                        "total_splits": split_count,
                        "original_order_id": order.client_order_id,
                        "split_reason": f"SEBI compliance: >{cls.MAX_LOTS_PER_ORDER} lots"
                    }
                )
                
                split_orders.append(split_order)
                
                logger.debug(
                    f"Split order {i+1}/{split_count}: {split_order.symbol} "
                    f"{split_order.side.value} {split_order.quantity} lots"
                )
            
            return SplitOrder(
                original_order=order,
                split_orders=split_orders,
                split_count=split_count,
                total_quantity=order.quantity,
                split_quantity=split_quantity
            )
        
        except Exception as e:
            logger.error(f"Error splitting order: {e}", exc_info=True)
            # Return original order on error
            return SplitOrder(
                original_order=order,
                split_orders=[order],
                split_count=1,
                total_quantity=order.quantity,
                split_quantity=order.quantity
            )
    
    @classmethod
    def validate_order_size(cls, quantity: float) -> tuple[bool, str]:
        """
        Validate if order size is within SEBI limits.
        
        Args:
            quantity: Order quantity in lots
            
        Returns:
            Tuple of (is_valid, message)
        """
        if quantity <= 0:
            return False, "Order quantity must be positive"
        
        if quantity > cls.MAX_LOTS_PER_ORDER:
            return True, f"Order will be split: {quantity} lots > {cls.MAX_LOTS_PER_ORDER} limit"
        
        return True, "Order size is within SEBI limits"


# Default instance
order_splitting_engine = OrderSplittingEngine()

__all__ = [
    "OrderSplittingEngine",
    "SplitOrder",
    "order_splitting_engine",
]

