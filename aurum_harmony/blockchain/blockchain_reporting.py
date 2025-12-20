"""
Blockchain reporting logic for AurumHarmony.

Provides high‑level query helpers over trade and settlement data stored on
Hyperledger Fabric. Uses FabricClient.query as the single integration point.
"""

from __future__ import annotations

from typing import Dict, Any, List
import logging

from .fabric_client import FabricClient


logger = logging.getLogger(__name__)


def query_trades_by_user(user_id: str) -> List[Dict[str, Any]]:
    client = FabricClient()
    logger.info("Querying trades for user_id=%s", user_id)
    resp = client.query("queryTradesByUser", {"user_id": user_id})
    return resp.get("result", [])


def query_trade_by_id(trade_id: str) -> Dict[str, Any]:
    client = FabricClient()
    logger.info("Querying trade for trade_id=%s", trade_id)
    resp = client.query("queryTradeById", {"trade_id": trade_id})
    return resp.get("result", {})


__all__ = ["query_trades_by_user", "query_trade_by_id"]
