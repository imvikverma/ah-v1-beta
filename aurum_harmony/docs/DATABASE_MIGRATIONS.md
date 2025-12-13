# 🗄️ AurumHarmony Database Migrations

## Smart Migration System

AurumHarmony uses a **smart migration system** that only runs database schema updates when needed, not on every startup.

---

## 🚀 How It Works

### **First Run**
On the first startup, Flask will:
1. Initialize the database
2. Run all necessary migrations
3. Create a flag file: `_local/.db_migration_completed`
4. Start the app

**Time: ~60-90 seconds** (includes migration)

### **Subsequent Runs**
On later startups, Flask will:
1. Initialize the database
2. See the flag file exists
3. Skip migrations ✅
4. Start the app

**Time: ~10-15 seconds** ⚡ Much faster!

---

## 🛠️ Manual Migration

### When to Run Migrations Manually

Run migrations when you:
- Pull new code with database schema changes
- Add new user fields or tables
- Need to fix database issues
- Want to force a re-migration

### How to Run

**Basic migration:**
```bash
python migrate_db.py
```

**Force re-run (even if already completed):**
```bash
python migrate_db.py --force
```

**Help:**
```bash
python migrate_db.py --help
```

---

## 🔧 Advanced: Force Migration on Startup

If you need migrations to run on every startup (not recommended for development):

**Windows:**
```powershell
$env:FORCE_DB_MIGRATION="true"
python aurum_harmony\master_codebase\Master_AurumHarmony_261125.py
```

**Linux/Mac:**
```bash
FORCE_DB_MIGRATION=true python aurum_harmony/master_codebase/Master_AurumHarmony_261125.py
```

---

## 📁 Migration Files

### **Flag File**
- Location: `_local/.db_migration_completed`
- Purpose: Indicates migrations have been run
- Delete this file to force migrations on next startup

### **Migration Script**
- Location: `aurum_harmony/database/migrate.py`
- Contains: `migrate_user_fields()` function
- Updates: User table schema (adds new columns if missing)

---

## 🐛 Troubleshooting

### "Migration already completed" but database is wrong

**Solution:** Force re-run migrations
```bash
python migrate_db.py --force
```

### Startup is still slow

**Check:**
1. Is `_local/.db_migration_completed` present? (Should be after first run)
2. Are there other heavy imports? (AI models, etc.)
3. Network issues? (Database connection timeout)

### Want to reset everything

**Delete the flag file:**
```bash
# Windows
Remove-Item "_local\.db_migration_completed"

# Linux/Mac
rm _local/.db_migration_completed
```

Next startup will run migrations again.

---

## 📊 Performance Impact

| Scenario | Before | After | Improvement |
|----------|--------|-------|-------------|
| First startup | 60-90s | 60-90s | Same |
| Subsequent startups | 60-90s | 10-15s | **80% faster** ⚡ |

---

## 🎯 Best Practices

### Development
- ✅ Let migrations run automatically on first startup
- ✅ Flag file prevents slowdown on subsequent runs
- ✅ Delete flag if you pull database changes

### Production
- ✅ Run migrations manually before deployment
- ✅ Use `migrate_db.py --force` in deployment scripts
- ✅ Keep flag file in `.gitignore`

### CI/CD Pipeline
```bash
# In your deployment script
python migrate_db.py --force
python aurum_harmony/master_codebase/Master_AurumHarmony_261125.py
```

---

## 🔐 What Gets Migrated

Current migrations add these fields to the `users` table:
- `date_of_birth` (DATE)
- `address` (TEXT)
- `city` (TEXT)
- `state` (TEXT)
- `postal_code` (TEXT)
- `country` (TEXT)
- `pan_card` (TEXT)
- `aadhar_card` (TEXT)
- `initial_capital` (FLOAT)
- `max_accounts_allowed` (INTEGER)

All migrations check if fields exist before adding them (idempotent).

---

## 📝 Adding New Migrations

To add a new migration:

1. Edit `aurum_harmony/database/migrate.py`
2. Add your migration logic to `migrate_user_fields()`
3. Use idempotent checks (if column doesn't exist, add it)
4. Test with `python migrate_db.py --force`
5. Delete flag file before committing (let others run it fresh)

**Example:**
```python
def migrate_user_fields():
    inspector = inspect(db.engine)
    columns = [col['name'] for col in inspector.get_columns('users')]
    
    # Add new field
    if 'new_field' not in columns:
        print("  - Adding new_field column...")
        db.session.execute(db.text('ALTER TABLE users ADD COLUMN new_field TEXT'))
        db.session.commit()
        print("    ✅ new_field added")
```

---

**Last Updated:** December 12, 2025  
**Status:** ✅ Active (Smart migration enabled)

