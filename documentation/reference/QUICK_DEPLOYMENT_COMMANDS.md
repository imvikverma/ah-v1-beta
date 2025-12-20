# Quick Deployment Commands

**Last Updated:** 2025-11-29

## One-Click Deployment Commands

### Frontend (Cloudflare Pages)
```bash
# From project root
git add .
git commit -m "feat: your changes"
git push origin main
# → Live in ~60 seconds at https://ah.saffronbolt.in
```

### Backend (Cloudflare Workers - Planned)
```bash
cd aurum-api-worker
wrangler deploy
# → Live instantly at https://api.ah.saffronbolt.in
```

### Sanity Check
```bash
curl https://api.ah.saffronbolt.in/health
```

## Current Deployment Method

### Using PowerShell Script
```powershell
# From project root
.\zzz-quick-access\start-all.ps1
# Select option 6: Deploy to Cloudflare Pages
```

### Manual Deployment
```powershell
# From project root
.\scripts\deploy_cloudflare.ps1
```

## Notes

- Frontend deployment is automatic via GitHub Actions when pushing to `main`
- Cloudflare Pages auto-deploys from `docs/` directory
- Backend Worker deployment is planned (not yet implemented)
- Current backend runs on localhost:5000 (Flask) with ngrok for external access

---

**See Also:**
- `documentation/deployment/NEW_WORKFLOW_CLOUDFLARE_WORKERS.md` - Future workflow
- `documentation/deployment/CUSTOM_DOMAIN_SETUP.md` - Domain configuration

