# Custom Domain Setup - saffronbolt.in

**Status:** ✅ Completed  
**Date:** 2025-11-29

## Goal
Link custom domain `ah.saffronbolt.in` to AurumHarmony Beta app on Cloudflare Pages.

## URLs
- **Production:** https://ah.saffronbolt.in
- **Optional:** https://aurumharmony.saffronbolt.in (same app)

## DNS Configuration (BigRock)

### CNAME Records
| Host Name       | Type  | Value / Target                        | TTL     |
|-----------------|-------|---------------------------------------|---------|
| ah              | CNAME | aurumharmony-v1-beta.pages.dev        | 1 Hour  |
| aurumharmony    | CNAME | aurumharmony-v1-beta.pages.dev        | 1 Hour  |

**Note:** These DNS records are already configured and should not be modified.

## Cloudflare Pages Configuration

### Step 1: Add Custom Domain
1. Go to Cloudflare Dashboard → Pages → `aurumharmony-v1-beta`
2. Navigate to **Custom domains**
3. Click **Add a domain**
4. Enter `ah.saffronbolt.in`
5. Optionally add `aurumharmony.saffronbolt.in`
6. Choose **"My DNS provider"** → Continue → Done

**Status:** ✅ Already configured

### Step 2: GitHub Repository Settings
1. Go to Repository → Settings → Pages
2. Under **Custom domain**, enter `ah.saffronbolt.in`
3. Click **Save**
4. Enable **"Enforce HTTPS"**

**Status:** ✅ Already configured (waiting for green checkmark)

## Result
✅ https://ah.saffronbolt.in is now live, fast, HTTPS-secured, and branded.

## Verification
- [ ] DNS propagation complete (check with `nslookup ah.saffronbolt.in`)
- [ ] HTTPS certificate active (green lock in browser)
- [ ] App loads correctly at custom domain
- [ ] GitHub Pages shows green checkmark for custom domain

---

**Last Updated:** 2025-11-29

