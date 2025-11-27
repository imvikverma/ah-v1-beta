"""
Blockchain trade recording logic for AurumHarmony.

This module defines a simple function to record trades on Hyperledger Fabric via
the central FabricClient abstraction. In this repo it is safe by default:
if no Fabric gateway is configured, calls are logged but do not fail.
"""

from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Dict, Any
import time
import logging

from .fabric_client import FabricClient


logger = logging.getLogger(__name__)


@dataclass
class TradeRecord:
    trade_id: str
    user_id: str
    symbol: str
    side: str
    quantity: float
    price: float
    timestamp: float
    strategy: str
    extra: Dict[str, Any] | None = None


def record_trade_on_chain(trade: TradeRecord) -> Dict[str, Any]:
    """
    Sends a trade record to the Fabric network (or logs a stub call).
    """
    client = FabricClient()
    payload = asdict(trade)
    # Ensure timestamp is a float (serialization‑friendly)
    if not payload.get("timestamp"):
        payload["timestamp"] = time.time()

    logger.info("Recording trade on chain: %s", payload)
    result = client.invoke("recordTrade", payload)
    return result


__all__ = ["TradeRecord", "record_trade_on_chain"]
