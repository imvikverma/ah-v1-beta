"""
Flask routes for authentication.
"""

from flask import Blueprint, request, jsonify, current_app
from ..database.db import db
from ..database.models import User, BrokerCredential
from ..database.utils.encryption import get_encryption_service
from .auth_service import AuthService
from .jwt_service import verify_session_token

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')

from functools import wraps

def require_auth(f):
    """Decorator to require authentication."""
    @wraps(f)
    def wrapper(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'Authorization required'}), 401
        
        # Remove 'Bearer ' prefix if present
        if token.startswith('Bearer '):
            token = token[7:]
        
        user = AuthService.get_user_from_token(token)
        if not user:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # Add user to request context
        request.current_user = user
        return f(*args, **kwargs)
    return wrapper


@auth_bp.route('/register', methods=['POST', 'OPTIONS'])
def register():
    """Register a new user."""
    if request.method == 'OPTIONS':
        return '', 200
    data = request.get_json() or {}
    
    email = data.get('email', '').strip()
    password = data.get('password', '')
    phone = data.get('phone', '').strip() or None
    username = data.get('username', '').strip() or None
    profile_picture_url = data.get('profile_picture_url') or None
    terms_accepted = data.get('terms_accepted', False)
    
    if not email:
        return jsonify({'error': 'Email is required'}), 400
    
    if not password or len(password) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400
    
    if not terms_accepted:
        return jsonify({'error': 'You must accept the Terms & Conditions'}), 400
    
    result = AuthService.register_user(
        email, password, phone, 
        username=username,
        profile_picture_url=profile_picture_url,
        terms_accepted=terms_accepted
    )
    
    if result['success']:
        return jsonify({
            'message': 'User registered successfully',
            'user': result['user']
        }), 201
    else:
        return jsonify({'error': result['error']}), 400


@auth_bp.route('/login', methods=['POST', 'OPTIONS'])
def login():
    """Login and get session token."""
    # Handle OPTIONS preflight request
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        
        email = data.get('email', '').strip()
        phone = data.get('phone', '').strip()
        password = data.get('password', '')
        
        if not password:
            return jsonify({'error': 'Password is required'}), 400
        
        if not email and not phone:
            return jsonify({'error': 'Email or phone is required'}), 400
        
        result = AuthService.login_user(email=email or None, phone=phone or None, password=password)
        
        if result['success']:
            # Check if user needs to change password
            user = result.get('user', {})
            force_password_change = user.get('force_password_change', False)
            
            return jsonify({
                'message': 'Login successful',
                'token': result['token'],
                'user': result['user'],
                'force_password_change': force_password_change
            }), 200
        else:
            return jsonify({'error': result['error']}), 401
    except Exception as e:
        # Log the full exception for debugging
        import traceback
        current_app.logger.error(f"Login error: {str(e)}\n{traceback.format_exc()}")
        return jsonify({'error': 'Internal server error during login. Please try again.'}), 500


@auth_bp.route('/logout', methods=['POST', 'OPTIONS'])
def logout():
    """Logout and invalidate session token."""
    if request.method == 'OPTIONS':
        return '', 200
    
    # Check auth for POST requests
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'error': 'Authorization required'}), 401
    
    if token.startswith('Bearer '):
        token = token[7:]
    
    if AuthService.logout_user(token):
        return jsonify({'message': 'Logout successful'}), 200
    else:
        return jsonify({'error': 'Logout failed'}), 400


@auth_bp.route('/me', methods=['GET', 'OPTIONS'])
def get_current_user():
    """Get current user information."""
    if request.method == 'OPTIONS':
        return '', 200
    
    # Check auth
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'error': 'Authorization required'}), 401
    
    if token.startswith('Bearer '):
        token = token[7:]
    
    user = AuthService.get_user_from_token(token)
    if not user:
        return jsonify({'error': 'Invalid or expired token'}), 401
    
    # Get user's broker credentials (without sensitive data)
    broker_creds = BrokerCredential.query.filter_by(
        user_id=user.id,
        is_active=True
    ).all()
    
    user_data = user.to_dict()
    user_data['brokers'] = [cred.to_dict() for cred in broker_creds]
    
    return jsonify(user_data), 200
