"""
Admin module for user management and database administration.
"""

from .routes import admin_bp
from .db_admin_routes import admin_db_bp

__all__ = ['admin_bp', 'admin_db_bp']

