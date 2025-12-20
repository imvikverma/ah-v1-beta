import sqlite3
import json
from datetime import datetime

db_path = r"D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\aurum_harmony.db"
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

print("Exporting users...")
users = []
cursor.execute("SELECT * FROM users")
for row in cursor.fetchall():
    user = dict(row)
    user['is_admin'] = 1 if user.get('is_admin') else 0
    user['is_active'] = 1 if user.get('is_active') else 0
    users.append(user)
print(f"Found {len(users)} users")

print("Exporting sessions...")
sessions = []
cursor.execute("SELECT * FROM sessions")
for row in cursor.fetchall():
    sessions.append(dict(row))
print(f"Found {len(sessions)} sessions")

print("Exporting broker credentials...")
credentials = []
cursor.execute("SELECT * FROM broker_credentials")
for row in cursor.fetchall():
    cred = dict(row)
    cred['is_active'] = 1 if cred.get('is_active') else 0
    credentials.append(cred)
print(f"Found {len(credentials)} credentials")

conn.close()

# Generate SQL
sql_statements = []

for user in users:
    cols = ', '.join([f'{k}' for k in user.keys()])
    values = ', '.join([f"'{str(v).replace("'", "''")}'" if v is not None else 'NULL' for v in user.values()])
    sql_statements.append(f"INSERT OR IGNORE INTO users ({cols}) VALUES ({values});")

for session in sessions:
    cols = ', '.join([f'{k}' for k in session.keys()])
    values = ', '.join([f"'{str(v).replace("'", "''")}'" if v is not None else 'NULL' for v in session.values()])
    sql_statements.append(f"INSERT OR IGNORE INTO sessions ({cols}) VALUES ({values});")

for cred in credentials:
    cols = ', '.join([f'{k}' for k in cred.keys()])
    values = ', '.join([f"'{str(v).replace("'", "''")}'" if v is not None else 'NULL' for v in cred.values()])
    sql_statements.append(f"INSERT OR IGNORE INTO broker_credentials ({cols}) VALUES ({values});")

output_file = r"D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest\worker\data_migration.sql"
with open(output_file, 'w', encoding='utf-8') as f:
    f.write('-- Data migration from SQLite to D1\n')
    f.write('-- Generated: ' + datetime.now().isoformat() + '\n\n')
    f.write('\n'.join(sql_statements))

print(f"\n✅ Export complete: {output_file}")
print(f"Total statements: {len(sql_statements)}")
