# Broker Setup Guides

This directory contains step-by-step guides for setting up broker integrations.

## 📚 Available Guides

### Kotak Neo API
- **[Complete Setup Guide](KOTAK_NEO_SETUP_GUIDE.md)** - Detailed step-by-step instructions
- **[Quick Reference](KOTAK_NEO_QUICK_REFERENCE.md)** - Quick checklist and common issues

### HDFC Sky API
- Setup guide coming soon

### Mangal Keshav API
- Setup guide coming soon

---

## 🚀 Quick Start

### Kotak Neo (Recommended for Testing)

1. **Run the setup script:**
   ```powershell
   .\scripts\brokers\setup_kotak_credentials.ps1
   ```

2. **Follow the interactive prompts** to add your credentials

3. **Test your connection:**
   ```powershell
   python scripts/brokers/test_kotak_connection.py
   ```

4. **For detailed instructions**, see [Kotak Neo Setup Guide](KOTAK_NEO_SETUP_GUIDE.md)

---

## 📖 What Each Guide Covers

- ✅ How to get API credentials from broker apps
- ✅ How to set up authentication (TOTP, OAuth, etc.)
- ✅ How to store credentials securely
- ✅ How to test the connection
- ✅ Troubleshooting common issues

---

**Last Updated:** 2025-12-08

