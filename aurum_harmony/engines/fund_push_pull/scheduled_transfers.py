"""
Scheduled Fund Push/Pull for AurumHarmony

Implements scheduled fund transfers as per Implementation Guide Ver 11:
- 09:15: PULL (Savings → Demat) - Fund trading account for the day
- 15:25: PUSH (Demat → Savings) - Move profits back to savings

Integrates with Razorpay + IMPS for fund transfers.
"""

from __future__ import annotations

import logging
import threading
import time
from typing import Dict, Any, List, Optional, Callable
from datetime import datetime, time as dt_time, timedelta
from dataclasses import dataclass

from aurum_harmony.engines.fund_push_pull.fund_push_pull import (
    FundPushPullEngine,
    FundTransfer
)

# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class ScheduledTransfer:
    """Represents a scheduled fund transfer."""
    transfer_id: str
    scheduled_time: dt_time
    transfer_type: str  # "PULL" (Savings→Demat) or "PUSH" (Demat→Savings)
    user_ids: List[str]  # List of user IDs to process
    amount_per_user: Optional[float] = None  # If None, uses user's available amount
    reason: str = ""
    last_executed: Optional[datetime] = None
    execution_count: int = 0


class ScheduledFundTransferManager:
    """
    Manages scheduled fund push/pull operations.
    
    Schedule:
    - 09:15 IST: PULL (Savings → Demat) - Fund trading accounts
    - 15:25 IST: PUSH (Demat → Savings) - Move profits to savings
    """
    
    def __init__(
        self,
        fund_engine: Optional[FundPushPullEngine] = None,
        razorpay_enabled: bool = False
    ):
        """
        Initialize scheduled fund transfer manager.
        
        Args:
            fund_engine: Fund push/pull engine instance
            razorpay_enabled: Enable Razorpay integration
        """
        from aurum_harmony.engines.fund_push_pull.fund_push_pull import fund_engine as default_fund
        
        self.fund_engine = fund_engine or default_fund
        self.razorpay_enabled = razorpay_enabled
        
        # Scheduled transfers
        self.scheduled_transfers: List[ScheduledTransfer] = [
            ScheduledTransfer(
                transfer_id="morning_pull",
                scheduled_time=dt_time(9, 15),  # 09:15 IST
                transfer_type="PULL",
                user_ids=[],  # Will be populated from active users
                reason="Daily funding: Savings → Demat for trading"
            ),
            ScheduledTransfer(
                transfer_id="evening_push",
                scheduled_time=dt_time(15, 25),  # 15:25 IST
                transfer_type="PUSH",
                user_ids=[],  # Will be populated from active users
                reason="Daily settlement: Demat → Savings (profits)"
            ),
        ]
        
        self.is_running = False
        self.scheduler_thread: Optional[threading.Thread] = None
        self._lock = threading.Lock()
        
        logger.info(
            "ScheduledFundTransferManager initialized: "
            "09:15 PULL, 15:25 PUSH"
        )
    
    def start(self) -> None:
        """Start the scheduled transfer manager."""
        if self.is_running:
            logger.warning("Scheduled transfer manager is already running")
            return
        
        self.is_running = True
        self.scheduler_thread = threading.Thread(target=self._scheduler_loop, daemon=True)
        self.scheduler_thread.start()
        logger.info("Scheduled fund transfer manager started")
    
    def stop(self) -> None:
        """Stop the scheduled transfer manager."""
        self.is_running = False
        if self.scheduler_thread:
            self.scheduler_thread.join(timeout=5.0)
        logger.info("Scheduled fund transfer manager stopped")
    
    def _scheduler_loop(self) -> None:
        """Main scheduler loop running in background thread."""
        while self.is_running:
            try:
                now = datetime.now()
                current_time = now.time()
                
                # Check each scheduled transfer
                for scheduled in self.scheduled_transfers:
                    # Check if it's time to execute
                    if self._should_execute(scheduled, current_time, now):
                        self._execute_scheduled_transfer(scheduled, now)
                
                # Wait 30 seconds before checking again
                time.sleep(30)
            
            except Exception as e:
                logger.error(f"Error in scheduler loop: {e}", exc_info=True)
                time.sleep(300)  # Wait 5 minutes before retrying
    
    def _should_execute(
        self,
        scheduled: ScheduledTransfer,
        current_time: dt_time,
        now: datetime
    ) -> bool:
        """Check if scheduled transfer should execute now."""
        # Check if current time matches scheduled time (within 1 minute window)
        scheduled_minutes = scheduled.scheduled_time.hour * 60 + scheduled.scheduled_time.minute
        current_minutes = current_time.hour * 60 + current_time.minute
        
        if abs(scheduled_minutes - current_minutes) > 1:
            return False
        
        # Check if already executed today
        if scheduled.last_executed:
            if scheduled.last_executed.date() == now.date():
                return False  # Already executed today
        
        return True
    
    def _execute_scheduled_transfer(
        self,
        scheduled: ScheduledTransfer,
        execution_time: datetime
    ) -> None:
        """Execute a scheduled transfer."""
        logger.info(
            f"Executing scheduled transfer: {scheduled.transfer_id} "
            f"({scheduled.transfer_type}) at {execution_time.strftime('%H:%M:%S')}"
        )
        
        try:
            # Get active user IDs (in production, fetch from database)
            # For now, use empty list - will be populated by caller
            user_ids = scheduled.user_ids
            
            if not user_ids:
                logger.warning(f"No users to process for {scheduled.transfer_id}")
                return
            
            success_count = 0
            failure_count = 0
            
            for user_id in user_ids:
                try:
                    if scheduled.transfer_type == "PULL":
                        # PULL: Savings → Demat
                        if scheduled.amount_per_user:
                            amount = scheduled.amount_per_user
                        else:
                            # Use user's available savings (would be fetched from DB)
                            amount = 0  # Placeholder
                        
                        if amount > 0:
                            result = self.fund_engine.pull_funds(
                                user_id=user_id,
                                amount=amount,
                                reason=scheduled.reason,
                                source="savings"
                            )
                            
                            if result.status == "COMPLETED":
                                success_count += 1
                            else:
                                failure_count += 1
                    
                    elif scheduled.transfer_type == "PUSH":
                        # PUSH: Demat → Savings
                        # Get user's demat balance (would be fetched from DB)
                        demat_balance = self.fund_engine.get_balance(user_id)
                        
                        if demat_balance > 0:
                            # Push all available balance (or use configured amount)
                            amount = scheduled.amount_per_user or demat_balance
                            
                            result = self.fund_engine.push_funds(
                                user_id=user_id,
                                amount=min(amount, demat_balance),
                                reason=scheduled.reason,
                                destination="savings"
                            )
                            
                            if result.status == "COMPLETED":
                                success_count += 1
                            else:
                                failure_count += 1
                
                except Exception as e:
                    logger.error(f"Error processing user {user_id}: {e}", exc_info=True)
                    failure_count += 1
            
            # Update scheduled transfer
            with self._lock:
                scheduled.last_executed = execution_time
                scheduled.execution_count += 1
            
            logger.info(
                f"Scheduled transfer {scheduled.transfer_id} completed: "
                f"{success_count} successful, {failure_count} failed"
            )
        
        except Exception as e:
            logger.error(f"Error executing scheduled transfer: {e}", exc_info=True)
    
    def set_active_users(self, user_ids: List[str]) -> None:
        """
        Set active user IDs for scheduled transfers.
        
        Args:
            user_ids: List of active user IDs
        """
        with self._lock:
            for scheduled in self.scheduled_transfers:
                scheduled.user_ids = user_ids
        
        logger.info(f"Set {len(user_ids)} active users for scheduled transfers")
    
    def get_status(self) -> Dict[str, Any]:
        """Get scheduled transfer manager status."""
        with self._lock:
            return {
                "is_running": self.is_running,
                "razorpay_enabled": self.razorpay_enabled,
                "scheduled_transfers": [
                    {
                        "transfer_id": st.transfer_id,
                        "scheduled_time": st.scheduled_time.strftime("%H:%M"),
                        "transfer_type": st.transfer_type,
                        "user_count": len(st.user_ids),
                        "last_executed": (
                            st.last_executed.isoformat()
                            if st.last_executed else None
                        ),
                        "execution_count": st.execution_count,
                    }
                    for st in self.scheduled_transfers
                ],
            }


# Default instance
scheduled_fund_manager = ScheduledFundTransferManager()

__all__ = [
    "ScheduledFundTransferManager",
    "ScheduledTransfer",
    "scheduled_fund_manager",
]

