# Broker Integration Quick Start Guide

**Last Updated:** December 23, 2025

## 🚀 Quick Setup (5 minutes)

### Step 1: Run Setup Script

```powershell
.\scripts\brokers\setup_brokers.ps1
```

This will guide you through:
- ✅ HDFC Sky credentials setup
- ✅ Kotak Neo credentials setup
- ✅ Creating/updating `.env` file

### Step 2: Test Connections

```powershell
# Test both brokers
.\scripts\test_broker_connections.ps1
```

### Step 3: Individual Tests (if needed)

```powershell
# HDFC Sky - detailed test
python scripts\brokers\test_hdfc_connection.py

# Kotak Neo - interactive login (TOTP + MPIN)
python scripts\brokers\test_kotak_connection.py
```

## 📋 What You Need

### HDFC Sky
- ✅ API Key & Secret from https://developer.hdfcsky.com
- ✅ Token ID (from URL after web login) OR Access Token (from OAuth)

### Kotak Neo
- ✅ Access Token from Kotak Neo App → Invest → Trade API
- ✅ Mobile Number (format: +91XXXXXXXXXX)
- ✅ Client Code (UCC)
- ✅ TOTP setup in authenticator app
- ✅ MPIN (6-digit)

## 🎯 Next Steps After Setup

1. **Verify connections work:**
   ```powershell
   .\scripts\test_broker_connections.ps1
   ```

2. **Start backend with broker support:**
   ```powershell
   .\start-all.ps1
   # Select Option 1: Start Backend
   ```

3. **Test paper trading with live data:**
   - Backend will automatically use Kotak Neo for live data if configured
   - Or use HDFC Sky for paper trading with live data

4. **Test live trading (after paper trading verified):**
   - Set `AURUM_TRADING_MODE=LIVE` in `.env`
   - Ensure HDFC Sky is fully authenticated
   - Start with small position sizes

## 📚 Full Documentation

- **Complete Guide:** `_local/documentation/BROKER_API_INTEGRATION_GUIDE.md`
- **Environment Template:** `scripts/brokers/env.template`

## ⚠️ Troubleshooting

### HDFC Sky Issues
- **Not authenticated:** Need `token_id` or `access_token`
- **Token expired:** Get fresh token from web login or OAuth flow

### Kotak Neo Issues
- **Not authenticated:** Run `test_kotak_connection.py` and login with TOTP + MPIN
- **TOTP not working:** Re-register TOTP in Kotak Neo app
- **Tokens expired:** Tokens valid for 24 hours, login again

## 💡 Tips

- **Paper Trading First:** Always test with paper trading before live trading
- **Save Tokens:** Kotak Neo tokens are valid for 24 hours, save them to `.env` if needed
- **Live Data:** Kotak Neo is great for live market data in paper trading mode
- **Live Trading:** HDFC Sky is recommended for actual live trading

---

**Need Help?** Check the full integration guide or test scripts for detailed error messages.
