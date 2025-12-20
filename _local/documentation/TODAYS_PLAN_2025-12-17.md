# 📋 Today's Work Plan - December 17, 2025

**Duration:** ~14-15 hours  
**Focus:** System checks → Integrity tests → Broker connectivity → Backtesting

---

## 🎯 **Phase 1: System Check (Morning) - ~2 hours**

### 1.1 Verify Session Expired Fix ✅
- [ ] Test login on v1 frontend (`https://ah.saffronbolt.in`)
- [ ] Test login on v2 frontend (`https://ah-v2.saffronbolt.in`)
- [ ] Confirm no "session expired" error for 5 minutes after login
- [ ] Verify token validation works after grace period (5+ minutes)
- [ ] Test multiple API calls immediately after login
- [ ] Check browser console for any errors

**Expected Behavior:**
- Login succeeds
- No "session expired" error for 5 minutes
- Token validation works after grace period
- API calls succeed immediately after login

---

## 🔍 **Phase 2: System Integrity Tests (Mid-Morning) - ~3 hours**

### 2.1 Backend Health Checks
- [ ] Test `/health` endpoint (v1 and v2 Workers)
- [ ] Test `/api/auth/login` endpoint
- [ ] Test `/api/auth/me` endpoint (with valid token)
- [ ] Test `/api/auth/me` endpoint (with invalid token)
- [ ] Verify D1 database connectivity
- [ ] Check JWT token generation/validation
- [ ] Test session management (create, validate, expire)

**Test Commands:**
```powershell
# Health check
curl https://api.ah.saffronbolt.in/health
curl https://api-v2.saffronbolt.in/health

# Auth endpoints
curl -X POST https://api-v2.saffronbolt.in/api/auth/login -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"test123"}'
```

### 2.2 Frontend Integrity
- [ ] Test login/logout flow (v1 and v2)
- [ ] Test admin panel access (if available)
- [ ] Test portfolio/positions display
- [ ] Test error handling and user feedback
- [ ] Test token persistence (refresh page, should stay logged in)
- [ ] Test session expiration handling

### 2.3 Database Integrity
- [ ] Verify user data consistency (v1 vs v2)
- [ ] Check session table cleanup
- [ ] Verify admin user flags
- [ ] Test database admin endpoints
- [ ] Check D1 database from Worker

---

## 🔌 **Phase 3: Broker API Connectivity (Afternoon) - ~4 hours**

### 3.1 HDFC Sky Integration
- [ ] Test broker connection/authentication
- [ ] Test order placement (paper trading mode)
- [ ] Test position tracking
- [ ] Test market data fetching
- [ ] Verify callback handling
- [ ] Test error scenarios (invalid credentials, network errors)

**Test Endpoints:**
```powershell
# Connect broker
POST /api/brokers/hdfc/connect
{
  "broker_name": "hdfc_sky",
  "api_key": "...",
  "api_secret": "..."
}

# Test order placement
POST /api/brokers/hdfc/orders

# Test position tracking
GET /api/brokers/hdfc/positions

# Test market data
GET /api/brokers/hdfc/historical?symbol=NIFTY&interval=DAY&days=30
```

### 3.2 Kotak Neo Integration
- [ ] Test TOTP/MPIN login flow
- [ ] Test order placement (paper trading mode)
- [ ] Test position tracking
- [ ] Test market data fetching
- [ ] Verify callback handling
- [ ] Test error scenarios

**Test Endpoints:**
```powershell
# TOTP login
POST /api/brokers/kotak/login/totp

# MPIN login
POST /api/brokers/kotak/login/mpin

# Test order placement
POST /api/brokers/kotak/orders

# Test position tracking
GET /api/brokers/kotak/positions
```

---

## 📊 **Phase 4: Backtesting Tests (Late Afternoon) - ~3 hours**

### 4.1 Realistic Backtest Tests
- [ ] Test `/api/backtest/realistic` endpoint
- [ ] Test with broker data (`use_broker_data=true`)
- [ ] Test with VIX simulation (fallback)
- [ ] Verify results accuracy
- [ ] Test with multiple symbols (NIFTY, BANKNIFTY)
- [ ] Test with different date ranges
- [ ] Verify performance metrics (win rate, Sharpe ratio, etc.)

**Test Command:**
```http
GET /api/backtest/realistic?use_broker_data=true&symbols=NIFTY,BANKNIFTY&days=20&exchange=NSE
Authorization: Bearer <token>
```

**Expected Response:**
- `data_source: "broker"` or `"vix_simulation"`
- `brokers_used: ["hdfc", "kotak"]` (if broker data available)
- Performance metrics (win rate, PnL, Sharpe ratio, etc.)

### 4.2 Edge Case Backtest Tests
- [ ] Test `/api/backtest/edge` endpoint
- [ ] Test with high VIX (35.0+)
- [ ] Test with extreme market conditions
- [ ] Verify edge case handling
- [ ] Test error scenarios
- [ ] Test with invalid parameters

**Test Command:**
```http
GET /api/backtest/edge?use_broker_data=true&symbols=NIFTY&days=20&vix=35.0&exchange=NSE
Authorization: Bearer <token>
```

---

## 📚 **Phase 5: Documentation Review (Evening) - ~2 hours**

### 5.1 Review Key Documents
- [ ] Review `COMPLETE_IMPLEMENTATION_SUMMARY.md`
- [ ] Review `MVP_COMPLETION_ASSESSMENT.md`
- [ ] Review `IMPLEMENTATION_STATUS.md`
- [ ] Review `PENDING_WORK_SUMMARY_2025-12-16.md`
- [ ] Review `TESTING_CHECKLIST.md`
- [ ] Review `REDESIGN_PLAN.md`

### 5.2 Update Documentation
- [ ] Update any outdated information
- [ ] Document test results
- [ ] Note any issues found
- [ ] Update pending work summary

---

## 🎯 **Success Criteria**

### Session Expired Fix:
- ✅ No "session expired" error for 5 minutes after login
- ✅ Token validation works correctly after grace period
- ✅ Multiple API calls succeed immediately after login

### System Integrity:
- ✅ All backend endpoints respond correctly
- ✅ Frontend works on both v1 and v2
- ✅ Database connectivity verified
- ✅ JWT tokens work correctly

### Broker Connectivity:
- ✅ HDFC Sky connection works
- ✅ Kotak Neo connection works
- ✅ Order placement works (paper trading)
- ✅ Position tracking works
- ✅ Market data fetching works

### Backtesting:
- ✅ Realistic backtest works with broker data
- ✅ Edge case backtest handles extreme conditions
- ✅ Performance metrics are accurate

---

## 📝 **Notes**

1. **Session Expired Fix:** Applied to both v1 and v2. Need to verify it works.
2. **Broker API:** Both HDFC Sky and Kotak Neo integrations are ready, need actual connectivity tests.
3. **Backtesting:** Endpoints are ready, need to test with real broker data and verify results.
4. **Documentation:** Review all pending work documents to understand what needs to be done next.

---

**Last Updated:** December 17, 2025  
**Status:** 🟢 In Progress

