# Repository Deployment Guide

## ✅ Repositories to Deploy

Only push these repositories:

1. **ah-v1-beta** - Main v1 codebase
   - GitHub: `https://github.com/imvikverma/ah-v1-beta`
   - Contains: Flask backend, admin panel, documentation

2. **aurumharmony-v2-frontend** - v2 Frontend
   - GitHub: `https://github.com/imvikverma/aurumharmony-v2-frontend`
   - Contains: Flutter frontend for v2

3. **aurumharmony-v2** - v2 Full Stack
   - GitHub: `https://github.com/imvikverma/aurumharmony-v2`
   - Contains: Complete v2 codebase

4. **aurum-api-v2-production** - v2 Worker API
   - GitHub: `https://github.com/imvikverma/aurum-api-v2-production`
   - Contains: Cloudflare Worker API (aurum-api-v2)
   - Deploys to: `api-v2.saffronbolt.in`

## ❌ Repositories to Remove/Archive

**DO NOT push these repositories:**

- ❌ `aurum-api-legacy` - Legacy Worker (deprecated)
- ❌ `aurum-api-production-legacy` - Legacy production Worker (deprecated)

These should be archived or deleted from GitHub.

## 📋 Admin Functionality

**Admin functionality is built into the main Worker:**

- Admin endpoints are part of `aurum-api-v2-production` Worker
- Admin panel is deployed via Cloudflare Pages from `ah-v1-beta` repo
- Admin domain: `admin-v2.saffronbolt.in`
- **No separate admin-only Worker repository exists**

Admin endpoints in Worker:
- `/api/admin/users` - User management
- `/api/admin/db/*` - Database admin endpoints
- Requires `is_admin = true` in user record

## 🚀 Deployment Workflow

1. **Main Codebase** → Push to `ah-v1-beta`
2. **v2 Frontend** → Push to `aurumharmony-v2-frontend`
3. **v2 Full Stack** → Push to `aurumharmony-v2`
4. **v2 Worker** → Push to `aurum-api-v2-production`

## ⚠️ Important Notes

- All Worker references use `aurum-api-v2` (not legacy versions)
- Worker domain: `api-v2.saffronbolt.in`
- Admin panel is part of main repo, not a separate Worker
- Legacy Workers should be removed from Cloudflare Dashboard

