# Urgency Assessment - Files in Review Panel

**Date:** December 13, 2025  
**Total Files Showing:** 19

---

## 🔴 URGENT - Review & Commit Today

### Critical Bug Fixes (Today's Work):
1. **`start-all.ps1`** 
   - ✅ HttpClient resource leak fix
   - ✅ PowerShell executable detection fix
   - **Impact:** Prevents system resource exhaustion and startup failures
   - **Action:** Review and commit

2. **`scripts/start_backend_wrapper.bat`**
   - ✅ Dynamic PowerShell detection (pwsh.exe → powershell.exe fallback)
   - **Impact:** Works on all Windows systems regardless of PowerShell version
   - **Action:** Review and commit

**Why Urgent:** These fix critical bugs that prevent the system from starting correctly.

---

## 🟡 IMPORTANT - Review This Week

### Previous Session Work (Code Changes):
3. **`aurum_harmony/auth/routes.py`** - Auth route changes
4. **`aurum_harmony/admin/routes.py`** - Admin route changes  
5. **`aurum_harmony/admin/db_admin_routes.py`** - DB admin routes
6. **Flutter Screen Files:**
   - `admin_screen.dart`
   - `login_screen.dart`
   - `reports_screen.dart`
   - `trade_screen.dart`
   - `notifications_screen_v2.dart` (new)
7. **Flutter Widget Files:**
   - `error_dialog.dart` (new)
   - `aurum_footer.dart` (new)
   - `backtest_results_table.dart` (new)
   - `position_progress_card.dart` (new)
   - `trade_activity_feed.dart` (new)

**Why Important:** These are actual code changes from previous development sessions that should be committed.

---

## 🟢 LOW PRIORITY - Can Ignore/Untrack

### Files That Should Be Ignored:
8. **`aurum_harmony.db`** - Local database file
   - **Action:** Stop tracking (run `git rm --cached aurum_harmony.db`)
   - **Reason:** Database files are local-only and shouldn't be in Git

9. **`.venv-backup-*` directories** (4 backup venvs)
   - **Action:** Already untracked, but showing as new files
   - **Reason:** Backup virtual environments are temporary

10. **Flutter Generated Files:**
    - `generated_plugin_registrant.cc` (Linux, Windows)
    - `generated_plugins.cmake` (Linux, Windows)
    - `GeneratedPluginRegistrant.swift` (macOS)
    - **Action:** Stop tracking these auto-generated files
    - **Reason:** They're regenerated on each build

11. **`pubspec.lock`** - Flutter dependency lock file
    - **Action:** Usually safe to commit, but not urgent
    - **Reason:** Dependency version lock (can be committed later)

---

## 📊 Summary

| Priority | Count | Action |
|----------|-------|--------|
| 🔴 Urgent | 2 | Review & commit today |
| 🟡 Important | ~12 | Review & commit this week |
| 🟢 Low Priority | ~5 | Untrack or ignore |

---

## ✅ Recommended Actions

### Immediate (Today):
1. Review `start-all.ps1` and `scripts/start_backend_wrapper.bat`
2. Commit the critical fixes
3. Run `.\scripts\fix_gitignore_tracking.ps1` to clean up ignored files

### This Week:
1. Review previous session work (auth/admin routes, Flutter screens)
2. Commit in logical groups (e.g., "Auth improvements", "Flutter UI updates")

### Ongoing:
1. Keep `.gitignore` updated
2. Run the fix script periodically to clean up tracked files that should be ignored

---

## 🎯 Why They Show Persistently

**Root Cause:** Files were tracked by Git **before** being added to `.gitignore`. Git continues tracking files even after they're added to `.gitignore` - you need to explicitly untrack them.

**Solution:** Run `scripts/fix_gitignore_tracking.ps1` to stop tracking files that should be ignored.

---

## 📝 Next Steps

1. **Review critical fixes** → Commit
2. **Run fix script** → Clean up ignored files
3. **Review previous work** → Commit in batches
4. **Test the fixes** → Verify `start-all.ps1` works correctly

