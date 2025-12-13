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
    def register_user(
        email: str, 
        password: str, 
        phone: Optional[str] = None,
        username: Optional[str] = None,
        profile_picture_url: Optional[str] = None,
        terms_accepted: bool = False
    ) -> Dict[str, Any]:
        """
        Register a new user.
        
        Args:
            email: User email
            password: Plain text password
            phone: Optional phone number
            username: Optional username/display name
            profile_picture_url: Optional profile picture URL
            terms_accepted: Whether user accepted terms & conditions
            
        Returns:
            Dict with 'success', 'user', and optional 'error'
        """
        # Check if user already exists (by email, phone, or username)
        existing_user = User.query.filter(
            (User.email == email) | 
            (User.phone == phone) |
            (username and hasattr(User, 'username') and User.username == username)
        ).first()
        
        if existing_user:
            return {
                'success': False,
                'error': 'User with this email, phone, or username already exists'
            }
        
        # Generate user code
        user_code = f"U{User.query.count() + 1:03d}"
        
        # Hash password
        password_hash = PasswordService.hash_password(password)
        
        # Create user with new fields (if database columns exist)
        user_data = {
            'email': email,
            'phone': phone,
            'password_hash': password_hash,
            'user_code': user_code,
            'is_admin': False,
            'is_active': True
        }
        
        # Add optional fields if they exist in the model
        if username and hasattr(User, 'username'):
            user_data['username'] = username
        if profile_picture_url and hasattr(User, 'profile_picture_url'):
            user_data['profile_picture_url'] = profile_picture_url
        if hasattr(User, 'terms_accepted'):
            user_data['terms_accepted'] = terms_accepted
        if hasattr(User, 'terms_accepted_at') and terms_accepted:
            from datetime import datetime
            user_data['terms_accepted_at'] = datetime.utcnow()
        if hasattr(User, 'email_verified'):
            user_data['email_verified'] = False
        
        user = User(**user_data)
        
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
        
        # Create session record (7 days expiration)
        expires_at = datetime.utcnow() + timedelta(hours=168)
        session = Session(
            user_id=user.id,
            session_token=token,
            expires_at=expires_at
        )
        
        # Retry database operation up to 3 times for transient errors
        max_retries = 3
        retry_count = 0
        
        while retry_count < max_retries:
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
                
                # Log the error for debugging but don't expose internal details to client
                import logging
                import time
                import traceback
                
                # Get the actual exception type and message
                error_type = type(e).__name__
                error_str = str(e).lower()
                error_full = traceback.format_exc()
                
                logging.error(f"Database error during login (attempt {retry_count + 1}/{max_retries}): {error_type}: {str(e)}", exc_info=True)
                
                # Check if it's a database connection issue that might be transient
                # RemoteException is a PowerShell exception that can occur with SQLite
                is_transient = (
                    'operationalerror' in error_str or 
                    'database is locked' in error_str or
                    'timeout' in error_str or
                    'remoteexception' in error_str or
                    'system.management.automation.remoteexception' in error_str or
                    error_type == 'RemoteException' or
                    'sqlalchemy.exc.operationalerror' in error_full.lower()
                )
                
                if is_transient and retry_count < max_retries - 1:
                    # Wait a bit before retrying (exponential backoff)
                    # Use longer delay for RemoteException (PowerShell-related issues)
                    if 'remoteexception' in error_str or error_type == 'RemoteException':
                        delay = 0.5 * (2 ** retry_count)  # Longer delay for PowerShell issues
                    else:
                        delay = 0.1 * (2 ** retry_count)
                    time.sleep(delay)
                    retry_count += 1
                    # Recreate session object for retry
                    session = Session(
                        user_id=user.id,
                        session_token=token,
                        expires_at=expires_at
                    )
                    continue
                
                # Non-retryable error or max retries reached
                if 'operationalerror' in error_str or 'database is locked' in error_str or 'remoteexception' in error_str:
                    return {
                        'success': False,
                        'error': 'Database connection error. Please try again in a moment.'
                    }
                elif 'integrityerror' in error_str or 'unique constraint' in error_str:
                    return {
                        'success': False,
                        'error': 'Session creation failed. Please try logging in again.'
                    }
                else:
                    # For RemoteException and other unexpected errors, provide generic message
                    return {
                        'success': False,
                        'error': 'Login failed. Please try again.'
                    }
        
        # Should not reach here, but just in case
        return {
            'success': False,
            'error': 'Login failed after multiple attempts. Please try again.'
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

