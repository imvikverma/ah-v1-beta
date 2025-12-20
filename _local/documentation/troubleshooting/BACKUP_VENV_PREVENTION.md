# Backup Venv Prevention Guide

**Date:** December 13, 2025  
**Issue:** Backup virtual environments are being activated instead of the correct `.venv`

---

## Problem

When you see this in your terminal prompt:
```
(.venv-backup-20251213-001521) PS D:\Projects\...>
```

A **backup virtual environment** is active instead of the correct `.venv`. This is unnerving and can cause issues.

---

## Why This Happens

1. **PowerShell Auto-Activation:** Some PowerShell configurations auto-activate venvs
2. **Manual Activation:** You might have accidentally activated a backup venv
3. **Script Activation:** A script might be activating the wrong venv
4. **Path Issues:** PowerShell might be finding backup venvs in PATH

---

## Quick Fix

### Option 1: Run the Fix Script
```powershell
.\scripts\ensure_correct_venv.ps1
```

This will:
- ✅ Deactivate any backup venv
- ✅ Activate the correct `.venv`
- ✅ Verify it's working

### Option 2: Manual Fix
```powershell
# Deactivate current venv
deactivate

# Activate correct .venv
.\.venv\Scripts\Activate.ps1

# Verify
python --version  # Should show Python 3.11.9
```

---

## Prevention

### 1. Add to PowerShell Profile

Add this to your PowerShell profile (`$PROFILE`):

```powershell
# Prevent backup venv activation
if ($PWD.Path -like "*AurumHarmonyTest*") {
    if ($env:VIRTUAL_ENV -and $env:VIRTUAL_ENV -match "backup") {
        Write-Host "⚠️  Backup venv detected! Run: .\scripts\ensure_correct_venv.ps1" -ForegroundColor Yellow
        deactivate
    }
}
```

To edit your profile:
```powershell
notepad $PROFILE
```

### 2. Use the Prevention Script

Before starting any work, run:
```powershell
.\scripts\prevent_backup_venv.ps1
```

### 3. Check Before Running Scripts

All scripts now check for backup venvs, but you can manually verify:
```powershell
if ($env:VIRTUAL_ENV -match "backup") {
    Write-Host "❌ Backup venv active!" -ForegroundColor Red
    .\scripts\ensure_correct_venv.ps1
}
```

---

## Scripts Updated

The following scripts now prevent backup venv activation:
- ✅ `scripts/start_backend_silent.ps1` - Checks for backup venv
- ✅ `scripts/start_backend_direct.ps1` - Deactivates backup venvs
- ✅ `scripts/fix_venv_activation.ps1` - Fixes venv activation
- ✅ `scripts/ensure_correct_venv.ps1` - New comprehensive fix script

---

## How to Verify Correct Venv

After activation, check:
```powershell
# Should show: D:\Projects\...\AurumHarmonyTest\.venv
$env:VIRTUAL_ENV

# Should show: Python 3.11.9
python --version

# Should show: Flask 3.0.3
pip show Flask | Select-String "Version:"
```

---

## Clean Up Backup Venvs

If you want to remove old backup venvs (after verifying `.venv` works):

```powershell
# List backup venvs
Get-ChildItem -Directory -Filter ".venv-backup-*"

# Remove old backups (be careful!)
# Get-ChildItem -Directory -Filter ".venv-backup-*" | Remove-Item -Recurse -Force
```

**Note:** Keep at least one recent backup in case you need to rollback.

---

## Status

**Prevention:** ✅ Scripts updated  
**Detection:** ✅ Automatic checks added  
**Fix Script:** ✅ `ensure_correct_venv.ps1` available  
**Priority:** High (affects all Python operations)

---

## Next Steps

1. Run `.\scripts\ensure_correct_venv.ps1` to fix current session
2. Add prevention to PowerShell profile (optional)
3. Always check `$env:VIRTUAL_ENV` before running Python commands
4. Use the fix script if you see backup venv in prompt

---

**Remember:** If you see `(.venv-backup-*)` in your prompt, run the fix script immediately!

