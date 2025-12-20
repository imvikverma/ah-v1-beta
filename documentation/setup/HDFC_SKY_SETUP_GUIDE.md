# HDFC Sky API Setup Guide - Step by Step

**Complete guide to get your HDFC Sky API credentials and connect to AurumHarmony**

Based on: [HDFC Sky API Documentation](https://developer.hdfcsky.com/sky-docs/docs/intro)

---

## 📋 What You'll Need

Before starting, make sure you have:
- ✅ HDFC Sky trading account (active)
- ✅ Access to HDFC Sky developer portal
- ✅ A registered redirect URI (for OAuth callback)

---

## Step 1: Get Your API Credentials

### 1.1 Access HDFC Sky Developer Portal
1. Go to **https://developer.hdfcsky.com**
2. Log in with your HDFC Sky credentials
3. Navigate to **"My Apps"** or **"Applications"** section

### 1.2 Create/Select Application
1. If you haven't created an app yet, click **"Create App"** or **"New Application"**
2. Give your app a name (e.g., "AurumHarmony Trading")
3. **Register a Redirect URI:**
   - This is where HDFC Sky will redirect after OAuth
   - Example: `https://your-domain.com/callback` or `http://localhost:5000/callback`
   - **Important:** This must match exactly in OAuth flow

### 1.3 Get API Key and Secret
1. After creating the app, you'll see:
   - **API Key** (also called Client ID)
   - **API Secret** (also called Client Secret)
2. **Copy both immediately** - you may not see the secret again!
3. **Save them securely**

**📝 Write them down:**
- API Key: `_________________`
- API Secret: `_________________`

---

## Step 2: OAuth Authentication Flow

HDFC Sky uses OAuth 2.0 for authentication:

### 2.1 Get Request Token (One-Time Setup)

**Option A: Using Browser (Recommended)**
1. Open this URL in your browser (replace with your API key):
   ```
   https://developer.hdfcsky.com/oauth/authorize?api_key=YOUR_API_KEY&redirect_uri=https://aurumharmony-v1-beta.pages.dev/callback/hdfc
   ```
   Or use our script:
   ```powershell
   .\scripts\brokers\get_hdfc_request_token.ps1
   ```
2. Log in with your HDFC Sky credentials
3. Authorize the application
4. You'll be redirected to: `https://aurumharmony-v1-beta.pages.dev/callback/hdfc?request_token=YOUR_TOKEN`
5. **Copy the request_token from the URL** (it will be displayed on the success page)

**Option B: Using Our Script**
```powershell
.\scripts\brokers\get_hdfc_request_token.ps1
```
This will guide you through the OAuth flow.

### 2.2 Exchange Request Token for Access Token

Once you have the `request_token`, exchange it for an `access_token`:

**Using our script:**
```powershell
.\scripts\brokers\setup_hdfc_sky.ps1
```

**Or manually:**
```python
from api.hdfc_sky_api import HDFCSkyAPI

client = HDFCSkyAPI(api_key="your_key", api_secret="your_secret")
result = client.get_access_token(request_token="your_request_token")
print(f"Access Token: {result['access_token']}")
```

---

## Step 3: Store Credentials Securely

### 3.1 Add to `.env` File

Add these lines to your `.env` file:

```env
# HDFC Sky API Credentials
HDFC_SKY_API_KEY=your_api_key_here
HDFC_SKY_API_SECRET=your_api_secret_here
HDFC_SKY_ACCESS_TOKEN=your_access_token_here
HDFC_SKY_REFRESH_TOKEN=your_refresh_token_here
```

**Replace:**
- `your_api_key_here` with your API Key
- `your_api_secret_here` with your API Secret
- `your_access_token_here` with your Access Token (after OAuth)
- `your_refresh_token_here` with your Refresh Token (after OAuth)

---

## Step 4: Test Your Connection

Run the test script:

```powershell
python scripts/brokers/test_hdfc_connection.py
```

**Expected output:**
```
✅ OAuth successful!
✅ Access Token obtained!
✅ Connection Test Passed!
```

---

## 🔄 Token Refresh

Access tokens expire after 24 hours. The system will automatically:
- Check token expiry
- Use refresh token to get new access token
- Update stored tokens

**No manual intervention needed!**

---

## 📖 API Endpoints

### Orders
- **Place Order:** `POST /oapi/v1/orders`
- **Modify Order:** `PUT /oapi/v1/orders/{order_id}`
- **Cancel Order:** `DELETE /oapi/v1/orders/{order_id}`

### Reports
- **Order Book:** `GET /oapi/v1/orders`
- **Trade Book:** `GET /oapi/v1/trades`

### Positions & Holdings
- **Positions:** `GET /oapi/v1/positions`
- **Holdings:** `GET /oapi/v1/holdings`

### Quotes
- **Get Quotes:** `GET /oapi/v1/quotes?symbol={SYMBOL}&exchange={EXCHANGE}`

---

## 🆘 Troubleshooting

### "Invalid API Key"
- Double-check your API key
- Make sure there are no extra spaces
- Verify it's active in the developer portal

### "Invalid Redirect URI"
- Redirect URI must match exactly what you registered
- Check for `http://` vs `https://`
- Check for trailing slashes

### "Request Token Expired"
- Request tokens expire quickly (usually 5-10 minutes)
- Get a fresh request token and try again

### "Access Token Expired"
- Use the refresh token to get a new access token
- Or complete OAuth flow again

---

## ✅ Checklist

- [ ] API Key obtained from developer portal
- [ ] API Secret obtained from developer portal
- [ ] Redirect URI registered
- [ ] OAuth flow completed
- [ ] Request token obtained
- [ ] Access token obtained
- [ ] Credentials saved in `.env`
- [ ] Connection test passed

---

## 🚀 Next Steps

After setup:
1. ✅ Test connection
2. ✅ Integrate into trading system
3. ✅ Use for live data paper trading

---

**For detailed API documentation, visit:** https://developer.hdfcsky.com/sky-docs/docs/intro

