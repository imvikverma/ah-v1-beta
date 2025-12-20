"""
Database migration script for AurumHarmony.
Migrates existing data to new schema if needed.
"""

import os
import sys
from pathlib import Path

# Use built-in print directly to avoid recursion
import builtins
_original_print = builtins.print

def safe_print(*args, **kwargs):
    """Simple print wrapper for Windows console compatibility."""
    # Replace problematic Unicode characters
    safe_args = []
    for arg in args:
        if isinstance(arg, str):
            safe_arg = arg.replace('✅', '[OK]').replace('⚠️', '[WARN]').replace('🚀', '[READY]')
            safe_args.append(safe_arg)
        else:
            safe_args.append(arg)
    _original_print(*safe_args, **kwargs)

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from flask import Flask
from aurum_harmony.database.db import db, init_db
from aurum_harmony.database.models import User, BrokerCredential, Session
from aurum_harmony.database.utils.password import PasswordService
from aurum_harmony.database.utils.encryption import get_encryption_service

# Only monkey-patch print when running as main script, not when imported
# This prevents breaking Flask's stdout when imported
if __name__ == '__main__':
    import builtins
    _original_print = builtins.print
    builtins.print = safe_print


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
        print("[OK] User codes assigned")
    else:
        print("[OK] All users have user_code")


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
                print(f"  [WARN] Warning: Could not process credentials for {cred.broker_name}: {e}")
        
        db.session.commit()
        print("[OK] Broker credentials migrated")
    else:
        print("[OK] No existing broker credentials to migrate")


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
        print("[OK] Admin user ready")
    else:
        print(f"[OK] Admin user exists: {admin.email}")


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
        print("[OK] No expired sessions to clean")


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
            print("    [OK] date_of_birth added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add date_of_birth: {e}")
    
    # Check and add anniversary
    if 'anniversary' not in columns:
        print("  - Adding anniversary column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN anniversary DATE'))
            db.session.commit()
            new_fields_added = True
            print("    [OK] anniversary added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add anniversary: {e}")
    
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
            print("    [OK] initial_capital added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add initial_capital: {e}")
    
    # Check and add internal_capital (ledger capital for TierManager)
    if 'internal_capital' not in columns:
        print("  - Adding internal_capital column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN internal_capital FLOAT DEFAULT 0.0 NOT NULL'))
            db.session.commit()
            # Optionally seed from initial_capital where available
            try:
                db.session.execute(
                    db.text('UPDATE users SET internal_capital = initial_capital WHERE internal_capital = 0.0')
                )
                db.session.commit()
            except Exception as seed_error:
                db.session.rollback()
                print(f"    [WARN] Could not seed internal_capital from initial_capital: {seed_error}")
            new_fields_added = True
            print("    [OK] internal_capital added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add internal_capital: {e}")

    # Check and add max_trades_per_index
    if 'max_trades_per_index' not in columns:
        print("  - Adding max_trades_per_index column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN max_trades_per_index TEXT'))
            db.session.commit()
            new_fields_added = True
            print("    [OK] max_trades_per_index added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add max_trades_per_index: {e}")
    
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
            print("    [OK] max_accounts_allowed added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add max_accounts_allowed: {e}")
    
    # Signup improvements fields
    if 'username' not in columns:
        print("  - Adding username column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN username VARCHAR(100)'))
            db.session.commit()
            # Create index if possible
            try:
                db.session.execute(db.text('CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)'))
                db.session.commit()
            except:
                pass  # Index might already exist or not supported
            new_fields_added = True
            print("    [OK] username added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add username: {e}")
    
    if 'profile_picture_url' not in columns:
        print("  - Adding profile_picture_url column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN profile_picture_url VARCHAR(500)'))
            db.session.commit()
            new_fields_added = True
            print("    [OK] profile_picture_url added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add profile_picture_url: {e}")
    
    if 'email_verified' not in columns:
        print("  - Adding email_verified column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT 0 NOT NULL'))
            db.session.commit()
            new_fields_added = True
            print("    [OK] email_verified added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add email_verified: {e}")
    
    if 'email_verification_token' not in columns:
        print("  - Adding email_verification_token column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN email_verification_token VARCHAR(255)'))
            db.session.commit()
            new_fields_added = True
            print("    [OK] email_verification_token added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add email_verification_token: {e}")
    
    if 'terms_accepted' not in columns:
        print("  - Adding terms_accepted column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN terms_accepted BOOLEAN DEFAULT 0 NOT NULL'))
            db.session.commit()
            new_fields_added = True
            print("    [OK] terms_accepted added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add terms_accepted: {e}")
    
    if 'terms_accepted_at' not in columns:
        print("  - Adding terms_accepted_at column...")
        try:
            db.session.execute(db.text('ALTER TABLE users ADD COLUMN terms_accepted_at DATETIME'))
            db.session.commit()
            new_fields_added = True
            print("    [OK] terms_accepted_at added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add terms_accepted_at: {e}")

    # User type flags (for onboarding / admin / test flows)
    if 'user_type' not in columns:
        print("  - Adding user_type column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN user_type VARCHAR(20) DEFAULT 'new' NOT NULL"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] user_type added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add user_type: {e}")

    if 'is_test' not in columns:
        print("  - Adding is_test column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN is_test BOOLEAN DEFAULT 0 NOT NULL"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] is_test added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add is_test: {e}")

    # Savings account fields (for onboarding)
    if 'savings_account_number' not in columns:
        print("  - Adding savings_account_number column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN savings_account_number VARCHAR(50)"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] savings_account_number added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add savings_account_number: {e}")

    if 'savings_account_ifsc' not in columns:
        print("  - Adding savings_account_ifsc column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN savings_account_ifsc VARCHAR(20)"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] savings_account_ifsc added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add savings_account_ifsc: {e}")

    if 'savings_account_holder_name' not in columns:
        print("  - Adding savings_account_holder_name column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN savings_account_holder_name VARCHAR(100)"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] savings_account_holder_name added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add savings_account_holder_name: {e}")

    # KYC verification fields
    if 'is_kyc_verified' not in columns:
        print("  - Adding is_kyc_verified column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN is_kyc_verified BOOLEAN DEFAULT 0 NOT NULL"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] is_kyc_verified added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add is_kyc_verified: {e}")

    if 'kyc_verification_id' not in columns:
        print("  - Adding kyc_verification_id column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN kyc_verification_id VARCHAR(100)"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] kyc_verification_id added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add kyc_verification_id: {e}")

    if 'kyc_verified_at' not in columns:
        print("  - Adding kyc_verified_at column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN kyc_verified_at DATETIME"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] kyc_verified_at added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add kyc_verified_at: {e}")

    # UPI verification fields
    if 'upi_id' not in columns:
        print("  - Adding upi_id column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN upi_id VARCHAR(100)"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] upi_id added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add upi_id: {e}")

    if 'upi_verified' not in columns:
        print("  - Adding upi_verified column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN upi_verified BOOLEAN DEFAULT 0 NOT NULL"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] upi_verified added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add upi_verified: {e}")

    if 'upi_verified_at' not in columns:
        print("  - Adding upi_verified_at column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN upi_verified_at DATETIME"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] upi_verified_at added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add upi_verified_at: {e}")

    if 'internal_capital' not in columns:
        print("  - Adding internal_capital column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN internal_capital FLOAT DEFAULT 0.0 NOT NULL"))
            db.session.commit()
            # Seed internal_capital from initial_capital if it exists and internal_capital is null
            db.session.execute(db.text("UPDATE users SET internal_capital = initial_capital WHERE internal_capital IS NULL AND initial_capital IS NOT NULL"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] internal_capital added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add internal_capital: {e}")
    
    # Capital & Settlement tracking fields
    if 'accumulated_profit' not in columns:
        print("  - Adding accumulated_profit column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN accumulated_profit FLOAT DEFAULT 0.0 NOT NULL"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] accumulated_profit added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add accumulated_profit: {e}")
    
    if 'capital_allocation' not in columns:
        print("  - Adding capital_allocation column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN capital_allocation TEXT"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] capital_allocation added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add capital_allocation: {e}")
    
    if 'last_increment_date' not in columns:
        print("  - Adding last_increment_date column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN last_increment_date DATETIME"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] last_increment_date added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add last_increment_date: {e}")
    
    if 'brokerage_fees_tracked' not in columns:
        print("  - Adding brokerage_fees_tracked column...")
        try:
            db.session.execute(db.text("ALTER TABLE users ADD COLUMN brokerage_fees_tracked FLOAT DEFAULT 0.0 NOT NULL"))
            db.session.commit()
            new_fields_added = True
            print("    [OK] brokerage_fees_tracked added")
        except Exception as e:
            db.session.rollback()
            print(f"    [WARN] Could not add brokerage_fees_tracked: {e}")
    
    if new_fields_added:
        print("[OK] New user fields migrated")
    else:
        print("[OK] All user fields already exist")


def migrate_kyc_documents_table():
    """Create kyc_documents table if it doesn't exist."""
    from sqlalchemy import inspect
    
    print("[INFO] Checking kyc_documents table...")
    inspector = inspect(db.engine)
    tables = inspector.get_table_names()
    
    if 'kyc_documents' in tables:
        print("  [OK] kyc_documents table already exists")
        return
    
    print("  - Creating kyc_documents table...")
    try:
        # Import model to register it with SQLAlchemy
        from aurum_harmony.database.models import KYCDocument
        
        # Create table using raw SQL (more reliable than db.create_all for migrations)
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS kyc_documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            document_type VARCHAR(50) NOT NULL,
            document_number VARCHAR(100),
            document_url TEXT,
            verified BOOLEAN DEFAULT 0 NOT NULL,
            verification_date DATETIME,
            digilocker_doc_uri VARCHAR(255),
            aadhaar_last4 VARCHAR(4),
            pan_number VARCHAR(10),
            full_name VARCHAR(200),
            date_of_birth DATE,
            address TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
        """
        db.session.execute(db.text(create_table_sql))
        db.session.commit()
        
        # Create index on user_id
        try:
            db.session.execute(db.text("CREATE INDEX IF NOT EXISTS ix_kyc_documents_user_id ON kyc_documents(user_id)"))
            db.session.commit()
        except Exception as idx_error:
            db.session.rollback()
            print(f"    [WARN] Could not create index: {idx_error}")
        
        # Verify it was created
        inspector = inspect(db.engine)
        tables = inspector.get_table_names()
        if 'kyc_documents' in tables:
            print("    [OK] kyc_documents table created successfully")
        else:
            print("    [WARN] kyc_documents table creation may have failed")
    except Exception as e:
        db.session.rollback()
        print(f"    [WARN] Could not create kyc_documents table: {e}")


def migrate_profit_tracking_table():
    """Create profit_tracking table if it doesn't exist."""
    from sqlalchemy import inspect
    
    print("[INFO] Checking profit_tracking table...")
    inspector = inspect(db.engine)
    tables = inspector.get_table_names()
    
    if 'profit_tracking' in tables:
        print("  [OK] profit_tracking table already exists")
        return
    
    print("  - Creating profit_tracking table...")
    try:
        # Import model to register it with SQLAlchemy
        from aurum_harmony.database.models import ProfitTracking
        
        # Create table using raw SQL
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS profit_tracking (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            period_start DATETIME NOT NULL,
            gross_profit FLOAT NOT NULL,
            brokerage_fees FLOAT DEFAULT 0.0 NOT NULL,
            loss_buffer FLOAT DEFAULT 0.0 NOT NULL,
            platform_fee FLOAT NOT NULL,
            tax_locked FLOAT NOT NULL,
            net_to_savings FLOAT NOT NULL,
            rounding_buffer FLOAT DEFAULT 0.0 NOT NULL,
            accumulated_profit FLOAT DEFAULT 0.0 NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id)
        )
        """
        db.session.execute(db.text(create_table_sql))
        db.session.commit()
        
        # Create index on user_id
        try:
            db.session.execute(db.text("CREATE INDEX IF NOT EXISTS ix_profit_tracking_user_id ON profit_tracking(user_id)"))
            db.session.commit()
        except Exception as idx_error:
            db.session.rollback()
            print(f"    [WARN] Could not create index: {idx_error}")
        
        # Verify it was created
        inspector = inspect(db.engine)
        tables = inspector.get_table_names()
        if 'profit_tracking' in tables:
            print("    [OK] profit_tracking table created successfully")
        else:
            print("    [WARN] profit_tracking table creation may have failed")
    except Exception as e:
        db.session.rollback()
        print(f"    [WARN] Could not create profit_tracking table: {e}")


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
        print("[OK] Database initialized")
        print()
        
        # Use app context for all database operations
        with app.app_context():
        
            # Run migrations in order: schema changes first, then data migrations
            migrate_user_fields()  # Add new columns first
            print()
            
            migrate_kyc_documents_table()  # Create kyc_documents table
            migrate_profit_tracking_table()  # Create profit_tracking table
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
        print("[SUCCESS] Migration completed successfully!")
        print("=" * 60)
        
    except Exception as e:
        print(f"[ERROR] Migration failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()

