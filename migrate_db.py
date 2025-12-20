#!/usr/bin/env python
"""
Database Migration Script for AurumHarmony

Run this script when you need to update the database schema:
  python migrate_db.py

To force re-run migrations:
  python migrate_db.py --force
"""

import os
import sys
from pathlib import Path

# Add project root to path
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

def run_migrations(force=False):
    """Run database migrations."""
    from flask import Flask
    from aurum_harmony.database.db import init_db
    from aurum_harmony.database.migrate import migrate_user_fields
    
    print("=" * 60)
    print("AurumHarmony Database Migration Tool")
    print("=" * 60)
    
    # Check migration flag
    migration_flag = Path(os.path.join(BASE_DIR, "_local", ".db_migration_completed"))
    
    if migration_flag.exists() and not force:
        print("\n✅ Migrations already completed!")
        print(f"   Flag file: {migration_flag}")
        print("\nTo force re-run: python migrate_db.py --force")
        return
    
    if force:
        print("\n⚠️  Force mode: Re-running migrations")
        if migration_flag.exists():
            migration_flag.unlink()
    
    # Create minimal Flask app for migration
    app = Flask(__name__)
    init_db(app)
    
    print("\n📊 Running database migrations...")
    print("-" * 60)
    
    try:
        with app.app_context():
            migrate_user_fields()
        
        # Mark as completed
        migration_flag.parent.mkdir(parents=True, exist_ok=True)
        migration_flag.touch()
        
        print("-" * 60)
        print("✅ Migrations completed successfully!")
        print(f"   Flag file created: {migration_flag}")
        
    except Exception as e:
        print("-" * 60)
        print(f"❌ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    force = "--force" in sys.argv or "-f" in sys.argv
    
    if "--help" in sys.argv or "-h" in sys.argv:
        print(__doc__)
        sys.exit(0)
    
    run_migrations(force=force)

