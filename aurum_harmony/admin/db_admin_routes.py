"""
Database admin API routes.
Provides endpoints for viewing and editing database records (admin only).
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
from sqlalchemy import inspect, text

admin_db_bp = Blueprint('admin_db', __name__, url_prefix='/api/admin/db')


def require_admin_db(f):
    """Decorator to require admin authentication for database admin."""
    @wraps(f)
    def wrapper(*args, **kwargs):
        # Allow OPTIONS requests without authentication (CORS preflight)
        if request.method == 'OPTIONS':
            return '', 200
        
        # For other methods, require authentication
        from aurum_harmony.auth.auth_service import AuthService
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'Authorization required'}), 401
        
        if token.startswith('Bearer '):
            token = token[7:]
        
        # Get user from token with error handling
        try:
            user = AuthService.get_user_from_token(token)
        except Exception as token_error:
            # Log error for debugging but return user-friendly message
            from flask import current_app
            try:
                current_app.logger.error(f"Error getting user from token in require_admin_db: {token_error}", exc_info=True)
            except:
                pass  # Logger might not be available
            return jsonify({'error': 'Invalid token format'}), 401
        
        if not user:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        if not user.is_admin:
            return jsonify({'error': 'Admin access required'}), 403
        
        # Store user in request context
        request.current_user = user
        return f(*args, **kwargs)
    return wrapper


@admin_db_bp.route('/tables', methods=['GET', 'OPTIONS'])
@require_admin_db
def list_tables():
    """Get list of all database tables (admin only)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        inspector = inspect(db.engine)
        tables = inspector.get_table_names()
        
        return jsonify({
            'success': True,
            'tables': tables
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_db_bp.route('/tables/<table_name>', methods=['GET', 'OPTIONS'])
@require_admin_db
def get_table_data(table_name):
    """Get all records from a specific table (admin only)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        # Security: Only allow access to known tables
        allowed_tables = ['users', 'broker_credentials', 'sessions']
        if table_name not in allowed_tables:
            return jsonify({'error': f'Table {table_name} is not accessible'}), 403
        
        # Get pagination params
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 50, type=int)
        per_page = min(per_page, 100)  # Max 100 records per page
        
        # Map table names to models
        model_map = {
            'users': User,
            'broker_credentials': BrokerCredential,
            'sessions': Session
        }
        
        model = model_map.get(table_name)
        if not model:
            return jsonify({'error': f'Table {table_name} not found'}), 404
        
        # Query with pagination
        query = model.query
        total = query.count()
        records = query.paginate(page=page, per_page=per_page, error_out=False)
        
        # Convert to dict
        records_data = []
        for record in records.items:
            if hasattr(record, 'to_dict'):
                records_data.append(record.to_dict())
            else:
                # Fallback: convert to dict manually
                records_data.append({col.name: getattr(record, col.name) for col in record.__table__.columns})
        
        return jsonify({
            'success': True,
            'table': table_name,
            'data': records_data,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': total,
                'pages': records.pages
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_db_bp.route('/tables/<table_name>/columns', methods=['GET', 'OPTIONS'])
@require_admin_db
def get_table_columns(table_name):
    """Get column information for a table (admin only)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        allowed_tables = ['users', 'broker_credentials', 'sessions']
        if table_name not in allowed_tables:
            return jsonify({'error': f'Table {table_name} is not accessible'}), 403
        
        inspector = inspect(db.engine)
        columns = inspector.get_columns(table_name)
        
        columns_info = []
        for col in columns:
            columns_info.append({
                'name': col['name'],
                'type': str(col['type']),
                'nullable': col['nullable'],
                'default': str(col['default']) if col['default'] is not None else None,
                'primary_key': col.get('primary_key', False)
            })
        
        return jsonify({
            'success': True,
            'table': table_name,
            'columns': columns_info
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_db_bp.route('/query', methods=['POST', 'OPTIONS'])
@require_admin_db
def execute_query():
    """
    Execute a safe SELECT query (admin only).
    Only SELECT queries are allowed for security.
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        data = request.get_json() or {}
        query_str = data.get('query', '').strip()
        
        if not query_str:
            return jsonify({'error': 'Query is required'}), 400
        
        # Security: Only allow SELECT queries
        query_upper = query_str.upper().strip()
        if not query_upper.startswith('SELECT'):
            return jsonify({'error': 'Only SELECT queries are allowed'}), 403
        
        # Execute query
        result = db.session.execute(text(query_str))
        
        # Get column names
        columns = result.keys()
        
        # Fetch all rows
        rows = result.fetchall()
        
        # Convert to list of dicts
        data_list = []
        for row in rows:
            data_list.append(dict(zip(columns, row)))
        
        return jsonify({
            'success': True,
            'columns': list(columns),
            'data': data_list,
            'row_count': len(data_list)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_db_bp.route('/stats', methods=['GET', 'OPTIONS'])
@require_admin_db
def get_database_stats():
    """Get database statistics (admin only)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        stats = {}
        
        # Count records in each table
        stats['users'] = User.query.count()
        stats['broker_credentials'] = BrokerCredential.query.count()
        stats['sessions'] = Session.query.count()
        
        # Get active users
        stats['active_users'] = User.query.filter_by(is_active=True).count()
        stats['admin_users'] = User.query.filter_by(is_admin=True).count()
        
        # Get database file size (for SQLite)
        if db.engine.url.drivername == 'sqlite':
            db_path = db.engine.url.database
            if os.path.exists(db_path):
                stats['database_size_bytes'] = os.path.getsize(db_path)
                stats['database_size_mb'] = round(stats['database_size_bytes'] / (1024 * 1024), 2)
        
        return jsonify({
            'success': True,
            'stats': stats
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

