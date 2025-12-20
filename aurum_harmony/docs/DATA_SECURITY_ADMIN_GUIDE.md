# AurumHarmony - Data Security & Admin Access Guide
**Version:** 1.0 Beta  
**Date:** December 11, 2025

---

## 🔐 Data Storage Architecture

### **1. SQLite Database (Local)**
**Location:** `aurum_harmony.db`

**Stores:**
- ✅ User accounts & profiles
- ✅ Authentication sessions (JWT tokens)
- ✅ Broker credentials (ENCRYPTED)
- ✅ Trading configurations

**Tables:**
- `users` - User information
- `sessions` - Active login sessions
- `broker_credentials` - Encrypted broker API keys

---

### **2. Hyperledger Fabric (Blockchain)**
**Purpose:** Immutable trade audit trail

**Stores ONLY Trade Records:**
```json
{
  "trade_id": "trade_abc123",
  "user_id": "U003",
  "symbol": "NIFTY50",
  "side": "BUY",
  "quantity": 1.0,
  "price": 18500.0,
  "timestamp": 1702345678,
  "strategy": "AI_Signal"
}
```

**DOES NOT Store:**
- ❌ User login credentials
- ❌ API keys
- ❌ Personal information (email, phone, DOB)
- ❌ KYC documents

**Why Blockchain?**
- Immutable audit trail for SEBI compliance
- Transparent trade history
- Cannot be altered or deleted retroactively

---

## 🛡️ Data Security - What's Protected

### **Sensitive Data (NEVER Exposed via API):**

#### **1. Password Hashes**
```python
password_hash = "bcrypt$12$abc123..."  # ❌ NEVER returned
```
- Stored in database: ✅
- Returned by `/api/admin/users`: ❌ NO
- Requires: `to_dict(include_sensitive=True)` (not used in API)

#### **2. Broker API Credentials**
```python
api_key = "encrypted_key_data..."      # ❌ NEVER returned
api_secret = "encrypted_secret_data..." # ❌ NEVER returned
access_token = "encrypted_token..."    # ❌ NEVER returned
```
- Stored in database: ✅ (ENCRYPTED)
- Returned by `/api/admin/users`: ❌ NO
- Requires: `to_dict(include_credentials=True)` (not used in API)

#### **3. Session Tokens (Full)**
```python
session_token = "eyJhbGciOiJIUzI1NiIs..."  # ❌ NEVER returned to admin
```
- Used for authentication only
- Not exposed in admin panel

---

## 📊 Admin Access - What YOU CAN See

### **Current `/api/admin/users` Returns:**

```json
{
  "id": 3,
  "email": "user@example.com",        // ✅ Visible (for contact)
  "phone": "9876543210",              // ✅ Visible (for contact)
  "username": "testuser2",            // ✅ Visible (display name)
  "user_code": "U003",                // ✅ Visible (unique ID)
  "is_admin": false,                  // ✅ Visible (role)
  "is_active": true,                  // ✅ Toggleable
  "profile_picture_url": null,        // ✅ Visible
  "email_verified": false,            // ✅ Visible
  "date_of_birth": "1990-01-15",      // ✅ Visible (for fee waivers)
  "anniversary": "2020-05-20",        // ✅ Visible (for discounts)
  "initial_capital": 10000.0,         // ✅ Toggleable
  "max_trades_per_index": {           // ✅ Toggleable
    "NIFTY50": 50,
    "BANKNIFTY": 30
  },
  "max_accounts_allowed": 1,          // ✅ Toggleable
  "created_at": "2025-12-11T16:46:12",
  "updated_at": "2025-12-11T16:46:12"
}
```

### **✅ What You CAN Toggle as Admin:**

#### **1. Trading Configuration:**
```json
{
  "initial_capital": 10000.0,          // Starting capital per user
  "max_trades_per_index": {
    "NIFTY50": 50,                     // Max trades on NIFTY
    "BANKNIFTY": 30,                   // Max trades on BANKNIFTY
    "SENSEX": 20                       // Max trades on SENSEX
  },
  "max_accounts_allowed": 2            // # of demat/broker accounts
}
```

**API Endpoint:** `PATCH /api/admin/users/{user_id}`

**Example:**
```bash
PATCH /api/admin/users/3
{
  "initial_capital": 50000.0,
  "max_trades_per_index": {
    "NIFTY50": 100,
    "BANKNIFTY": 50
  },
  "max_accounts_allowed": 3
}
```

#### **2. User Status:**
```json
{
  "is_active": true,    // Enable/disable user account
  "is_admin": false     // Grant/revoke admin access
}
```

#### **3. Contact & Profile:**
```json
{
  "email": "newemail@example.com",     // Update email
  "phone": "9999999999",               // Update phone
  "date_of_birth": "1990-01-15",       // Update DOB (for fee waivers)
  "anniversary": "2020-05-20"          // Update anniversary (for discounts)
}
```

---

## 🔒 What You CANNOT See/Edit as Admin:

### **1. Login Credentials**
- ❌ Password hash
- ❌ Session tokens
- **Why?** Security best practice - even admins shouldn't see passwords

### **2. Broker API Keys**
- ❌ API keys
- ❌ API secrets
- ❌ Access tokens
- **Why?** These are encrypted and tied to user's broker account

### **3. KYC Documents**
- ❌ Not stored in this system yet
- **When implemented:** Will be encrypted and require special access

---

## 🎯 Admin Workflow Examples

### **Example 1: Increase User's Trade Limits**

**Scenario:** User requests to trade more on NIFTY50

```bash
PATCH /api/admin/users/3
Authorization: Bearer {admin_token}

{
  "max_trades_per_index": {
    "NIFTY50": 100,      // Increased from 50
    "BANKNIFTY": 30      // Unchanged
  }
}
```

### **Example 2: Add Multiple Broker Accounts**

**Scenario:** Premium user wants to connect HDFC + Kotak

```bash
PATCH /api/admin/users/3
Authorization: Bearer {admin_token}

{
  "max_accounts_allowed": 2   // Increased from 1
}
```

### **Example 3: Disable User Temporarily**

**Scenario:** User violated trading rules

```bash
PATCH /api/admin/users/3
Authorization: Bearer {admin_token}

{
  "is_active": false   // User cannot login until reactivated
}
```

### **Example 4: Set Initial Capital for New User**

**Scenario:** Onboard premium user with higher capital

```bash
PATCH /api/admin/users/4
Authorization: Bearer {admin_token}

{
  "initial_capital": 100000.0   // ₹1 lakh instead of ₹10k default
}
```

---

## 📋 Complete Field Reference

### **User Model Fields:**

| Field | Type | Admin Visible | Admin Editable | Sensitive |
|-------|------|--------------|----------------|-----------|
| `id` | Integer | ✅ | ❌ | No |
| `email` | String | ✅ | ✅ | No |
| `phone` | String | ✅ | ✅ | No |
| `password_hash` | String | ❌ | ❌ | **YES** |
| `username` | String | ✅ | ✅ | No |
| `user_code` | String | ✅ | ❌ | No |
| `is_admin` | Boolean | ✅ | ✅ | No |
| `is_active` | Boolean | ✅ | ✅ | No |
| `profile_picture_url` | String | ✅ | ✅ | No |
| `email_verified` | Boolean | ✅ | ✅ | No |
| `date_of_birth` | Date | ✅ | ✅ | No |
| `anniversary` | Date | ✅ | ✅ | No |
| `initial_capital` | Float | ✅ | ✅ | No |
| `max_trades_per_index` | JSON | ✅ | ✅ | No |
| `max_accounts_allowed` | Integer | ✅ | ✅ | No |
| `created_at` | DateTime | ✅ | ❌ | No |
| `updated_at` | DateTime | ✅ | ❌ | No |

### **Broker Credentials (Separate Table):**

| Field | Admin Visible | Admin Editable | Sensitive |
|-------|--------------|----------------|-----------|
| `broker_name` | ✅ | ❌ | No |
| `is_active` | ✅ | ✅ | No |
| `api_key` | ❌ | ❌ | **YES** |
| `api_secret` | ❌ | ❌ | **YES** |
| `access_token` | ❌ | ❌ | **YES** |
| `refresh_token` | ❌ | ❌ | **YES** |

---

## 🔍 Database Admin Panel

**Endpoint:** `/api/admin/db/*`

**Features:**
- View all tables: `GET /api/admin/db/tables`
- View table data: `GET /api/admin/db/tables/users`
- View table schema: `GET /api/admin/db/tables/users/columns`
- Get database stats: `GET /api/admin/db/stats`

**Security:**
- Only accessible by admin users (`is_admin=true`)
- Read-only access (no direct editing via DB panel)
- Use `/api/admin/users/{id}` endpoints for updates

---

## 🚨 Security Best Practices

### **1. Password Handling**
- ✅ Passwords hashed with bcrypt (cost factor 12)
- ✅ Never returned in API responses
- ✅ Cannot be viewed by admins
- ✅ Users must reset if forgotten (email flow)

### **2. Broker Credentials**
- ✅ Encrypted at rest in database
- ✅ Never returned in admin API
- ✅ Only decrypted during trade execution
- ✅ User-specific encryption keys

### **3. Admin Access**
- ✅ Requires `is_admin=true` flag
- ✅ All admin actions logged
- ✅ Token-based authentication (24hr expiry)
- ✅ Separate admin endpoints (`/api/admin/*`)

### **4. Blockchain Integrity**
- ✅ Trades recorded immutably
- ✅ Cannot be edited or deleted
- ✅ Provides audit trail for SEBI
- ✅ Does not contain PII (Personally Identifiable Information)

---

## 📞 Questions?

**Common Admin Queries:**

**Q: Can I see a user's password?**  
A: No. Passwords are one-way hashed and cannot be retrieved by anyone, including admins.

**Q: Can I see a user's broker API keys?**  
A: No. These are encrypted and only used by the system for trade execution.

**Q: How do I help a user who forgot their password?**  
A: Implement a password reset flow via email (not yet built).

**Q: Can I manually execute trades for a user?**  
A: No. All trades must be executed through the orchestrator with user consent.

**Q: How do I audit a user's trading history?**  
A: Query the blockchain for their `user_id` - this shows immutable trade records.

---

**Last Updated:** December 11, 2025  
**Security Level:** Production-Ready  
**Compliance:** SEBI Ready (trade audit trail)

