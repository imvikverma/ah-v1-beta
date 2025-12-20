import sqlite3

conn = sqlite3.connect('aurum_harmony.db')
cursor = conn.cursor()

cursor.execute('SELECT id, email, username, is_admin FROM users')
users = cursor.fetchall()

print('USERS IN DATABASE:')
print('-' * 70)
print(f"{'ID':<5} | {'Email':<30} | {'Username':<15} | {'Admin':<5}")
print('-' * 70)

for u in users:
    admin_status = 'YES' if u[3] else 'NO'
    username = u[2] if u[2] else '(none)'
    print(f"{u[0]:<5} | {u[1]:<30} | {username:<15} | {admin_status:<5}")

print('-' * 70)
print(f"\nTotal users: {len(users)}")
print(f"Admin users: {sum(1 for u in users if u[3])}")

conn.close()

