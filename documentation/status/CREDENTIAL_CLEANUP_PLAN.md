# Credential Cleanup Plan

**Status:** 🔴 URGENT  
**Date:** 2025-12-06

## Issue
- `Other_Files/API Keys.txt` may contain leaked credentials in git history
- Need to permanently remove from ALL commit history
- Rotate ngrok token (even though we don't use it anymore)

## Current Status
- ✅ File not found in current working directory (already deleted locally)
- ⚠️ May still exist in git history
- ⚠️ Git rebase in progress (blocking other operations)

## Steps to Complete

### Step 1: Resolve Git Rebase Issue
The git rebase is stuck. We need to:
1. Close any open git editor windows
2. Either complete or abort the rebase
3. Then proceed with credential cleanup

### Step 2: Check Git History for Leaked File
```powershell
# Check if file exists in git history
git log --all --full-history -- "Other_Files/API Keys.txt"
```

### Step 3: Remove from Git History (if found)
If the file exists in history, we'll need to use `git filter-repo` or BFG Repo-Cleaner to remove it from ALL commits.

### Step 4: Rotate ngrok Token
1. Go to https://dashboard.ngrok.com/get-started/your-authtoken
2. Generate new token
3. Revoke old token
4. (Note: We don't use ngrok anymore, but good security practice)

## Next Actions

**Immediate:**
1. Resolve git rebase issue
2. Check git history for leaked file
3. If found, remove from all history using `git filter-repo`

**After cleanup:**
- Force push to GitHub (will require coordination)
- Update any documentation that references the old token

---

**Note:** This is a sensitive operation. We should coordinate before force-pushing to avoid disrupting other work.

