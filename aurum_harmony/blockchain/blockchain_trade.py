"""
Blockchain trade recording logic for AurumHarmony.

This module defines a simple function to record trades on Hyperledger Fabric via
the central FabricClient abstraction. In this repo it is safe by default:
if no Fabric gateway is configured, calls are logged but do not fail.

Enhanced with:
- Input validation
- Error handling
- Retry logic
- Comprehensive logging
"""

from __future__ import annotations

from dataclasses import dataclass, asdict, field
from typing import Dict, Any, Optional
import time
import logging
import uuid

from .fabric_client import FabricClient, load_fabric_config

logger = logging.getLogger(__name__)


@dataclass
class TradeRecord:
    """Represents a trade record for blockchain storage."""
    trade_id: str
    user_id: str
    symbol: str
    side: str
    quantity: float
    price: float
    timestamp: float
    strategy: str
    extra: Dict[str, Any] = field(default_factory=dict)
    
    def __post_init__(self):
        """Validate trade record."""
        if not self.trade_id:
            self.trade_id = f"trade_{uuid.uuid4().hex[:16]}"
        
        if not self.user_id:
            raise ValueError("user_id is required")
        
        if not self.symbol:
            raise ValueError("symbol is required")
        
        if self.quantity <= 0:
            raise ValueError(f"quantity must be positive, got: {self.quantity}")
        
        if self.price <= 0:
            raise ValueError(f"price must be positive, got: {self.price}")
        
        if not self.timestamp or self.timestamp <= 0:
            self.timestamp = time.time()
        
        if not self.side or self.side.upper() not in ("BUY", "SELL"):
            raise ValueError(f"side must be BUY or SELL, got: {self.side}")
        
        self.side = self.side.upper()
        self.symbol = self.symbol.strip().upper()


def record_trade_on_chain(trade: TradeRecord, retry_count: int = 3) -> Dict[str, Any]:
    """
    Sends a trade record to the Fabric network with retry logic.
    
    Args:
        trade: TradeRecord to record
        retry_count: Number of retry attempts on failure
        
    Returns:
        Result dictionary from Fabric client
    """
    try:
        # Validate trade record
        if not isinstance(trade, TradeRecord):
            raise ValueError(f"trade must be a TradeRecord instance, got: {type(trade)}")
        
        # Load Fabric client
        fabric_config = load_fabric_config()
        client = FabricClient(fabric_config)
        
        # Prepare payload
        payload = asdict(trade)
        # Ensure timestamp is a float (serialization-friendly)
        if not payload.get("timestamp") or payload["timestamp"] <= 0:
            payload["timestamp"] = time.time()
        
        # Convert extra to dict if None
        if payload.get("extra") is None:
            payload["extra"] = {}
        
        logger.info(
            f"Recording trade on chain: {trade.trade_id} "
            f"({trade.symbol} {trade.side} {trade.quantity} @ ₹{trade.price:,.2f})"
        )
        
        # Invoke with retry logic
        result = None
        last_error = None
        
        for attempt in range(retry_count):
            try:
                result = client.invoke("RecordTrade", payload)
                
                if result.get("status") in ("success", "OK"):
                    logger.info(f"Trade {trade.trade_id} recorded successfully on blockchain")
                    return result
                elif result.get("status") == "NOOP":
                    logger.debug(f"Fabric gateway not configured, trade logged but not recorded")
                    return result
                else:
                    logger.warning(
                        f"Trade recording attempt {attempt + 1} returned status: {result.get('status')}"
                    )
                    
            except Exception as e:
                last_error = e
                logger.warning(
                    f"Trade recording attempt {attempt + 1} failed: {e}"
                )
                if attempt < retry_count - 1:
                    time.sleep(0.5 * (attempt + 1))  # Exponential backoff
        
        # All retries failed
        logger.error(
            f"Failed to record trade {trade.trade_id} after {retry_count} attempts: {last_error}"
        )
        return {
            "status": "ERROR",
            "message": f"Failed to record trade after {retry_count} attempts",
            "error": str(last_error) if last_error else "Unknown error"
        }
        
    except Exception as e:
        logger.error(f"Error recording trade on chain: {e}", exc_info=True)
        return {
            "status": "ERROR",
            "message": f"Error recording trade: {str(e)}"
        }


__all__ = ["TradeRecord", "record_trade_on_chain"]
