# Broker Integration Test Guide

## 🎯 Overview

This guide helps you test the Unified Snapshot System with real broker data from HDFC Sky and Kotak Neo.

## ✅ Pre-Flight Checklist

- [ ] Backend is running (`.\start-all.ps1`)
- [ ] `.env` file exists with broker credentials
- [ ] HDFC Sky credentials configured (optional)
- [ ] Kotak Neo credentials configured (optional)
- [ ] Frontend is accessible (for getting auth token)

## 🚀 Quick Test

Run the master test script:

```powershell
.\scripts\run_broker_tests.ps1
```

This will:
1. Check your setup
2. Test individual brokers
3. Test unified snapshot health
4. Run full integration test

## 📋 Step-by-Step Testing

### 1. Setup Check

```powershell
.\scripts\setup_broker_test_env.ps1
```

This verifies your `.env` file has broker credentials.

### 2. Test Individual Brokers

**HDFC Sky:**
```powershell
python scripts/brokers/test_hdfc_connection.py
```

**Kotak Neo:**
```powershell
python scripts/brokers/test_kotak_connection.py
```

**Note:** Kotak Neo requires interactive TOTP + MPIN authentication.

### 3. Test Unified Snapshot Health

```powershell
.\scripts\test_unified_snapshot.ps1
```

This tests the health endpoint (no auth required).

### 4. Test Full Integration

**Get Auth Token:**
1. Login via frontend
2. Open browser DevTools → Application → Local Storage
3. Find `auth_token` or `jwt_token`
4. Copy the token value

**Run Test:**
```powershell
$env:AURUM_TEST_TOKEN='your_token_here'
.\scripts\test_broker_integration.ps1
```

## 🔍 What to Look For

### Successful Test Results

✅ **Health Endpoint:**
- Shows configured engines
- Shows available engines
- No errors

✅ **Unified Snapshot:**
- Returns aggregated positions
- Returns aggregated balance
- Shows engine breakdown
- Summary stats present

✅ **Frontend:**
- Dashboard shows aggregated balance
- Trade screen shows positions from all engines
- No "Session expired" errors

### Common Issues

❌ **"No engines available"**
- **Cause:** Broker credentials not configured or not authenticated
- **Fix:** Check `.env` file, authenticate brokers

❌ **"Session expired"**
- **Cause:** Token expired or invalid
- **Fix:** Login again, get new token

❌ **"Backend not running"**
- **Cause:** Backend not started
- **Fix:** Run `.\start-all.ps1`

❌ **"Kotak authentication failed"**
- **Cause:** Wrong TOTP/MPIN or expired session
- **Fix:** Re-authenticate via frontend or test script

## 📊 Expected Output

### Health Endpoint Response
```json
{
  "success": true,
  "status": {
    "total_engines": 5,
    "engines": {
      "HDFC_SKY_NSE": {"initialized": true, "available": true},
      "HDFC_SKY_BSE": {"initialized": true, "available": true},
      "KOTAK_NEO_NSE": {"initialized": true, "available": false},
      "KOTAK_NEO_BSE": {"initialized": true, "available": false},
      "PAPER_TRADING": {"initialized": true, "available": true}
    }
  }
}
```

### Unified Snapshot Response
```json
{
  "success": true,
  "snapshot": {
    "available_engines": 3,
    "total_engines": 5,
    "all_positions": [...],
    "aggregated_balance": {
      "available": 100000.0,
      "total_equity": 100000.0,
      "margin_used": 0.0
    },
    "summary": {
      "total_positions": 0,
      "total_exposure": 0.0,
      "total_unrealized_pnl": 0.0,
      "nse_positions": 0,
      "bse_positions": 0
    }
  }
}
```

## 🎓 Understanding the Results

### Engine Status
- **Initialized:** Adapter created successfully
- **Available:** Adapter authenticated and ready to use

### Position Aggregation
- Positions from all available engines are merged
- Same symbol+exchange from multiple engines are deduplicated
- Quantities are aggregated, prices use weighted averages

### Balance Aggregation
- Balances from all engines are summed
- Available + Margin Used = Total Equity

## 🔄 Next Steps After Testing

1. **Verify Frontend Integration:**
   - Check Dashboard shows aggregated data
   - Check Trade screen shows positions from all engines

2. **Test Orchestrator:**
   - Run orchestrator: `POST /api/orchestrator/run`
   - Verify it uses unified snapshot for risk checks

3. **Monitor Health:**
   - Set up monitoring for `/api/unified-snapshot/health`
   - Alert on engine failures

4. **Production Deployment:**
   - Ensure all broker credentials are secure
   - Set up proper error handling and logging
   - Configure retry logic for failed engines

## 📚 Related Documentation

- `UNIFIED_SNAPSHOT_SYSTEM.md` - Architecture details
- `QUICK_START_BROKER_TEST.md` - Quick reference
- `Final Implementation Guide Ver 11.md` - Holy Grail docs
- `rules.md` - Operational rules

## 🆘 Troubleshooting

See `QUICK_START_BROKER_TEST.md` for detailed troubleshooting steps.

