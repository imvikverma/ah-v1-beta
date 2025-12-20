# AurumHarmony Quick Reference

## 🚀 Current Setup: Development with Ngrok

### Start Development Environment

```powershell
# Option 1: Master launcher (recommended)
.\zzz-quick-access\start-all.ps1
# Select: 3 (Backend + Ngrok)

# Option 2: Individual scripts
.\scripts\start_backend.ps1      # Terminal 1: Flask backend
.\scripts\start_ngrok.ps1        # Terminal 2: Ngrok tunnel (connects to Cloud Endpoint)
```

### Your Current Ngrok URL

**URL:** `https://top-manatee-busy.ngrok-free.app`

**Endpoints:**
- OAuth Callback: `https://top-manatee-busy.ngrok-free.app/callback`
- Webhooks: `https://top-manatee-busy.ngrok-free.app/broker/{broker}/webhook`

### Ngrok Configuration

**Cloud Endpoint:**
- ID: `ep_369nmRSDOInIpM3gG0wFAhnqBzV`
- Settings: https://dashboard.ngrok.com/endpoints/cloud/ep_369nmRSDOInIpM3gG0wFAhnqBzV/settings
- Internal URL: `https://default.internal` (used by agent endpoint)

**API Key:**
- ID: `ak_367YEZKNQ4gVLJKCqi2TYKuBFc1`
- Add to `.env`: Run `.\scripts\setup\add_ngrok_api_key.ps1`
- Not needed for current setup (dashboard is fine)

### Configure Ngrok Cloud Endpoint

1. **Go to:** https://dashboard.ngrok.com/endpoints/cloud/ep_369nmRSDOInIpM3gG0wFAhnqBzV/settings
2. **Set Backend URL:** `http://localhost:5000` (if not already set)
3. **Check Traffic Policy:** Should forward to `https://default.internal`

### Update Broker Portals

**HDFC Sky:**
- Portal: https://developer.hdfcsky.com
- Redirect URL: `https://top-manatee-busy.ngrok-free.app/callback`

**Kotak Neo:**
- Postback URL: `https://top-manatee-busy.ngrok-free.app/broker/kotak/webhook`

### Environment Variables

Add to `.env` (optional, for API automation):
```env
NGROK_API_KEY=ak_367YEZKNQ4gVLJKCqi2TYKuBFc1
```

Or run: `.\scripts\setup\add_ngrok_api_key.ps1`

## 📦 Production Setup: Kubernetes (Ready When Needed)

### Quick Deploy (When Ready)

```powershell
# 1. Build Docker image
docker build -f k8s/Dockerfile -t aurumharmony/backend:latest .

# 2. Push to registry
docker tag aurumharmony/backend:latest YOUR_ACCOUNT.dkr.ecr.ap-south-1.amazonaws.com/aurumharmony/backend:latest
docker push YOUR_ACCOUNT.dkr.ecr.ap-south-1.amazonaws.com/aurumharmony/backend:latest

# 3. Deploy to Kubernetes
kubectl apply -f k8s/
```

**Full Guide:** See `k8s/README.md`

## 📚 Documentation

- **Development Setup:** `docs/setup/NGROK_ENDPOINT_SETUP.md`
- **Cloud Endpoint Connection:** `docs/setup/CLOUD_ENDPOINT_CONNECTION.md`
- **API Key Usage:** `docs/setup/NGROK_API_KEY_USAGE.md`
- **Kubernetes Guide:** `k8s/README.md`
- **Migration Path:** `docs/setup/DEVELOPMENT_VS_PRODUCTION.md`
- **Comparison:** `docs/setup/NGROK_VS_PRODUCTION.md`

## 🔧 Common Tasks

### Test OAuth Callback
```powershell
# Visit in browser:
https://top-manatee-busy.ngrok-free.app/callback?request_token=test123
```

### Test Webhook
```powershell
$body = @{ order_id = "TEST123"; status = "EXECUTED" } | ConvertTo-Json
Invoke-RestMethod -Uri "https://top-manatee-busy.ngrok-free.app/broker/hdfc/webhook" `
    -Method Post -Body $body -ContentType "application/json"
```

### Add API Key to .env
```powershell
.\scripts\setup\add_ngrok_api_key.ps1
```

### Update Ngrok URL in Scripts
If ngrok URL changes, update:
- `scripts/brokers/get_hdfc_request_token.ps1`
- `scripts/brokers/get_fresh_hdfc_token.ps1`
- `scripts/brokers/test_hdfc_oauth_endpoints.ps1`

## ✅ Status Checklist

### Development (Active)
- [x] Ngrok cloud endpoint configured
- [x] Agent endpoint connects to Cloud Endpoint
- [x] Scripts updated with URL
- [x] Flask backend ready
- [ ] HDFC Sky redirect URL updated
- [ ] OAuth flow tested
- [ ] Webhooks tested
- [ ] API key added to .env (optional)

### Production (Ready)
- [x] Kubernetes manifests created
- [x] Dockerfile ready
- [x] Auto-scaling configured
- [x] AWS Mumbai setup
- [ ] Docker image built
- [ ] Secrets configured
- [ ] Deployed to EKS

---

**Current Focus:** Development with ngrok  
**Production:** Ready when you are! 🚀
