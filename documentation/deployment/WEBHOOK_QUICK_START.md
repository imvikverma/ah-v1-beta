# GitHub Webhook Quick Start

## What This Does

Replaces the 30-second polling mechanism with **instant webhook-based deployment**:

- ✅ **Instant**: Deploys immediately when you push to GitHub
- ✅ **Efficient**: No polling overhead
- ✅ **Reliable**: GitHub handles retries automatically

## Setup (5 minutes)

### Step 1: Get Cloudflare Deploy Hook

1. Go to: https://dash.cloudflare.com
2. Navigate: **Pages** → **ah-v1-beta** → **Settings** → **Builds & deployments**
3. Scroll to **Build hooks**
4. Copy the hook URL (or create new one)

### Step 2: Add to Worker Environment

```bash
# Using Wrangler CLI
wrangler secret put CLOUDFLARE_DEPLOY_HOOK
# Paste the hook URL when prompted

# Optional: Add GitHub webhook secret for security
wrangler secret put GITHUB_WEBHOOK_SECRET
# Enter a random secret (you'll use this in GitHub)
```

Or via Cloudflare Dashboard:
1. Go to **Workers & Pages** → **aurum-api** → **Settings** → **Variables**
2. Add `CLOUDFLARE_DEPLOY_HOOK` with your hook URL
3. (Optional) Add `GITHUB_WEBHOOK_SECRET` with a random secret

### Step 3: Deploy Updated Worker

```bash
cd worker
wrangler deploy
```

### Step 4: Configure GitHub Webhook

1. Go to your GitHub repo: **Settings** → **Webhooks** → **Add webhook**
2. Configure:
   - **Payload URL**: `https://api.ah.saffronbolt.in/webhook/github`
   - **Content type**: `application/json`
   - **Secret**: (if you set `GITHUB_WEBHOOK_SECRET`, use the same value)
   - **Events**: Select "Just the push event"
   - **Active**: ✅ Checked
3. Click **Add webhook**

### Step 5: Test

1. Make a small change (e.g., add a comment)
2. Commit and push:
   ```bash
   git add .
   git commit -m "test: webhook deployment"
   git push origin main
   ```
3. Check:
   - GitHub webhook delivery (should show 200 OK)
   - Cloudflare Pages (should start new deployment)

## How It Works

```
You push to GitHub
    ↓
GitHub sends webhook to Worker
    ↓
Worker verifies signature (if configured)
    ↓
Worker checks if relevant files changed
    ↓
Worker triggers Cloudflare Pages build hook
    ↓
Cloudflare Pages starts deployment
```

## Fallback

The existing `auto_deploy.ps1` polling script will still work as a fallback if webhooks fail.

## Troubleshooting

**Webhook not working?**
- Check GitHub webhook delivery logs for errors
- Verify Worker URL: `https://api.ah.saffronbolt.in/webhook/github`
- Check Worker logs in Cloudflare Dashboard

**Deployment not starting?**
- Verify `CLOUDFLARE_DEPLOY_HOOK` is set correctly
- Check Cloudflare Pages build hook is active
- Review Worker response in GitHub webhook delivery

## Benefits Over Polling

| Polling (Current) | Webhooks (New) |
|-------------------|----------------|
| 30-second delay | Instant |
| Constant CPU usage | Event-driven |
| May miss rapid changes | Never misses |
| Manual trigger needed | Automatic |

