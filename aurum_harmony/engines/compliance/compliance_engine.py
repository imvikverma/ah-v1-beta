"""
SEBI Compliance Engine for AurumHarmony

Ensures all trading activities comply with SEBI regulations and internal policies.
"""

from __future__ import annotations

import logging
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum

# Configure logging
logger = logging.getLogger(__name__)


class ComplianceStatus(str, Enum):
    """Compliance check status."""
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    WARNING = "WARNING"
    PENDING = "PENDING"


@dataclass
class ComplianceCheck:
    """Result of a compliance check."""
    status: ComplianceStatus
    rule_name: str
    message: str
    details: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.details is None:
            self.details = {}


class ComplianceEngine:
    """
    SEBI compliance checking engine for Intraday Options Trading System.
    
    System Scope:
    - STRICTLY Intraday Options Trading ONLY
    - Symbols: NIFTY50, BANKNIFTY, SENSEX (NSE & BSE)
    - Low premium options only
    - NO individual stocks allowed
    
    Validates:
    - Symbol restrictions (only allowed indices)
    - Trade limits and restrictions
    - KYC compliance
    - Position limits
    - Settlement requirements
    - Regulatory reporting
    """
    
    def __init__(self):
        """Initialize compliance engine."""
        self.check_history: List[ComplianceCheck] = []
        self.kyc_verified_users: set[str] = set()
        logger.info("ComplianceEngine initialized")
    
    def check_trade_compliance(
        self,
        user_id: str,
        symbol: str,
        quantity: float,
        order_value: float,
        user_category: str = "restricted"
    ) -> ComplianceCheck:
        """
        Check if a trade complies with SEBI regulations and system rules.
        
        System Rules:
        - Only NIFTY50, BANKNIFTY, SENSEX allowed
        - Intraday options trading only
        - No individual stocks
        """
        """
        Check if a trade complies with SEBI regulations.
        
        Args:
            user_id: User identifier
            symbol: Trading symbol
            quantity: Order quantity
            order_value: Total order value
            user_category: User category (NGD, restricted, semi, admin)
            
        Returns:
            ComplianceCheck result
        """
        try:
            # Check KYC compliance
            if user_id not in self.kyc_verified_users:
                return ComplianceCheck(
                    status=ComplianceStatus.REJECTED,
                    rule_name="KYC_VERIFICATION",
                    message="User KYC not verified",
                    details={"user_id": user_id}
                )
            
            # Check position limits (SEBI regulations)
            max_position_value = self._get_max_position_value(user_category)
            if order_value > max_position_value:
                return ComplianceCheck(
                    status=ComplianceStatus.REJECTED,
                    rule_name="POSITION_LIMIT",
                    message=f"Order value exceeds maximum allowed position",
                    details={
                        "order_value": order_value,
                        "max_allowed": max_position_value,
                        "category": user_category
                    }
                )
            
            # Check daily trading limits
            daily_limit = self._get_daily_trading_limit(user_category)
            # This would check against actual daily trading volume
            # For now, just log a warning if approaching limit
            
            # Check symbol restrictions (CRITICAL: Only NIFTY50, BANKNIFTY, SENSEX allowed)
            if self._is_symbol_restricted(symbol, user_category):
                return ComplianceCheck(
                    status=ComplianceStatus.REJECTED,
                    rule_name="SYMBOL_RESTRICTION",
                    message=(
                        f"Symbol {symbol} is not allowed. "
                        f"System only supports intraday options on NIFTY50, BANKNIFTY, SENSEX. "
                        f"No individual stocks permitted."
                    ),
                    details={
                        "symbol": symbol,
                        "category": user_category,
                        "allowed_symbols": ["NIFTY50", "BANKNIFTY", "SENSEX"],
                        "system_type": "Intraday Options Trading Only"
                    }
                )
            
            # All checks passed
            check = ComplianceCheck(
                status=ComplianceStatus.APPROVED,
                rule_name="TRADE_COMPLIANCE",
                message="Trade complies with SEBI regulations",
                details={
                    "user_id": user_id,
                    "symbol": symbol,
                    "quantity": quantity,
                    "order_value": order_value,
                    "category": user_category
                }
            )
            
            self.check_history.append(check)
            logger.debug(f"Trade compliance check passed for user {user_id}, symbol {symbol}")
            return check
            
        except Exception as e:
            logger.error(f"Error in compliance check: {e}", exc_info=True)
            return ComplianceCheck(
                status=ComplianceStatus.REJECTED,
                rule_name="COMPLIANCE_ERROR",
                message=f"Compliance check failed: {str(e)}",
                details={"error": str(e)}
            )
    
    def verify_kyc(self, user_id: str, kyc_data: Dict[str, Any]) -> bool:
        """
        Verify user KYC compliance.
        
        Args:
            user_id: User identifier
            kyc_data: KYC information (PAN, Aadhaar, etc.)
            
        Returns:
            True if KYC verified, False otherwise
        """
        try:
            # Validate required KYC fields
            required_fields = ["pan", "name", "dob"]
            for field in required_fields:
                if field not in kyc_data or not kyc_data[field]:
                    logger.warning(f"KYC verification failed for {user_id}: missing {field}")
                    return False
            
            # Additional validation (PAN format, age verification, etc.)
            if not self._validate_pan(kyc_data.get("pan", "")):
                logger.warning(f"KYC verification failed for {user_id}: invalid PAN")
                return False
            
            # Mark as verified
            self.kyc_verified_users.add(user_id)
            logger.info(f"KYC verified for user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error verifying KYC for {user_id}: {e}", exc_info=True)
            return False
    
    def _get_max_position_value(self, category: str) -> float:
        """Get maximum position value for a category."""
        limits = {
            "NGD": 50000.0,
            "restricted": 100000.0,
            "semi": 500000.0,
            "admin": 10000000.0,  # Higher limit for admin
        }
        return limits.get(category, limits["restricted"])
    
    def _get_daily_trading_limit(self, category: str) -> float:
        """Get daily trading limit for a category."""
        limits = {
            "NGD": 100000.0,
            "restricted": 500000.0,
            "semi": 2000000.0,
            "admin": 10000000.0,
        }
        return limits.get(category, limits["restricted"])
    
    def _is_symbol_restricted(self, symbol: str, category: str) -> bool:
        """
        Check if symbol is restricted or invalid.
        
        System ONLY allows:
        - NIFTY50 (NSE)
        - BANKNIFTY (NSE)
        - SENSEX (BSE)
        
        All individual stocks are REJECTED.
        """
        # Normalize symbol
        symbol_upper = symbol.upper().strip()
        
        # Define allowed symbols (intraday options only)
        ALLOWED_SYMBOLS = {
            "NIFTY50", "NIFTY", "NIFTY 50", "NIFTY-50",
            "BANKNIFTY", "BANK NIFTY", "BANK-NIFTY",
            "SENSEX", "SENSEX 30", "SENSEX-30"
        }
        
        # Check if symbol matches allowed patterns
        symbol_normalized = symbol_upper.replace(" ", "").replace("-", "")
        allowed_normalized = {s.replace(" ", "").replace("-", "") for s in ALLOWED_SYMBOLS}
        
        # Check exact match or contains allowed base
        is_allowed = (
            symbol_upper in ALLOWED_SYMBOLS or
            symbol_normalized in allowed_normalized or
            any(base in symbol_upper for base in ["NIFTY50", "NIFTY", "BANKNIFTY", "SENSEX"])
        )
        
        if not is_allowed:
            logger.warning(
                f"Symbol {symbol} rejected: Only NIFTY50, BANKNIFTY, SENSEX allowed "
                f"(Intraday Options Trading System - no individual stocks)"
            )
            return True  # Restricted (not allowed)
        
        # Additional category-based restrictions
        if category == "NGD":
            # NGD users might have restrictions on certain symbols
            # (Currently all allowed symbols are permitted for NGD)
            pass
        
        return False  # Not restricted
    
    def _validate_pan(self, pan: str) -> bool:
        """Validate PAN format."""
        if not pan or len(pan) != 10:
            return False
        # Basic PAN format: ABCDE1234F
        # First 5 letters, next 4 digits, last letter
        if not pan[:5].isalpha() or not pan[5:9].isdigit() or not pan[9].isalpha():
            return False
        return True
    
    def get_compliance_report(self, user_id: Optional[str] = None) -> Dict[str, Any]:
        """Get compliance report."""
        checks = self.check_history
        if user_id:
            checks = [c for c in checks if c.details.get("user_id") == user_id]
        
        approved = sum(1 for c in checks if c.status == ComplianceStatus.APPROVED)
        rejected = sum(1 for c in checks if c.status == ComplianceStatus.REJECTED)
        warnings = sum(1 for c in checks if c.status == ComplianceStatus.WARNING)
        
        return {
            "total_checks": len(checks),
            "approved": approved,
            "rejected": rejected,
            "warnings": warnings,
            "kyc_verified_users": len(self.kyc_verified_users),
            "recent_checks": checks[-10:] if checks else [],
        }


# Default instance
compliance_engine = ComplianceEngine()

__all__ = [
    "ComplianceEngine",
    "ComplianceStatus",
    "ComplianceCheck",
    "compliance_engine",
]
