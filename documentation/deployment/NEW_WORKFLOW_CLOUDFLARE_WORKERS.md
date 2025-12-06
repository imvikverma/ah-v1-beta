# New Workflow: Cloudflare Workers + Custom Domain

**Status:** 📋 Planned  
**Date:** 2025-11-29  
**Goal:** Move from ngrok/localhost to production-ready Cloudflare Workers backend

## Current vs. New Architecture

### Current Setup
- **Frontend:** Cloudflare Pages (`aurumharmony-v1-beta.pages.dev`)
- **Backend:** Flask on localhost:5000 (via ngrok for external access)
- **Development:** Local development with ngrok tunneling

### New Setup (Planned)
- **Frontend:** Cloudflare Pages (`ah.saffronbolt.in`)
- **Backend:** Cloudflare Workers (`api.ah.saffronbolt.in`)
- **Development:** Direct deployment, no ngrok needed

## Live URLs (Target State)

| Purpose                | URL                               | Status |
|------------------------|-----------------------------------|--------|
| Corporate site         | https://www.saffronbolt.in        | ✅ Live |
| AurumHarmony Beta App  | https://ah.saffronbolt.in         | ✅ Live |
| API / Broker callbacks | https://api.ah.saffronbolt.in     | 📋 Planned |

## Required DNS Configuration

| Host         | Type  | Target                                    | Status |
|--------------|-------|-------------------------------------------|--------|
| ah           | CNAME | aurumharmony-v1-beta.pages.dev            | ✅ Done |
| aurumharmony | CNAME | aurumharmony-v1-beta.pages.dev            | ✅ Done |
| api          | CNAME | your-worker-name.youraccount.workers.dev  | 📋 Pending |

**Note:** The `api` CNAME will be added after Cloudflare Worker creation.

## Daily Workflow (Target State)

### Project Structure
```
/aurumharmony-v1-beta/     → Frontend (Cloudflare Pages)
/aurum-api-worker/         → Backend (Cloudflare Workers)
```

### Frontend Deployment
```bash
# From aurumharmony-v1-beta directory
git add .
git commit -m "feat: xyz"
git push origin main
# → Live in ~60 seconds at https://ah.saffronbolt.in
```

### Backend Deployment
```bash
# From aurum-api-worker directory
cd aurum-api-worker
wrangler deploy
# → Live instantly at https://api.ah.saffronbolt.in
```

### Sanity Check
```bash
curl https://api.ah.saffronbolt.in/health
```

## Migration Steps

### Phase 1: Frontend (✅ Complete)
- [x] Custom domain configured (`ah.saffronbolt.in`)
- [x] DNS records set up
- [x] Cloudflare Pages connected

### Phase 2: Backend (📋 Pending)
- [ ] Create Cloudflare Worker project
- [ ] Migrate Flask routes to Worker handlers
- [ ] Set up Worker environment variables
- [ ] Configure CORS for `ah.saffronbolt.in`
- [ ] Deploy Worker
- [ ] Add `api` CNAME record
- [ ] Update frontend API endpoints to use `api.ah.saffronbolt.in`
- [ ] Test broker callbacks (HDFC Sky, Kotak Neo)

### Phase 3: Cleanup (📋 Pending)
- [ ] Remove ngrok dependencies
- [ ] Update documentation
- [ ] Update deployment scripts
- [ ] Archive old ngrok setup files

## Benefits

1. **No ngrok needed** - Direct production deployment
2. **No localhost** - Everything runs in the cloud
3. **Custom domain** - Professional branding
4. **Faster** - Cloudflare's edge network
5. **Scalable** - Workers auto-scale
6. **Cost-effective** - Free tier covers most use cases

## Backend API Endpoints (To Migrate)

### Authentication
- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/auth/me`

### Brokers
- `GET /api/brokers`
- `POST /api/brokers/connect`
- `GET /api/brokers/{id}/status`

### Trading
- `POST /api/trades/execute`
- `GET /api/trades/history`

### Admin
- `GET /api/admin/users`
- `POST /api/admin/users/{id}/tier`

## Notes

- This workflow eliminates the need for ngrok in production
- Development can still use localhost for faster iteration
- Cloudflare Workers support Python via Pyodide or JavaScript/TypeScript
- Consider using Cloudflare Durable Objects for stateful data

---

**Next Steps:** Create Cloudflare Worker project and begin migration.

