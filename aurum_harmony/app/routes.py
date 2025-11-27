# Placeholder for AurumHarmony API routes 

from flask import Blueprint, request, jsonify
from .models import User

admin_bp = Blueprint('admin', __name__)

# In-memory user store (replace with Fabric integration)
users = {}

def get_user(user_code):
    return users.get(user_code)

@admin_bp.route('/admin/users', methods=['GET'])
def list_users():
    return jsonify([user.to_dict() for user in users.values()])

@admin_bp.route('/admin/user/<user_code>', methods=['GET'])
def get_user_info(user_code):
    user = get_user(user_code)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    return jsonify(user.to_dict())

@admin_bp.route('/admin/user/<user_code>', methods=['POST'])
def edit_user(user_code):
    user = get_user(user_code)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    data = request.json
    # Update fields if not locked
    if not user.initial_capital_locked and 'initial_capital' in data:
        user.initial_capital = data['initial_capital']
    if not user.trade_limit_locked and 'trade_limit' in data:
        user.trade_limit = data['trade_limit']
    if not user.accounts_locked and 'accounts' in data:
        user.accounts = data['accounts']
    return jsonify(user.to_dict())

@admin_bp.route('/admin/user/<user_code>/lock', methods=['POST'])
def lock_fields(user_code):
    user = get_user(user_code)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    data = request.json
    if 'initial_capital_locked' in data:
        user.initial_capital_locked = data['initial_capital_locked']
    if 'trade_limit_locked' in data:
        user.trade_limit_locked = data['trade_limit_locked']
    if 'accounts_locked' in data:
        user.accounts_locked = data['accounts_locked']
    return jsonify(user.to_dict())

@admin_bp.route('/admin/user/<user_code>/accounts', methods=['POST'])
def modify_accounts(user_code):
    user = get_user(user_code)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    data = request.json
    action = data.get('action')
    account_id = data.get('account_id')
    if action == 'add' and account_id:
        user.accounts.append(account_id)
    elif action == 'remove' and account_id and account_id in user.accounts:
        user.accounts.remove(account_id)
    return jsonify(user.to_dict())

# Example: Add a test admin user (remove in production)
users['U001'] = User('U001', {'name': 'Admin', 'pan': 'ABCDE1234F'}, 100000, 50, ['ACC001'], is_admin=True) 