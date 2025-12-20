# Kotak Neo API - Quick Reference Card

**Quick checklist for setting up Kotak Neo API**

---

## 📱 What You Need (5 Items)

1. **Access Token** - From Kotak Neo app → Invest → Trade API
2. **Mobile Number** - Format: `+91XXXXXXXXXX`
3. **Client Code (UCC)** - From app profile or contract notes
4. **TOTP** - Set up via app → Trade API → TOTP Registration
5. **MPIN** - Your 6-digit trading PIN

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Get Credentials
- Open Kotak Neo app
- Go to: **Invest → Trade API**
- Copy Access Token
- Note your Client Code (from Profile)
- Format mobile: `+91XXXXXXXXXX`

### Step 2: Set Up TOTP (One-Time)
- In app: **Trade API → TOTP Registration**
- Scan QR with Google/Microsoft Authenticator
- Verify with TOTP code

### Step 3: Add to .env
Run the setup script:
```powershell
.\scripts\brokers\setup_kotak_credentials.ps1
```

Or manually add to `.env`:
```env
KOTAK_NEO_ACCESS_TOKEN=your_token_here
KOTAK_NEO_MOBILE_NUMBER=+919876543210
KOTAK_NEO_CLIENT_CODE=ABC123
```

---

## ✅ Test Connection

```powershell
python scripts/brokers/test_kotak_connection.py
```

You'll be prompted for:
1. TOTP (from authenticator app)
2. MPIN (your trading PIN)

---

## 📖 Full Guide

For detailed step-by-step instructions:
**`documentation/setup/KOTAK_NEO_SETUP_GUIDE.md`**

---

## 🆘 Common Issues

| Problem | Solution |
|---------|----------|
| Invalid TOTP | Check phone time sync, use current code |
| Invalid MPIN | Use trading PIN, not login password |
| Invalid Token | Copy full token, check for `Bearer ` prefix |
| Format Error | Mobile must be `+91XXXXXXXXXX` (no spaces) |

---

**Last Updated:** 2025-12-08

