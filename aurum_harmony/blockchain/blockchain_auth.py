"""
Blockchain authentication logic for AurumHarmony.

In a real deployment this would manage Fabric identities (enroll, register,
store in a wallet). For now we keep a very small abstraction so the rest of the
code can depend on a stable interface.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional


@dataclass
class FabricIdentity:
    """
    Placeholder for a Fabric identity (certificate + private key).
    In this stub, we only store a logical user name.
    """

    user_name: str
    msp_id: str = "Org1MSP"
    cert_path: Optional[str] = None
    key_path: Optional[str] = None


def get_default_identity() -> FabricIdentity:
    """
    Returns a default logical identity for development and testing.
    You can later extend this to load from a wallet directory.
    """
    return FabricIdentity(user_name="aurum_admin")


__all__ = ["FabricIdentity", "get_default_identity"]
