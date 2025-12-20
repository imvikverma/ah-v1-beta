"""
Database models for AurumHarmony.

Robust data models with validation, type safety, and comprehensive error handling.
"""

from __future__ import annotations

from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field
import logging

# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class User:
    """
    Represents a user in the AurumHarmony system.
    
    Stores user code, KYC data, capital, trade limits, account info, and lock states.
    Enhanced with validation and type safety.
    """
    user_code: str
    kyc_data: Dict[str, Any]
    initial_capital: float
    trade_limit: int
    accounts: List[str] = field(default_factory=list)
    is_admin: bool = False
    initial_capital_locked: bool = False
    trade_limit_locked: bool = False
    accounts_locked: bool = False
    category: str = "restricted"  # NGD, restricted, semi, admin
    current_capital: Optional[float] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    
    def __post_init__(self):
        """Validate and initialize user data."""
        # Validate user_code
        if not self.user_code or not isinstance(self.user_code, str):
            raise ValueError(f"Invalid user_code: {self.user_code}")
        self.user_code = self.user_code.strip().upper()
        
        # Validate KYC data
        if not isinstance(self.kyc_data, dict):
            raise ValueError(f"kyc_data must be a dictionary, got: {type(self.kyc_data)}")
        
        # Validate initial_capital
        if self.initial_capital < 0:
            raise ValueError(f"initial_capital must be non-negative, got: {self.initial_capital}")
        
        # Validate trade_limit
        if self.trade_limit < 0:
            raise ValueError(f"trade_limit must be non-negative, got: {self.trade_limit}")
        
        # Validate accounts
        if not isinstance(self.accounts, list):
            raise ValueError(f"accounts must be a list, got: {type(self.accounts)}")
        
        # Validate category
        valid_categories = ["NGD", "restricted", "semi", "admin"]
        if self.category not in valid_categories:
            logger.warning(f"Invalid category '{self.category}', defaulting to 'restricted'")
            self.category = "restricted"
        
        # Set current_capital to initial_capital if not set
        if self.current_capital is None:
            self.current_capital = self.initial_capital
        
        # Validate current_capital
        if self.current_capital < 0:
            logger.warning(f"Negative current_capital: {self.current_capital}, setting to 0")
            self.current_capital = 0.0
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert user to dictionary."""
        return {
            'user_code': self.user_code,
            'kyc_data': self.kyc_data,
            'initial_capital': self.initial_capital,
            'current_capital': self.current_capital,
            'initial_capital_locked': self.initial_capital_locked,
            'trade_limit': self.trade_limit,
            'trade_limit_locked': self.trade_limit_locked,
            'accounts': self.accounts,
            'accounts_locked': self.accounts_locked,
            'is_admin': self.is_admin,
            'category': self.category,
            'created_at': self.created_at,
            'updated_at': self.updated_at,
        }
    
    def update_capital(self, new_capital: float, lock: bool = False) -> bool:
        """
        Update user capital.
        
        Args:
            new_capital: New capital amount
            lock: Whether to lock the capital
            
        Returns:
            True if updated, False if locked
        """
        if self.initial_capital_locked and lock:
            logger.warning(f"Cannot update capital for {self.user_code}: capital is locked")
            return False
        
        if new_capital < 0:
            raise ValueError(f"Capital must be non-negative, got: {new_capital}")
        
        old_capital = self.current_capital
        self.current_capital = new_capital
        if lock:
            self.initial_capital_locked = True
        
        logger.info(
            f"Capital updated for {self.user_code}: "
            f"₹{old_capital:,.2f} -> ₹{new_capital:,.2f}"
        )
        return True
    
    def add_account(self, account_id: str) -> bool:
        """Add a trading account."""
        if self.accounts_locked:
            logger.warning(f"Cannot add account for {self.user_code}: accounts are locked")
            return False
        
        if not account_id or not isinstance(account_id, str):
            raise ValueError(f"Invalid account_id: {account_id}")
        
        if account_id not in self.accounts:
            self.accounts.append(account_id)
            logger.info(f"Account {account_id} added for user {self.user_code}")
            return True
        
        return False
    
    def remove_account(self, account_id: str) -> bool:
        """Remove a trading account."""
        if self.accounts_locked:
            logger.warning(f"Cannot remove account for {self.user_code}: accounts are locked")
            return False
        
        if account_id in self.accounts:
            self.accounts.remove(account_id)
            logger.info(f"Account {account_id} removed for user {self.user_code}")
            return True
        
        return False
    
    def lock_field(self, field_name: str) -> bool:
        """
        Lock a field to prevent modifications.
        
        Args:
            field_name: Field to lock (capital, trade_limit, accounts)
            
        Returns:
            True if locked, False if invalid field
        """
        if field_name == "capital":
            self.initial_capital_locked = True
            logger.info(f"Capital locked for user {self.user_code}")
            return True
        elif field_name == "trade_limit":
            self.trade_limit_locked = True
            logger.info(f"Trade limit locked for user {self.user_code}")
            return True
        elif field_name == "accounts":
            self.accounts_locked = True
            logger.info(f"Accounts locked for user {self.user_code}")
            return True
        else:
            logger.warning(f"Unknown field to lock: {field_name}")
            return False
    
    def unlock_field(self, field_name: str) -> bool:
        """
        Unlock a field to allow modifications.
        
        Args:
            field_name: Field to unlock (capital, trade_limit, accounts)
            
        Returns:
            True if unlocked, False if invalid field
        """
        if field_name == "capital":
            self.initial_capital_locked = False
            logger.info(f"Capital unlocked for user {self.user_code}")
            return True
        elif field_name == "trade_limit":
            self.trade_limit_locked = False
            logger.info(f"Trade limit unlocked for user {self.user_code}")
            return True
        elif field_name == "accounts":
            self.accounts_locked = False
            logger.info(f"Accounts unlocked for user {self.user_code}")
            return True
        else:
            logger.warning(f"Unknown field to unlock: {field_name}")
            return False
    
    def is_field_locked(self, field_name: str) -> bool:
        """Check if a field is locked."""
        if field_name == "capital":
            return self.initial_capital_locked
        elif field_name == "trade_limit":
            return self.trade_limit_locked
        elif field_name == "accounts":
            return self.accounts_locked
        return False


__all__ = ["User"]
 