# Python 3.11.9 Installation Instructions

**Date:** 2025-12-12  
**File:** python-3.11.9-amd64.exe

---

## 📥 INSTALLATION STEPS

### 1. Run the Installer
- Double-click `python-3.11.9-amd64.exe`
- **IMPORTANT:** Click "Customize installation" (NOT "Install Now")

### 2. Optional Features (First Screen)
✅ Check ALL boxes:
- ✅ Documentation
- ✅ pip
- ✅ tcl/tk and IDLE
- ✅ Python test suite
- ✅ py launcher
- ✅ for all users (requires admin)

Click **Next**

### 3. Advanced Options (Second Screen)
✅ Check these:
- ✅ Install Python 3.11 for all users
- ✅ Associate files with Python (requires the launcher)
- ✅ Create shortcuts for installed applications
- ✅ **Add Python to environment variables** ← CRITICAL!
- ✅ Precompile standard library

**Customize install location:**
- Change to: `C:\Python311\`
- (Or leave default if you prefer)

Click **Install**

### 4. During Installation
- May ask for administrator permission → Click **Yes**
- Installation takes ~2-3 minutes
- Progress bar will show file copying

### 5. After Installation Complete
- You'll see "Setup was successful"
- Click **Close**

---

## ✅ VERIFY INSTALLATION

Open a **NEW** PowerShell window (important - closes your current one first):

```powershell
# Check Python version
python --version
# Should show: Python 3.11.9

# Or use full path
C:\Python311\python.exe --version
```

---

## 🚀 NEXT STEPS (After Python is Installed)

### Step 1: Close Current Terminal
Your current PowerShell has the old PATH. Close it and open a new one.

### Step 2: Navigate to Project
```powershell
cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
```

### Step 3: Run Rebuild Script
```powershell
.\rebuild_flask_env.ps1
```

### Step 4: Wait (~10 minutes)
The script will:
- Stop all processes
- Backup old .venv
- Create new venv with Python 3.11
- Install all packages
- Verify everything

### Step 5: Test
```powershell
# Quick test
python -m aurum_harmony.master_codebase.Master_AurumHarmony_261125

# Should start in ~5-8 seconds with no errors!
```

---

## 🐛 TROUBLESHOOTING

### Issue: "python --version" shows old version (3.13)
**Solution:** Close PowerShell completely and open a new one. Windows needs to reload PATH.

### Issue: "python: command not found"
**Solution:** 
1. Check if Python installed to `C:\Python311\`
2. Manually add to PATH:
   - Search → "Environment Variables"
   - System variables → Path → Edit
   - Add: `C:\Python311\`
   - Add: `C:\Python311\Scripts\`
   - Click OK, restart PowerShell

### Issue: Installation asks for admin password
**Solution:** This is normal. Enter admin password to continue.

### Issue: "Modify Setup" appears instead of "Install"
**Solution:** Python 3.11 might already be installed. Check:
```powershell
C:\Python311\python.exe --version
```
If it shows 3.11.9, you're good! Skip installation, proceed to rebuild script.

---

## 📋 CHECKLIST

- [ ] Downloaded python-3.11.9-amd64.exe
- [ ] Ran installer
- [ ] Chose "Customize installation"
- [ ] Checked "Add Python to environment variables"
- [ ] Installed to C:\Python311\
- [ ] Installation completed successfully
- [ ] Closed current PowerShell
- [ ] Opened NEW PowerShell
- [ ] Verified: `python --version` shows 3.11.9
- [ ] Ready to run `.\rebuild_flask_env.ps1`

---

**When you see "Python 3.11.9" in the version check, you're ready to rebuild!** ✅

