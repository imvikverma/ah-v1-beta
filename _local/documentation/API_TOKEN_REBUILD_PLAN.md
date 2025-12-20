# 🔧 Cloudflare API Token Rebuild Plan
## Complete Step-by-Step Guide (No Project Files Affected)

**Date Created:** 14/12/2024  
**Status:** Ready for Execution  
**Approach:** Complete rebuild from scratch without touching project files/folders  
**Estimated Time:** 30-45 minutes

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Pre-Flight Checklist](#pre-flight-checklist)
3. [Phase 1: Document Current State](#phase-1-document-current-state)
4. [Phase 2: Clean Up Old Setup](#phase-2-clean-up-old-setup)
5. [Phase 3: Create Fresh API Tokens](#phase-3-create-fresh-api-tokens)
6. [Phase 4: Update GitHub Secrets](#phase-4-update-github-secrets)
7. [Phase 5: Verify Cloudflare Configuration](#phase-5-verify-cloudflare-configuration)
8. [Phase 6: Test Deployments](#phase-6-test-deployments)
9. [Phase 7: Clean Up & Documentation](#phase-7-clean-up--documentation)
10. [Troubleshooting Guide](#troubleshooting-guide)
11. [Success Criteria](#success-criteria)

---

## Overview

### 🎯 Goal
Completely rebuild Cloudflare API tokens from scratch to resolve:
- Stale API tokens causing authentication errors
- Build token issues in Cloudflare Pages
- Worker deployment failures
- Missing or incorrect permissions

### ✅ What This Plan Does
- Creates fresh API tokens with correct permissions
- Updates GitHub secrets (no code changes)
- Verifies Cloudflare configuration
- Tests deployments end-to-end
- Cleans up old tokens

### ❌ What This Plan Does NOT Do
- **NO changes to project files or folders**
- **NO code modifications**
- **NO configuration file edits**
- **NO git commits**
- Only updates external services (Cloudflare Dashboard, GitHub Secrets)

### 🔐 Required Information
Before starting, ensure you have access to:
- ✅ Cloudflare Dashboard: https://dash.cloudflare.com
- ✅ GitHub Repository: https://github.com/imvikverma/ah-v1-beta
- ✅ GitHub Secrets access (admin permissions)
- ✅ Cloudflare Account ID: `e75d70dfd45bd465d93950e54cd264bd`
- ✅ Zone: `saffronbolt.in`
- ✅ Worker Name: `aurum-api`
- ✅ Pages Project: `aurumharmony-v1-beta`

---

## Pre-Flight Checklist

Before starting the rebuild, verify:

- [ ] You have admin access to Cloudflare account
- [ ] You have admin access to GitHub repository
- [ ] You can access Cloudflare Dashboard
- [ ] You can access GitHub Settings → Secrets
- [ ] You have 30-45 minutes of uninterrupted time
- [ ] You have a secure place to temporarily store new tokens (password manager, notes app)
- [ ] You understand that tokens are shown only once - must copy immediately!

**⚠️ CRITICAL:** Tokens are only displayed once when created. Have a secure place ready to copy/paste them immediately!

---

## Phase 1: Document Current State

**Time:** 5 minutes  
**Purpose:** Understand what we're working with before making changes

### Step 1.1: List Current GitHub Secrets

1. Go to: https://github.com/imvikverma/ah-v1-beta/settings/secrets/actions
2. Document what secrets exist:
   - [ ] `Cloudflare_API_Token` (exists? ✅/❌)
   - [ ] `Cloudflare_Account_ID` (exists? ✅/❌, value: `_____________`)
   - [ ] `Cloudflare_Deploy_Hook` (exists? ✅/❌)
   - [ ] `CLOUDFLARE_API_TOKEN` (exists? ✅/❌) - Note: different naming
   - [ ] Any other Cloudflare-related secrets?

**📝 Record:** Note which secrets exist and their approximate last update date (if visible)

### Step 1.2: List Current Cloudflare API Tokens

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Document existing tokens:
   - [ ] Count how many tokens exist
   - [ ] Note token names (e.g., "AurumHarmony-Worker", "GitHub Actions", etc.)
   - [ ] Note creation dates (if visible)
   - [ ] **DO NOT delete yet** - we'll do that after new ones work

**📝 Record:** List token names and approximate ages

### Step 1.3: Check Cloudflare Pages Integration

1. Go to: https://dash.cloudflare.com → **Workers & Pages** → **Pages**
2. Click on: **aurumharmony-v1-beta**
3. Go to: **Settings** → **Builds & deployments**
4. Check:
   - [ ] Is there a GitHub integration connected? (Yes/No)
   - [ ] Is there a build hook configured? (Yes/No)
   - [ ] What's the build configuration? (Note it down)
   - [ ] Any build token errors visible?

**📝 Record:** Integration status and any errors

### Step 1.4: Check Worker Settings

1. Go to: https://dash.cloudflare.com → **Workers & Pages** → **Workers**
2. Click on: **aurum-api**
3. Go to: **Settings**
4. Check:
   - [ ] Routes configured: `api.ah.saffronbolt.in` ✅/❌
   - [ ] D1 Database binding: `aurum-harmony-db` ✅/❌
   - [ ] Environment variables present? (List them)
   - [ ] Any errors or warnings?

**📝 Record:** Worker configuration status

### Step 1.5: Check DNS Configuration

1. Go to: https://dash.cloudflare.com → **DNS** → **Records**
2. For zone: **saffronbolt.in**
3. Verify:
   - [ ] `api.ah.saffronbolt.in` → Points to Worker route ✅/❌
   - [ ] `ah.saffronbolt.in` → Points to Pages ✅/❌
   - [ ] Record types are correct (CNAME/Proxy)

**📝 Record:** DNS status

---

## Phase 2: Clean Up Old Setup

**Time:** 5-10 minutes  
**Purpose:** Remove conflicting integrations that might cause issues

### Step 2.1: Disconnect Cloudflare Pages GitHub Integration (if exists)

**⚠️ Only do this if Pages has a GitHub integration connected!**

1. Go to: **Workers & Pages** → **Pages** → **aurumharmony-v1-beta**
2. Go to: **Settings** → **Builds & deployments**
3. If you see "Connected to GitHub" or similar:
   - [ ] Click **"Disconnect"** or **"Remove integration"**
   - [ ] Confirm disconnection
   - [ ] **Reason:** We use GitHub Actions for deployment, not Cloudflare's GitHub integration

**📝 Note:** This prevents "build token deleted" errors

### Step 2.2: Check Worker GitHub Integration

1. Go to: **Workers & Pages** → **Workers** → **aurum-api**
2. Go to: **Settings** → **Triggers** (or similar)
3. Check if there's a GitHub integration:
   - [ ] If yes, disconnect it (we use GitHub Actions)
   - [ ] If no, proceed

**📝 Note:** Workers typically don't have GitHub integrations, but check to be sure

### Step 2.3: Verify Build Hook (Keep This!)

1. Go to: **Pages** → **aurumharmony-v1-beta** → **Settings** → **Builds & deployments**
2. Find: **Build hook** section
3. If a build hook exists:
   - [ ] Copy the URL (we'll verify it later)
   - [ ] **DO NOT delete it** - we might use it
4. If no build hook:
   - [ ] We can create one later if needed
   - [ ] Or rely on GitHub Actions

**📝 Record:** Build hook URL (if exists)

---

## Phase 3: Create Fresh API Tokens

**Time:** 10-15 minutes  
**Purpose:** Create new API tokens with correct permissions

### Step 3.1: Create Main API Token (Workers + Pages)

This single token will handle both Workers and Pages deployments.

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click: **"Create Token"** button
3. Choose: **"Create Custom Token"** (not a template)

#### Configure Account Permissions:

- [ ] **Account** → **Workers Scripts** → **Edit** ✅
- [ ] **Account** → **Workers Routes** → **Edit** ✅
- [ ] **Account** → **Cloudflare Pages** → **Edit** ✅
- [ ] **Account** → **Account Settings** → **Read** ✅
- [ ] **Account** → **D1** → **Edit** ✅ (for D1 database access)

#### Configure Zone Permissions (for `saffronbolt.in`):

1. Click: **"Add"** under **Zone**
2. Select zone: **saffronbolt.in**
3. Add permissions:
   - [ ] **Zone** → **Zone Settings** → **Edit** ✅
   - [ ] **Zone** → **Workers Routes** → **Edit** ✅
   - [ ] **Zone** → **Zone** → **Read** ✅

#### Finalize Token:

- [ ] Token name: `AurumHarmony-Full-Deploy-14-12-2024`
- [ ] TTL: **No expiration** (or set to 1 year if preferred)
- [ ] Click: **"Continue to summary"**
- [ ] Review permissions carefully
- [ ] Click: **"Create Token"**

#### ⚠️ CRITICAL: Copy Token Immediately!

- [ ] **Copy the token NOW** - it's only shown once!
- [ ] Paste it to a secure location (password manager, notes app)
- [ ] **DO NOT close this page until you've copied it!**
- [ ] Verify you have the full token (should be ~40+ characters)

**📝 Record:** Token name and where you stored it

### Step 3.2: Verify Token Permissions (Optional but Recommended)

1. On the token list page, find your new token
2. Click on it to view details
3. Verify it shows:
   - ✅ Workers Scripts:Edit
   - ✅ Workers Routes:Edit
   - ✅ Cloudflare Pages:Edit
   - ✅ Zone permissions for saffronbolt.in

**📝 Note:** If permissions look wrong, delete this token and recreate it

---

## Phase 4: Update GitHub Secrets

**Time:** 5 minutes  
**Purpose:** Update GitHub with new API token

### Step 4.1: Update Cloudflare_API_Token Secret

1. Go to: https://github.com/imvikverma/ah-v1-beta/settings/secrets/actions
2. Find: **Cloudflare_API_Token** secret
3. Click: **"Update"** (or create if it doesn't exist)
4. Paste: Your new token from Phase 3.1
5. Click: **"Update secret"** (or "Add secret")
6. Verify: Secret shows as updated

**✅ Check:** Secret name is exactly `Cloudflare_API_Token` (case-sensitive!)

### Step 4.2: Verify Cloudflare_Account_ID Secret

1. Still on GitHub Secrets page
2. Find: **Cloudflare_Account_ID** secret
3. Check value: Should be `e75d70dfd45bd465d93950e54cd264bd`
4. If correct:
   - [ ] ✅ Leave it as is
5. If incorrect or missing:
   - [ ] Click **"Update"** or **"New repository secret"**
   - [ ] Name: `Cloudflare_Account_ID`
   - [ ] Value: `e75d70dfd45bd465d93950e54cd264bd`
   - [ ] Click **"Add secret"** or **"Update secret"**

**✅ Check:** Account ID is correct (no spaces, no extra characters)

### Step 4.3: Check Cloudflare_Deploy_Hook Secret (Optional)

1. Find: **Cloudflare_Deploy_Hook** secret
2. If it exists:
   - [ ] Verify it's still valid (we'll test later)
   - [ ] If you have the build hook URL from Phase 2.3, compare them
3. If it doesn't exist:
   - [ ] We can add it later if needed
   - [ ] Or rely on GitHub Actions Pages deployment

**📝 Note:** This is optional - GitHub Actions can deploy without it

### Step 4.4: Remove Duplicate Secrets (if any)

1. Check for: **CLOUDFLARE_API_TOKEN** (all caps, different name)
2. If it exists:
   - [ ] This is a duplicate/old naming
   - [ ] We should remove it to avoid confusion
   - [ ] Click on it → **"Delete"** → Confirm
3. Verify only these secrets exist:
   - ✅ `Cloudflare_API_Token` (correct one)
   - ✅ `Cloudflare_Account_ID`
   - ✅ `Cloudflare_Deploy_Hook` (optional)

**📝 Note:** Some workflows might use `CLOUDFLARE_API_TOKEN` - check workflows first!

### Step 4.5: Verify Workflow Secret Names

Check which secret names the workflows actually use:

1. Go to: `.github/workflows/deploy-worker.yml`
   - Uses: `secrets.Cloudflare_API_Token` ✅
   - Uses: `secrets.Cloudflare_Account_ID` ✅

2. Go to: `.github/workflows/cloudflare-deploy.yml`
   - Uses: `secrets.CLOUDFLARE_API_TOKEN` ⚠️ (different name!)
   - Uses: `secrets.CLOUDFLARE_ACCOUNT_ID` ⚠️ (different name!)

**🔧 Action Required:** We need to either:
- **Option A:** Update workflows to use consistent naming
- **Option B:** Create both secret names (duplicate values)

**For now:** Create both secret names to avoid breaking workflows:
- [ ] `Cloudflare_API_Token` → New token
- [ ] `CLOUDFLARE_API_TOKEN` → Same new token (duplicate)
- [ ] `Cloudflare_Account_ID` → Account ID
- [ ] `CLOUDFLARE_ACCOUNT_ID` → Same Account ID (duplicate)

**📝 Note:** We'll standardize this later, but for now duplicate to ensure compatibility

---

## Phase 5: Verify Cloudflare Configuration

**Time:** 5 minutes  
**Purpose:** Ensure Cloudflare settings are correct

### Step 5.1: Verify Worker Configuration

1. Go to: **Workers & Pages** → **Workers** → **aurum-api**
2. Go to: **Settings** → **Triggers** (or **Routes**)
3. Verify:
   - [ ] Route exists: `api.ah.saffronbolt.in` ✅
   - [ ] Route is active/enabled ✅
   - [ ] Zone: `saffronbolt.in` ✅

4. Go to: **Settings** → **Variables and Secrets**
5. Verify:
   - [ ] D1 Database binding: `DB` → `aurum-harmony-db` ✅
   - [ ] Environment variables are set (if any)
   - [ ] No errors or warnings

**📝 Record:** Any issues found

### Step 5.2: Verify Pages Configuration

1. Go to: **Workers & Pages** → **Pages** → **aurumharmony-v1-beta**
2. Go to: **Settings** → **Builds & deployments**
3. Verify:
   - [ ] No GitHub integration connected (we use GitHub Actions) ✅
   - [ ] Build configuration is correct
   - [ ] Custom domain: `ah.saffronbolt.in` ✅

4. Go to: **Custom domains**
5. Verify:
   - [ ] `ah.saffronbolt.in` is configured ✅
   - [ ] SSL/TLS is active ✅

**📝 Record:** Any issues found

### Step 5.3: Verify DNS Records

1. Go to: **DNS** → **Records** (for `saffronbolt.in`)
2. Verify these records exist:

   **Record 1:**
   - [ ] Type: `CNAME` or `A`
   - [ ] Name: `api` (or `api.ah`)
   - [ ] Target: Worker route or `api.ah.saffronbolt.in`
   - [ ] Proxy: Enabled (orange cloud) ✅

   **Record 2:**
   - [ ] Type: `CNAME`
   - [ ] Name: `ah` (or `@` for root)
   - [ ] Target: Pages custom domain
   - [ ] Proxy: Enabled (orange cloud) ✅

**📝 Record:** DNS configuration status

---

## Phase 6: Test Deployments

**Time:** 10-15 minutes  
**Purpose:** Verify everything works with new tokens

### Step 6.1: Test Worker Deployment

1. Go to: https://github.com/imvikverma/ah-v1-beta/actions
2. Find workflow: **"Deploy Cloudflare Worker (aurum-api)"**
3. Click: **"Run workflow"** → **"Run workflow"** (manual trigger)
4. Watch the workflow run:
   - [ ] Workflow starts ✅
   - [ ] No authentication errors ✅
   - [ ] Deployment succeeds ✅
   - [ ] Verification step passes ✅

5. Check logs for:
   - ✅ "CLOUDFLARE_API_TOKEN is set"
   - ✅ "CLOUDFLARE_ACCOUNT_ID is set"
   - ✅ "Worker deployed successfully!"
   - ❌ No "Authentication error [code: 10000]"
   - ❌ No "build token deleted" errors

**📝 Record:** Deployment status and any errors

### Step 6.2: Verify Worker is Live

1. Wait: 1-2 minutes for deployment to propagate
2. Test endpoint: https://api.ah.saffronbolt.in/health
3. Expected responses:
   - ✅ HTTP 200: Worker is working!
   - ✅ HTTP 401: Worker is working (auth required, which is expected)
   - ❌ HTTP 502/503: Worker not deployed or route issue
   - ❌ Connection refused: DNS or routing issue

**📝 Record:** Worker health check result

### Step 6.3: Test Pages Deployment

1. Go to: **GitHub Actions**
2. Find workflow: **"Deploy to Cloudflare Pages"**
3. Click: **"Run workflow"** → **"Run workflow"** (manual trigger)
4. Watch the workflow run:
   - [ ] Workflow starts ✅
   - [ ] Flutter build succeeds ✅
   - [ ] Pages deployment succeeds ✅
   - [ ] No build token errors ✅

5. Check logs for:
   - ✅ "Deploying to Cloudflare Pages"
   - ✅ "Deployment successful"
   - ❌ No "build token deleted" errors
   - ❌ No authentication errors

**📝 Record:** Pages deployment status

### Step 6.4: Verify Site is Live

1. Wait: 2-3 minutes for deployment to complete
2. Visit: https://ah.saffronbolt.in
3. Check:
   - [ ] Site loads ✅
   - [ ] No CSP errors in browser console ✅
   - [ ] Flutter app initializes ✅
   - [ ] No "Failed to fetch" errors ✅

**📝 Record:** Site status and any console errors

### Step 6.5: Test Integration (Full Stack)

1. Open: https://ah.saffronbolt.in
2. Open browser DevTools → Console
3. Try to login (or check if already logged in):
   - [ ] Login page loads ✅
   - [ ] Can submit login form ✅
   - [ ] API calls to `api.ah.saffronbolt.in` succeed ✅
   - [ ] No "Session expired" errors ✅
   - [ ] No CORS errors ✅

**📝 Record:** Integration test results

---

## Phase 7: Clean Up & Documentation

**Time:** 5 minutes  
**Purpose:** Remove old tokens and document final setup

### Step 7.1: Remove Old API Tokens

**⚠️ Only do this after confirming new tokens work!**

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. For each old token (not the new one we just created):
   - [ ] Identify it (by name, date, or last used)
   - [ ] Click on it → **"Delete"** → Confirm
   - [ ] Verify it's removed

3. Final token list should have:
   - ✅ `AurumHarmony-Full-Deploy-14-12-2024` (or your new token name)
   - ❌ No old/stale tokens

**📝 Record:** Which tokens were deleted

### Step 7.2: Document Final Setup

Update this document or create a summary:

**Final Configuration:**
- [ ] API Token Name: `_________________`
- [ ] Token Created: `14/12/2024`
- [ ] GitHub Secrets Updated: ✅
- [ ] Worker Deploys: ✅/❌
- [ ] Pages Deploys: ✅/❌
- [ ] Site Live: ✅/❌
- [ ] Integration Works: ✅/❌

**Issues Encountered:**
- [ ] List any problems and how they were resolved

**Next Steps (if any):**
- [ ] Standardize GitHub secret names in workflows
- [ ] Set up token rotation schedule
- [ ] Document token permissions for future reference

---

## Troubleshooting Guide

### Issue: "Authentication error [code: 10000]"

**Cause:** API token missing Zone permissions

**Fix:**
1. Go to Cloudflare API tokens
2. Edit your token
3. Add Zone permissions for `saffronbolt.in`:
   - Zone Settings:Edit
   - Workers Routes:Edit
4. Update GitHub secret with new token

### Issue: "The build token selected for this build has been deleted"

**Cause:** Cloudflare Pages has a GitHub integration with a stale token

**Fix:**
1. Go to Pages → Settings → Builds & deployments
2. Disconnect GitHub integration
3. Use GitHub Actions for deployment instead

### Issue: "CLOUDFLARE_API_TOKEN is not set"

**Cause:** GitHub secret name mismatch

**Fix:**
1. Check workflow file for exact secret name
2. Verify secret exists in GitHub with that exact name
3. Create/update secret with correct name

### Issue: Worker deploys but returns 502/503

**Cause:** Route configuration issue

**Fix:**
1. Check Worker routes in Cloudflare Dashboard
2. Verify DNS record points to Worker
3. Check route pattern matches domain

### Issue: Pages deploys but site doesn't load

**Cause:** DNS or custom domain issue

**Fix:**
1. Check DNS records
2. Verify custom domain in Pages settings
3. Wait for DNS propagation (up to 24 hours, usually 5-10 minutes)

---

## Success Criteria

After completing this plan, you should have:

✅ **Fresh API Token Created**
- Token has all required permissions
- Token is stored securely
- Token name is descriptive

✅ **GitHub Secrets Updated**
- `Cloudflare_API_Token` updated with new token
- `Cloudflare_Account_ID` verified correct
- All workflow-compatible secret names exist

✅ **Cloudflare Configuration Verified**
- Worker routes configured correctly
- Pages custom domain configured
- DNS records correct
- No conflicting integrations

✅ **Deployments Working**
- Worker deploys via GitHub Actions ✅
- Pages deploys via GitHub Actions ✅
- No authentication errors ✅
- No build token errors ✅

✅ **Services Live**
- Worker accessible at: https://api.ah.saffronbolt.in ✅
- Site accessible at: https://ah.saffronbolt.in ✅
- Frontend can connect to backend ✅
- Authentication works ✅

✅ **Clean Up Complete**
- Old tokens removed
- Final setup documented
- No duplicate secrets

---

## Quick Reference

### Important Links

- **Cloudflare API Tokens:** https://dash.cloudflare.com/profile/api-tokens
- **GitHub Secrets:** https://github.com/imvikverma/ah-v1-beta/settings/secrets/actions
- **Cloudflare Dashboard:** https://dash.cloudflare.com
- **Worker Settings:** https://dash.cloudflare.com/e75d70dfd45bd465d93950e54cd264bd/workers/services/view/aurum-api/production/settings
- **Pages Settings:** https://dash.cloudflare.com/e75d70dfd45bd465d93950e54cd264bd/pages/view/aurumharmony-v1-beta
- **GitHub Actions:** https://github.com/imvikverma/ah-v1-beta/actions

### Key Values

- **Account ID:** `e75d70dfd45bd465d93950e54cd264bd`
- **Zone:** `saffronbolt.in`
- **Worker:** `aurum-api`
- **Pages Project:** `aurumharmony-v1-beta`
- **Worker URL:** `https://api.ah.saffronbolt.in`
- **Site URL:** `https://ah.saffronbolt.in`

### Required Permissions Summary

**Account Permissions:**
- Workers Scripts:Edit
- Workers Routes:Edit
- Cloudflare Pages:Edit
- Account Settings:Read
- D1:Edit

**Zone Permissions (saffronbolt.in):**
- Zone Settings:Edit
- Workers Routes:Edit
- Zone:Read

---

## Notes

- ⚠️ **Tokens are shown only once** - copy immediately!
- 🔐 **Store tokens securely** - use password manager
- 📝 **Document as you go** - note any issues or changes
- ✅ **Test after each phase** - don't wait until the end
- 🧹 **Clean up old tokens** - but only after new ones work
- 🔄 **Standardize secret names** - update workflows later for consistency

---

**Last Updated:** 14/12/2024  
**Status:** Ready for Execution  
**Next Step:** Review plan with Vik, then execute Phase 1

