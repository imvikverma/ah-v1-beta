# Site Not Loading Fix (ah.saffronbolt.in)

## Problem
Site `ah.saffronbolt.in` is not loading.

## Possible Causes

1. **Deployment Not Triggered**
   - Workflow removed commit/push steps (to fix protected branch)
   - Cloudflare Pages action might not have secrets configured
   - No recent deployment triggered

2. **Cloudflare Pages Configuration**
   - Custom domain not connected
   - Build failed or incomplete
   - Project not connected to GitHub

3. **DNS Issues**
   - Custom domain DNS not configured
   - CNAME not pointing to Cloudflare Pages

## Quick Fixes

### Option 1: Trigger GitHub Actions Workflow (Recommended) ⭐

1. Go to: https://github.com/imvikverma/ah-v1-beta/actions/workflows/cloudflare-deploy.yml
2. Click **"Run workflow"** button (top right)
3. Select branch: `main`
4. Click **"Run workflow"**
5. Wait 2-3 minutes for build and deployment

**This will:**
- Build Flutter web app
- Deploy to Cloudflare Pages via action
- Update the site automatically

### Option 2: Use Quick Deploy Script

**If branch protection allows:**
```powershell
.\start-all.ps1
# Select Option 5: Quick Deploy
```

**This will:**
- Build Flutter web locally
- Commit to `docs/` folder
- Push to GitHub (if allowed)
- Trigger Cloudflare auto-deploy

### Option 3: Check Cloudflare Pages Dashboard

1. Go to: https://dash.cloudflare.com
2. Navigate to: **Pages** → **aurumharmony-v1-beta**
3. Check:
   - Latest deployment status
   - Build logs for errors
   - Custom domain configuration

### Option 4: Manual Deployment via Cloudflare Dashboard

1. Build Flutter web locally:
   ```powershell
   cd aurum_harmony\frontend\flutter_app
   flutter build web --release
   ```

2. Upload to Cloudflare Pages:
   - Cloudflare Dashboard → Pages → aurumharmony-v1-beta
   - Click **"Upload assets"**
   - Upload `build/web/` folder contents

## Verify Deployment

**Check deployment status:**
- GitHub Actions: https://github.com/imvikverma/ah-v1-beta/actions
- Cloudflare Pages: https://dash.cloudflare.com → Pages → aurumharmony-v1-beta

**Test the site:**
- https://ah.saffronbolt.in
- https://aurumharmony-v1-beta.pages.dev (Cloudflare Pages default URL)

## Long-term Solution

**Connect Cloudflare Pages to GitHub (Recommended):**

1. Cloudflare Dashboard → Pages → Create a project
2. Select **"Connect to Git"**
3. Choose repository: `imvikverma/ah-v1-beta`
4. Configure build settings:
   - **Framework preset:** None (or Static Site)
   - **Build command:** `cd aurum_harmony/frontend/flutter_app && flutter build web --release`
   - **Build output directory:** `aurum_harmony/frontend/flutter_app/build/web`
   - **Root directory:** `/` (root of repo)

**Benefits:**
- Auto-builds on every push to `main`
- No need to commit `docs/` folder
- Respects branch protection
- Cleaner git history

## Custom Domain Setup

**If custom domain not working:**

1. Cloudflare Dashboard → Pages → aurumharmony-v1-beta → **Custom domains**
2. Add custom domain: `ah.saffronbolt.in`
3. Configure DNS:
   - Add CNAME record: `ah` → `aurumharmony-v1-beta.pages.dev`
   - Or use Cloudflare's automatic DNS configuration

## Troubleshooting

**If site still not loading after deployment:**

1. **Check DNS:**
   ```bash
   nslookup ah.saffronbolt.in
   # Should resolve to Cloudflare Pages IP
   ```

2. **Check Cloudflare Pages logs:**
   - Dashboard → Pages → aurumharmony-v1-beta → Deployments
   - Click on latest deployment → View logs

3. **Check browser console:**
   - Open https://ah.saffronbolt.in
   - Press F12 → Console tab
   - Look for errors

4. **Verify secrets are set:**
   - GitHub → Settings → Secrets and variables → Actions
   - Check: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`

---

**Last Updated:** 2025-01-13  
**Status:** Site deployment troubleshooting guide

