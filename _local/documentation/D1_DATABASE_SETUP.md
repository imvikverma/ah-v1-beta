# D1 Database Setup Guide

## Current Status
- Database ID is **NOT set** in `wrangler.toml`
- Need to either find existing database or create new one

## Option 1: Get Database ID from Cloudflare Dashboard (Easiest)

1. Go to: https://dash.cloudflare.com/
2. Select your account
3. Go to **Workers & Pages** → **D1**
4. Look for database named: `aurum-harmony-db`
5. Click on it to see details
6. Copy the **Database ID** (looks like: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

Then update `wrangler.toml`:
```toml
database_id = "your-database-id-here"
```

## Option 2: Create New Database (if doesn't exist)

### Prerequisites
- Node.js and npm installed
- Wrangler CLI installed globally: `npm install -g wrangler`
- Or use npx: `npx wrangler`

### Steps

1. **Install Node.js** (if not installed):
   - Download from: https://nodejs.org/
   - Install and restart terminal

2. **Create Database**:
   ```powershell
   cd worker
   npx wrangler d1 create aurum-harmony-db
   ```

3. **Copy Database ID** from output:
   ```
   database_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   ```

4. **Update wrangler.toml**:
   - Open `wrangler.toml` in project root
   - Replace `database_id = ""` with the ID from step 3

5. **Migrate Schema**:
   ```powershell
   .\scripts\migrate_d1_schema.ps1
   ```

## Option 3: Use Setup Script (Automated)

If you have npm/wrangler installed:
```powershell
.\scripts\setup_d1_database.ps1
```

This will:
- Create database (if needed)
- Extract database ID automatically
- Update wrangler.toml
- Migrate schema
- Optionally sync data from SQLite

## After Setup

Once database ID is set and schema is migrated:

1. **Deploy Worker**:
   ```powershell
   .\start-all.ps1 → Option 4 → Deploy Worker
   ```

2. **Test Login**:
   - Worker should now return 200/401 instead of 503
   - Flutter will use Worker API instead of Flask fallback

## Troubleshooting

- **npm not found**: Install Node.js from https://nodejs.org/
- **wrangler not found**: Run `npm install -g wrangler` or use `npx wrangler`
- **Database already exists**: Get ID from Cloudflare Dashboard (Option 1)
- **Permission errors**: Make sure you're logged into Cloudflare: `npx wrangler login`

