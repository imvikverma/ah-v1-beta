# PowerShell 7.5.4 Rollback Guide

**Date:** December 13, 2025  
**Current Version:** PowerShell 7.5.4  
**Issues Experienced:**
- RemoteException in Start-Process (workarounds implemented)
- Terminal selection/copy not working (likely Cursor IDE issue)

---

## Should You Roll Back?

### ✅ **Arguments FOR Rollback:**
1. **RemoteException Issues:** PowerShell 7.5.4 has known issues with `Start-Process` in certain scenarios
2. **Stability:** Newer versions sometimes introduce regressions
3. **Compatibility:** Older versions are more battle-tested

### ❌ **Arguments AGAINST Rollback:**
1. **Workarounds Implemented:** We've already fixed the RemoteException with WMI and HttpClient changes
2. **Terminal Selection:** This is likely a **Cursor IDE issue**, not PowerShell
3. **Features:** PowerShell 7.5.4 has security updates and bug fixes
4. **Compatibility:** Our code now works with 7.5.4 (with workarounds)

---

## Recommendation

### **Option 1: Keep 7.5.4 (Recommended)**
- ✅ We've already fixed the RemoteException issues
- ✅ Terminal selection is a Cursor IDE issue (not PowerShell)
- ✅ All our scripts work with current workarounds
- ✅ Security updates in 7.5.4

**Action:** No rollback needed. Continue using 7.5.4 with our fixes.

### **Option 2: Rollback to 7.4.x (If Issues Persist)**
If you continue experiencing problems:
- **Recommended Version:** PowerShell 7.4.2 (LTS preview) or 7.3.11 (stable)
- These versions are known to be stable
- Less likely to have RemoteException issues

### **Option 3: Use Windows PowerShell 5.1 (Fallback)**
- Already installed on your system
- Most stable, but lacks PowerShell 7 features
- Our scripts have fallback logic for this

---

## Stable PowerShell 7 Versions

| Version | Status | Recommendation |
|---------|--------|---------------|
| 7.5.4 | Current | Use with workarounds ✅ |
| 7.4.2 | LTS Preview | Stable alternative |
| 7.3.11 | Stable | Very stable, recommended if rolling back |
| 7.2.18 | Older | Not recommended (security updates) |

**Best Choice for Rollback:** PowerShell 7.3.11 or 7.4.2

---

## How to Rollback (If Needed)

### Step 1: Download Previous Version

**PowerShell 7.3.11:**
- URL: https://github.com/PowerShell/PowerShell/releases/tag/v7.3.11
- Download: `PowerShell-7.3.11-win-x64.msi`

**PowerShell 7.4.2:**
- URL: https://github.com/PowerShell/PowerShell/releases/tag/v7.4.2
- Download: `PowerShell-7.4.2-win-x64.msi`

### Step 2: Uninstall Current Version

```powershell
# Check current installation
Get-Package -Name "PowerShell" | Select-Object Name, Version

# Uninstall PowerShell 7.5.4
# Go to: Settings → Apps → PowerShell → Uninstall
# Or use: winget uninstall Microsoft.PowerShell
```

### Step 3: Install Previous Version

1. Run the downloaded `.msi` installer
2. Choose "Add PowerShell to PATH"
3. Complete installation
4. **Close all PowerShell windows**
5. Open new PowerShell and verify:
   ```powershell
   $PSVersionTable.PSVersion
   ```

### Step 4: Verify Scripts Still Work

```powershell
# Test our fixes still work
.\start-all.ps1
# Select option 4 (Invoke Backend Flask & Frontend Flutter)
```

---

## Testing After Rollback

1. **Test RemoteException Fix:**
   ```powershell
   .\start-all.ps1
   # Option 4: Invoke Backend Flask & Frontend Flutter
   ```

2. **Test Terminal Selection:**
   - Try selecting text in terminal
   - Try Ctrl+C
   - If still not working, it's a Cursor IDE issue (not PowerShell)

3. **Test All Scripts:**
   ```powershell
   .\scripts\system_integrity_check.ps1
   ```

---

## Alternative: Use Windows PowerShell 5.1

If PowerShell 7 continues to cause issues:

1. **Our scripts already support this:**
   - `start-all.ps1` has fallback logic
   - `start_backend_wrapper.bat` tries `pwsh.exe` then `powershell.exe`

2. **Switch Cursor to use PowerShell 5.1:**
   - Settings → Terminal → Default Profile
   - Select "Windows PowerShell"

3. **Test:**
   ```powershell
   # Should show version 5.1.22621.4249
   $PSVersionTable.PSVersion
   ```

---

## Decision Matrix

| Scenario | Action |
|----------|--------|
| RemoteException fixed, terminal selection still broken | **Keep 7.5.4** (terminal is Cursor issue) |
| RemoteException returns after updates | **Rollback to 7.3.11** |
| Want maximum stability | **Rollback to 7.3.11** or use **PowerShell 5.1** |
| Need latest features | **Keep 7.5.4** with workarounds |

---

## My Recommendation

**Keep PowerShell 7.5.4** because:
1. ✅ We've fixed the RemoteException issues
2. ✅ Terminal selection is a Cursor IDE problem (not PowerShell)
3. ✅ All scripts work correctly now
4. ✅ Security updates in 7.5.4

**Only rollback if:**
- RemoteException issues return
- You need maximum stability for production
- You're willing to lose 7.5.4 features

---

## Quick Test

Before rolling back, test if the issue is actually PowerShell:

```powershell
# Test if RemoteException still occurs
.\start-all.ps1
# Select option 4

# If it works, PowerShell 7.5.4 is fine
# If terminal selection still broken, it's Cursor IDE
```

---

## Summary

- **Current Status:** PowerShell 7.5.4 with workarounds ✅
- **Terminal Selection:** Cursor IDE issue (not PowerShell)
- **Recommendation:** Keep 7.5.4, no rollback needed
- **If Rolling Back:** Use PowerShell 7.3.11 for stability

