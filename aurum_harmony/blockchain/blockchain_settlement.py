"""
Blockchain settlement logic for AurumHarmony.

Records settlement events (success/failure) for trades on Hyperledger Fabric via
the FabricClient abstraction. Safe no‑op behaviour when gateway is not set.
"""

from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Dict, Any
import time
import logging

from .fabric_client import FabricClient


logger = logging.getLogger(__name__)


@dataclass
class SettlementRecord:
    settlement_id: str
    trade_id: str
    status: str  # e.g., "SUCCESS" or "FAILED"
    timestamp: float
    details: Dict[str, Any] | None = None


def record_settlement_on_chain(settlement: SettlementRecord) -> Dict[str, Any]:
    client = FabricClient()
    payload = asdict(settlement)
    if not payload.get("timestamp"):
        payload["timestamp"] = time.time()

    logger.info("Recording settlement on chain: %s", payload)
    result = client.invoke("recordSettlement", payload)
    return result


__all__ = ["SettlementRecord", "record_settlement_on_chain"]
