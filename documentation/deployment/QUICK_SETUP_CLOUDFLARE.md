# 🚀 Quick Cloudflare Setup (5 Minutes)

## What You Need

1. **Cloudflare Account ID**: `e75d70dfd45bd465d93950e54cd264bd` ✅ (You have this)
2. **Cloudflare API Token**: Need to create (see below)

## Step 1: Get API Token (2 minutes)

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click **"Create Token"**
3. Use template: **"Edit Cloudflare Workers"**
4. Set:
   - Token name: `GitHub Actions`
   - Account: Select your account (ID: `e75d70dfd45bd465d93950e54cd264bd`)
5. Click **"Create Token"**
6. **COPY THE TOKEN** (you won't see it again!)

## Step 2: Add to GitHub (1 minute)

1. Go to: https://github.com/imvikverma/aurumharmony-v1-beta/settings/secrets/actions
2. Click **"New repository secret"**
3. Add:
   - Name: `CLOUDFLARE_ACCOUNT_ID`
   - Value: `e75d70dfd45bd465d93950e54cd264bd`
4. Click **"New repository secret"** again
5. Add:
   - Name: `CLOUDFLARE_API_TOKEN`
   - Value: (paste the token from Step 1)

## Step 3: Test (2 minutes)

1. Go to: https://github.com/imvikverma/aurumharmony-v1-beta/actions
2. Click **"Deploy to Cloudflare Pages"**
3. Click **"Run workflow"** → **"Run workflow"**
4. Watch it deploy! 🎉

## That's It!

Your workflows are already configured. Once you add the secrets, automatic deployment will work!

**Need help?** See `docs/setup/CLOUDFLARE_COMPLETE_SETUP.md` for detailed instructions.

