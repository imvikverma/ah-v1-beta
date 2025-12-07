"""
Database migration script for AurumHarmony.
Migrates existing data to new schema if needed.
"""

import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from flask import Flask
from aurum_harmony.database.db import db, init_db
from aurum_harmony.database.models import User, BrokerCredential, Session
from aurum_harmony.database.utils.password import PasswordService
from aurum_harmony.database.utils.encryption import get_encryption_service


def migrate_existing_users():
    """Migrate any existing user data to new schema."""
    print("Checking for existing users to migrate...")
    
    # Check if there are any users without proper user_code
    users_without_code = User.query.filter(
        (User.user_code == None) | (User.user_code == '')
    ).all()
    
    if users_without_code:
        print(f"Found {len(users_without_code)} users without user_code")
        for user in users_without_code:
            if not user.user_code:
                # Generate user code
                user_count = User.query.count()
                user.user_code = f"U{user_count:03d}"
                print(f"  - Assigned user_code {user.user_code} to user {user.email}")
        
        db.session.commit()
        print("✅ User codes assigned")
    else:
        print("✅ All users have user_code")


def migrate_broker_credentials():
    """Migrate any existing broker credentials."""
    print("Checking for existing broker credentials...")
    
    # Check for credentials that might need encryption updates
    all_creds = BrokerCredential.query.all()
    
    if all_creds:
        print(f"Found {len(all_creds)} broker credentials")
        encryption_service = get_encryption_service()
        
        for cred in all_creds:
            # Verify encryption is working
            try:
                # Try to decrypt (if already encrypted, this will work)
                # If not encrypted, we need to encrypt it
                if cred.api_key and not cred.api_key.startswith('gAAAAAB'):  # Fernet encrypted strings start with this
                    # Re-encrypt with current encryption service
                    encrypted_key = encryption_service.encrypt(cred.api_key)
                    cred.api_key = encrypted_key
                    print(f"  - Re-encrypted credentials for {cred.broker_name}")
                
                if cred.api_secret and not cred.api_secret.startswith('gAAAAAB'):
                    encrypted_secret = encryption_service.encrypt(cred.api_secret)
                    cred.api_secret = encrypted_secret
                    
            except Exception as e:
                print(f"  ⚠️  Warning: Could not process credentials for {cred.broker_name}: {e}")
        
        db.session.commit()
        print("✅ Broker credentials migrated")
    else:
        print("✅ No existing broker credentials to migrate")


def create_default_admin():
    """Create a default admin user if none exists."""
    print("Checking for admin user...")
    
    admin = User.query.filter_by(is_admin=True).first()
    
    if not admin:
        print("Creating default admin user...")
        admin_email = os.getenv('ADMIN_EMAIL', 'admin@aurumharmony.com')
        admin_password = os.getenv('ADMIN_PASSWORD', 'admin123')
        
        # Check if user already exists
        existing = User.query.filter_by(email=admin_email).first()
        if existing:
            existing.is_admin = True
            print(f"  - Promoted existing user {admin_email} to admin")
        else:
            password_hash = PasswordService.hash_password(admin_password)
            admin = User(
                email=admin_email,
                password_hash=password_hash,
                user_code='U001',
                is_admin=True,
                is_active=True
            )
            db.session.add(admin)
            print(f"  - Created admin user: {admin_email}")
        
        db.session.commit()
        print("✅ Admin user ready")
    else:
        print(f"✅ Admin user exists: {admin.email}")


def cleanup_expired_sessions():
    """Remove expired sessions from database."""
    print("Cleaning up expired sessions...")
    
    from datetime import datetime
    expired_sessions = Session.query.filter(
        Session.expires_at < datetime.utcnow()
    ).all()
    
    if expired_sessions:
        count = len(expired_sessions)
        for session in expired_sessions:
            db.session.delete(session)
        db.session.commit()
        print(f"  - Removed {count} expired sessions")
    else:
        print("✅ No expired sessions to clean")


def migrate_user_fields():
    """Add new user fields if they don't exist."""
    print("Checking for new user fields...")
    
    from sqlalchemy import inspect, Column, Float, Date, Text, Integer
    from sqlalchemy.schema import CreateColumn
    
    inspector = inspect(db.engine)
    columns = [col['name'] for col in inspector.get_columns('users')]
    
    new_fields_added = False
    
    # Check and add date_of_birth
    if 'date_of_birth' not in columns:
        print("  - Adding date_of_birth column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN date_of_birth DATE'))
            db.session.commit()
            new_fields_added = True
            print("    ✅ date_of_birth added")
        except Exception as e:
            db.session.rollback()
            print(f"    ⚠️  Could not add date_of_birth: {e}")
    
    # Check and add anniversary
    if 'anniversary' not in columns:
        print("  - Adding anniversary column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN anniversary DATE'))
            db.session.commit()
            new_fields_added = True
            print("    ✅ anniversary added")
        except Exception as e:
            db.session.rollback()
            print(f"    ⚠️  Could not add anniversary: {e}")
    
    # Check and add initial_capital
    if 'initial_capital' not in columns:
        print("  - Adding initial_capital column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN initial_capital FLOAT DEFAULT 10000.0 NOT NULL'))
            db.session.commit()
            # Update existing users with default value
            db.session.execute(db.text('UPDATE users SET initial_capital = 10000.0 WHERE initial_capital IS NULL'))
            db.session.commit()
            new_fields_added = True
            print("    ✅ initial_capital added")
        except Exception as e:
            db.session.rollback()
            print(f"    ⚠️  Could not add initial_capital: {e}")
    
    # Check and add max_trades_per_index
    if 'max_trades_per_index' not in columns:
        print("  - Adding max_trades_per_index column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN max_trades_per_index TEXT'))
            db.session.commit()
            new_fields_added = True
            print("    ✅ max_trades_per_index added")
        except Exception as e:
            db.session.rollback()
            print(f"    ⚠️  Could not add max_trades_per_index: {e}")
    
    # Check and add max_accounts_allowed
    if 'max_accounts_allowed' not in columns:
        print("  - Adding max_accounts_allowed column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN max_accounts_allowed INTEGER DEFAULT 1 NOT NULL'))
            db.session.commit()
            # Update existing users with default value
            db.session.execute(db.text('UPDATE users SET max_accounts_allowed = 1 WHERE max_accounts_allowed IS NULL'))
            db.session.commit()
            new_fields_added = True
            print("    ✅ max_accounts_allowed added")
        except Exception as e:
            db.session.rollback()
            print(f"    ⚠️  Could not add max_accounts_allowed: {e}")
    
    if new_fields_added:
        print("✅ New user fields migrated")
    else:
        print("✅ All user fields already exist")


def main():
    """Run all migrations."""
    print("=" * 60)
    print("AurumHarmony Database Migration")
    print("=" * 60)
    print()
    
    try:
        # Create Flask app for database context
        app = Flask(__name__)
        init_db(app)
        print("✅ Database initialized")
        print()
        
        # Use app context for all database operations
        with app.app_context():
        
            # Run migrations in order: schema changes first, then data migrations
            migrate_user_fields()  # Add new columns first
            print()
            
            migrate_existing_users()  # Then migrate existing data
            print()
            
            migrate_broker_credentials()
            print()
            
            create_default_admin()
            print()
            
            cleanup_expired_sessions()
            print()
        
        print("=" * 60)
        print("✅ Migration completed successfully!")
        print("=" * 60)
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

