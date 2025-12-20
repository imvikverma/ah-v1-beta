# D1 Database Setup Guide

## Overview

Cloudflare D1 is a serverless SQLite database that works with Cloudflare Workers. This guide will help you set up D1 for the AurumHarmony API Worker.

## Quick Setup

### Option 1: Automated Setup (Recommended)

```powershell
.\start-all.ps1 → Option 7: Setup D1 Database
```

This will:
1. ✅ Create D1 database in Cloudflare
2. ✅ Update `wrangler.toml` with database ID
3. ✅ Migrate schema (users, sessions, broker_credentials)
4. ✅ Optionally sync data from your existing SQLite database

### Option 2: Manual Setup

```powershell
# 1. Create database
cd worker
npx wrangler d1 create aurum-harmony-db

# 2. Copy the database_id from output and update wrangler.toml
# database_id = "your-database-id-here"

# 3. Migrate schema
npx wrangler d1 execute aurum-harmony-db --file=schema.sql

# 4. (Optional) Sync data from SQLite
cd ..
.\scripts\sync_sqlite_to_d1.ps1
```

## Database Schema

The D1 database includes:

### Tables

1. **users** - User accounts and profiles
   - id, email, phone, password_hash
   - user_code, is_admin, is_active
   - date_of_birth, anniversary
   - initial_capital, max_trades_per_index, max_accounts_allowed
   - created_at, updated_at

2. **sessions** - User session tokens
   - id, user_id, session_token
   - expires_at, created_at, last_accessed

3. **broker_credentials** - Encrypted broker API credentials
   - id, user_id, broker_name
   - api_key, api_secret, token_id
   - access_token, refresh_token
   - is_active, expires_at, last_validated
   - created_at, updated_at

## Data Migration

### Sync from SQLite to D1

If you have existing data in your SQLite database (`aurum_harmony.db`):

```powershell
.\scripts\sync_sqlite_to_d1.ps1
```

This will:
- Export all users, sessions, and broker credentials
- Generate SQL insert statements
- Import to D1 database

**Note:** The script uses `INSERT OR IGNORE` to avoid duplicates.

## Environment Variables

After setting up D1, you need to set the JWT secret:

```powershell
cd worker
npx wrangler secret put JWT_SECRET
# Enter your secret (use: openssl rand -hex 32)
```

Or set it via Cloudflare Dashboard:
1. Go to Workers & Pages → aurum-api
2. Settings → Variables
3. Add `JWT_SECRET` secret

## Verify Setup

### Test Database Connection

```powershell
cd worker
npx wrangler d1 execute aurum-harmony-db --command="SELECT COUNT(*) as user_count FROM users;"
```

### Test Worker

After deploying the worker:

```powershell
# Test health endpoint
curl https://api.ah.saffronbolt.in/health

# Test login (should work now!)
curl -X POST https://api.ah.saffronbolt.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"your@email.com","password":"yourpassword"}'
```

## Troubleshooting

### Database Not Found

If you get "Database not configured" error:

1. Check `wrangler.toml` has the correct `database_id`
2. Verify database exists: `npx wrangler d1 list`
3. Redeploy worker: `.\start-all.ps1 → Option 6`

### Schema Migration Failed

If schema migration fails:

1. Check `worker/schema.sql` exists
2. Run manually: `npx wrangler d1 execute aurum-harmony-db --file=schema.sql`
3. Check for SQL syntax errors

### Data Sync Issues

If data sync fails:

1. Verify SQLite database exists: `Test-Path aurum_harmony.db`
2. Check Python is installed: `python --version`
3. Review generated SQL: `worker/data_migration.sql`
4. Run import manually: `npx wrangler d1 execute aurum-harmony-db --file=worker/data_migration.sql`

## Production Checklist

- [ ] D1 database created
- [ ] `wrangler.toml` updated with `database_id`
- [ ] Schema migrated
- [ ] Data synced (if needed)
- [ ] `JWT_SECRET` set as secret
- [ ] Worker deployed
- [ ] Login endpoint tested
- [ ] Health endpoint verified

## Next Steps

After D1 is set up:

1. **Deploy Worker**: `.\start-all.ps1 → Option 6`
2. **Test Login**: Try logging in from Flutter app
3. **Monitor**: Check Cloudflare Dashboard for errors

## Notes

- D1 is SQLite-compatible, so your existing SQLite queries work
- D1 has some limitations (no foreign key constraints, limited transactions)
- For production, consider using D1's backup/restore features
- D1 is free for up to 5GB storage and 5M reads/day

---

**Last Updated**: 2025-12-09
**Status**: ✅ Ready to use

