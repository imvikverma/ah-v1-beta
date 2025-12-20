# Cloudflare API Token Permissions Fix

## Error
```
✘ [ERROR] A request to the Cloudflare API (/zones/.../workers/routes) failed.
  Authentication error [code: 10000]
```

## Problem
The API token doesn't have the correct permissions to manage Worker routes.

## Required Permissions

### For Worker Deployment:
1. **Workers:Edit** - Deploy and manage Workers
2. **Zone:Edit** - Manage zone settings (for routes)
3. **Zone:Workers Routes:Edit** - Manage Worker routes
4. **Account:Read** - Read account information

## How to Fix

### Option 1: Use "Edit Cloudflare Workers" Template (Recommended)

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click **"Create Token"**
3. Select **"Edit Cloudflare Workers"** template
4. **Add Zone Permissions:**
   - Click **"Add"** under Zone
   - Select **"Zone Settings"** → **Edit**
   - Select **"Workers Routes"** → **Edit**
   - Include: **saffronbolt.in** zone
5. Click **"Continue to summary"**
6. Click **"Create Token"**
7. **Copy the token** (you'll only see it once!)

### Option 2: Edit Existing Token

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Find your existing token
3. Click **"Edit"**
4. **Add Zone Permissions:**
   - Zone → Zone Settings → Edit
   - Zone → Workers Routes → Edit
   - Include: saffronbolt.in zone
5. Click **"Save"**
6. **Copy the updated token**

### Update GitHub Secret

1. Go to: https://github.com/imvikverma/ah-v1-beta/settings/secrets/actions
2. Find **Cloudflare_API_Token**
3. Click **"Update"**
4. Paste the new token
5. Click **"Update secret"**

## Verify Permissions

After updating, the token should have:
- ✅ Workers:Edit
- ✅ Zone:Edit (for saffronbolt.in)
- ✅ Zone:Workers Routes:Edit (for saffronbolt.in)
- ✅ Account:Read

## Test

1. Trigger the workflow manually
2. Check if deployment succeeds
3. If still fails, check workflow logs for specific error

---

**Last Updated:** 2025-01-13  
**Status:** Fix guide for API token permissions

