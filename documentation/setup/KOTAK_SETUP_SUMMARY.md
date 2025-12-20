# Kotak Neo Integration - Setup Summary

**What I've created to help you set up Kotak Neo API step-by-step**

---

## 📚 Documentation Created

### 1. **Complete Setup Guide** 
   **File:** `documentation/setup/KOTAK_NEO_SETUP_GUIDE.md`
   
   A comprehensive 9-step guide covering:
   - Getting API Access Token from Kotak Neo app
   - Finding your Client Code (UCC)
   - Formatting your mobile number
   - Setting up TOTP (one-time password)
   - Storing credentials securely
   - Testing the connection
   - Troubleshooting common issues

### 2. **Quick Reference Card**
   **File:** `documentation/setup/KOTAK_NEO_QUICK_REFERENCE.md`
   
   A quick checklist for when you just need a reminder:
   - What you need (5 items)
   - 3-step quick setup
   - Common issues and solutions

---

## 🛠️ Scripts Created

### 1. **Interactive Setup Script**
   **File:** `scripts/brokers/setup_kotak_credentials.ps1`
   
   **What it does:**
   - Guides you through entering credentials
   - Validates formats
   - Automatically adds to `.env` file
   - Preserves existing `.env` variables

   **How to use:**
   ```powershell
   .\scripts\brokers\setup_kotak_credentials.ps1
   ```

### 2. **Connection Test Script**
   **File:** `scripts/brokers/test_kotak_connection.py`
   
   **What it does:**
   - Loads credentials from `.env`
   - Tests TOTP login
   - Tests MPIN validation
   - Verifies API connection
   - Shows detailed error messages if something fails

   **How to use:**
   ```powershell
   python scripts/brokers/test_kotak_connection.py
   ```

---

## 🚀 How to Get Started

### Option 1: Use the Interactive Script (Easiest)

1. **Run the setup script:**
   ```powershell
   .\scripts\brokers\setup_kotak_credentials.ps1
   ```

2. **Follow the prompts:**
   - It will ask for Access Token, Mobile Number, and Client Code
   - Enter each when prompted
   - It will save everything to `.env` automatically

3. **Test the connection:**
   ```powershell
   python scripts/brokers/test_kotak_connection.py
   ```

### Option 2: Follow the Complete Guide

1. **Open the guide:**
   - `documentation/setup/KOTAK_NEO_SETUP_GUIDE.md`

2. **Follow each step:**
   - Step 1: Get Access Token from Kotak Neo app
   - Step 2: Get Client Code
   - Step 3: Format Mobile Number
   - Step 4: Set up TOTP (one-time)
   - Step 5: Know your MPIN
   - Step 6: Store in `.env`
   - Step 7: Test connection

---

## 📋 What You'll Need

Before starting, gather these 5 items:

1. **Access Token** - From Kotak Neo app → Invest → Trade API
2. **Mobile Number** - Your registered mobile (format: `+91XXXXXXXXXX`)
3. **Client Code (UCC)** - From app profile or contract notes
4. **TOTP Setup** - One-time setup via app (scan QR code)
5. **MPIN** - Your 6-digit trading PIN

---

## ✅ Quick Checklist

- [ ] Read the setup guide (or use interactive script)
- [ ] Get Access Token from Kotak Neo app
- [ ] Get Client Code (UCC)
- [ ] Format mobile number (`+91XXXXXXXXXX`)
- [ ] Set up TOTP (scan QR code with authenticator app)
- [ ] Know your MPIN
- [ ] Add credentials to `.env` (via script or manually)
- [ ] Run test script to verify connection
- [ ] See "✅ CONNECTION TEST PASSED!" message

---

## 🆘 Need Help?

### If the test fails:

1. **Check the error message** - The test script shows detailed errors
2. **Review the troubleshooting section** in the setup guide
3. **Common issues:**
   - Invalid TOTP → Check phone time sync
   - Invalid MPIN → Use trading PIN, not login password
   - Format errors → Check mobile number format
   - Token errors → Copy full access token

### If you're stuck:

1. Open `documentation/setup/KOTAK_NEO_SETUP_GUIDE.md`
2. Go to "Step 8: Troubleshooting"
3. Check the error code and solution

---

## 📖 Next Steps After Setup

Once your connection test passes:

1. ✅ Your Kotak Neo API is configured
2. ✅ The system can now authenticate automatically
3. ✅ You can place orders, check positions, etc.
4. ✅ The integration is ready for live trading

---

## 🔒 Security Notes

- ⚠️ **Never commit `.env` to Git** (already in `.gitignore`)
- ⚠️ **Never share your credentials** with anyone
- ⚠️ **Keep MPIN secret** - don't store it in `.env`
- ⚠️ **Access tokens expire** - you may need to regenerate

---

**Ready to start?** Run the setup script or open the complete guide!

**Last Updated:** 2025-12-08

