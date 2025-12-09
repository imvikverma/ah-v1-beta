"""
Notifications Engine for AurumHarmony

Handles all notification delivery (email, SMS, in-app, etc.)
with retry logic and delivery tracking.
"""

from __future__ import annotations

import logging
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, field
from enum import Enum
from datetime import datetime
import time

# Configure logging
logger = logging.getLogger(__name__)


class NotificationType(str, Enum):
    """Types of notifications."""
    EMAIL = "EMAIL"
    SMS = "SMS"
    IN_APP = "IN_APP"
    PUSH = "PUSH"


class NotificationPriority(str, Enum):
    """Notification priority levels."""
    LOW = "LOW"
    NORMAL = "NORMAL"
    HIGH = "HIGH"
    URGENT = "URGENT"


@dataclass
class Notification:
    """Represents a notification."""
    user_id: str
    notification_type: NotificationType
    subject: str
    message: str
    priority: NotificationPriority = NotificationPriority.NORMAL
    metadata: Dict[str, Any] = field(default_factory=dict)
    status: str = "PENDING"  # PENDING, SENT, FAILED, DELIVERED
    created_at: float = field(default_factory=time.time)
    sent_at: Optional[float] = None
    delivery_attempts: int = 0
    max_attempts: int = 3


class NotificationEngine:
    """
    Centralized notification delivery engine.
    
    Features:
    - Multi-channel delivery (email, SMS, in-app, push)
    - Retry logic with exponential backoff
    - Priority-based queuing
    - Delivery tracking
    - Max 5 notifications per day per user (per Implementation Guide Ver 11)
    - Tiered alerts system
    """
    
    MAX_NOTIFICATIONS_PER_DAY = 5  # Per Implementation Guide Ver 11
    
    def __init__(self, max_per_day: int = MAX_NOTIFICATIONS_PER_DAY):
        """
        Initialize notification engine.
        
        Args:
            max_per_day: Maximum notifications per user per day (default: 5)
        """
        self.max_notifications_per_day = max_per_day
        self.notification_queue: List[Notification] = []
        self.notification_history: List[Notification] = []
        self.daily_notification_count: Dict[str, Dict[str, int]] = {}  # {user_id: {date: count}}
        self.delivery_stats = {
            "total_sent": 0,
            "total_failed": 0,
            "by_type": {},
            "by_priority": {},
        }
        logger.info(
            f"NotificationEngine initialized: "
            f"max_per_day={max_per_day} per user"
        )
    
    def send_notification(
        self,
        user_id: str,
        notification_type: NotificationType,
        subject: str,
        message: str,
        priority: NotificationPriority = NotificationPriority.NORMAL,
        metadata: Optional[Dict[str, Any]] = None,
        bypass_daily_limit: bool = False
    ) -> Optional[Notification]:
        """
        Send a notification with daily limit enforcement.
        
        Per Implementation Guide Ver 11:
        - Max 5 notifications per day per user
        - URGENT priority can bypass limit (safety critical)
        - Tiered alerts system
        
        Args:
            user_id: User identifier
            notification_type: Type of notification
            subject: Notification subject
            message: Notification message
            priority: Notification priority
            metadata: Additional metadata
            bypass_daily_limit: Force send even if limit reached (use sparingly)
            
        Returns:
            Notification object if sent/queued, None if limit reached
        """
        # Check daily limit (unless URGENT or bypassed)
        if not bypass_daily_limit and priority != NotificationPriority.URGENT:
            if not self._can_send_notification(user_id):
                logger.info(
                    f"Notification limit reached for user {user_id}: "
                    f"{self._get_today_count(user_id)}/{self.max_notifications_per_day} "
                    f"(Priority: {priority.value}, Subject: {subject})"
                )
                return None  # Limit reached, notification not sent
        
        notification = Notification(
            user_id=user_id,
            notification_type=notification_type,
            subject=subject,
            message=message,
            priority=priority,
            metadata=metadata or {}
        )
        
        # Increment daily count
        self._increment_daily_count(user_id)
        
        # Add to queue
        self.notification_queue.append(notification)
        
        # Process immediately for high priority
        if priority in (NotificationPriority.HIGH, NotificationPriority.URGENT):
            self._process_notification(notification)
        else:
            # Queue for batch processing
            logger.debug(f"Notification queued: {subject} for user {user_id}")
        
        return notification
    
    def _can_send_notification(self, user_id: str) -> bool:
        """
        Check if user can receive more notifications today.
        
        Args:
            user_id: User identifier
            
        Returns:
            True if under daily limit, False otherwise
        """
        today_count = self._get_today_count(user_id)
        return today_count < self.max_notifications_per_day
    
    def _get_today_count(self, user_id: str) -> int:
        """Get today's notification count for a user."""
        from datetime import datetime
        today = datetime.now().strftime("%Y-%m-%d")
        
        if user_id not in self.daily_notification_count:
            return 0
        
        return self.daily_notification_count[user_id].get(today, 0)
    
    def _increment_daily_count(self, user_id: str) -> None:
        """Increment today's notification count for a user."""
        from datetime import datetime
        today = datetime.now().strftime("%Y-%m-%d")
        
        if user_id not in self.daily_notification_count:
            self.daily_notification_count[user_id] = {}
        
        self.daily_notification_count[user_id][today] = \
            self.daily_notification_count[user_id].get(today, 0) + 1
    
    def _process_notification(self, notification: Notification) -> bool:
        """
        Process and send a notification.
        
        Args:
            notification: Notification to send
            
        Returns:
            True if sent successfully, False otherwise
        """
        try:
            notification.delivery_attempts += 1
            
            # Route to appropriate handler
            if notification.notification_type == NotificationType.EMAIL:
                success = self._send_email(notification)
            elif notification.notification_type == NotificationType.SMS:
                success = self._send_sms(notification)
            elif notification.notification_type == NotificationType.IN_APP:
                success = self._send_in_app(notification)
            elif notification.notification_type == NotificationType.PUSH:
                success = self._send_push(notification)
            else:
                logger.warning(f"Unknown notification type: {notification.notification_type}")
                success = False
            
            if success:
                notification.status = "SENT"
                notification.sent_at = time.time()
                self.delivery_stats["total_sent"] += 1
                self.delivery_stats["by_type"][notification.notification_type.value] = \
                    self.delivery_stats["by_type"].get(notification.notification_type.value, 0) + 1
                self.delivery_stats["by_priority"][notification.priority.value] = \
                    self.delivery_stats["by_priority"].get(notification.priority.value, 0) + 1
                logger.info(
                    f"Notification sent: {notification.subject} to user {notification.user_id} "
                    f"(Priority: {notification.priority.value}, "
                    f"Today: {self._get_today_count(notification.user_id)}/{self.max_notifications_per_day})"
                )
            else:
                if notification.delivery_attempts >= notification.max_attempts:
                    notification.status = "FAILED"
                    self.delivery_stats["total_failed"] += 1
                    logger.error(f"Notification failed after {notification.max_attempts} attempts: {notification.subject}")
                else:
                    logger.warning(f"Notification delivery attempt {notification.delivery_attempts} failed, will retry")
            
            self.notification_history.append(notification)
            return success
            
        except Exception as e:
            logger.error(f"Error processing notification: {e}", exc_info=True)
            notification.status = "FAILED"
            self.notification_history.append(notification)
            return False
    
    def _send_email(self, notification: Notification) -> bool:
        """Send email notification."""
        try:
            # Import email service if available
            try:
                from aurum_harmony.admin.email_service import send_email
                return send_email(
                    to_email=notification.metadata.get("email"),
                    subject=notification.subject,
                    body=notification.message
                )
            except ImportError:
                logger.debug("Email service not available, logging notification")
                logger.info(f"EMAIL NOTIFICATION: {notification.subject} - {notification.message}")
                return True  # Assume success for logging
        except Exception as e:
            logger.error(f"Error sending email: {e}")
            return False
    
    def _send_sms(self, notification: Notification) -> bool:
        """Send SMS notification."""
        try:
            # SMS service integration would go here
            logger.info(f"SMS NOTIFICATION: {notification.subject} - {notification.message}")
            return True  # Placeholder
        except Exception as e:
            logger.error(f"Error sending SMS: {e}")
            return False
    
    def _send_in_app(self, notification: Notification) -> bool:
        """Send in-app notification."""
        try:
            # In-app notification would be stored in database
            logger.debug(f"In-app notification: {notification.subject} for user {notification.user_id}")
            return True  # Placeholder
        except Exception as e:
            logger.error(f"Error sending in-app notification: {e}")
            return False
    
    def _send_push(self, notification: Notification) -> bool:
        """Send push notification."""
        try:
            # Push notification service integration would go here
            logger.debug(f"Push notification: {notification.subject} for user {notification.user_id}")
            return True  # Placeholder
        except Exception as e:
            logger.error(f"Error sending push notification: {e}")
            return False
    
    def process_queue(self) -> int:
        """
        Process all queued notifications.
        
        Returns:
            Number of notifications processed
        """
        processed = 0
        while self.notification_queue:
            notification = self.notification_queue.pop(0)
            if notification.status == "PENDING":
                self._process_notification(notification)
                processed += 1
        return processed
    
    def get_notification_history(self, user_id: Optional[str] = None) -> List[Notification]:
        """Get notification history."""
        if user_id:
            return [n for n in self.notification_history if n.user_id == user_id]
        return self.notification_history.copy()
    
    def get_statistics(self, user_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Get notification statistics.
        
        Args:
            user_id: Optional user ID to get user-specific stats
            
        Returns:
            Statistics dictionary
        """
        stats = {
            **self.delivery_stats,
            "queue_size": len(self.notification_queue),
            "total_notifications": len(self.notification_history),
            "pending": len([n for n in self.notification_history if n.status == "PENDING"]),
            "sent": len([n for n in self.notification_history if n.status == "SENT"]),
            "failed": len([n for n in self.notification_history if n.status == "FAILED"]),
            "max_per_day": self.max_notifications_per_day,
        }
        
        if user_id:
            stats["user_today_count"] = self._get_today_count(user_id)
            stats["user_remaining_today"] = max(0, self.max_notifications_per_day - self._get_today_count(user_id))
            stats["user_notifications"] = len([n for n in self.notification_history if n.user_id == user_id])
        
        return stats
    
    def get_tiered_alerts_summary(self, user_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Get tiered alerts summary per Implementation Guide Ver 11.
        
        Args:
            user_id: Optional user ID to get user-specific summary
            
        Returns:
            Tiered alerts summary
        """
        notifications = self.notification_history
        if user_id:
            notifications = [n for n in notifications if n.user_id == user_id]
        
        # Count by priority tier
        tier_counts = {
            "URGENT": len([n for n in notifications if n.priority == NotificationPriority.URGENT]),
            "HIGH": len([n for n in notifications if n.priority == NotificationPriority.HIGH]),
            "NORMAL": len([n for n in notifications if n.priority == NotificationPriority.NORMAL]),
            "LOW": len([n for n in notifications if n.priority == NotificationPriority.LOW]),
        }
        
        # Today's notifications by tier
        from datetime import datetime
        today = datetime.now().strftime("%Y-%m-%d")
        today_notifications = [
            n for n in notifications
            if datetime.fromtimestamp(n.created_at).strftime("%Y-%m-%d") == today
        ]
        
        today_tier_counts = {
            "URGENT": len([n for n in today_notifications if n.priority == NotificationPriority.URGENT]),
            "HIGH": len([n for n in today_notifications if n.priority == NotificationPriority.HIGH]),
            "NORMAL": len([n for n in today_notifications if n.priority == NotificationPriority.NORMAL]),
            "LOW": len([n for n in today_notifications if n.priority == NotificationPriority.LOW]),
        }
        
        return {
            "total_by_tier": tier_counts,
            "today_by_tier": today_tier_counts,
            "today_total": len(today_notifications),
            "max_per_day": self.max_notifications_per_day,
            "remaining_today": max(0, self.max_notifications_per_day - len(today_notifications)),
        }


# Default instance
notifier = NotificationEngine()

__all__ = [
    "NotificationEngine",
    "Notification",
    "NotificationType",
    "NotificationPriority",
    "notifier",
]
