# Kotak Neo API Setup Guide - Step by Step

**Complete guide to get your Kotak Neo API credentials and connect to AurumHarmony**

---

## 📋 What You'll Need

Before starting, make sure you have:
- ✅ Kotak Neo mobile app installed on your phone
- ✅ Kotak Securities trading account (active)
- ✅ Google Authenticator or Microsoft Authenticator app installed
- ✅ Your Kotak trading account login credentials
- ✅ Your MPIN (6-digit trading PIN)

---

## Step 1: Get Your API Access Token

### 1.1 Open Kotak Neo App
1. Open the **Kotak Neo** app on your phone
2. Log in with your credentials

### 1.2 Navigate to Trade API
1. Tap on **"Invest"** (bottom navigation)
2. Scroll down and find **"Trade API"** section
3. Tap on **"Trade API"**

### 1.3 Create API App
1. If you haven't created an app yet, tap **"Create App"** or **"New App"**
2. Give your app a name (e.g., "AurumHarmony Trading")
3. Tap **"Create"** or **"Generate"**

### 1.4 Copy Access Token
1. You'll see an **"Access Token"** or **"API Token"**
2. **IMPORTANT:** Copy this token immediately - you may not see it again!
3. It will look something like: `Bearer abc123xyz789...` or just `abc123xyz789...`
4. **Save this token securely** - you'll need it for Step 4

**📝 Note:** If you already have an app, tap on it to view/copy the access token.

---

## Step 2: Get Your Client Code (UCC)

### 2.1 Find Your Client Code
Your **Client Code** (also called **UCC - Unique Client Code**) can be found in several places:

**Option A: From Kotak Neo App**
1. Open Kotak Neo app
2. Go to **"Profile"** or **"Account"** section
3. Look for **"Client Code"**, **"UCC"**, or **"Customer ID"**
4. It's usually a 6-8 digit alphanumeric code (e.g., `ABC123` or `123456`)

**Option B: From Contract Note**
- Check any contract note or statement from Kotak Securities
- Client Code is usually printed on the top

**Option C: From Kotak Website**
1. Log in to Kotak Securities website
2. Go to **"My Account"** or **"Profile"**
3. Your Client Code will be displayed there

**📝 Write down your Client Code:** `_________________`

---

## Step 3: Get Your Mobile Number

### 3.1 Format Your Mobile Number
- Your mobile number must be in international format: `+91XXXXXXXXXX`
- Example: If your number is `9876543210`, format it as `+919876543210`
- **No spaces, no dashes** - just `+91` followed by 10 digits

**📝 Write down your formatted mobile number:** `+91_________________`

---

## Step 4: Set Up TOTP (One-Time Password)

### 4.1 Access TOTP Registration
1. Open **Kotak Neo app**
2. Go to **"Invest"** → **"Trade API"**
3. Look for **"TOTP Registration"** or **"API Settings"**
4. Tap on **"TOTP Registration"**

### 4.2 Verify Your Identity
1. Enter your **mobile number** (registered with Kotak)
2. You'll receive an **OTP** on your mobile
3. Enter the **OTP** to verify
4. Enter your **Client Code** (UCC) when prompted

### 4.3 Scan QR Code
1. A **QR code** will appear on the screen
2. Open **Google Authenticator** or **Microsoft Authenticator** app on your phone
3. Tap **"+"** or **"Add Account"** in the authenticator app
4. Choose **"Scan QR Code"**
5. Scan the QR code from Kotak Neo app

### 4.4 Verify TOTP Setup
1. After scanning, your authenticator app will show a 6-digit code
2. Enter this **6-digit TOTP** in the Kotak Neo app
3. Tap **"Verify"** or **"Register"**
4. You should see a success message: **"TOTP Registered Successfully"**

**✅ TOTP Setup Complete!**

**📝 Important:** 
- The TOTP code changes every 30 seconds
- You'll need to use the current code from your authenticator app each time you log in
- Make sure your phone's time is synced correctly

---

## Step 5: Know Your MPIN

### 5.1 What is MPIN?
- **MPIN** is your 6-digit trading PIN
- It's the PIN you use to place trades in the Kotak Neo app
- **NOT** your login password or ATM PIN

### 5.2 If You Don't Remember Your MPIN
1. Open Kotak Neo app
2. Go to **"Settings"** → **"Security"** → **"Change MPIN"**
3. Follow the reset process (you'll need your login password)

**📝 Write down your MPIN:** `______` (Keep this SECRET!)

---

## Step 6: Store Credentials Securely

### 6.1 Create `.env` File
1. Open your project folder in a text editor
2. Look for a file named `.env` (if it doesn't exist, create it)
3. **IMPORTANT:** The `.env` file should be in your project root (same folder as `start-all.ps1`)

### 6.2 Add Kotak Neo Credentials
Add these lines to your `.env` file:

```env
# Kotak Neo API Credentials
KOTAK_NEO_ACCESS_TOKEN=your_access_token_here
KOTAK_NEO_MOBILE_NUMBER=+919876543210
KOTAK_NEO_CLIENT_CODE=ABC123
```

**Replace:**
- `your_access_token_here` with the access token from Step 1.4
- `+919876543210` with your formatted mobile number from Step 3
- `ABC123` with your client code from Step 2

**Example:**
```env
KOTAK_NEO_ACCESS_TOKEN=Bearer abc123xyz789def456ghi012jkl345mno678pqr901stu234vwx567yz
KOTAK_NEO_MOBILE_NUMBER=+919876543210
KOTAK_NEO_CLIENT_CODE=KOT123
```

### 6.3 Security Notes
- ⚠️ **NEVER commit `.env` file to Git** (it's already in `.gitignore`)
- ⚠️ **NEVER share your credentials** with anyone
- ⚠️ **Keep your MPIN secret** - don't store it in `.env` (you'll enter it when needed)

---

## Step 7: Test Your Connection

### 7.1 Run the Test Script
I'll create a test script for you to verify everything works.

**Run this command:**
```powershell
python scripts/brokers/test_kotak_connection.py
```

### 7.2 What the Test Does
1. Loads your credentials from `.env`
2. Prompts you to enter TOTP (from authenticator app)
3. Prompts you to enter MPIN
4. Tests the login flow
5. Shows connection status

### 7.3 Expected Output
If everything works, you'll see:
```
✅ TOTP Login Successful!
✅ MPIN Validation Successful!
✅ Connection Test Passed!
```

---

## Step 8: Troubleshooting

### Problem: "Invalid Access Token"
**Solution:**
- Make sure you copied the **full** access token
- Check if it starts with `Bearer ` - if yes, include it; if no, don't add it
- Try generating a new access token from the app

### Problem: "Invalid TOTP"
**Solution:**
- Make sure your phone's time is **synced correctly**
- Use the **current** 6-digit code from authenticator app (it changes every 30 seconds)
- Make sure you scanned the QR code correctly

### Problem: "Invalid MPIN"
**Solution:**
- Make sure you're entering your **trading MPIN**, not login password
- Reset your MPIN from the app if needed

### Problem: "Invalid Client Code"
**Solution:**
- Double-check your client code (UCC)
- Make sure there are no extra spaces
- Try the format without any dashes or special characters

### Problem: "Mobile Number Format Error"
**Solution:**
- Must be in format: `+91XXXXXXXXXX`
- No spaces, no dashes
- Must start with `+91` followed by exactly 10 digits

---

## Step 9: Integration with AurumHarmony

Once your test passes, your Kotak Neo integration is ready!

### 9.1 Using the API
The system will automatically:
- Load credentials from `.env`
- Handle TOTP/MPIN authentication
- Place orders, check positions, etc.

### 9.2 Manual Testing via API
You can test via the Flask API:

**TOTP Login:**
```powershell
curl -X POST http://localhost:5000/api/brokers/kotak/login/totp `
  -H "Content-Type: application/json" `
  -d '{
    "user_id": "test_user",
    "totp": "123456"
  }'
```

**MPIN Validation:**
```powershell
curl -X POST http://localhost:5000/api/brokers/kotak/login/mpin `
  -H "Content-Type: application/json" `
  -d '{
    "user_id": "test_user",
    "mpin": "123456"
  }'
```

---

## ✅ Checklist

Before you start trading, make sure:

- [ ] Access Token copied and saved in `.env`
- [ ] Mobile number formatted correctly (`+91XXXXXXXXXX`)
- [ ] Client Code (UCC) saved in `.env`
- [ ] TOTP registered and working (can generate codes)
- [ ] MPIN known and ready to enter
- [ ] Test script runs successfully
- [ ] Connection test passes

---

## 🆘 Need Help?

If you're stuck:
1. Check the troubleshooting section above
2. Verify all credentials are correct
3. Make sure your Kotak account is active
4. Contact Kotak Securities support if API access is denied

---

**Last Updated:** 2025-12-08

