"""
Authentication service for user registration, login, and session management.
"""

from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from ..database.db import db
from ..database.models import User, Session
from ..database.utils.password import PasswordService
from .jwt_service import generate_session_token, verify_session_token

class AuthService:
    """Service for user authentication and session management."""
    
    @staticmethod
    def register_user(email: str, password: str, phone: Optional[str] = None) -> Dict[str, Any]:
        """
        Register a new user.
        
        Args:
            email: User email
            password: Plain text password
            phone: Optional phone number
            
        Returns:
            Dict with 'success', 'user', and optional 'error'
        """
        # Check if user already exists
        existing_user = User.query.filter(
            (User.email == email) | (User.phone == phone)
        ).first()
        
        if existing_user:
            return {
                'success': False,
                'error': 'User with this email or phone already exists'
            }
        
        # Generate user code
        user_code = f"U{User.query.count() + 1:03d}"
        
        # Hash password
        password_hash = PasswordService.hash_password(password)
        
        # Create user
        user = User(
            email=email,
            phone=phone,
            password_hash=password_hash,
            user_code=user_code,
            is_admin=False,
            is_active=True
        )
        
        try:
            db.session.add(user)
            db.session.commit()
            
            return {
                'success': True,
                'user': user.to_dict()
            }
        except Exception as e:
            db.session.rollback()
            return {
                'success': False,
                'error': f'Registration failed: {str(e)}'
            }
    
    @staticmethod
    def login_user(email: Optional[str] = None, phone: Optional[str] = None, password: str = "") -> Dict[str, Any]:
        """
        Authenticate a user and create a session.
        
        Args:
            email: User email (or phone)
            phone: User phone (or email)
            password: Plain text password
            
        Returns:
            Dict with 'success', 'token', 'user', and optional 'error'
        """
        if not email and not phone:
            return {
                'success': False,
                'error': 'Email or phone required'
            }
        
        # Find user
        if email:
            user = User.query.filter_by(email=email).first()
        else:
            user = User.query.filter_by(phone=phone).first()
        
        if not user:
            return {
                'success': False,
                'error': 'Invalid credentials'
            }
        
        if not user.is_active:
            return {
                'success': False,
                'error': 'Account is inactive'
            }
        
        # Verify password
        if not PasswordService.verify_password(password, user.password_hash):
            return {
                'success': False,
                'error': 'Invalid credentials'
            }
        
        # Generate session token
        token = generate_session_token(user.id)
        
        # Create session record
        expires_at = datetime.utcnow() + timedelta(hours=24)
        session = Session(
            user_id=user.id,
            session_token=token,
            expires_at=expires_at
        )
        
        try:
            db.session.add(session)
            db.session.commit()
            
            return {
                'success': True,
                'token': token,
                'user': user.to_dict()
            }
        except Exception as e:
            db.session.rollback()
            return {
                'success': False,
                'error': f'Login failed: {str(e)}'
            }
    
    @staticmethod
    def get_user_from_token(token: str) -> Optional[User]:
        """
        Get user from session token.
        
        Args:
            token: JWT session token
            
        Returns:
            User object or None if invalid
        """
        user_id = verify_session_token(token)
        if not user_id:
            return None
        
        # Verify session exists in database
        session = Session.query.filter_by(
            session_token=token,
            user_id=user_id
        ).first()
        
        if not session or session.is_expired():
            return None
        
        # Update last accessed
        session.last_accessed = datetime.utcnow()
        db.session.commit()
        
        return User.query.get(user_id)
    
    @staticmethod
    def logout_user(token: str) -> bool:
        """
        Logout a user by invalidating their session.
        
        Args:
            token: Session token
            
        Returns:
            True if successful
        """
        session = Session.query.filter_by(session_token=token).first()
        if session:
            db.session.delete(session)
            db.session.commit()
            return True
        return False

