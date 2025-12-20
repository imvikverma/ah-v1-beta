# Quick Start: Database Setup for Worker

## 🚀 Get Database Running in 3 Steps

### Step 1: Setup D1 Database
```powershell
.\scripts\setup_d1_database.ps1
```
This creates the database and schema automatically.

### Step 2: Set JWT Secret
```powershell
cd worker
wrangler secret put JWT_SECRET
# Paste the secret shown in Step 1 output
```

### Step 3: Deploy
```powershell
.\scripts\deploy_worker.ps1
```

## ✅ Done!

Your Worker now has:
- ✅ Database access (D1)
- ✅ User registration
- ✅ User login
- ✅ Session management
- ✅ User info endpoint

## Test It

```powershell
# Register a user
$body = @{email="test@test.com"; password="test123"} | ConvertTo-Json
Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/api/auth/register" `
    -Method POST -Body $body -ContentType "application/json"

# Login
$response = Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/api/auth/login" `
    -Method POST -Body $body -ContentType "application/json"
$token = ($response.Content | ConvertFrom-Json).token

# Get user info
Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/api/auth/me" `
    -Headers @{Authorization="Bearer $token"}
```

## Migrate Existing Users (Optional)

If you have users in SQLite:
```powershell
.\scripts\migrate_to_d1.ps1
```

## Full Documentation

See `WORKER_DATABASE_SETUP.md` for complete details.

---

**That's it!** Your Worker is now fully functional with database access. 🎉
