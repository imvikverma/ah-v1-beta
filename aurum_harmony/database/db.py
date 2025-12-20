"""
Database initialization and configuration.
"""

import os
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import create_engine
from sqlalchemy.pool import StaticPool

db = SQLAlchemy()

def init_db(app):
    """
    Initialize database connection for Flask app.
    
    Uses SQLite for development, can be configured for PostgreSQL in production.
    """
    # Get database URL from environment or use default SQLite
    database_url = os.getenv('DATABASE_URL')
    
    if not database_url:
        # Default to SQLite in project root
        db_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            'aurum_harmony.db'
        )
        database_url = f'sqlite:///{db_path}'
    
    app.config['SQLALCHEMY_DATABASE_URI'] = database_url
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # SQLite-specific configuration
    if database_url.startswith('sqlite'):
        app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
            'poolclass': StaticPool,
            'connect_args': {
                'check_same_thread': False,
                'timeout': 20.0  # 20 second timeout for database operations
            },
            'pool_pre_ping': True,  # Verify connections before using
            'pool_recycle': 3600  # Recycle connections after 1 hour
        }
    
    db.init_app(app)
    
    # Create tables
    with app.app_context():
        db.create_all()
    
    return db

