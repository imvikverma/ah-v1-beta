# GitHub Webhook Setup for Real-Time Cloudflare Deployment

## Overview

Instead of polling every 30 seconds, we can use GitHub webhooks to trigger Cloudflare Pages deployments instantly when code is pushed.

## Architecture

```
GitHub Push Event → GitHub Webhook → Cloudflare Worker → Cloudflare Pages Build Hook
```

## Setup Steps

### 1. Configure Cloudflare Worker Environment Variables

In your Cloudflare Worker (`aurum-api`), add these environment variables:

```bash
# Required
CLOUDFLARE_DEPLOY_HOOK=https://api.cloudflare.com/client/v4/pages/webhooks/deploy_hooks/your-hook-id

# Optional (for security)
GITHUB_WEBHOOK_SECRET=your-github-webhook-secret
```

**To get the Cloudflare Deploy Hook:**
1. Go to Cloudflare Dashboard → Pages
2. Select your project (`ah-v1-beta`)
3. Go to Settings → Builds & deployments
4. Scroll to "Build hooks"
5. Create a new build hook or copy existing one

### 2. Deploy the Webhook Handler

The webhook handler is in `worker/src/webhook.ts`. You can either:
- Merge it into `worker/src/index.ts` as a new route
- Or deploy it as a separate Worker

**Option A: Add to existing Worker (Recommended)**

Add this route to `worker/src/index.ts`:

```typescript
// Add to routes array
{
  method: 'POST',
  path: '/webhook/github',
  handler: async (request, env) => {
    // Copy the webhook handler logic from webhook.ts
  },
}
```

**Option B: Separate Worker**

Deploy `webhook.ts` as a separate Worker with its own `wrangler.toml`.

### 3. Set Up GitHub Webhook

1. Go to your GitHub repository
2. Navigate to: **Settings** → **Webhooks** → **Add webhook**
3. Configure:
   - **Payload URL**: `https://api.ah.saffronbolt.in/webhook/github`
   - **Content type**: `application/json`
   - **Secret**: (optional) Set a secret and add it to Worker env vars as `GITHUB_WEBHOOK_SECRET`
   - **Events**: Select "Just the push event"
   - **Active**: ✅ Checked

4. Click **Add webhook**

### 4. Test the Webhook

1. Make a small change to your code
2. Commit and push to `main` branch
3. Check GitHub webhook delivery logs:
   - Go to **Settings** → **Webhooks** → Click your webhook
   - View "Recent deliveries"
   - Should show 200 OK response

4. Check Cloudflare Pages:
   - Should automatically start a new deployment
   - Check deployment logs in Cloudflare Dashboard

## Benefits

✅ **Instant deployment** - No 30-second polling delay  
✅ **Efficient** - Only triggers on actual pushes  
✅ **Reliable** - GitHub handles webhook delivery retries  
✅ **Secure** - Optional signature verification  

## Fallback

If webhook fails, the existing polling mechanism (`auto_deploy.ps1`) will still catch changes within 30 seconds.

## Troubleshooting

### Webhook not triggering
- Check GitHub webhook delivery logs for errors
- Verify Worker URL is correct: `https://api.ah.saffronbolt.in/webhook/github`
- Check Worker logs in Cloudflare Dashboard

### Deployment not starting
- Verify `CLOUDFLARE_DEPLOY_HOOK` is set correctly
- Check Cloudflare Pages build hook is active
- Review Worker response in GitHub webhook delivery logs

### Signature verification failing
- Ensure `GITHUB_WEBHOOK_SECRET` matches the secret in GitHub webhook settings
- Check that signature header is being sent correctly

## Security Notes

- **Always use HTTPS** for webhook URLs
- **Enable signature verification** in production
- **Limit webhook to push events only**
- **Monitor webhook deliveries** for suspicious activity

