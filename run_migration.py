#!/usr/bin/env python
"""Quick database migration runner"""
import os
import sys
from pathlib import Path

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

def run_migrations():
    """Run database migrations."""
    from flask import Flask
    from aurum_harmony.database.db import init_db
    from aurum_harmony.database.migrate import migrate_user_fields, migrate_kyc_documents_table
    
    print("=" * 60)
    print("AurumHarmony Database Migration")
    print("=" * 60)
    
    app = Flask(__name__)
    init_db(app)
    
    print("\nRunning database migrations...")
    print("-" * 60)
    
    try:
        with app.app_context():
            migrate_user_fields()
            migrate_kyc_documents_table()
        
        print("-" * 60)
        print("[OK] Migrations completed successfully!")
        
    except Exception as e:
        print("-" * 60)
        print(f"[ERROR] Migration failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    run_migrations()

