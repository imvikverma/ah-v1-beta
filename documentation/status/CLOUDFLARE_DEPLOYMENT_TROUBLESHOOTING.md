# Cloudflare Deployment Troubleshooting

**Date:** 2025-12-06  
**Issue:** GitHub Actions workflow failing to trigger Cloudflare deployment

## Current Status

- **Run #3:** Failed ❌ (Update CNAME commit)
- **Run #2:** Success ✅ (Create CNAME commit)  
- **Run #1:** Success ✅ (UI fixes commit)

## Workflow Configuration

The workflow triggers on:
- Changes to `aurum_harmony/frontend/**`
- Changes to `.github/workflows/deploy.yml`
- Changes to `docs/**`
- Manual trigger via `workflow_dispatch`

**Workflow File:** [deploy.yml](https://raw.githubusercontent.com/imvikverma/aurumharmony-v1-beta/7f126c9c63e70e4b4646c1be3cb91de8b5f5b1dd/.github/workflows/deploy.yml)

## Common Failure Causes

### 1. Missing or Invalid Secret

**Error Message:**
```
⚠️  Warning: CLOUDFLARE_DEPLOY_HOOK secret not set
```

**Fix:**
1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Check if `CLOUDFLARE_DEPLOY_HOOK` exists
3. If missing, add it with your Cloudflare Pages webhook URL
4. Get webhook URL from: Cloudflare Dashboard → Pages → Your Project → Settings → Builds & deployments → Build hook

### 2. Webhook URL Expired or Invalid

**Error Message:**
```
❌ Failed to trigger deployment (HTTP 404)
```

**Fix:**
1. Generate a new build hook in Cloudflare Pages
2. Update the `CLOUDFLARE_DEPLOY_HOOK` secret with the new URL
3. Webhook URLs can expire or be revoked

### 3. Cloudflare Rejection

**Error Message:**
```
❌ Failed to trigger deployment (HTTP 401/403)
```

**Possible Causes:**
- Webhook URL is incorrect
- Cloudflare project settings changed
- Authentication issue

**Fix:**
1. Verify webhook URL in Cloudflare dashboard
2. Regenerate build hook if needed
3. Check Cloudflare Pages project settings

### 4. Path Filter Not Matching

**Symptom:** Workflow doesn't trigger at all

**Fix:**
- Ensure changes are in:
  - `aurum_harmony/frontend/**`
  - `.github/workflows/deploy.yml`
  - `docs/**`
- Or use manual trigger: GitHub Actions → Run workflow

## Debugging Steps

### Step 1: Check Workflow Logs

1. Go to GitHub Actions → "Deploy to Cloudflare Pages (Webhook)"
2. Click on the failed run (#3)
3. Expand "Trigger Cloudflare Deploy Hook" step
4. Look for error messages

### Step 2: Verify Secret

```bash
# In GitHub repository
Settings → Secrets and variables → Actions
# Check if CLOUDFLARE_DEPLOY_HOOK exists
```

### Step 3: Test Webhook Manually

```bash
# Get webhook URL from Cloudflare
curl -X POST "YOUR_WEBHOOK_URL"

# Should return 200 or 204
```

### Step 4: Check Cloudflare Dashboard

1. Go to Cloudflare Dashboard → Pages
2. Select your project (aurumharmony-v1-beta)
3. Check "Deployments" tab
4. See if deployment was triggered

## Quick Fixes

### Option 1: Regenerate Webhook

1. Cloudflare Dashboard → Pages → Your Project
2. Settings → Builds & deployments
3. Copy new "Build hook" URL
4. Update GitHub secret: `CLOUDFLARE_DEPLOY_HOOK`

### Option 2: Manual Trigger

1. GitHub Actions → "Deploy to Cloudflare Pages (Webhook)"
2. Click "Run workflow" button
3. Select branch: `main`
4. Click "Run workflow"

### Option 3: Check Recent Commits

The workflow only triggers on specific paths. If your recent commits don't include:
- `aurum_harmony/frontend/**` changes
- `docs/**` changes
- `.github/workflows/deploy.yml` changes

The workflow won't trigger automatically. Use manual trigger or include one of these paths.

## Expected Behavior

When working correctly:
1. ✅ Workflow triggers on push to `main` (if paths match)
2. ✅ Checks for `CLOUDFLARE_DEPLOY_HOOK` secret
3. ✅ Makes POST request to Cloudflare webhook
4. ✅ Receives HTTP 200/204 response
5. ✅ Cloudflare starts building and deploying
6. ✅ New deployment appears in Cloudflare Dashboard

## Next Steps

1. **Check Run #3 logs** for specific error message
2. **Verify secret** is set correctly
3. **Test webhook URL** manually
4. **Regenerate webhook** if needed
5. **Try manual trigger** to test

---

**Status:** 🔍 Investigating - Need Run #3 error logs for diagnosis

