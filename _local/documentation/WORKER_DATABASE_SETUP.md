# Cloudflare Worker Database Setup - Complete Guide

## Overview

This guide will help you set up Cloudflare D1 database for the Worker, enabling full authentication and user management.

## Prerequisites

1. **Wrangler CLI installed**
   ```powershell
   npm install -g wrangler
   ```

2. **Cloudflare account** with Workers enabled

3. **Authenticated with Wrangler**
   ```powershell
   wrangler login
   ```

## Step-by-Step Setup

### Step 1: Create D1 Database

Run the setup script:
```powershell
.\scripts\setup_d1_database.ps1
```

This will:
- ✅ Create D1 database named `aurum-harmony-db`
- ✅ Update `wrangler.toml` with database ID
- ✅ Create database schema (tables, indexes)
- ✅ Generate JWT secret

**Manual alternative:**
```powershell
cd worker
wrangler d1 create aurum-harmony-db
# Copy the database_id from output
# Update wrangler.toml: database_id = "your-id-here"
wrangler d1 execute aurum-harmony-db --file=schema.sql
```

### Step 2: Set JWT Secret

The setup script will generate a JWT secret. Set it as a Worker secret:

```powershell
cd worker
wrangler secret put JWT_SECRET
# When prompted, paste the generated secret
```

**Or via Cloudflare Dashboard:**
1. Go to Workers & Pages → aurum-api
2. Settings → Variables and Secrets
3. Add secret: `JWT_SECRET` with your generated value

### Step 3: Migrate Existing Data (Optional)

If you have existing users in SQLite database:

```powershell
.\scripts\migrate_to_d1.ps1
```

This will copy all users from `aurum_harmony.db` to D1.

### Step 4: Deploy Worker

```powershell
.\scripts\deploy_worker.ps1
```

Or manually:
```powershell
cd worker
wrangler deploy
```

### Step 5: Test

```powershell
# Test health endpoint
Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/health"

# Test registration
$body = @{
    email = "test@example.com"
    password = "test123"
} | ConvertTo-Json

Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/api/auth/register" `
    -Method POST `
    -Body $body `
    -ContentType "application/json"

# Test login
$body = @{
    email = "test@example.com"
    password = "test123"
} | ConvertTo-Json

$response = Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/api/auth/login" `
    -Method POST `
    -Body $body `
    -ContentType "application/json"

$token = ($response.Content | ConvertFrom-Json).token

# Test /me endpoint
Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/api/auth/me" `
    -Headers @{Authorization = "Bearer $token"}
```

## Database Schema

The D1 database includes:

- **users** - User accounts with authentication
- **sessions** - Active user sessions
- **broker_credentials** - Encrypted broker API credentials

See `worker/schema.sql` for full schema.

## Environment Variables

Required:
- `JWT_SECRET` - Secret key for JWT token generation

Optional:
- `CLOUDFLARE_DEPLOY_HOOK` - For GitHub webhooks
- `GITHUB_WEBHOOK_SECRET` - Webhook verification
- `HDFC_CLIENT_ID` - HDFC Sky OAuth
- `HDFC_CLIENT_SECRET` - HDFC Sky OAuth
- `KOTAK_CONSUMER_KEY` - Kotak Neo

## Troubleshooting

### "Database not configured" error
- Check `wrangler.toml` has correct `database_id`
- Verify database exists: `wrangler d1 list`

### "JWT_SECRET not found" error
- Set JWT secret: `wrangler secret put JWT_SECRET`
- Or set in Cloudflare Dashboard

### Migration fails
- Check SQLite database exists: `aurum_harmony.db`
- Verify Python is installed
- Check wrangler is authenticated: `wrangler whoami`

### Authentication not working
- Verify database has users: `wrangler d1 execute aurum-harmony-db --command "SELECT COUNT(*) FROM users"`
- Check password hashing is working
- Verify JWT secret is set correctly

## API Endpoints

### POST /api/auth/register
Register a new user.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "phone": "+1234567890" // optional
}
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "user_code": "userabc123"
  }
}
```

### POST /api/auth/login
Login and get session token.

**Request:**
```json
{
  "email": "user@example.com", // or "phone": "+1234567890"
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "jwt-token-here",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "user_code": "userabc123",
    "is_admin": false
  }
}
```

### GET /api/auth/me
Get current user info.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "user_code": "userabc123",
    "is_admin": false,
    "is_active": true,
    ...
  }
}
```

### POST /api/auth/logout
Logout and invalidate session.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

## Next Steps

1. ✅ Database is set up
2. ✅ Authentication endpoints working
3. ⏭️ Migrate more endpoints (brokers, trading, admin)
4. ⏭️ Add more features as needed

## Support

If you encounter issues:
1. Check Cloudflare Dashboard → Workers & Pages → aurum-api → Logs
2. Run diagnostic: `.\scripts\diagnose_worker.ps1`
3. Check database: `wrangler d1 execute aurum-harmony-db --command "SELECT * FROM users LIMIT 5"`

---

**You're all set!** The Worker now has full database access and authentication working. 🎉
