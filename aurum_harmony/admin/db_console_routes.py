"""
Database Console API for Beta Testing.
SHOWS ALL USER DATA INCLUDING SENSITIVE FIELDS.
WARNING: Disable this endpoint in production!
"""

from flask import Blueprint, request, jsonify
from functools import wraps
import sys
import os

# Add project root to path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from aurum_harmony.database.db import db
from aurum_harmony.database.models import User, BrokerCredential, Session
from aurum_harmony.auth.routes import require_auth
from sqlalchemy import inspect

db_console_bp = Blueprint('db_console', __name__, url_prefix='/api/admin/console')

# BETA TESTING FLAG - SET TO FALSE IN PRODUCTION
BETA_MODE_SHOW_SENSITIVE = True  # ← CHANGE TO FALSE FOR PRODUCTION


def require_admin_console(f):
    """Decorator to require admin authentication for console access."""
    @wraps(f)
    @require_auth
    def wrapper(*args, **kwargs):
        if not request.current_user.is_admin:
            return jsonify({'error': 'Admin access required'}), 403
        
        # Check if beta mode is enabled
        if not BETA_MODE_SHOW_SENSITIVE:
            return jsonify({
                'error': 'Console access disabled in production mode',
                'hint': 'Set BETA_MODE_SHOW_SENSITIVE=True in db_console_routes.py'
            }), 403
        
        return f(*args, **kwargs)
    return wrapper


@db_console_bp.route('/users/all', methods=['GET', 'OPTIONS'])
@require_admin_console
def get_all_users_with_sensitive():
    """
    Get ALL users with ALL fields including sensitive data.
    BETA TESTING ONLY - Shows passwords, API keys, etc.
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        show_sensitive = request.args.get('show_sensitive', 'true').lower() == 'true'
        
        users = User.query.order_by(User.created_at.desc()).all()
        users_data = []
        
        for user in users:
            # Get ALL user data including sensitive fields
            user_dict = user.to_dict(include_sensitive=show_sensitive)
            
            # Get broker credentials for this user
            broker_creds = BrokerCredential.query.filter_by(user_id=user.id).all()
            user_dict['broker_credentials'] = [
                cred.to_dict(include_credentials=show_sensitive) for cred in broker_creds
            ]
            
            # Get active sessions for this user
            sessions = Session.query.filter_by(user_id=user.id).all()
            user_dict['sessions'] = []
            for session in sessions:
                session_dict = {
                    'id': session.id,
                    'expires_at': session.expires_at.isoformat() if session.expires_at else None,
                    'created_at': session.created_at.isoformat() if session.created_at else None,
                    'last_accessed': session.last_accessed.isoformat() if session.last_accessed else None,
                }
                if show_sensitive:
                    session_dict['session_token'] = session.session_token
                user_dict['sessions'].append(session_dict)
            
            users_data.append(user_dict)
        
        return jsonify({
            'success': True,
            'beta_mode': BETA_MODE_SHOW_SENSITIVE,
            'show_sensitive': show_sensitive,
            'count': len(users_data),
            'users': users_data,
            'warning': '⚠️  SENSITIVE DATA INCLUDED - BETA TESTING ONLY' if show_sensitive else None
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@db_console_bp.route('/users/<int:user_id>/full', methods=['GET', 'OPTIONS'])
@require_admin_console
def get_user_full_details(user_id):
    """
    Get complete user details including ALL sensitive data.
    BETA TESTING ONLY.
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        show_sensitive = request.args.get('show_sensitive', 'true').lower() == 'true'
        
        # Get user data with all fields
        user_dict = user.to_dict(include_sensitive=show_sensitive)
        
        # Get broker credentials
        broker_creds = BrokerCredential.query.filter_by(user_id=user.id).all()
        user_dict['broker_credentials'] = [
            cred.to_dict(include_credentials=show_sensitive) for cred in broker_creds
        ]
        
        # Get sessions
        sessions = Session.query.filter_by(user_id=user.id).all()
        user_dict['sessions'] = []
        for session in sessions:
            session_dict = {
                'id': session.id,
                'expires_at': session.expires_at.isoformat() if session.expires_at else None,
                'created_at': session.created_at.isoformat() if session.created_at else None,
                'last_accessed': session.last_accessed.isoformat() if session.last_accessed else None,
            }
            if show_sensitive:
                session_dict['session_token'] = session.session_token
            user_dict['sessions'].append(session_dict)
        
        return jsonify({
            'success': True,
            'beta_mode': BETA_MODE_SHOW_SENSITIVE,
            'show_sensitive': show_sensitive,
            'user': user_dict,
            'warning': '⚠️  SENSITIVE DATA INCLUDED - BETA TESTING ONLY' if show_sensitive else None
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@db_console_bp.route('/raw-query', methods=['POST', 'OPTIONS'])
@require_admin_console
def execute_raw_query():
    """
    Execute a raw SQL SELECT query.
    BETA TESTING ONLY - Read-only queries allowed.
    WARNING: Only SELECT statements allowed for security.
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        query = data.get('query', '').strip()
        
        if not query:
            return jsonify({'error': 'Query is required'}), 400
        
        # Security: Only allow SELECT queries
        if not query.upper().startswith('SELECT'):
            return jsonify({
                'error': 'Only SELECT queries are allowed',
                'hint': 'For data modification, use the appropriate API endpoints'
            }), 400
        
        # Execute query
        result = db.session.execute(query)
        
        # Fetch results
        rows = []
        columns = result.keys()
        for row in result:
            rows.append(dict(zip(columns, row)))
        
        return jsonify({
            'success': True,
            'beta_mode': BETA_MODE_SHOW_SENSITIVE,
            'query': query,
            'columns': list(columns),
            'rows': rows,
            'count': len(rows),
            'warning': '⚠️  RAW SQL QUERY - BETA TESTING ONLY'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@db_console_bp.route('/export/csv', methods=['GET', 'OPTIONS'])
@require_admin_console
def export_users_csv():
    """
    Export all users to CSV format.
    BETA TESTING ONLY.
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        show_sensitive = request.args.get('show_sensitive', 'false').lower() == 'true'
        
        users = User.query.order_by(User.created_at.desc()).all()
        
        # Build CSV
        if show_sensitive:
            headers = ['id', 'email', 'phone', 'username', 'user_code', 'password_hash', 
                      'is_admin', 'is_active', 'date_of_birth', 'anniversary', 
                      'initial_capital', 'created_at']
        else:
            headers = ['id', 'email', 'phone', 'username', 'user_code', 
                      'is_admin', 'is_active', 'date_of_birth', 'anniversary', 
                      'initial_capital', 'created_at']
        
        csv_lines = [','.join(headers)]
        
        for user in users:
            user_dict = user.to_dict(include_sensitive=show_sensitive)
            row = [str(user_dict.get(h, '')) for h in headers]
            csv_lines.append(','.join(row))
        
        csv_content = '\n'.join(csv_lines)
        
        return csv_content, 200, {
            'Content-Type': 'text/csv',
            'Content-Disposition': 'attachment; filename=users_export.csv'
        }
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@db_console_bp.route('/status', methods=['GET'])
def get_console_status():
    """Check if console is enabled and get beta mode status."""
    return jsonify({
        'beta_mode_enabled': BETA_MODE_SHOW_SENSITIVE,
        'console_access': 'enabled' if BETA_MODE_SHOW_SENSITIVE else 'disabled',
        'warning': '⚠️  This endpoint shows sensitive data in beta mode',
        'production_note': 'Set BETA_MODE_SHOW_SENSITIVE=False before production deployment'
    }), 200

