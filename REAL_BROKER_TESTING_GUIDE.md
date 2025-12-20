# Real Broker Testing Guide

## 🎯 What We Need From You

### Option 1: Test with Onboarding Flow (Recommended)
1. **Create a test user** via signup
2. **Complete onboarding wizard**:
   - Step 1: Select broker (HDFC Sky or Kotak Neo)
   - Step 2: Enter broker API credentials:
     - **HDFC Sky**: API Key, API Secret, Token ID (optional)
     - **Kotak Neo**: Access Token, Mobile Number, Client Code
   - Step 3: UPI verification (optional for testing)
   - Step 4: KYC (optional for testing)
   - Step 5: Review & Complete

### Option 2: Manual Credential Entry
If you prefer to test without going through onboarding:
- Use `/api/brokers/connect` endpoint with credentials
- Or set environment variables (fallback)

## 📋 Broker Credentials Needed

### For HDFC Sky:
```
- HDFC_SKY_API_KEY: Your API key (Consumer Key)
- HDFC_SKY_API_SECRET: Your API secret (Consumer Secret)
- HDFC_SKY_TOKEN_ID: Request token (if available)
- HDFC_SKY_ACCESS_TOKEN: Access token (if already obtained)
```

### For Kotak Neo:
```
- KOTAK_NEO_ACCESS_TOKEN: API access token
- KOTAK_NEO_MOBILE_NUMBER: Registered mobile number
- KOTAK_NEO_CLIENT_CODE: Client code
```

## 🧪 What We'll Test

Once credentials are provided:

### 1. **Database Credential Loading** ✅
- Verify credentials are saved to database (encrypted)
- Test `get_hdfc_client(user_id)` loads from DB
- Test `get_kotak_client(user_id)` loads from DB

### 2. **Unified Snapshot with Real Data**
- Test unified snapshot endpoint with real broker
- Verify positions, balance, quotes from broker
- Check aggregation across multiple engines

### 3. **Broker API Calls**
- Test quote fetching
- Test position retrieval
- Test balance fetching
- Verify authentication works

### 4. **Orchestrator Integration**
- Test orchestrator loads broker clients from DB
- Verify prediction run uses real broker data
- Check paper trading mode for test users

## 🔒 Security Notes

- Credentials are encrypted in database
- We'll use test/demo credentials if available
- Can use paper trading mode for safe testing
- All API calls will be logged for debugging

## 📝 Test Checklist

Once you provide credentials:

- [ ] Credentials saved to database (via onboarding or API)
- [ ] Database credential loading works
- [ ] Broker client authentication successful
- [ ] Unified snapshot retrieves real data
- [ ] Positions/balance/quotes fetched correctly
- [ ] Orchestrator uses real broker data
- [ ] Test user mode uses paper trading (no real trades)

## 🚀 Ready When You Are!

Just provide:
1. **Broker choice**: HDFC Sky or Kotak Neo (or both)
2. **Credentials**: Via onboarding wizard OR manually
3. **Test mode**: Real trading or paper trading only

Then I'll run comprehensive tests and show you real numbers! 💪

