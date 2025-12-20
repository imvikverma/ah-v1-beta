# Python 3.11.9 Setup Guide

**Date:** 2025-12-12  
**Goal:** Clean Flask environment with stable Python 3.11.9

---

## 🎯 Step-by-Step Instructions

### STEP 1: Download Python 3.11.9 ✅

**Download Link:** https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe

**Installation Options:**
- ✅ Check "Add Python 3.11 to PATH"
- ✅ Check "Install for all users" (optional)
- Choose Custom Installation
- Install to: `C:\Python311\` (recommended)

**Verify Installation:**
```powershell
C:\Python311\python.exe --version
# Should show: Python 3.11.9
```

---

### STEP 2: Backup Current Environment ✅

```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"

# Stop all running processes
Get-Process python* -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process dart* -ErrorAction SilentlyContinue | Stop-Process -Force

# Backup old virtual environment
if (Test-Path ".venv") {
    Rename-Item .venv .venv-backup-python313
    Write-Host "[OK] Backed up old .venv" -ForegroundColor Green
}
```

---

### STEP 3: Create New Virtual Environment ✅

```powershell
# Create new venv with Python 3.11
C:\Python311\python.exe -m venv .venv

# Activate it
.\.venv\Scripts\Activate.ps1

# Verify Python version
python --version
# Should show: Python 3.11.9

# Upgrade pip
python -m pip install --upgrade pip
```

---

### STEP 4: Install Packages ✅

```powershell
# Install all dependencies (this will take 5-10 minutes)
pip install -r requirements.txt

# Verify Flask installation
pip show Flask
# Should show: Version: 3.0.3
```

---

### STEP 5: Test Backend ✅

```powershell
# Quick test
python -m aurum_harmony.master_codebase.Master_AurumHarmony_261125

# You should see:
# [OK] Database initialized
# [OK] Database migrations already completed (skipping)
# Running on http://127.0.0.1:5000
```

---

### STEP 6: Fix .env File (if needed) ✅

If you see dotenv warnings:

```powershell
# Check .env encoding
Get-Content .env -Raw | Format-Hex | Select-Object -First 50

# If it has BOM (EF BB BF at start), recreate it:
# 1. Note down all current values
# 2. Delete .env
# 3. Create new .env with Notepad++ or VSCode (UTF-8 without BOM)
# 4. Paste values back
```

---

### STEP 7: Start Everything ✅

```powershell
# Use the start-all.ps1 script
.\start-all.ps1
# Select Option 4: Invoke Backend + Frontend
```

---

## 🎯 Expected Results

**Before (Python 3.13):**
- Startup: 10-15 seconds
- Warnings: dotenv parsing, encoding issues
- TensorFlow: 2.20.0 (experimental)
- Stability: Unknown

**After (Python 3.11):**
- Startup: 5-8 seconds (with smart migration)
- Warnings: None
- TensorFlow: 2.15.0 (stable, proven)
- Stability: Production-ready ✅

---

## 🐛 Troubleshooting

### Issue: "python.exe not found"
**Solution:** Add Python 3.11 to PATH or use full path `C:\Python311\python.exe`

### Issue: "pip install fails"
**Solution:** 
```powershell
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

### Issue: "TensorFlow won't install"
**Solution:** TensorFlow 2.15 requires Visual C++ Redistributable
- Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
- Install and retry

### Issue: ".venv activation fails"
**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## ✅ Verification Checklist

- [ ] Python 3.11.9 installed
- [ ] Old .venv backed up
- [ ] New .venv created
- [ ] All packages installed
- [ ] Flask 3.0.3 verified
- [ ] TensorFlow 2.15.0 verified
- [ ] Backend starts without errors
- [ ] Frontend connects successfully
- [ ] No encoding warnings
- [ ] No dotenv warnings

---

**Ready to rebuild? Follow these steps and let me know when you've downloaded Python 3.11.9!**

