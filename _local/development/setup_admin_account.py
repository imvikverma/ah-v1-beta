import sqlite3
import bcrypt
from datetime import datetime

# Connect to database
conn = sqlite3.connect('aurum_harmony.db')
cursor = conn.cursor()

print("=" * 70)
print("ADMIN ACCOUNT SETUP")
print("=" * 70)

# 1. Check current users
print("\n[1] Current users in database:")
cursor.execute('SELECT id, email, username, user_code, is_admin FROM users')
users = cursor.fetchall()
for user in users:
    admin_status = "ADMIN" if user[4] else "USER"
    print(f"   ID: {user[0]} | {user[1]} | {user[2] or '(no username)'} | {user[3]} | {admin_status}")

# 2. Add force_password_change column if not exists
print("\n[2] Adding force_password_change column...")
try:
    cursor.execute("ALTER TABLE users ADD COLUMN force_password_change BOOLEAN DEFAULT 0")
    conn.commit()
    print("   [OK] Column added successfully")
except sqlite3.OperationalError as e:
    if "duplicate column name" in str(e):
        print("   [OK] Column already exists")
    else:
        raise

# 3. Create new elevated admin account
print("\n[3] Creating elevated admin account...")

# Temporary password - user will be forced to change on first login
temp_password = "AurumAdmin@2025"
password_hash = bcrypt.hashpw(temp_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

new_admin_email = "vikram@saffronbolt.in"  # User's actual email
new_admin_username = "Vikram"

# Check if already exists
cursor.execute('SELECT id FROM users WHERE email = ?', (new_admin_email,))
existing = cursor.fetchone()

if existing:
    # Update existing account to admin with force password change
    cursor.execute('''
        UPDATE users 
        SET is_admin = 1, 
            force_password_change = 1,
            username = ?,
            updated_at = ?
        WHERE email = ?
    ''', (new_admin_username, datetime.utcnow(), new_admin_email))
    print(f"   [OK] Updated existing account: {new_admin_email}")
    admin_id = existing[0]
else:
    # Create new admin account
    cursor.execute('''
        INSERT INTO users (
            email, phone, password_hash, user_code, 
            is_admin, is_active, username,
            force_password_change, terms_accepted, terms_accepted_at,
            initial_capital, max_accounts_allowed,
            created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        new_admin_email,
        None,  # Phone
        password_hash,
        'A001',  # Admin user code
        1,  # is_admin = True
        1,  # is_active = True
        new_admin_username,
        1,  # force_password_change = True
        1,  # terms_accepted
        datetime.utcnow(),
        50000.0,  # Higher initial capital for admin
        5,  # Max accounts
        datetime.utcnow(),
        datetime.utcnow()
    ))
    admin_id = cursor.lastrowid
    print(f"   [OK] Created new admin account: {new_admin_email}")

conn.commit()

# 4. Delete testing accounts (keep only testuser2/U003)
print("\n[4] Cleaning up test accounts...")

# Get list of users to delete (everyone except new admin and testuser2)
cursor.execute('''
    SELECT id, email, user_code 
    FROM users 
    WHERE id != ? 
    AND user_code != 'U003'
''', (admin_id,))

users_to_delete = cursor.fetchall()

if users_to_delete:
    for user in users_to_delete:
        print(f"   Deleting: {user[1]} ({user[2]})")
        
        # Delete related sessions
        cursor.execute('DELETE FROM sessions WHERE user_id = ?', (user[0],))
        
        # Delete related broker credentials
        cursor.execute('DELETE FROM broker_credentials WHERE user_id = ?', (user[0],))
        
        # Delete user
        cursor.execute('DELETE FROM users WHERE id = ?', (user[0],))
    
    conn.commit()
    print(f"   [OK] Deleted {len(users_to_delete)} test account(s)")
else:
    print("   [OK] No test accounts to delete")

# 5. Final user list
print("\n[5] Final user list:")
cursor.execute('SELECT id, email, username, user_code, is_admin, force_password_change FROM users')
users = cursor.fetchall()
for user in users:
    admin_status = "ADMIN" if user[4] else "USER"
    force_change = "[!] MUST CHANGE PASSWORD" if user[5] else ""
    print(f"   ID: {user[0]} | {user[1]} | {user[2] or '(no username)'} | {user[3]} | {admin_status} {force_change}")

conn.close()

print("\n" + "=" * 70)
print("ADMIN ACCOUNT SETUP COMPLETE!")
print("=" * 70)
print(f"\nAdmin Email: {new_admin_email}")
print(f"Temporary Password: {temp_password}")
print(f"[!] You will be forced to change password on first login")
print("\nNext steps:")
print("   1. Login with temporary password")
print("   2. System will prompt for new password")
print("   3. Set your permanent secure password")
print("=" * 70)

