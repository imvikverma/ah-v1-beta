"""
Kotak Neo Token Storage

Stores authentication tokens after first login to avoid repeated TOTP/MPIN prompts.
"""

from __future__ import annotations

import os
import json
import logging
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from pathlib import Path

logger = logging.getLogger(__name__)


class KotakTokenStorage:
    """
    Manages storage and retrieval of Kotak Neo authentication tokens.
    
    Stores tokens after first successful login to avoid repeated authentication.
    """
    
    def __init__(self, storage_path: Optional[str] = None):
        """
        Initialize token storage.
        
        Args:
            storage_path: Path to token storage file (default: .kotak_tokens.json in project root)
        """
        if storage_path:
            self.storage_path = Path(storage_path)
        else:
            # Default to project root
            project_root = Path(__file__).parent.parent.parent
            self.storage_path = project_root / ".kotak_tokens.json"
        
        self.tokens: Dict[str, Any] = {}
        self._load_tokens()
    
    def _load_tokens(self) -> None:
        """Load tokens from storage file."""
        try:
            if self.storage_path.exists():
                with open(self.storage_path, 'r') as f:
                    self.tokens = json.load(f)
                logger.debug(f"Loaded tokens from {self.storage_path}")
        except Exception as e:
            logger.warning(f"Error loading tokens: {e}")
            self.tokens = {}
    
    def _save_tokens(self) -> None:
        """Save tokens to storage file."""
        try:
            with open(self.storage_path, 'w') as f:
                json.dump(self.tokens, f, indent=2)
            logger.debug(f"Saved tokens to {self.storage_path}")
        except Exception as e:
            logger.error(f"Error saving tokens: {e}")
    
    def store_tokens(
        self,
        user_id: str,
        view_token: str,
        view_sid: str,
        trade_token: str,
        trade_sid: str,
        base_url: str,
        expires_at: Optional[datetime] = None
    ) -> None:
        """
        Store authentication tokens for a user.
        
        Args:
            user_id: User identifier
            view_token: View token from TOTP login
            view_sid: View session ID
            trade_token: Trade token from MPIN validation
            trade_sid: Trade session ID
            base_url: Base URL for API calls
            expires_at: Token expiration time (default: 24 hours from now)
        """
        if expires_at is None:
            expires_at = datetime.now() + timedelta(hours=24)
        
        self.tokens[user_id] = {
            "view_token": view_token,
            "view_sid": view_sid,
            "trade_token": trade_token,
            "trade_sid": trade_sid,
            "base_url": base_url,
            "expires_at": expires_at.isoformat(),
            "stored_at": datetime.now().isoformat()
        }
        
        self._save_tokens()
        logger.info(f"Stored tokens for user {user_id}")
    
    def get_tokens(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get stored tokens for a user.
        
        Args:
            user_id: User identifier
            
        Returns:
            Token dictionary or None if not found/expired
        """
        if user_id not in self.tokens:
            return None
        
        token_data = self.tokens[user_id]
        
        # Check expiration
        expires_at = datetime.fromisoformat(token_data["expires_at"])
        if datetime.now() >= expires_at:
            logger.info(f"Tokens expired for user {user_id}")
            self.clear_tokens(user_id)
            return None
        
        return token_data
    
    def clear_tokens(self, user_id: str) -> None:
        """Clear stored tokens for a user."""
        if user_id in self.tokens:
            del self.tokens[user_id]
            self._save_tokens()
            logger.info(f"Cleared tokens for user {user_id}")
    
    def has_valid_tokens(self, user_id: str) -> bool:
        """Check if user has valid stored tokens."""
        return self.get_tokens(user_id) is not None


# Global instance
token_storage = KotakTokenStorage()

__all__ = ["KotakTokenStorage", "token_storage"]

