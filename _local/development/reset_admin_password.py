import sqlite3
import bcrypt

# New admin password
new_password = "admin123"

# Hash the password
password_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

# Update the database
conn = sqlite3.connect('aurum_harmony.db')
cursor = conn.cursor()

cursor.execute('UPDATE users SET password_hash = ? WHERE id = 1', (password_hash,))
conn.commit()

print("Admin password reset successfully!")
print(f"Email: admin@aurumharmony.com")
print(f"Password: {new_password}")

conn.close()

