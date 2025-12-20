"""
Add dummy broker credentials for testing.
"""

import sys
import os
from datetime import datetime

# Add project root to path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from aurum_harmony.database.db import db, init_db
from aurum_harmony.database.models import User, BrokerCredential
from aurum_harmony.database.utils.encryption import get_encryption_service
from flask import Flask

# Configure output encoding
sys.stdout.reconfigure(encoding='utf-8')

# Create Flask app context
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///aurum_harmony.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
init_db(app)

print("=" * 70)
print("ADDING DUMMY BROKER CREDENTIALS FOR TESTING")
print("=" * 70)

# Run within app context
with app.app_context():
    # Get encryption service
    encryption = get_encryption_service()
    
    # Get users
    users = User.query.all()
    print(f"\n[1] Found {len(users)} users in database:")
    for user in users:
        print(f"   {user.id} | {user.email} | {user.user_code}")

    # Check existing credentials
    existing = BrokerCredential.query.all()
    print(f"\n[2] Current broker credentials: {len(existing)}")
    if existing:
        for cred in existing:
            user = User.query.get(cred.user_id)
            print(f"   User {cred.user_id} ({user.email if user else 'Unknown'}) | {cred.broker_name} | Active: {cred.is_active}")
    else:
        print("   (none yet)")

    # Add dummy credentials for admin user (vikram@saffronbolt.in)
    admin = User.query.filter_by(email='vikram@saffronbolt.in').first()
    if admin:
        print(f"\n[3] Adding dummy brokers for admin ({admin.email})...")
        
        # Kotak Neo dummy credentials
        kotak_existing = BrokerCredential.query.filter_by(
            user_id=admin.id,
            broker_name='kotak_neo'
        ).first()
        
        if not kotak_existing:
            kotak_cred = BrokerCredential(
                user_id=admin.id,
                broker_name='kotak_neo',
                api_key=encryption.encrypt('DEMO_KOTAK_API_KEY_12345'),
                api_secret=encryption.encrypt('DEMO_KOTAK_SECRET_67890'),
                access_token=encryption.encrypt('demo_kotak_access_token_xyz'),
                expires_at=datetime(2025, 12, 31, 23, 59, 59),
                is_active=True,
                last_validated=datetime.utcnow(),
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.session.add(kotak_cred)
            print("   [OK] Added Kotak Neo credentials")
        else:
            print("   [INFO] Kotak Neo already exists")
        
        # HDFC Sky dummy credentials
        hdfc_existing = BrokerCredential.query.filter_by(
            user_id=admin.id,
            broker_name='hdfc_sky'
        ).first()
        
        if not hdfc_existing:
            hdfc_cred = BrokerCredential(
                user_id=admin.id,
                broker_name='hdfc_sky',
                api_key=encryption.encrypt('DEMO_HDFC_CLIENT_ID_ABCD'),
                api_secret=encryption.encrypt('DEMO_HDFC_SECRET_EFGH'),
                access_token=encryption.encrypt('demo_hdfc_access_token_123'),
                expires_at=datetime(2025, 12, 31, 23, 59, 59),
                is_active=True,
                last_validated=datetime.utcnow(),
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.session.add(hdfc_cred)
            print("   [OK] Added HDFC Sky credentials")
        else:
            print("   [INFO] HDFC Sky already exists")
        
        db.session.commit()
        print("\n[OK] Admin broker credentials saved!")
    else:
        print("\n[ERROR] Admin user not found!")

    # Add for test user too
    testuser = User.query.filter_by(email='testuser2@example.com').first()
    if testuser:
        print(f"\n[4] Adding dummy broker for test user ({testuser.email})...")
        
        test_kotak = BrokerCredential.query.filter_by(
            user_id=testuser.id,
            broker_name='kotak_neo'
        ).first()
        
        if not test_kotak:
            test_cred = BrokerCredential(
                user_id=testuser.id,
                broker_name='kotak_neo',
                api_key=encryption.encrypt('TEST_KOTAK_KEY_999'),
                api_secret=encryption.encrypt('TEST_KOTAK_SECRET_888'),
                access_token=encryption.encrypt('test_access_token_abc'),
                expires_at=datetime(2025, 12, 31, 23, 59, 59),
                is_active=True,
                last_validated=datetime.utcnow(),
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.session.add(test_cred)
            print("   [OK] Added Kotak Neo for test user")
            db.session.commit()
        else:
            print("   [INFO] Test user already has Kotak Neo")

    # Final count
    final_count = BrokerCredential.query.count()
    print(f"\n[5] Final broker credentials count: {final_count}")
    all_creds = BrokerCredential.query.all()
    for cred in all_creds:
        user = User.query.get(cred.user_id)
        print(f"   User: {user.email if user else 'Unknown'} | Broker: {cred.broker_name} | Active: {cred.is_active}")

    print("\n" + "=" * 70)
    print("DONE! Refresh admin panel Database tab to see broker credentials.")
    print("=" * 70)
