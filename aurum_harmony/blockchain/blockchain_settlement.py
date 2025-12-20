"""
Blockchain settlement logic for AurumHarmony.

Records settlement events (success/failure) for trades on Hyperledger Fabric via
the FabricClient abstraction. Safe no‑op behaviour when gateway is not set.

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
class SettlementRecord:
    """Represents a settlement record for blockchain storage."""
    settlement_id: str
    trade_id: str
    status: str  # e.g., "SUCCESS" or "FAILED"
    timestamp: float
    details: Dict[str, Any] = field(default_factory=dict)
    user_id: Optional[str] = None
    profit: Optional[float] = None
    
    def __post_init__(self):
        """Validate settlement record."""
        if not self.settlement_id:
            self.settlement_id = f"settlement_{uuid.uuid4().hex[:16]}"
        
        if not self.trade_id:
            raise ValueError("trade_id is required")
        
        if not self.status:
            raise ValueError("status is required")
        
        self.status = self.status.upper()
        
        valid_statuses = ("SUCCESS", "FAILED", "PENDING", "CANCELLED")
        if self.status not in valid_statuses:
            logger.warning(f"Unknown settlement status: {self.status}, using SUCCESS")
            self.status = "SUCCESS"
        
        if not self.timestamp or self.timestamp <= 0:
            self.timestamp = time.time()


def record_settlement_on_chain(settlement: SettlementRecord, retry_count: int = 3) -> Dict[str, Any]:
    """
    Records a settlement event on the Fabric network with retry logic.
    
    Args:
        settlement: SettlementRecord to record
        retry_count: Number of retry attempts on failure
        
    Returns:
        Result dictionary from Fabric client
    """
    try:
        # Validate settlement record
        if not isinstance(settlement, SettlementRecord):
            raise ValueError(f"settlement must be a SettlementRecord instance, got: {type(settlement)}")
        
        # Load Fabric client
        fabric_config = load_fabric_config()
        client = FabricClient(fabric_config)
        
        # Prepare payload
        payload = asdict(settlement)
        # Ensure timestamp is a float
        if not payload.get("timestamp") or payload["timestamp"] <= 0:
            payload["timestamp"] = time.time()
        
        # Convert details to dict if None
        if payload.get("details") is None:
            payload["details"] = {}
        
        logger.info(
            f"Recording settlement on chain: {settlement.settlement_id} "
            f"(Trade: {settlement.trade_id}, Status: {settlement.status})"
        )
        
        # Invoke with retry logic
        result = None
        last_error = None
        
        for attempt in range(retry_count):
            try:
                result = client.invoke("RecordSettlement", payload)
                
                if result.get("status") in ("success", "OK"):
                    logger.info(f"Settlement {settlement.settlement_id} recorded successfully on blockchain")
                    return result
                elif result.get("status") == "NOOP":
                    logger.debug(f"Fabric gateway not configured, settlement logged but not recorded")
                    return result
                else:
                    logger.warning(
                        f"Settlement recording attempt {attempt + 1} returned status: {result.get('status')}"
                    )
                    
            except Exception as e:
                last_error = e
                logger.warning(
                    f"Settlement recording attempt {attempt + 1} failed: {e}"
                )
                if attempt < retry_count - 1:
                    time.sleep(0.5 * (attempt + 1))  # Exponential backoff
        
        # All retries failed
        logger.error(
            f"Failed to record settlement {settlement.settlement_id} after {retry_count} attempts: {last_error}"
        )
        return {
            "status": "ERROR",
            "message": f"Failed to record settlement after {retry_count} attempts",
            "error": str(last_error) if last_error else "Unknown error"
        }
        
    except Exception as e:
        logger.error(f"Error recording settlement on chain: {e}", exc_info=True)
        return {
            "status": "ERROR",
            "message": f"Error recording settlement: {str(e)}"
        }


__all__ = ["SettlementRecord", "record_settlement_on_chain"]
