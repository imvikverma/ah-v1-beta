# 01 – Link saffronbolt.in to AurumHarmony Beta (Cloudflare Pages)

Goal:  
https://ah.saffronbolt.in  →  your live beta app  
https://aurumharmony.saffronbolt.in  →  same app (optional)

### Step 1: CNAME records (already done in BigRock – never touch again)
| Host Name       | Type  | Value / Target                        | TTL     |
|-----------------|-------|---------------------------------------|---------|
| ah              | CNAME | aurumharmony-v1-beta.pages.dev        | 1 Hour  |
| aurumharmony    | CNAME | aurumharmony-v1-beta.pages.dev        | 1 Hour  |

### Step 2: Cloudflare Pages custom domain (already done)
Dashboard → Pages → aurumharmony-v1-beta → Custom domains  
→ Add `ah.saffronbolt.in` (and optionally `aurumharmony.saffronbolt.in`)  
→ Choose “My DNS provider” → Continue → Done

### Step 3: GitHub repo custom domain (already done, waiting for green check)
Repo → Settings → Pages → Custom domain  
→ Enter `ah.saffronbolt.in` → Save → Tick “Enforce HTTPS”

Result:  
https://ah.saffronbolt.in is now live, fast, HTTPS-secured, and branded forever.