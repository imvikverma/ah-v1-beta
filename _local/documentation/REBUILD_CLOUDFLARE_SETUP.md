# Rebuild Cloudflare Setup - Step by Step

**Date:** 2025-12-14  
**Status:** Ready to Execute  
**Approach:** Complete rebuild from ground up

## 🎯 Goal
Completely rebuild the Cloudflare API token and deployment setup from scratch, ensuring everything is configured correctly.

## 📋 Step-by-Step Rebuild Plan

### Phase 1: Clean Up Old Setup

#### Step 1.1: Document Current State
- [ ] List all current GitHub secrets related to Cloudflare
- [ ] Note current Cloudflare API tokens (for reference)
- [ ] Check Cloudflare Pages integration status
- [ ] Check Worker GitHub integration status

#### Step 1.2: Remove Old Integrations
- [ ] Disconnect GitHub integration from Cloudflare Pages (if exists)
- [ ] Disconnect GitHub integration from Worker (if exists)
- [ ] Remove any stale webhooks
- [ ] Clean up old API tokens (after new ones are working)

### Phase 2: Create Fresh API Tokens

#### Step 2.1: Create Main API Token (for Workers)
- [ ] Go to: https://dash.cloudflare.com/profile/api-tokens
- [ ] Click "Create Token"
- [ ] Use "Edit Cloudflare Workers" template OR create custom:
  - **Account Permissions:**
    - `Workers Scripts:Edit` ✅
    - `Workers Routes:Edit` ✅
    - `Account:Read` ✅
    - `D1:Edit` ✅ (if using D1 database)
  - **Zone Permissions (saffronbolt.in):**
    - `Zone:Edit` ✅
    - `Zone:Workers Routes:Edit` ✅
    - `Zone:Read` ✅
- [ ] **Copy token immediately** (only shown once!)
- [ ] Name it: `AurumHarmony-Worker-Deploy-2025-12-14`
- [ ] Save token value securely

#### Step 2.2: Create Pages API Token (if needed)
- [ ] Go to: https://dash.cloudflare.com/profile/api-tokens
- [ ] Click "Create Token"
- [ ] Use "Edit Cloudflare Pages" template OR create custom:
  - **Account Permissions:**
    - `Cloudflare Pages:Edit` ✅
    - `Account:Read` ✅
  - **Zone Permissions (saffronbolt.in):**
    - `Zone:Read` ✅
- [ ] **Copy token immediately**
- [ ] Name it: `AurumHarmony-Pages-Deploy-2025-12-14`
- [ ] Save token value securely

### Phase 3: Update GitHub Secrets

#### Step 3.1: Update Worker Secrets
- [ ] Go to: https://github.com/imvikverma/ah-v1-beta/settings/secrets/actions
- [ ] Update `Cloudflare_API_Token` with new Worker token
- [ ] Verify `Cloudflare_Account_ID` is correct: `e75d70dfd45bd465d93950e54cd264bd`
- [ ] If `Cloudflare_Account_ID` is wrong, update it

#### Step 3.2: Update Pages Secrets (if using separate token)
- [ ] Update `CLOUDFLARE_API_TOKEN` (if exists) with new Pages token
- [ ] Or use same token for both (simpler)

#### Step 3.3: Verify All Secrets
- [ ] `Cloudflare_API_Token` ✅
- [ ] `Cloudflare_Account_ID` ✅
- [ ] `Cloudflare_Deploy_Hook` (verify it's still valid)

### Phase 4: Verify Cloudflare Configuration

#### Step 4.1: Check Worker Configuration
- [ ] Go to: Workers & Pages → aurum-api → Settings
- [ ] Verify routes are correct: `api.ah.saffronbolt.in`
- [ ] Check D1 database binding is correct
- [ ] Verify environment variables (if any)

#### Step 4.2: Check Pages Configuration
- [ ] Go to: Workers & Pages → Pages → aurumharmony-v1-beta
- [ ] Settings → Builds & deployments
- [ ] Verify no GitHub integration (we use GitHub Actions)
- [ ] Check build configuration
- [ ] Verify custom domain: `ah.saffronbolt.in`

#### Step 4.3: Check DNS Settings
- [ ] Go to: DNS → Records
- [ ] Verify `api.ah.saffronbolt.in` → Worker route
- [ ] Verify `ah.saffronbolt.in` → Pages
- [ ] Check CNAME records are correct

### Phase 5: Test Deployments

#### Step 5.1: Test Worker Deployment
- [ ] Go to: https://github.com/imvikverma/ah-v1-beta/actions
- [ ] Find "Deploy Cloudflare Worker (aurum-api)"
- [ ] Click "Run workflow" → "Run workflow"
- [ ] Watch for errors
- [ ] Verify deployment succeeds
- [ ] Test Worker endpoint: https://api.ah.saffronbolt.in/health

#### Step 5.2: Test Pages Deployment
- [ ] Trigger Pages deployment (via GitHub Actions or manual)
- [ ] Verify build succeeds
- [ ] Test site: https://ah.saffronbolt.in
- [ ] Check for CSP errors in console

#### Step 5.3: Test Integration
- [ ] Login to app
- [ ] Test API calls to Worker
- [ ] Verify authentication works
- [ ] Check for any errors

### Phase 6: Clean Up

#### Step 6.1: Remove Old Tokens
- [ ] Go to: https://dash.cloudflare.com/profile/api-tokens
- [ ] Delete old/stale tokens (after confirming new ones work)
- [ ] Keep only the new tokens

#### Step 6.2: Document Final Setup
- [ ] Update documentation with new token names
- [ ] Note any changes made
- [ ] Document any issues encountered

## 🔍 Verification Checklist

After rebuild, verify:
- [ ] Worker deploys via GitHub Actions ✅
- [ ] Worker is accessible at: https://api.ah.saffronbolt.in ✅
- [ ] Pages deploys successfully ✅
- [ ] Site is accessible at: https://ah.saffronbolt.in ✅
- [ ] No build token errors ✅
- [ ] No authentication errors ✅
- [ ] All API endpoints work ✅
- [ ] Frontend can connect to Worker ✅

## 🚨 Common Issues to Watch For

1. **Token Permissions:**
   - Make sure Zone permissions include `saffronbolt.in`
   - Workers Routes:Edit is critical

2. **Secret Names:**
   - GitHub secrets are case-sensitive
   - `Cloudflare_API_Token` (not `CLOUDFLARE_API_TOKEN`)

3. **Build Token Errors:**
   - Usually from Pages GitHub integration
   - Disconnect it if using GitHub Actions

4. **DNS Issues:**
   - Verify CNAME records point correctly
   - Wait for DNS propagation

## 📝 Notes

- **Token Security:** Copy tokens immediately - they're only shown once!
- **Account ID:** Should be: `e75d70dfd45bd465d93950e54cd264bd`
- **Zone:** `saffronbolt.in`
- **Worker:** `aurum-api`
- **Pages Project:** `aurumharmony-v1-beta`

## 🎯 Success Criteria

✅ All deployments work via GitHub Actions  
✅ No build token errors  
✅ Worker and Pages both accessible  
✅ Frontend can connect to backend  
✅ Authentication works  
✅ All API endpoints functional  

---

**Ready to execute tomorrow!** 🚀

