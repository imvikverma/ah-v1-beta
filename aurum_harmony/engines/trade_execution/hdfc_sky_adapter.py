"""
HDFC Sky Broker Adapter

Implements BrokerAdapter interface for HDFC Sky API.
Connects HDFC Sky to the trading orchestrator.
"""

from __future__ import annotations

import logging
from typing import Optional
import os
from dotenv import load_dotenv

from aurum_harmony.engines.trade_execution.trade_execution import (
    BrokerAdapter,
    Order,
    OrderStatus,
    OrderSide,
    OrderType,
)

load_dotenv()

logger = logging.getLogger(__name__)


class HDFCSkyBrokerAdapter(BrokerAdapter):
    """
    Broker adapter for HDFC Sky API.
    
    Implements the BrokerAdapter interface to connect HDFC Sky
    to the trading orchestrator for live trading.
    """
    
    def __init__(self, hdfc_client: Optional[object] = None):
        """
        Initialize HDFC Sky broker adapter.
        
        Args:
            hdfc_client: Optional HDFCSkyAPI instance. If not provided,
                        will try to create from environment variables.
        """
        if hdfc_client:
            self.client = hdfc_client
        else:
            # Try to create from environment variables
            try:
                from api.hdfc_sky_api import HDFCSkyAPI
                
                api_key = os.getenv("HDFC_SKY_API_KEY")
                api_secret = os.getenv("HDFC_SKY_API_SECRET")
                token_id = os.getenv("HDFC_SKY_TOKEN_ID")
                access_token = os.getenv("HDFC_SKY_ACCESS_TOKEN")
                
                if not api_key or not api_secret:
                    raise ValueError("HDFC_SKY_API_KEY and HDFC_SKY_API_SECRET must be set in environment")
                
                self.client = HDFCSkyAPI(
                    api_key=api_key,
                    api_secret=api_secret,
                    token_id=token_id,
                    access_token=access_token
                )
                
                if not self.client.is_authenticated():
                    logger.warning("HDFC Sky client created but not authenticated. Set HDFC_SKY_TOKEN_ID or HDFC_SKY_ACCESS_TOKEN")
            except Exception as e:
                logger.error(f"Error creating HDFC Sky client: {e}")
                raise
        
        if not self.client.is_authenticated():
            raise ValueError("HDFC Sky client is not authenticated. Please set HDFC_SKY_TOKEN_ID or HDFC_SKY_ACCESS_TOKEN")
        
        logger.info("HDFC Sky BrokerAdapter initialized and authenticated")
    
    def place_order(self, order: Order) -> Order:
        """
        Place an order through HDFC Sky API.
        
        Args:
            order: Order object to place
            
        Returns:
            Order object with broker_order_id and status updated
        """
        try:
            # Map OrderSide to HDFC Sky transaction type
            transaction_type = "BUY" if order.side == OrderSide.BUY else "SELL"
            
            # Map OrderType to HDFC Sky order type
            if order.order_type == OrderType.MARKET:
                hdfc_order_type = "MARKET"
                price = 0
            elif order.order_type == OrderType.LIMIT:
                hdfc_order_type = "LIMIT"
                price = order.limit_price or 0
                if price <= 0:
                    raise ValueError(f"Limit price required for LIMIT orders, got: {price}")
            else:
                raise ValueError(f"Unsupported order type: {order.order_type}")
            
            # Determine exchange (default to NSE)
            exchange = order.metadata.get("exchange", "NSE")
            
            # Place order through HDFC Sky API
            result = self.client.place_order(
                symbol=order.symbol,
                exchange=exchange,
                quantity=int(order.quantity),
                order_type=hdfc_order_type,
                price=price,
                transaction_type=transaction_type,
                product_type=order.metadata.get("product_type", "INTRADAY"),
                validity=order.metadata.get("validity", "DAY")
            )
            
            # Extract broker order ID from response
            # HDFC Sky response format may vary, adjust based on actual API response
            if isinstance(result, dict):
                broker_order_id = result.get("order_id") or result.get("orderId") or result.get("data", {}).get("order_id")
                if broker_order_id:
                    order.broker_order_id = str(broker_order_id)
                    order.update_status(OrderStatus.NEW, "Order placed successfully")
                    logger.info(f"Order {order.client_order_id} placed via HDFC Sky: {order.broker_order_id}")
                else:
                    # If no order_id in response, mark as filled (some brokers do this)
                    order.update_status(OrderStatus.FILLED, "Order executed immediately")
                    logger.info(f"Order {order.client_order_id} executed immediately via HDFC Sky")
            else:
                # Unexpected response format
                order.update_status(OrderStatus.REJECTED, f"Unexpected response format: {result}")
                logger.warning(f"Unexpected response from HDFC Sky: {result}")
            
            return order
            
        except Exception as e:
            logger.error(f"Error placing order {order.client_order_id} via HDFC Sky: {e}")
            order.update_status(OrderStatus.REJECTED, str(e))
            return order
    
    def cancel_order(self, broker_order_id: str) -> bool:
        """
        Cancel an order through HDFC Sky API.
        
        Args:
            broker_order_id: Broker's order ID to cancel
            
        Returns:
            True if cancellation was successful, False otherwise
        """
        try:
            result = self.client.cancel_order(broker_order_id)
            
            # Check if cancellation was successful
            # HDFC Sky response format may vary, adjust based on actual API response
            if isinstance(result, dict):
                success = result.get("status") == "CANCELLED" or result.get("success") or result.get("data", {}).get("status") == "CANCELLED"
                if success:
                    logger.info(f"Order {broker_order_id} cancelled successfully via HDFC Sky")
                    return True
                else:
                    logger.warning(f"Order {broker_order_id} cancellation may have failed: {result}")
                    return False
            else:
                # If response is not a dict, assume success if no exception
                logger.info(f"Order {broker_order_id} cancelled via HDFC Sky")
                return True
                
        except Exception as e:
            logger.error(f"Error cancelling order {broker_order_id} via HDFC Sky: {e}")
            return False

