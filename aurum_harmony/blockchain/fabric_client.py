"""
Fabric client abstraction for AurumHarmony.

This module centralizes all Hyperledger Fabric connectivity so the rest of the
codebase does NOT talk to Fabric directly. In this repo it is implemented as a
safe stub that you can later replace with a real SDK or REST gateway.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Optional
import os
import logging


logger = logging.getLogger(__name__)


@dataclass
class FabricConfig:
    """Configuration needed to talk to a Fabric network or gateway."""

    channel_name: str
    chaincode_name: str
    # If you use a REST / gRPC gateway service, configure it here:
    gateway_url: Optional[str] = None


def load_fabric_config() -> FabricConfig:
    """
    Loads Fabric configuration from environment variables.
    Defaults are safe and non‑production.
    """
    channel_name = os.getenv("FABRIC_CHANNEL_NAME", "aurumchannel")
    chaincode_name = os.getenv("FABRIC_CHAINCODE_NAME", "aurum_cc")
    gateway_url = os.getenv("FABRIC_GATEWAY_URL")  # e.g. http://localhost:8080
    return FabricConfig(
        channel_name=channel_name,
        chaincode_name=chaincode_name,
        gateway_url=gateway_url,
    )


class FabricClient:
    """
    Very thin abstraction around Fabric.

    In this starter implementation:
    - If FABRIC_GATEWAY_URL is not set, calls become logged no‑ops.
    - Later you can implement real calls to a Node.js / Go gateway or Python SDK.
    """

    def __init__(self, config: Optional[FabricConfig] = None) -> None:
        self.config = config or load_fabric_config()

    def invoke(
        self,
        function: str,
        args: Dict[str, Any],
        transient: Optional[Dict[str, bytes]] = None,
    ) -> Dict[str, Any]:
        """
        Invoke a state‑changing chaincode function.
        For now this is a stub that logs and returns a dummy response.
        """
        if not self.config.gateway_url:
            logger.info(
                "FabricClient.invoke called without FABRIC_GATEWAY_URL set. "
                "This is a NO‑OP stub. function=%s args=%s",
                function,
                args,
            )
            return {"status": "NOOP", "message": "Fabric gateway not configured"}

        # TODO: Implement real HTTP/gRPC call to gateway service.
        logger.info(
            "Would invoke Fabric gateway at %s: function=%s args=%s",
            self.config.gateway_url,
            function,
            args,
        )
        return {"status": "OK", "message": "Stubbed Fabric invoke"}

    def query(self, function: str, args: Dict[str, Any]) -> Dict[str, Any]:
        """
        Query chaincode (read‑only).
        Stubbed the same way as invoke.
        """
        if not self.config.gateway_url:
            logger.info(
                "FabricClient.query called without FABRIC_GATEWAY_URL set. "
                "This is a NO‑OP stub. function=%s args=%s",
                function,
                args,
            )
            return {"status": "NOOP", "result": []}

        # TODO: Implement real HTTP/gRPC call to gateway service.
        logger.info(
            "Would query Fabric gateway at %s: function=%s args=%s",
            self.config.gateway_url,
            function,
            args,
        )
        return {"status": "OK", "result": []}


__all__ = ["FabricConfig", "FabricClient", "load_fabric_config"]


