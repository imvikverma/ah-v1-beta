# Cloudflare Worker - Complete Fix Guide

## Quick Fix (All Steps)

Run these commands in order:

```powershell
# Step 1: Fix all issues
.\scripts\fix_worker.ps1

# Step 2: Deploy the worker
.\scripts\deploy_worker.ps1
```

## Manual Steps

### 1. Install Dependencies

```powershell
cd worker
npm install
```

### 2. Check TypeScript

```powershell
cd worker
npx tsc --noEmit
```

If there are errors, fix them before deploying.

### 3. Deploy Worker

```powershell
cd worker
wrangler deploy
```

### 4. Set Environment Variables (Optional)

In Cloudflare Dashboard:
1. Go to Workers & Pages → aurum-api
2. Settings → Variables and Secrets
3. Add these (if needed):
   - `CLOUDFLARE_DEPLOY_HOOK` - For GitHub webhook
   - `GITHUB_WEBHOOK_SECRET` - For webhook verification
   - `HDFC_CLIENT_ID` - For HDFC Sky OAuth
   - `HDFC_CLIENT_SECRET` - For HDFC Sky OAuth
   - `KOTAK_CONSUMER_KEY` - For Kotak Neo

### 5. Test Worker

```powershell
# Test health endpoint
Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/health"
```

## Common Issues & Solutions

### Issue: "Wrangler not found"
**Solution:**
```powershell
npm install -g wrangler
```

### Issue: "TypeScript errors"
**Solution:**
```powershell
cd worker
npm install
npx tsc --noEmit
# Fix any errors shown
```

### Issue: "Worker not responding"
**Solutions:**
1. Check Cloudflare Dashboard → Workers & Pages → aurum-api → Deployments
2. Look for build errors
3. Check DNS: `api.ah.saffronbolt.in` should point to the worker
4. Verify route in `wrangler.toml`

### Issue: "501 Not Implemented" errors
**This is normal!** Most endpoints return 501 because they need database access.

**Solution:** Use localhost backend for development:
- Frontend: `http://localhost:58643`
- Backend: `http://localhost:5000`
- Start with: `.\start-all.ps1` → Option 1

## What the Worker Does

✅ **Working:**
- Health check (`/health`)
- CORS handling
- GitHub webhook (`/webhook/github`) - if configured
- HDFC Sky callback (`/callback/hdfc`) - if configured
- Kotak Neo callback (`/callback/kotak`) - if configured

⚠️ **Not Implemented (Returns 501/503):**
- Authentication endpoints (need database)
- Most API endpoints (need database)

**For now, use localhost backend for full functionality.**

## Development Workflow

**Recommended:** Use localhost for development
```powershell
.\start-all.ps1
# Select Option 1 (Auto-Start Everything)
# Frontend: http://localhost:58643
# Backend: http://localhost:5000
```

**Production:** Deploy worker for webhooks/callbacks only
```powershell
.\scripts\deploy_worker.ps1
```

## Troubleshooting

### Check Worker Status
```powershell
.\scripts\diagnose_worker.ps1
```

### Check Worker Logs
1. Go to Cloudflare Dashboard
2. Workers & Pages → aurum-api
3. Click on latest deployment
4. View "Logs" tab

### Test Endpoints
```powershell
# Health check
Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/health"

# Test API endpoint (will return 501 - this is expected)
Invoke-WebRequest -Uri "https://api.ah.saffronbolt.in/api/auth/login" -Method POST
```

## Next Steps

1. **For Development:** Keep using localhost backend
2. **For Production:** Migrate Flask routes to Worker (requires database setup)
3. **For Webhooks:** Worker is ready - just configure environment variables

---

**Remember:** The worker is mostly a placeholder. For full functionality, use the localhost backend!
