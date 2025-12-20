# Why Files Show Persistently in Review Panel

**Date:** December 13, 2025  
**Issue:** 19 files showing in review panel persistently

---

## Root Cause Analysis

### 1. **Uncommitted Changes (17 Modified Files)**
These are actual code changes that haven't been committed to Git:
- **Critical fixes (today):** `start-all.ps1`, `scripts/start_backend_wrapper.bat`
- **Previous work:** Various Python, Dart, and Flutter files from earlier sessions
- **Database:** `aurum_harmony.db` (should be ignored but is tracked)

**Why they persist:** Git tracks these as modified until you commit or discard them.

---

### 2. **Untracked Files (25 Files)**
These are new files Git doesn't know about:
- **Backup venvs:** `.venv-backup-*` directories (should be ignored)
- **Generated files:** Flutter `generated_plugin_registrant.*` files (auto-generated)
- **Documentation:** Some docs that should be in `_local/` (already ignored)

**Why they persist:** Git shows untracked files until you:
- Add them to `.gitignore`
- Commit them
- Remove them

---

### 3. **Files That Should Be Ignored**

#### Already in `.gitignore` but still showing:
- `aurum_harmony.db` - Database file (line 67: `*.db` should catch this)
- `.venv-backup-*` - Backup virtual environments
- `generated_plugin_registrant.*` - Flutter auto-generated files

**Why they still show:**
- They were **already tracked** by Git before being added to `.gitignore`
- `.gitignore` only prevents **new** files from being tracked
- To stop tracking existing files: `git rm --cached <file>`

---

## Urgency Assessment

### 🔴 **URGENT - Review & Commit:**
1. `start-all.ps1` - Critical bug fixes (HttpClient leak, PowerShell executable)
2. `scripts/start_backend_wrapper.bat` - Critical bug fix (PowerShell detection)

### 🟡 **IMPORTANT - Review Soon:**
3. `aurum_harmony/auth/routes.py` - Previous session work
4. `aurum_harmony/admin/routes.py` - Previous session work
5. `aurum_harmony/admin/db_admin_routes.py` - Previous session work
6. Flutter screen files - Previous session work

### 🟢 **LOW PRIORITY - Can Ignore:**
- `aurum_harmony.db` - Local database (should be ignored)
- `.venv-backup-*` - Backup directories (should be ignored)
- `generated_plugin_registrant.*` - Auto-generated (should be ignored)
- `pubspec.lock` - Dependency lock file (usually safe to commit, but not urgent)

---

## Solutions

### Option 1: Fix `.gitignore` and Stop Tracking Files

```powershell
# Stop tracking files that should be ignored
git rm --cached aurum_harmony.db
git rm --cached -r .venv-backup-*/
git rm --cached aurum_harmony/frontend/flutter_app/*/flutter/generated_plugin_registrant.*
```

### Option 2: Update `.gitignore` to Be More Specific

Add these patterns:
```
# Backup virtual environments
.venv-backup-*/

# Flutter generated files (platform-specific)
**/generated_plugin_registrant.*
**/GeneratedPluginRegistrant.*
```

### Option 3: Commit Critical Fixes Only

```powershell
# Stage only today's critical fixes
git add start-all.ps1
git add scripts/start_backend_wrapper.bat
git commit -m "Fix: HttpClient resource leak and PowerShell executable detection"
```

---

## Recommended Action Plan

1. **Immediate:** Review and commit today's critical fixes (`start-all.ps1`, `start_backend_wrapper.bat`)
2. **Today:** Fix `.gitignore` and stop tracking files that should be ignored
3. **This Week:** Review and commit previous session work (auth/admin routes, Flutter screens)
4. **Ongoing:** Keep `.gitignore` updated to prevent tracking unwanted files

---

## Why They Show in Cursor's Review Panel

Cursor's review panel shows:
- **Git modified files** (uncommitted changes)
- **Git untracked files** (new files not in `.gitignore`)
- **Files moved/renamed** (shows as deleted + added)

The panel persists because:
- Git hasn't been told to ignore these files (they were tracked before `.gitignore` was updated)
- Changes haven't been committed
- Cursor tracks all file system changes, not just Git-tracked files

---

## Quick Fix Script

See `scripts/fix_gitignore_tracking.ps1` for an automated solution.

