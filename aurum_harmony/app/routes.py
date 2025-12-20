"""
Admin API Routes for AurumHarmony

Provides admin endpoints for user management with comprehensive
error handling, validation, and logging.
"""

from flask import Blueprint, request, jsonify
from typing import Dict, Any, Optional
import logging

from .models import User

# Configure logging
logger = logging.getLogger(__name__)

admin_bp = Blueprint('admin', __name__)

# In-memory user store (replace with database/Fabric integration in production)
users: Dict[str, User] = {}


def get_user(user_code: str) -> Optional[User]:
    """Get user by code with validation."""
    if not user_code:
        return None
    return users.get(user_code.upper().strip())

@admin_bp.route('/admin/users', methods=['GET'])
def list_users():
    """List all users."""
    try:
        user_list = [user.to_dict() for user in users.values()]
        logger.info(f"Listed {len(user_list)} users")
        return jsonify(user_list), 200
    except Exception as e:
        logger.error(f"Error listing users: {e}", exc_info=True)
        return jsonify({'error': 'Internal server error'}), 500


@admin_bp.route('/admin/user/<user_code>', methods=['GET'])
def get_user_info(user_code: str):
    """Get user information."""
    try:
        user = get_user(user_code)
        if not user:
            logger.warning(f"User not found: {user_code}")
            return jsonify({'error': 'User not found'}), 404
        return jsonify(user.to_dict()), 200
    except Exception as e:
        logger.error(f"Error getting user {user_code}: {e}", exc_info=True)
        return jsonify({'error': 'Internal server error'}), 500


@admin_bp.route('/admin/user/<user_code>', methods=['POST'])
def edit_user(user_code: str):
    """Edit user information."""
    try:
        user = get_user(user_code)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.json
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Update fields if not locked
        updated_fields = []
        
        if 'initial_capital' in data:
            if user.initial_capital_locked:
                return jsonify({'error': 'Initial capital is locked'}), 403
            try:
                new_capital = float(data['initial_capital'])
                if user.update_capital(new_capital):
                    updated_fields.append('initial_capital')
            except (ValueError, TypeError) as e:
                return jsonify({'error': f'Invalid initial_capital: {e}'}), 400
        
        if 'trade_limit' in data:
            if user.trade_limit_locked:
                return jsonify({'error': 'Trade limit is locked'}), 403
            try:
                new_limit = int(data['trade_limit'])
                if new_limit < 0:
                    return jsonify({'error': 'Trade limit must be non-negative'}), 400
                user.trade_limit = new_limit
                updated_fields.append('trade_limit')
            except (ValueError, TypeError) as e:
                return jsonify({'error': f'Invalid trade_limit: {e}'}), 400
        
        if 'accounts' in data:
            if user.accounts_locked:
                return jsonify({'error': 'Accounts are locked'}), 403
            if not isinstance(data['accounts'], list):
                return jsonify({'error': 'Accounts must be a list'}), 400
            user.accounts = data['accounts']
            updated_fields.append('accounts')
        
        if 'category' in data:
            valid_categories = ["NGD", "restricted", "semi", "admin"]
            if data['category'] not in valid_categories:
                return jsonify({'error': f'Invalid category. Must be one of: {valid_categories}'}), 400
            user.category = data['category']
            updated_fields.append('category')
        
        logger.info(f"User {user_code} updated: {', '.join(updated_fields)}")
        return jsonify(user.to_dict()), 200
        
    except Exception as e:
        logger.error(f"Error editing user {user_code}: {e}", exc_info=True)
        return jsonify({'error': 'Internal server error'}), 500


@admin_bp.route('/admin/user/<user_code>/lock', methods=['POST'])
def lock_fields(user_code: str):
    """Lock/unlock user fields."""
    try:
        user = get_user(user_code)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.json
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        locked_fields = []
        
        if 'field' in data:
            field_name = data['field']
            lock = data.get('lock', True)
            
            if lock:
                if user.lock_field(field_name):
                    locked_fields.append(f"{field_name} (locked)")
            else:
                if user.unlock_field(field_name):
                    locked_fields.append(f"{field_name} (unlocked)")
        else:
            # Legacy support: direct field updates
            if 'initial_capital_locked' in data:
                user.initial_capital_locked = bool(data['initial_capital_locked'])
                locked_fields.append('initial_capital')
            if 'trade_limit_locked' in data:
                user.trade_limit_locked = bool(data['trade_limit_locked'])
                locked_fields.append('trade_limit')
            if 'accounts_locked' in data:
                user.accounts_locked = bool(data['accounts_locked'])
                locked_fields.append('accounts')
        
        logger.info(f"Fields locked/unlocked for user {user_code}: {', '.join(locked_fields)}")
        return jsonify(user.to_dict()), 200
        
    except Exception as e:
        logger.error(f"Error locking fields for user {user_code}: {e}", exc_info=True)
        return jsonify({'error': 'Internal server error'}), 500


@admin_bp.route('/admin/user/<user_code>/accounts', methods=['POST'])
def modify_accounts(user_code: str):
    """Add or remove user accounts."""
    try:
        user = get_user(user_code)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        if user.accounts_locked:
            return jsonify({'error': 'Accounts are locked'}), 403
        
        data = request.json
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        action = data.get('action')
        account_id = data.get('account_id')
        
        if not action or not account_id:
            return jsonify({'error': 'action and account_id are required'}), 400
        
        if action == 'add':
            if user.add_account(account_id):
                logger.info(f"Account {account_id} added for user {user_code}")
                return jsonify(user.to_dict()), 200
            else:
                return jsonify({'error': 'Account already exists or accounts are locked'}), 400
        elif action == 'remove':
            if user.remove_account(account_id):
                logger.info(f"Account {account_id} removed for user {user_code}")
                return jsonify(user.to_dict()), 200
            else:
                return jsonify({'error': 'Account not found or accounts are locked'}), 404
        else:
            return jsonify({'error': f'Invalid action: {action}. Must be "add" or "remove"'}), 400
            
    except Exception as e:
        logger.error(f"Error modifying accounts for user {user_code}: {e}", exc_info=True)
        return jsonify({'error': 'Internal server error'}), 500


# Initialize with a test admin user (remove in production or load from database)
try:
    test_admin = User(
        user_code='U001',
        kyc_data={'name': 'Admin User', 'pan': 'ABCDE1234F'},
        initial_capital=100000.0,
        trade_limit=50,
        accounts=['ACC001'],
        is_admin=True,
        category='admin'
    )
    users['U001'] = test_admin
    logger.info("Test admin user initialized: U001")
except Exception as e:
    logger.warning(f"Could not initialize test admin user: {e}") 