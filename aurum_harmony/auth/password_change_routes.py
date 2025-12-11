"""
Password change enforcement routes for first-time admin login.
"""

from flask import Blueprint, request, jsonify
from functools import wraps
import bcrypt
from datetime import datetime

from ..database.db import db
from ..database.models import User
from .jwt_service import verify_session_token

password_change_bp = Blueprint('password_change', __name__, url_prefix='/api/auth')


@password_change_bp.route('/check-password-change-required', methods=['POST', 'OPTIONS'])
def check_password_change_required():
    """Check if user must change password."""
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'Authorization required'}), 401
        
        if token.startswith('Bearer '):
            token = token[7:]
        
        # Verify token and get user
        from .auth_service import AuthService
        user = AuthService.get_user_from_token(token)
        
        if not user:
            return jsonify({'error': 'Invalid token'}), 401
        
        # Check if password change is required
        force_change = getattr(user, 'force_password_change', False)
        
        return jsonify({
            'force_password_change': bool(force_change),
            'message': 'Password change required for first login' if force_change else 'Password change not required'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@password_change_bp.route('/change-password', methods=['POST', 'OPTIONS'])
def change_password():
    """Change user password (required after first admin login)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'Authorization required'}), 401
        
        if token.startswith('Bearer '):
            token = token[7:]
        
        # Verify token and get user
        from .auth_service import AuthService
        user = AuthService.get_user_from_token(token)
        
        if not user:
            return jsonify({'error': 'Invalid token'}), 401
        
        data = request.get_json() or {}
        current_password = data.get('current_password')
        new_password = data.get('new_password')
        confirm_password = data.get('confirm_password')
        
        # Validate inputs
        if not current_password:
            return jsonify({'error': 'Current password is required'}), 400
        
        if not new_password:
            return jsonify({'error': 'New password is required'}), 400
        
        if len(new_password) < 6:
            return jsonify({'error': 'New password must be at least 6 characters'}), 400
        
        if new_password != confirm_password:
            return jsonify({'error': 'New password and confirmation do not match'}), 400
        
        if current_password == new_password:
            return jsonify({'error': 'New password must be different from current password'}), 400
        
        # Verify current password
        if not bcrypt.checkpw(current_password.encode('utf-8'), user.password_hash.encode('utf-8')):
            return jsonify({'error': 'Current password is incorrect'}), 401
        
        # Hash new password
        new_password_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        # Update password and clear force_password_change flag
        user.password_hash = new_password_hash
        user.force_password_change = False
        user.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Password changed successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@password_change_bp.route('/force-logout-all-sessions', methods=['POST', 'OPTIONS'])
def force_logout_all_sessions():
    """Force logout all sessions for a user (admin only, after password change)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'Authorization required'}), 401
        
        if token.startswith('Bearer '):
            token = token[7:]
        
        # Verify token and get user
        from .auth_service import AuthService
        user = AuthService.get_user_from_token(token)
        
        if not user:
            return jsonify({'error': 'Invalid token'}), 401
        
        # Delete all sessions for this user except current one
        from ..database.models import Session
        current_session = Session.query.filter_by(session_token=token).first()
        
        if current_session:
            Session.query.filter(
                Session.user_id == user.id,
                Session.id != current_session.id
            ).delete()
        else:
            # If current session not found, delete all sessions
            Session.query.filter_by(user_id=user.id).delete()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'All other sessions logged out successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

