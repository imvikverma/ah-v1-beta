# 02 – CURSOR PERMANENT WORKFLOW (Dec 2025 onward)  
No ngrok · No localhost · No .pages.dev · Only saffronbolt.in

### Live URLs (use forever)
| Purpose                | URL                               |
|------------------------|-----------------------------------|
| Corporate site         | https://www.saffronbolt.in        |
| AurumHarmony Beta App  | https://ah.saffronbolt.in         |
| API / Broker callbacks | https://api.ah.saffronbolt.in     |

### Required DNS (already added in BigRock)
| Host         | Type  | Target                                    |
|--------------|-------|-------------------------------------------|
| ah           | CNAME | aurumharmony-v1-beta.pages.dev            |
| aurumharmony | CNAME | aurumharmony-v1-beta.pages.dev            |
| api          | CNAME | your-worker-name.youraccount.workers.dev  (add after Worker creation)|

### Daily Cursor workflow
1. Open two folders side-by-side
   - `/aurumharmony-v1-beta/`     → Frontend (Pages)
   - `/aurum-api-worker/`        → Backend (Worker)

2. Frontend changes
   ```bash
   npm run dev                 # local test (optional)
   git add . && git commit -m "feat: xyz" && git push origin main
   # → live in ~60 sec at https://ah.saffronbolt.in