# Fix: Backup Venv Activation Issue

**Issue:** PowerShell terminal showing backup venv activated instead of current `.venv`

**Symptoms:**
- Terminal prompt shows: `(.venv-backup-20251213-001521)`
- Should show: `(.venv)`

---

## Quick Fix

In the affected PowerShell terminal, run:

```powershell
# Deactivate current (backup) venv
deactivate

# Activate correct .venv
.\.venv\Scripts\Activate.ps1

# Verify
python --version  # Should show Python 3.11.9
$env:VIRTUAL_ENV  # Should show path ending in \.venv (not \.venv-backup-*)
```

---

## Prevention

The backup venv was likely activated manually or from a previous session. To prevent this:

1. **Close all PowerShell terminals**
2. **Open fresh terminal**
3. **Navigate to project:**
   ```powershell
   cd "D:\Projects\AI Projects\Testbed\Downloads Repo\AurumHarmonyTest"
   ```
4. **Activate correct venv:**
   ```powershell
   .\.venv\Scripts\Activate.ps1
   ```

---

## Verify Correct Venv

After activation, verify:
```powershell
# Check Python version
python --version
# Should show: Python 3.11.9

# Check Flask version
pip show Flask
# Should show: Version: 3.0.3

# Check venv path
$env:VIRTUAL_ENV
# Should end with: \.venv (NOT \.venv-backup-*)
```

---

## Clean Up Old Backups (Optional)

If you want to remove old backup venvs to avoid confusion:

```powershell
# List all backups
Get-ChildItem -Directory -Filter ".venv-backup-*"

# Remove specific backup (be careful!)
# Remove-Item -Recurse -Force ".venv-backup-20251213-001521"
```

**Note:** Keep at least the most recent backup until you're sure everything works.

---

**Status:** Current `.venv` is correct (Python 3.11.9, Flask 3.0.3)  
**Action Required:** Fix the terminal session that has backup venv activated

