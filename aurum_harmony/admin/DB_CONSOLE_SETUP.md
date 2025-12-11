# Database Console Setup Guide

**⚠️ BETA TESTING ONLY - Shows ALL user data including passwords & API keys**

---

## 🚀 Quick Setup

### 1. Register the Blueprint

**File:** `aurum_harmony/master_codebase/Master_AurumHarmony_261125.py`

**Add this import** (around line 36):
```python
from aurum_harmony.admin import admin_bp, admin_db_bp
from aurum_harmony.admin.db_console_routes import db_console_bp  # ← ADD THIS
```

**Register the blueprint** (around line 65-70, where other blueprints are registered):
```python
app.register_blueprint(auth_bp)
app.register_blueprint(brokers_bp)
app.register_blueprint(kotak_bp)
app.register_blueprint(hdfc_bp)
app.register_blueprint(paper_bp)
app.register_blueprint(admin_bp)
app.register_blueprint(admin_db_bp)
app.register_blueprint(db_console_bp)  # ← ADD THIS
```

### 2. Restart Flask Backend

```powershell
# Stop current backend
Stop-Process -Name python -Force

# Start backend again
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
.\scripts\start_backend_silent.ps1
```

### 3. Test the Console

```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
.\_local\development\test_db_console.ps1
```

---

## 📡 API Endpoints

### Base URL: `/api/admin/console`

All endpoints require admin authentication.

---

### 1. **Get Console Status**

```http
GET /api/admin/console/status
```

**Response:**
```json
{
  "beta_mode_enabled": true,
  "console_access": "enabled",
  "warning": "⚠️  This endpoint shows sensitive data in beta mode"
}
```

---

### 2. **Get All Users (Safe Mode)**

```http
GET /api/admin/console/users/all?show_sensitive=false
Authorization: Bearer {admin_token}
```

**Shows:**
- ✅ Email, phone, username
- ✅ User code, admin status
- ✅ Date of birth, anniversary
- ✅ Initial capital, trade limits
- ❌ Password hashes (hidden)
- ❌ API keys (hidden)
- ❌ Session tokens (hidden)

---

### 3. **Get All Users (Beta Mode - ALL DATA)**

```http
GET /api/admin/console/users/all?show_sensitive=true
Authorization: Bearer {admin_token}
```

**Shows EVERYTHING:**
- ✅ All safe data above
- ⚠️  **Password hashes**
- ⚠️  **Broker API keys** (encrypted)
- ⚠️  **Session tokens**
- ⚠️  **All database fields**

**Response:**
```json
{
  "success": true,
  "beta_mode": true,
  "show_sensitive": true,
  "count": 3,
  "users": [
    {
      "id": 1,
      "email": "admin@aurumharmony.com",
      "password_hash": "$2b$12$abc123...",     // ← SHOWN IN BETA MODE
      "user_code": "U001",
      "initial_capital": 10000.0,
      "broker_credentials": [
        {
          "broker_name": "KOTAK_NEO",
          "api_key": "encrypted_key...",        // ← SHOWN IN BETA MODE
          "api_secret": "encrypted_secret..."   // ← SHOWN IN BETA MODE
        }
      ],
      "sessions": [
        {
          "session_token": "eyJhbGc..."        // ← SHOWN IN BETA MODE
        }
      ]
    }
  ],
  "warning": "⚠️  SENSITIVE DATA INCLUDED - BETA TESTING ONLY"
}
```

---

### 4. **Get Single User Full Details**

```http
GET /api/admin/console/users/{user_id}/full?show_sensitive=true
Authorization: Bearer {admin_token}
```

Get complete details for one specific user.

---

### 5. **Execute Raw SQL Query (Read-Only)**

```http
POST /api/admin/console/raw-query
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "query": "SELECT email, user_code, initial_capital FROM users WHERE is_admin = 1"
}
```

**Security:**
- ✅ Only SELECT queries allowed
- ❌ INSERT, UPDATE, DELETE blocked
- ⚠️  Beta testing only

---

### 6. **Export Users to CSV**

```http
GET /api/admin/console/export/csv?show_sensitive=false
Authorization: Bearer {admin_token}
```

Downloads a CSV file with all user data.

**Parameters:**
- `show_sensitive=false` - Safe export (default)
- `show_sensitive=true` - Include passwords & API keys (beta only)

---

## 🔒 Production Security

### **Before Production Deploy:**

**File:** `aurum_harmony/admin/db_console_routes.py`

**Change this line:**
```python
# Line 21
BETA_MODE_SHOW_SENSITIVE = False  # ← CHANGE FROM True TO False
```

**Effect:**
- ❌ Console endpoints return 403 Forbidden
- ❌ No sensitive data exposed
- ✅ Safe for production

---

## 💻 PowerShell Quick Test

```powershell
# Login as admin
$headers = @{"Content-Type"="application/json"}
$body = @{email="admin@aurumharmony.com"; password="admin123"} | ConvertTo-Json
$response = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method Post -Headers $headers -Body $body
$token = $response.token

# Get all users (safe mode)
$authHeaders = @{"Authorization"="Bearer $token"}
$users = Invoke-RestMethod -Uri "http://localhost:5000/api/admin/console/users/all?show_sensitive=false" -Method Get -Headers $authHeaders
$users | ConvertTo-Json -Depth 5

# Get all users (with sensitive data - BETA ONLY)
$usersWithSensitive = Invoke-RestMethod -Uri "http://localhost:5000/api/admin/console/users/all?show_sensitive=true" -Method Get -Headers $authHeaders
$usersWithSensitive | ConvertTo-Json -Depth 5
```

---

## 📊 Use Cases

### **Beta Testing:**
- View all user data for debugging
- Check password hashes are correct
- Verify broker credentials are encrypted
- Monitor active sessions
- Export data for analysis

### **Production:**
- Set `BETA_MODE_SHOW_SENSITIVE = False`
- Use regular `/api/admin/users` endpoint
- Only shows safe data (no passwords/keys)

---

## ⚠️ Security Warnings

1. **NEVER** enable beta mode in production
2. **NEVER** share API responses with sensitive data
3. **ALWAYS** use HTTPS in production
4. **ALWAYS** rotate admin passwords regularly
5. **CONSIDER** adding IP whitelist for console endpoints

---

## 🎯 Summary

| Endpoint | Shows Passwords | Shows API Keys | Production Safe |
|----------|----------------|----------------|-----------------|
| `/api/admin/users` | ❌ | ❌ | ✅ YES |
| `/api/admin/console/*` (beta=false) | ❌ | ❌ | ✅ YES |
| `/api/admin/console/*` (beta=true) | ⚠️  YES | ⚠️  YES | ❌ NO |

---

**Created:** December 11, 2025  
**Status:** Beta Testing  
**Production Ready:** Set `BETA_MODE_SHOW_SENSITIVE = False`

