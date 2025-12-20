# Cloudflare CSP (Content Security Policy) Warnings

## About the Warnings

The CSP warnings you're seeing are **report-only** warnings from Cloudflare Pages. They don't block functionality, just report potential policy violations.

## Common Warnings

1. **Cloudflare Insights** - Analytics script
2. **Stripe.js** - Payment processing (if you add payments later)
3. **CORS errors** - Cross-origin requests

## Solutions

### Option 1: Ignore (Recommended for now)
These are report-only warnings and won't affect functionality. You can safely ignore them during development.

### Option 2: Configure CSP in Cloudflare
1. Go to Cloudflare Dashboard → Pages → Your Project
2. Settings → Builds & deployments
3. Add custom headers or configure CSP

### Option 3: Add _headers file (if needed)
Create `docs/_headers` file:
```
/*
  Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.cloudflare.com https://js.stripe.com; style-src 'self' 'unsafe-inline';
```

## Note
These warnings are normal for Cloudflare Pages deployments and don't affect your app's functionality.

