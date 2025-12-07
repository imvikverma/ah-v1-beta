# Migrate data from SQLite to Cloudflare D1
# This script copies user data from aurum_harmony.db to D1

$ErrorActionPreference = "Continue"
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "=== Migrating Data to D1 Database ===" -ForegroundColor Cyan
Write-Host ""

# Check if SQLite database exists
$sqliteDb = Join-Path $projectRoot "aurum_harmony.db"
if (-not (Test-Path $sqliteDb)) {
    Write-Host "⚠️  SQLite database not found: $sqliteDb" -ForegroundColor Yellow
    Write-Host "   Skipping migration (database will be empty)" -ForegroundColor Gray
    exit 0
}

Write-Host "Found SQLite database: $sqliteDb" -ForegroundColor Green
Write-Host ""

# Check if Python is available
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python not found"
    }
    Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python not found!" -ForegroundColor Red
    Write-Host "   This script requires Python to read SQLite database" -ForegroundColor Yellow
    exit 1
}

# Create migration script
$migrationScript = @"
import sqlite3
import json
import subprocess
import sys
import os

db_path = r"$sqliteDb"
project_root = r"$projectRoot"

# Connect to SQLite
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get all users
cursor.execute("SELECT * FROM users")
users = cursor.fetchall()

# Get column names
column_names = [description[0] for description in cursor.description]

print(f"Found {len(users)} users to migrate")

# Convert to dictionaries
users_data = []
for user in users:
    user_dict = dict(zip(column_names, user))
    users_data.append(user_dict)

# Generate SQL insert statements
if users_data:
    print("\\nMigrating users to D1...")
    
    for user in users_data:
        # Prepare values
        email = user.get('email', '')
        phone = user.get('phone') or None
        password_hash = user.get('password_hash', '')
        user_code = user.get('user_code', '')
        is_admin = 1 if user.get('is_admin') else 0
        is_active = 1 if user.get('is_active', True) else 0
        date_of_birth = user.get('date_of_birth')
        anniversary = user.get('anniversary')
        initial_capital = user.get('initial_capital', 10000.0)
        max_trades_per_index = user.get('max_trades_per_index')
        max_accounts_allowed = user.get('max_accounts_allowed', 1)
        created_at = user.get('created_at', '')
        updated_at = user.get('updated_at', '')
        
        # Convert dates to ISO strings if they're date objects
        if date_of_birth and hasattr(date_of_birth, 'isoformat'):
            date_of_birth = date_of_birth.isoformat()
        if anniversary and hasattr(anniversary, 'isoformat'):
            anniversary = anniversary.isoformat()
        if created_at and hasattr(created_at, 'isoformat'):
            created_at = created_at.isoformat()
        if updated_at and hasattr(updated_at, 'isoformat'):
            updated_at = updated_at.isoformat()
        
        # Build SQL
        sql = f\"\"\"
        INSERT INTO users (email, phone, password_hash, user_code, is_admin, is_active, 
                          date_of_birth, anniversary, initial_capital, max_trades_per_index, 
                          max_accounts_allowed, created_at, updated_at)
        VALUES ('{email.replace("'", "''")}', 
                {'NULL' if phone is None else f"'{phone.replace(\"'\", \"''\")}'"}, 
                '{password_hash.replace("'", "''")}', 
                '{user_code.replace("'", "''")}', 
                {is_admin}, 
                {is_active}, 
                {'NULL' if date_of_birth is None else f"'{date_of_birth}'"}, 
                {'NULL' if anniversary is None else f"'{anniversary}'"}, 
                {initial_capital}, 
                {'NULL' if max_trades_per_index is None else f"'{max_trades_per_index.replace(\"'\", \"''\")}'"}, 
                {max_accounts_allowed}, 
                '{created_at}', 
                '{updated_at}')
        ON CONFLICT(email) DO NOTHING;
        \"\"\"
        
        # Write to temp file
        temp_sql = os.path.join(project_root, 'worker', 'temp_migration.sql')
        with open(temp_sql, 'w', encoding='utf-8') as f:
            f.write(sql)
        
        # Execute with wrangler
        result = subprocess.run(
            ['wrangler', 'd1', 'execute', 'aurum-harmony-db', '--file', temp_sql],
            capture_output=True,
            text=True,
            cwd=os.path.join(project_root, 'worker')
        )
        
        if result.returncode == 0:
            print(f"  ✅ Migrated user: {email}")
        else:
            print(f"  ⚠️  Error migrating {email}: {result.stderr}")
        
        # Clean up
        if os.path.exists(temp_sql):
            os.remove(temp_sql)

print("\\n✅ Migration complete!")
conn.close()
"@

$tempScript = Join-Path $projectRoot "temp_migrate.py"
Set-Content -Path $tempScript -Value $migrationScript

Write-Host "Running migration script..." -ForegroundColor Yellow
python $tempScript

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Migration completed successfully" -ForegroundColor Green
} else {
    Write-Host "⚠️  Migration had some issues (check output above)" -ForegroundColor Yellow
}

# Clean up
Remove-Item $tempScript -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Migration Complete ===" -ForegroundColor Green
Write-Host ""
