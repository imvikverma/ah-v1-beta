# Kotak Neo Quick Setup (TOTP & MPIN Ready)

**You already have TOTP and MPIN? Great! You just need 3 more items.**

---

## ✅ What You Already Have
- ✅ TOTP setup (authenticator app working)
- ✅ MPIN (6-digit trading PIN)

---

## 📋 What You Need to Get (3 Items)

### 1. Access Token (2 minutes)

**Steps:**
1. Open **Kotak Neo app** on your phone
2. Tap **"Invest"** (bottom navigation)
3. Scroll to **"Trade API"** section
4. Tap **"Trade API"**
5. If you have an existing app, tap on it
6. **Copy the Access Token** (it's a long string)
   - It might look like: `Bearer abc123xyz...` or just `abc123xyz...`
   - Copy the **entire token**

**📝 Write it down or keep it ready:** `_________________`

---

### 2. Mobile Number (30 seconds)

**Format:** `+91XXXXXXXXXX` (no spaces, no dashes)

**Example:**
- If your number is `9876543210`
- Format it as: `+919876543210`

**📝 Your formatted mobile:** `+91_________________`

---

### 3. Client Code / UCC (1 minute)

**Where to find it:**

**Option A: From Kotak Neo App**
1. Open Kotak Neo app
2. Go to **"Profile"** or **"Account"** section
3. Look for **"Client Code"**, **"UCC"**, or **"Customer ID"**
4. It's usually 6-8 characters (e.g., `ABC123` or `123456`)

**Option B: From Contract Note**
- Check any contract note or statement
- Client Code is usually on the top

**Option C: From Kotak Website**
1. Log in to Kotak Securities website
2. Go to **"My Account"** or **"Profile"**
3. Your Client Code will be displayed

**📝 Your Client Code:** `_________________`

---

## 🚀 Quick Setup (2 Steps)

### Step 1: Run Setup Script

```powershell
.\scripts\brokers\setup_kotak_credentials.ps1
```

**Enter when prompted:**
1. Access Token (paste the token you copied)
2. Mobile Number (format: `+91XXXXXXXXXX`)
3. Client Code (your UCC)

The script will save everything to `.env` automatically.

---

### Step 2: Test Connection

```powershell
python scripts/brokers/test_kotak_connection.py
```

**When prompted:**
1. Enter **TOTP code** (from your authenticator app - 6 digits)
2. Enter **MPIN** (your 6-digit trading PIN)

**Expected output:**
```
✅ TOTP Login Successful!
✅ MPIN Validation Successful!
✅ CONNECTION TEST PASSED!
```

---

## ✅ That's It!

Once the test passes, your Kotak Neo integration is ready to use!

---

## 🆘 If Something Goes Wrong

### "Invalid Access Token"
- Make sure you copied the **entire** token
- If it starts with `Bearer `, include it; if not, don't add it

### "Invalid TOTP"
- Make sure your phone's time is synced
- Use the **current** 6-digit code (it changes every 30 seconds)

### "Invalid MPIN"
- Make sure you're using your **trading PIN**, not login password

### "Mobile Number Format Error"
- Must be exactly: `+91XXXXXXXXXX`
- No spaces, no dashes
- Must start with `+91` followed by 10 digits

---

**Ready?** Get those 3 items and run the setup script! 🚀

