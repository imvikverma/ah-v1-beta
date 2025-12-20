# Deployment Best Practices

## Quick Reference: When to Rebuild vs. Just Update

### ✅ Just Update Files (No Rebuild Needed)

**Header Changes:**
- Update `docs/_headers` directly
- Commit and push
- Cloudflare Pages reads this immediately
- **No Flutter rebuild needed!**

**Example:**
```powershell
# Just edit and commit
git add docs/_headers
git commit -m "Update CSP headers"
git push
```

**Configuration Files:**
- `docs/_headers` - Cloudflare Pages headers
- `docs/_redirects` - Cloudflare Pages redirects
- `docs/CNAME` - Custom domain
- Any static files in `docs/`

### 🔨 Rebuild Required

**Source Code Changes:**
- Flutter app code changes (`lib/**`)
- Dependencies updated (`pubspec.yaml`)
- Assets changed
- Build configuration changed

**Use Incremental Deployment:**
```powershell
.\start-all.ps1
# Option 5: Quick Deploy (uses incremental script)
```

### 📋 Deployment Decision Tree

```
Is it a header/config file?
├─ YES → Just update docs/_headers or docs/_redirects
│        → Commit and push
│        → No rebuild needed!
│
└─ NO → Is it source code?
    ├─ YES → Use incremental deployment
    │        → Only rebuilds if source changed
    │        → Only copies changed files
    │
    └─ NO → Check what changed
            → Update appropriate file
            → Commit and push
```

## Incremental Deployment

**Use `scripts/deploy_incremental.ps1` for:**
- Source code changes
- Automatic change detection
- Only rebuilds if needed
- Only copies changed files
- Faster deployments

**When to use:**
- Regular development updates
- Source code changes
- Asset updates

## Full Deployment

**Only needed for:**
- First-time setup
- Major dependency changes
- Build system changes
- When incremental fails

## CSP Header Updates

**Quick Fix (No Rebuild):**
1. Edit `docs/_headers`
2. `git add docs/_headers`
3. `git commit -m "Update CSP headers"`
4. `git push`
5. Done! Cloudflare Pages uses it immediately

**Why this works:**
- Cloudflare Pages reads `_headers` file directly
- No build process needed
- Instant deployment
- No Flutter rebuild required

## Common Mistakes to Avoid

❌ **Don't rebuild Flutter for header changes**
- Just update `docs/_headers` directly

❌ **Don't do full rebuilds for small changes**
- Use incremental deployment

❌ **Don't commit entire `docs/` folder unnecessarily**
- Only commit what changed

✅ **Do use incremental deployment for code changes**
- Faster and more efficient

✅ **Do update config files directly**
- Headers, redirects, CNAME, etc.

---

**Last Updated:** 2025-01-13  
**Status:** Best practices guide

