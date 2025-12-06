# Credential Cleanup - Step-by-Step Guide

**Status:** 🔴 URGENT  
**Date:** 2025-12-06

## Problem
- `Other_Files/API Keys.txt` may contain leaked credentials in git history
- Need to permanently remove from ALL commit history
- Rotate ngrok token (security best practice)

## Prerequisites

### Option 1: Install git-filter-repo (Recommended)
```powershell
pip install git-filter-repo
```

### Option 2: Use BFG Repo-Cleaner
Download from: https://rtyley.github.io/bfg-repo-cleaner/

## Step-by-Step Process

### Step 1: Check Git History
```powershell
git log --all --full-history --oneline -- "Other_Files/API Keys.txt"
```

**If no output:** File doesn't exist in history ✅  
**If commits shown:** File exists in history ⚠️ (proceed to Step 2)

### Step 2: Remove from History

#### Using git-filter-repo:
```powershell
git filter-repo --path "Other_Files/API Keys.txt" --invert-paths --force
```

#### Using BFG Repo-Cleaner:
```powershell
# Download BFG jar file first
java -jar bfg.jar --delete-files "Other_Files/API Keys.txt"
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

### Step 3: Verify Cleanup
```powershell
git log --all --full-history --oneline -- "Other_Files/API Keys.txt"
```
Should return nothing or "fatal: ambiguous argument"

### Step 4: Force Push to GitHub
⚠️ **WARNING:** This rewrites remote history. Coordinate with team first!

```powershell
git push origin --force --all
git push origin --force --tags
```

### Step 5: Rotate ngrok Token (Optional)
**Note:** We're not using ngrok anymore. We now use custom domains:
- `ah.saffronbolt.in` 
- `aurumharmony.saffronbolt.in`
- Both linked via Cloudflare Pages and GitHub

However, if the ngrok token was leaked, it's still good security practice to rotate it to prevent abuse:

1. Go to: https://dashboard.ngrok.com/get-started/your-authtoken
2. Click "Generate new token"
3. Revoke the old token
4. (Optional since we're not using ngrok, but prevents abuse of leaked token)

## Automated Script

A cleanup script is available at:
```
scripts/cleanup_credentials.ps1
```

Run it with:
```powershell
.\scripts\cleanup_credentials.ps1
```

## Important Notes

1. **Backup First:** Make sure you have a backup of your repository
2. **Coordinate:** If working with a team, coordinate before force pushing
3. **Local Only:** The cleanup only affects your local repo until you force push
4. **GitHub:** After force push, GitHub will update, but anyone who cloned before will need to re-clone

## Current Status

- ✅ Cleanup script created: `scripts/cleanup_credentials.ps1`
- ⚠️ Git rebase in progress (may need to resolve first)
- 📋 Need to check if file exists in history
- 📋 Need to install git-filter-repo or BFG

## After Cleanup

1. Update `.gitignore` to prevent future leaks:
   ```
   # Add to .gitignore
   **/API Keys.txt
   **/*Keys*.txt
   **/*credentials*.txt
   **/*secrets*.txt
   ```

2. Review other files for potential leaks
3. Set up pre-commit hooks to prevent committing secrets

---

**Next Action:** Resolve git rebase issue, then run cleanup script.

