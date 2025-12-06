
### Frontend (Cloudflare Pages)
- Repo: https://github.com/imvikverma/aurumharmony-v1-beta
- Deploy: Automatic on `git push origin main`
- Custom domains: `ah.saffronbolt.in` + `aurumharmony.saffronbolt.in`
- Status: **Active + SSL enabled** (green everywhere)

### Backend API (Cloudflare Worker)
- Worker name: `aurum-api`
- URL: https://api.ah.saffronbolt.in
- Health check: https://api.ah.saffronbolt.in/health → “AurumHarmony API v1 – Running”
- Custom domain bound: **Done**
- Secrets to add (when you get the keys):
- `HDFC_CLIENT_ID`
- `HDFC_CLIENT_SECRET`
- `KOTAK_CONSUMER_KEY`

### What Cursor Must Do From Now On (Daily Workflow)

1. **Frontend changes** (the app itself)
 ```bash
 # In aurumharmony-v1-beta folder
 npm run dev                    # local preview
 git add .
 git commit -m "feat: xyz"
 git push origin main           # deploys instantly to https://ah.saffronbolt.in