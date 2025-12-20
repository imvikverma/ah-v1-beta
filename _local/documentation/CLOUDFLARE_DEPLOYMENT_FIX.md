# Cloudflare Pages Deployment Fix Guide

## Problem
✅ **Cursor → Git**: Working (commits and pushes successful)  
❌ **Git → Cloudflare**: Not working (Cloudflare Pages not auto-deploying)

## Root Cause
Cloudflare Pages is not automatically deploying when `docs/` folder changes in GitHub.

## Solutions

### Option 1: Connect Cloudflare Pages to GitHub (Recommended) ⭐

**Steps:**
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Navigate to **Pages** → **Create a project**
3. Select **Connect to Git**
4. Choose your GitHub repository: `imvikverma/ah-v1-beta`
5. Configure build settings:
   - **Framework preset**: None (or Static Site)
   - **Build command**: (leave empty - we pre-build)
   - **Build output directory**: `docs`
   - **Root directory**: `/` (root of repo)
6. Click **Save and Deploy**

**Result:** Cloudflare will auto-deploy whenever `docs/` changes in GitHub.

---

### Option 2: Use GitHub Actions with Cloudflare Secrets

**If Option 1 doesn't work, configure GitHub Actions:**

1. **Get Cloudflare API Token:**
   - Go to [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
   - Click **Create Token**
   - Use **Edit Cloudflare Workers** template
   - Add permissions: **Account** → **Cloudflare Pages** → **Edit**
   - Copy the token

2. **Get Cloudflare Account ID:**
   - Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
   - Right sidebar → **Account ID** (copy it)

3. **Add GitHub Secrets:**
   - Go to your GitHub repo: `imvikverma/ah-v1-beta`
   - **Settings** → **Secrets and variables** → **Actions**
   - Click **New repository secret**
   - Add these secrets:
     - `CLOUDFLARE_API_TOKEN` = (token from step 1)
     - `CLOUDFLARE_ACCOUNT_ID` = (account ID from step 2)

4. **Verify workflow:**
   - The workflow `.github/workflows/cloudflare-deploy.yml` will now work
   - It uses `cloudflare/pages-action@v1` to deploy directly

---

### Option 3: Use Cloudflare Pages Build Hook (Current Setup)

**If you're using the webhook method:**

1. **Get Build Hook URL:**
   - Cloudflare Dashboard → **Pages** → Your project
   - **Settings** → **Builds & deployments** → **Build hooks**
   - Create a new hook → Copy the URL

2. **Add to Worker Environment:**
   ```bash
   wrangler secret put CLOUDFLARE_DEPLOY_HOOK
   # Paste the hook URL when prompted
   ```

3. **The Worker will trigger deployments:**
   - When GitHub webhook hits `/webhook/github`
   - Worker calls the build hook
   - Cloudflare Pages deploys

---

## Quick Diagnostic Checklist

- [ ] Is Cloudflare Pages project connected to GitHub repo?
- [ ] Is `docs/` folder being committed and pushed to GitHub?
- [ ] Are GitHub Actions secrets configured? (if using Option 2)
- [ ] Is Cloudflare Pages watching the correct branch? (usually `main`)
- [ ] Is build output directory set to `docs` in Cloudflare Pages settings?

---

## Current Workflow Status

**What's working:**
- ✅ Local Flutter build → `docs/` folder
- ✅ Git commit and push to GitHub
- ✅ GitHub Actions can build Flutter (if triggered)

**What's NOT working:**
- ❌ Cloudflare Pages auto-deployment from GitHub
- ❌ GitHub Actions → Cloudflare Pages (if secrets missing)

---

## Recommended Fix

**Use Option 1** (Connect Cloudflare Pages to GitHub):
- Simplest and most reliable
- Auto-deploys on every push to `main`
- No secrets needed
- Works with the current `docs/` folder approach

**Steps:**
1. Cloudflare Dashboard → Pages
2. Connect to Git → Select your repo
3. Build settings: Output directory = `docs`
4. Save and Deploy

That's it! 🎉

---

## Testing After Fix

1. Make a small change to `docs/index.html`
2. Commit and push to GitHub
3. Check Cloudflare Pages dashboard
4. Should see a new deployment starting automatically

---

## Troubleshooting

**If deployments still don't trigger:**
- Check Cloudflare Pages → **Deployments** tab
- Look for error messages
- Verify branch name matches (usually `main`)
- Check if `docs/` folder exists in the pushed commit

**If GitHub Actions fails:**
- Check Actions tab in GitHub
- Look for missing secrets errors
- Verify `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` are set

---

**Last Updated:** 2025-01-13  
**Status:** Git → Cloudflare connection needs configuration

