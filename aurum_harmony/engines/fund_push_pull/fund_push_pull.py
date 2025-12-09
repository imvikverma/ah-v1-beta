"""
Dynamic Fund Push/Pull Engine for AurumHarmony

Manages fund allocation, capital increments, and fund transfers
based on user performance and category progression.
"""

from __future__ import annotations

import logging
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from decimal import Decimal
from datetime import datetime

# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class FundTransfer:
    """
    Represents a fund transfer operation.
    
    Transfer Types:
    - PUSH: Demat → Savings (withdraw from trading account)
    - PULL: Savings → Demat (deposit to trading account)
    """
    user_id: str
    amount: float
    transfer_type: str  # "PUSH" (Demat→Savings) or "PULL" (Savings→Demat)
    reason: str
    status: str = "PENDING"  # PENDING, COMPLETED, FAILED
    timestamp: float = 0.0
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.timestamp == 0.0:
            import time
            self.timestamp = time.time()
        if self.metadata is None:
            self.metadata = {}


class FundPushPullEngine:
    """
    Dynamic fund management engine.
    
    Transfer Directions:
    - PUSH: Demat → Savings (withdraw from trading account, move to savings)
    - PULL: Savings → Demat (deposit to trading account, move from savings)
    
    Typical Schedule:
    - 09:15: PULL (Savings → Demat) - Fund trading account for the day
    - 15:25: PUSH (Demat → Savings) - Move profits back to savings
    
    Handles:
    - Capital increments based on performance
    - Fund transfers (push/pull)
    - Balance management (demat account balances)
    - Settlement fund allocation
    """
    
    def __init__(self):
        """Initialize fund engine."""
        self.transfer_history: List[FundTransfer] = []
        self.user_balances: Dict[str, Decimal] = {}
        logger.info("FundPushPullEngine initialized")
    
    def push_funds(
        self,
        user_id: str,
        amount: float,
        reason: str = "Withdrawal to savings",
        destination: str = "savings"
    ) -> FundTransfer:
        """
        Push funds FROM Demat TO Savings (withdraw from trading account).
        
        Direction: Demat → Savings
        Effect: Decreases demat balance, moves funds to savings account
        
        Args:
            user_id: User identifier
            amount: Amount to push (withdraw from demat)
            reason: Reason for fund push
            destination: Destination account (savings, bank, etc.)
            
        Returns:
            FundTransfer object
        """
        if amount <= 0:
            raise ValueError(f"Push amount must be positive, got: {amount}")
        
        try:
            # Get current demat balance
            current_balance = self.user_balances.get(user_id, Decimal("0"))
            
            # Check sufficient balance
            if current_balance < Decimal(str(amount)):
                transfer = FundTransfer(
                    user_id=user_id,
                    amount=amount,
                    transfer_type="PUSH",
                    reason=reason,
                    status="FAILED",
                    metadata={
                        "error": "Insufficient balance",
                        "available": float(current_balance),
                        "requested": amount,
                        "destination": destination
                    }
                )
                self.transfer_history.append(transfer)
                logger.warning(
                    f"Insufficient balance for push: user {user_id}, "
                    f"requested ₹{amount:,.2f}, available ₹{float(current_balance):,.2f}"
                )
                return transfer
            
            # Deduct funds from demat (push to savings)
            new_balance = current_balance - Decimal(str(amount))
            self.user_balances[user_id] = new_balance
            
            # Create transfer record
            transfer = FundTransfer(
                user_id=user_id,
                amount=amount,
                transfer_type="PUSH",
                reason=reason,
                status="COMPLETED",
                metadata={
                    "destination": destination,
                    "previous_balance": float(current_balance),
                    "direction": "Demat → Savings"
                }
            )
            
            self.transfer_history.append(transfer)
            
            logger.info(
                f"Funds pushed (Demat → Savings) for user {user_id}: ₹{amount:,.2f} "
                f"(Demat Balance: ₹{float(current_balance):,.2f} -> ₹{float(new_balance):,.2f})"
            )
            
            return transfer
            
        except Exception as e:
            logger.error(f"Error pushing funds from {user_id}: {e}", exc_info=True)
            transfer = FundTransfer(
                user_id=user_id,
                amount=amount,
                transfer_type="PUSH",
                reason=reason,
                status="FAILED",
                metadata={"error": str(e), "destination": destination}
            )
            self.transfer_history.append(transfer)
            return transfer
    
    def pull_funds(
        self,
        user_id: str,
        amount: float,
        reason: str = "Deposit to trading account",
        source: str = "savings"
    ) -> FundTransfer:
        """
        Pull funds FROM Savings TO Demat (deposit to trading account).
        
        Direction: Savings → Demat
        Effect: Increases demat balance, moves funds from savings account
        
        Args:
            user_id: User identifier
            amount: Amount to pull (deposit to demat)
            reason: Reason for fund pull
            source: Source account (savings, bank, etc.)
            
        Returns:
            FundTransfer object
        """
        if amount <= 0:
            raise ValueError(f"Pull amount must be positive, got: {amount}")
        
        try:
            # Get current demat balance
            current_balance = self.user_balances.get(user_id, Decimal("0"))
            
            # Add funds to demat (pull from savings)
            # Note: In production, this would check savings balance first
            new_balance = current_balance + Decimal(str(amount))
            self.user_balances[user_id] = new_balance
            
            # Create transfer record
            transfer = FundTransfer(
                user_id=user_id,
                amount=amount,
                transfer_type="PULL",
                reason=reason,
                status="COMPLETED",
                metadata={
                    "source": source,
                    "previous_balance": float(current_balance),
                    "direction": "Savings → Demat"
                }
            )
            
            self.transfer_history.append(transfer)
            
            logger.info(
                f"Funds pulled (Savings → Demat) for user {user_id}: ₹{amount:,.2f} "
                f"(Demat Balance: ₹{float(current_balance):,.2f} -> ₹{float(new_balance):,.2f})"
            )
            
            return transfer
            
        except Exception as e:
            logger.error(f"Error pulling funds to {user_id}: {e}", exc_info=True)
            transfer = FundTransfer(
                user_id=user_id,
                amount=amount,
                transfer_type="PULL",
                reason=reason,
                status="FAILED",
                metadata={"error": str(e), "source": source}
            )
            self.transfer_history.append(transfer)
            return transfer
    
    def increment_capital(
        self,
        user_id: str,
        current_capital: float,
        next_capital: float,
        category: str
    ) -> Optional[FundTransfer]:
        """
        Increment user capital to next level.
        
        Args:
            user_id: User identifier
            current_capital: Current capital level
            next_capital: Next capital level
            category: User category
            
        Returns:
            FundTransfer if increment occurred, None otherwise
        """
        if next_capital <= current_capital:
            logger.debug(f"No capital increment needed for {user_id}: {next_capital} <= {current_capital}")
            return None
        
        increment_amount = next_capital - current_capital
        
        # Capital increment: Pull funds from savings to demat
        return self.pull_funds(
            user_id=user_id,
            amount=increment_amount,
            reason=f"Capital increment: {category} level progression",
            source="increment"
        )
    
    def get_balance(self, user_id: str) -> float:
        """Get current balance for a user."""
        balance = self.user_balances.get(user_id, Decimal("0"))
        return float(balance)
    
    def get_transfer_history(self, user_id: Optional[str] = None) -> List[FundTransfer]:
        """Get transfer history."""
        if user_id:
            return [t for t in self.transfer_history if t.user_id == user_id]
        return self.transfer_history.copy()
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get fund engine statistics."""
        total_balance = sum(float(b) for b in self.user_balances.values())
        push_count = sum(1 for t in self.transfer_history if t.transfer_type == "PUSH")
        pull_count = sum(1 for t in self.transfer_history if t.transfer_type == "PULL")
        total_pushed = sum(t.amount for t in self.transfer_history if t.transfer_type == "PUSH" and t.status == "COMPLETED")
        total_pulled = sum(t.amount for t in self.transfer_history if t.transfer_type == "PULL" and t.status == "COMPLETED")
        
        return {
            "total_users": len(self.user_balances),
            "total_balance": total_balance,
            "total_pushed": total_pushed,
            "total_pulled": total_pulled,
            "push_count": push_count,
            "pull_count": pull_count,
            "net_flow": total_pushed - total_pulled,
        }


# Default instance
fund_engine = FundPushPullEngine()

__all__ = [
    "FundPushPullEngine",
    "FundTransfer",
    "fund_engine",
]
