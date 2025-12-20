# Tomorrow's Task: Fresh API Token Setup

**Date:** 2025-12-14  
**Status:** Pending  
**Priority:** High

## Problem
Current Cloudflare API tokens have gotten stale and need to be refreshed.

## What We Need to Do Tomorrow

### 1. Create New Cloudflare API Token
- Go to: https://dash.cloudflare.com/profile/api-tokens
- Click "Create Token"
- Use "Edit Cloudflare Workers" template or custom:
  - **Account Permissions:**
    - `Workers Scripts:Edit`
    - `Workers Routes:Edit`
    - `Account:Read`
  - **Zone Permissions (for saffronbolt.in):**
    - `Zone:Edit`
    - `Zone:Workers Routes:Edit`
    - `Zone:Read`
- Copy the token immediately (only shown once!)

### 2. Update GitHub Secrets
- Go to: https://github.com/imvikverma/ah-v1-beta/settings/secrets/actions
- Update these secrets:
  - `Cloudflare_API_Token` → New token value
  - `Cloudflare_Account_ID` → Verify it's still correct (e75d70dfd45bd465d93950e54cd264bd)

### 3. Fix Build Token Issue
- Check Cloudflare Pages: Workers & Pages → Pages → aurumharmony-v1-beta
- Settings → Builds & deployments
- Look for GitHub integration or build token
- Either disconnect GitHub integration (we use GitHub Actions) or regenerate build token

### 4. Test Worker Deployment
- Trigger GitHub Actions workflow: Deploy Cloudflare Worker (aurum-api)
- Verify it deploys successfully
- Check Worker is live at: https://api.ah.saffronbolt.in

## Current Token Issues
- API token permissions might be insufficient
- Build token for Pages might be stale/deleted
- Need fresh tokens with correct permissions

## Notes
- Remember: Copy token immediately when created (only shown once!)
- Token should have Zone permissions for saffronbolt.in
- We're using GitHub Actions, so don't need Cloudflare's GitHub integration

## Quick Links
- Cloudflare API Tokens: https://dash.cloudflare.com/profile/api-tokens
- GitHub Secrets: https://github.com/imvikverma/ah-v1-beta/settings/secrets/actions
- Cloudflare Pages: https://dash.cloudflare.com → Workers & Pages → Pages
- Worker Settings: https://dash.cloudflare.com/e75d70dfd45bd465d93950e54cd264bd/workers/services/view/aurum-api/production/settings

