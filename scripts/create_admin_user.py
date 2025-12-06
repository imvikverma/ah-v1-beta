"""
Create a hardcoded admin user in the database.
Run this script to ensure an admin user exists with known credentials.
"""

import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from flask import Flask
from aurum_harmony.database.db import db, init_db
from aurum_harmony.database.models import User
from aurum_harmony.database.utils.password import PasswordService


def create_admin_user():
    """Create or update admin user with hardcoded credentials."""
    print("=" * 60)
    print("Creating Admin User")
    print("=" * 60)
    print()
    
    # Hardcoded admin credentials
    ADMIN_EMAIL = "admin@aurumharmony.com"
    ADMIN_PASSWORD = "Admin@123"  # Hardcoded password
    ADMIN_PHONE = "+919876543210"  # Optional phone number
    
    try:
        # Create Flask app for database context
        app = Flask(__name__)
        init_db(app)
        print("✓ Database initialized")
        print()
        
        # Use app context for all database operations
        with app.app_context():
            # Check if admin user already exists
            admin = User.query.filter_by(email=ADMIN_EMAIL).first()
            
            if admin:
                print(f"Admin user already exists: {ADMIN_EMAIL}")
                print("Updating password and ensuring admin privileges...")
                
                # Update password
                admin.password_hash = PasswordService.hash_password(ADMIN_PASSWORD)
                admin.is_admin = True
                admin.is_active = True
                if ADMIN_PHONE:
                    admin.phone = ADMIN_PHONE
                
                db.session.commit()
                print(f"✓ Admin user updated")
                print(f"  Email: {ADMIN_EMAIL}")
                print(f"  Password: {ADMIN_PASSWORD}")
                print(f"  User Code: {admin.user_code}")
                print(f"  Is Admin: {admin.is_admin}")
            else:
                print("Creating new admin user...")
                
                # Create admin user
                password_hash = PasswordService.hash_password(ADMIN_PASSWORD)
                admin = User(
                    email=ADMIN_EMAIL,
                    phone=ADMIN_PHONE,
                    password_hash=password_hash,
                    user_code="U001",
                    is_admin=True,
                    is_active=True
                )
                
                db.session.add(admin)
                db.session.commit()
                
                print(f"✓ Admin user created successfully!")
                print(f"  Email: {ADMIN_EMAIL}")
                print(f"  Password: {ADMIN_PASSWORD}")
                print(f"  User Code: {admin.user_code}")
                print(f"  Phone: {ADMIN_PHONE}")
                print(f"  Is Admin: {admin.is_admin}")
        
        print()
        print("=" * 60)
        print("✓ Admin user ready!")
        print("=" * 60)
        print()
        print("You can now login with:")
        print(f"  Email: {ADMIN_EMAIL}")
        print(f"  Password: {ADMIN_PASSWORD}")
        print()
        
    except Exception as e:
        print(f"❌ Error creating admin user: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    create_admin_user()

