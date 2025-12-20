# GitHub Secrets Setup Guide

## Overview
GitHub Secrets are secure credentials stored in GitHub that workflows can use to authenticate with external services (like Cloudflare).

## Required Secrets for Worker Deployment

### 1. CLOUDFLARE_API_TOKEN

**What it is:** Your Cloudflare API token that allows GitHub Actions to deploy Workers.

**How to get it:**
1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click **"Create Token"**
3. Use **"Edit Cloudflare Workers"** template (recommended)
   - Or create custom token with:
     - **Account** → **Workers Scripts** → **Edit**
     - **Account** → **Account Settings** → **Read**
4. Click **"Continue to summary"**
5. Click **"Create Token"**
6. **Copy the token immediately** (you'll only see it once!)

**How to add to GitHub:**
1. Go to: https://github.com/imvikverma/ah-v1-beta/settings/secrets/actions
2. Click **"New repository secret"**
3. Name: `CLOUDFLARE_API_TOKEN`
4. Value: Paste your token
5. Click **"Add secret"**

### 2. CLOUDFLARE_ACCOUNT_ID

**What it is:** Your Cloudflare account identifier.

**How to get it:**

**Option A: From Cloudflare Dashboard**
1. Go to: https://dash.cloudflare.com
2. Look at the **right sidebar**
3. Account ID is shown there (format: usually alphanumeric)

**Option B: From Wrangler CLI (if installed)**
```bash
wrangler whoami
```
Look for "Account ID" in the output.

**Option C: From Worker Settings**
1. Go to: Cloudflare Dashboard → **Workers & Pages** → **aurum-api**
2. Check **Settings** → **Variables**
3. Account ID might be shown there

**How to add to GitHub:**
1. Go to: https://github.com/imvikverma/ah-v1-beta/settings/secrets/actions
2. Click **"New repository secret"**
3. Name: `CLOUDFLARE_ACCOUNT_ID`
4. Value: Your account ID (just the ID, no spaces or extra text)
5. Click **"Add secret"**

## Quick Links

- **GitHub Secrets:** https://github.com/imvikverma/ah-v1-beta/settings/secrets/actions
- **Cloudflare API Tokens:** https://dash.cloudflare.com/profile/api-tokens
- **Cloudflare Dashboard:** https://dash.cloudflare.com

## Verification

After setting both secrets:
1. Go to GitHub Actions: https://github.com/imvikverma/ah-v1-beta/actions
2. Find "Deploy Cloudflare Worker (aurum-api)" workflow
3. Click **"Run workflow"** → **"Run workflow"**
4. Check if it runs successfully

If it fails:
- Check workflow logs for specific errors
- Verify secrets are spelled correctly (case-sensitive)
- Make sure API token has correct permissions

## Security Notes

- ✅ Secrets are encrypted and never exposed in logs
- ✅ Only repository admins can view/edit secrets
- ✅ Secrets are masked in workflow logs
- ⚠️  Never commit secrets to code
- ⚠️  Never share secrets in chat/email

---

**Last Updated:** 2025-01-13  
**Status:** Setup guide for GitHub Secrets

