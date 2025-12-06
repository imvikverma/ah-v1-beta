"""
JWT token generation and validation for session management.
"""

import os
import secrets
import jwt
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

class JWTService:
    """Service for JWT token generation and validation."""
    
    def __init__(self, secret_key: Optional[str] = None, algorithm: str = 'HS256'):
        """
        Initialize JWT service.
        
        Args:
            secret_key: Secret key for signing tokens (from env or generated)
            algorithm: JWT algorithm to use
        """
        self.secret_key = secret_key or os.getenv('JWT_SECRET_KEY') or secrets.token_urlsafe(32)
        self.algorithm = algorithm
    
    def generate_token(self, user_id: int, expires_in_hours: int = 24) -> str:
        """
        Generate a JWT token for a user.
        
        Args:
            user_id: User ID
            expires_in_hours: Token expiration time in hours
            
        Returns:
            JWT token string
        """
        payload = {
            'user_id': user_id,
            'iat': datetime.utcnow(),
            'exp': datetime.utcnow() + timedelta(hours=expires_in_hours)
        }
        return jwt.encode(payload, self.secret_key, algorithm=self.algorithm)
    
    def verify_token(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Verify and decode a JWT token.
        
        Args:
            token: JWT token string
            
        Returns:
            Decoded payload dict or None if invalid
        """
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            return payload
        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None


# Global instance
_jwt_service: Optional[JWTService] = None

def get_jwt_service() -> JWTService:
    """Get or create global JWT service instance."""
    global _jwt_service
    if _jwt_service is None:
        _jwt_service = JWTService()
    return _jwt_service

def generate_session_token(user_id: int) -> str:
    """Generate a session token for a user."""
    return get_jwt_service().generate_token(user_id)

def verify_session_token(token: str) -> Optional[int]:
    """
    Verify a session token and return user ID.
    
    Returns:
        User ID if token is valid, None otherwise
    """
    payload = get_jwt_service().verify_token(token)
    if payload:
        return payload.get('user_id')
    return None

