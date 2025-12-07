"""
Admin API routes for user management.
Provides endpoints for admins to view and edit user information.
"""

from flask import Blueprint, request, jsonify
from datetime import datetime, date
from functools import wraps
import json
import sys
import os

# Add project root to path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from aurum_harmony.database.db import db
from aurum_harmony.database.models import User
from aurum_harmony.auth.routes import require_auth
from aurum_harmony.admin.notifications import get_upcoming_birthdays_and_anniversaries
from aurum_harmony.admin.email_service import admin_email_service

admin_bp = Blueprint('admin', __name__, url_prefix='/api/admin')


def require_admin(f):
    """Decorator to require admin authentication."""
    @wraps(f)
    @require_auth
    def wrapper(*args, **kwargs):
        if not request.current_user.is_admin:
            return jsonify({'error': 'Admin access required'}), 403
        return f(*args, **kwargs)
    return wrapper


@admin_bp.route('/users', methods=['GET', 'OPTIONS'])
@require_admin
def list_users():
    """Get all users (admin only)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        users = User.query.order_by(User.created_at.desc()).all()
        users_data = [user.to_dict() for user in users]
        return jsonify({
            'success': True,
            'users': users_data,
            'count': len(users_data)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/users/<int:user_id>', methods=['GET', 'OPTIONS'])
@require_admin
def get_user(user_id):
    """Get a specific user by ID (admin only)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({
            'success': True,
            'user': user.to_dict()
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/users/<int:user_id>', methods=['PATCH', 'PUT', 'OPTIONS'])
@require_admin
def update_user(user_id):
    """Update user information (admin only)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.get_json() or {}
        
        # Update email (with validation)
        if 'email' in data:
            new_email = data['email'].strip()
            if new_email and '@' in new_email:
                # Check if email is already taken by another user
                existing = User.query.filter(
                    User.email == new_email,
                    User.id != user_id
                ).first()
                if existing:
                    return jsonify({'error': 'Email already in use'}), 400
                user.email = new_email
            else:
                return jsonify({'error': 'Invalid email format'}), 400
        
        # Update phone (with validation)
        if 'phone' in data:
            phone = data['phone']
            if phone is None or phone == '':
                user.phone = None
            else:
                phone = phone.strip()
                # Basic phone validation (10-15 digits)
                if phone and phone.replace('+', '').replace('-', '').replace(' ', '').isdigit():
                    # Check if phone is already taken by another user
                    existing = User.query.filter(
                        User.phone == phone,
                        User.id != user_id
                    ).first()
                    if existing:
                        return jsonify({'error': 'Phone number already in use'}), 400
                    user.phone = phone
                else:
                    return jsonify({'error': 'Invalid phone format'}), 400
        
        # Update date of birth
        if 'date_of_birth' in data:
            dob = data['date_of_birth']
            if dob is None or dob == '':
                user.date_of_birth = None
            else:
                try:
                    # Parse ISO format date string
                    if isinstance(dob, str):
                        user.date_of_birth = datetime.fromisoformat(dob.split('T')[0]).date()
                    else:
                        return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
                except (ValueError, AttributeError):
                    return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
        
        # Update anniversary
        if 'anniversary' in data:
            anniv = data['anniversary']
            if anniv is None or anniv == '':
                user.anniversary = None
            else:
                try:
                    # Parse ISO format date string
                    if isinstance(anniv, str):
                        user.anniversary = datetime.fromisoformat(anniv.split('T')[0]).date()
                    else:
                        return jsonify({'error': 'Invalid anniversary date format. Use YYYY-MM-DD'}), 400
                except (ValueError, AttributeError):
                    return jsonify({'error': 'Invalid anniversary date format. Use YYYY-MM-DD'}), 400
        
        # Update initial capital
        if 'initial_capital' in data:
            try:
                capital = float(data['initial_capital'])
                if capital < 0:
                    return jsonify({'error': 'Initial capital cannot be negative'}), 400
                user.initial_capital = capital
            except (ValueError, TypeError):
                return jsonify({'error': 'Invalid initial capital value'}), 400
        
        # Update max trades per index
        if 'max_trades_per_index' in data:
            trades = data['max_trades_per_index']
            if trades is None:
                user.max_trades_per_index = None
            elif isinstance(trades, dict):
                # Validate all values are positive integers
                for index, limit in trades.items():
                    if not isinstance(limit, int) or limit < 0:
                        return jsonify({'error': f'Invalid trade limit for {index}. Must be a non-negative integer'}), 400
                user.max_trades_per_index = json.dumps(trades)
            else:
                return jsonify({'error': 'max_trades_per_index must be a JSON object'}), 400
        
        # Update max accounts allowed
        if 'max_accounts_allowed' in data:
            try:
                max_accounts = int(data['max_accounts_allowed'])
                if max_accounts < 1:
                    return jsonify({'error': 'Max accounts allowed must be at least 1'}), 400
                user.max_accounts_allowed = max_accounts
            except (ValueError, TypeError):
                return jsonify({'error': 'Invalid max_accounts_allowed value'}), 400
        
        # Update is_admin (only other admins can change this)
        if 'is_admin' in data:
            is_admin = bool(data['is_admin'])
            user.is_admin = is_admin
        
        # Update is_active
        if 'is_active' in data:
            user.is_active = bool(data['is_active'])
        
        # Update timestamp
        user.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'User updated successfully',
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/notifications/birthdays-anniversaries', methods=['GET', 'OPTIONS'])
@require_admin
def get_birthday_anniversary_notifications():
    """
    Get monthly birthday and anniversary notifications (admin only).
    Returns all users with birthdays/anniversaries in the current month.
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        # Get month/year from query params, or use current month
        month = request.args.get('month', type=int)
        year = request.args.get('year', type=int)
        
        summary = get_upcoming_birthdays_and_anniversaries(month=month, year=year)
        
        return jsonify({
            'success': True,
            'summary': summary
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/notifications/send-monthly-report', methods=['POST', 'OPTIONS'])
@require_admin
def send_monthly_report():
    """
    Send monthly birthday and anniversary report via email to admin (admin only).
    Can be triggered manually or scheduled.
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        month = data.get('month') or request.args.get('month', type=int)
        year = data.get('year') or request.args.get('year', type=int)
        
        # Get the summary
        summary = get_upcoming_birthdays_and_anniversaries(month=month, year=year)
        
        # Send email
        email_result = admin_email_service.send_monthly_birthday_anniversary_report(
            summary=summary,
            month=month,
            year=year
        )
        
        if email_result.get('success'):
            return jsonify({
                'success': True,
                'message': 'Monthly report sent successfully',
                'email_result': email_result,
                'summary': summary
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to send email',
                'email_result': email_result,
                'summary': summary
            }), 500
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

