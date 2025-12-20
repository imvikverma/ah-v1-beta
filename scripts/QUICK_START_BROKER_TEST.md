# 🚀 Quick Start: Testing Unified Snapshot with Real Brokers

## Step 1: Check Your Setup

```powershell
.\scripts\setup_broker_test_env.ps1
```

This will check if your `.env` file has broker credentials configured.

## Step 2: Configure Broker Credentials

### HDFC Sky
Add to `.env`:
```
HDFC_SKY_API_KEY=your_api_key
HDFC_SKY_API_SECRET=your_api_secret
HDFC_SKY_TOKEN_ID=your_token_id
HDFC_SKY_ACCESS_TOKEN=your_access_token
```

### Kotak Neo
Add to `.env`:
```
KOTAK_NEO_ACCESS_TOKEN=your_access_token
KOTAK_NEO_MOBILE_NUMBER=+91XXXXXXXXXX
KOTAK_NEO_CLIENT_CODE=your_client_code
```

## Step 3: Test Individual Brokers

### Test HDFC Sky
```powershell
python scripts/brokers/test_hdfc_connection.py
```

### Test Kotak Neo
```powershell
python scripts/brokers/test_kotak_connection.py
```

**Note:** Kotak Neo requires TOTP + MPIN authentication. The script will guide you through it.

## Step 4: Start Backend

```powershell
.\start-all.ps1
# Select option to start backend only
```

## Step 5: Test Unified Snapshot System

### Option A: Quick Health Check (No Auth Required)
```powershell
.\scripts\test_unified_snapshot.ps1
```

### Option B: Full Integration Test (Requires Auth)
```powershell
# First, login via frontend and get your token
# Then set it:
$env:AURUM_TEST_TOKEN='your_jwt_token'

# Run comprehensive test:
.\scripts\test_broker_integration.ps1
```

### Option C: Manual API Test
```powershell
# Health check (no auth)
curl http://localhost:5000/api/unified-snapshot/health

# Full snapshot (requires auth)
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:5000/api/unified-snapshot
```

## Step 6: Verify Frontend

1. Open frontend: `http://localhost:58643` (or your Flutter web port)
2. Login
3. Go to Dashboard - should show aggregated balance from all engines
4. Go to Trade screen - should show positions from all engines

## Troubleshooting

### "No engines available"
- Check broker credentials in `.env`
- Verify broker APIs are authenticated
- Check backend logs for errors

### "Session expired"
- Token might have expired
- Login again and get a new token
- Check JWT_SECRET_KEY matches between frontend/backend

### "Backend not running"
- Start backend: `.\start-all.ps1`
- Check port 5000 is available
- Check backend logs for errors

### "Kotak Neo authentication failed"
- Make sure TOTP is current (6-digit code from authenticator app)
- MPIN must be correct
- Check mobile number format: `+91XXXXXXXXXX`

## Expected Results

When everything is working:
- ✅ Health endpoint shows all configured engines
- ✅ Unified snapshot returns aggregated positions and balance
- ✅ Frontend Dashboard shows live capital from all engines
- ✅ Frontend Trade screen shows positions from all engines
- ✅ Orchestrator uses unified snapshot for risk checks

## Next Steps

Once testing is successful:
1. Run orchestrator to test auto-trading with unified snapshot
2. Monitor engine availability via health endpoint
3. Check frontend shows real-time aggregated data
4. Verify position deduplication works correctly

