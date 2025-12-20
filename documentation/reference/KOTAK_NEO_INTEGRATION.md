# Kotak Neo API Integration Guide

**Status:** ✅ Implemented  
**Date:** 2025-12-06

## Overview

Kotak Neo API integration with TOTP-based authentication and full trading capabilities.

## Architecture

### Components

1. **`api/kotak_neo.py`** - Core API client class (`KotakNeoAPI`)
2. **`aurum_harmony/brokers/kotak_neo.py`** - Flask routes and service layer
3. **Registered in:** `aurum_harmony/master_codebase/Master_AurumHarmony_261125.py`

## Authentication Flow

Kotak Neo uses a 3-step TOTP-based authentication:

### Step 1: TOTP Login
```http
POST /api/brokers/kotak/login/totp
Content-Type: application/json

{
  "user_id": "user123",
  "access_token": "api_access_token_from_neo_app",
  "mobile_number": "+91XXXXXXXXXX",
  "client_code": "CLIENT_CODE",
  "totp": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "TOTP login successful",
  "data": {
    "view_token": "view_jwt_token",
    "view_sid": "view_session_id",
    "kType": "View"
  }
}
```

### Step 2: MPIN Validation
```http
POST /api/brokers/kotak/login/mpin
Content-Type: application/json

{
  "user_id": "user123",
  "mpin": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "MPIN validation successful",
  "data": {
    "trade_token": "trade_jwt_token",
    "trade_sid": "trade_session_id",
    "base_url": "https://cis.kotaksecurities.com",
    "kType": "Trade"
  }
}
```

## API Endpoints

### Orders

#### Place Order
```http
POST /api/brokers/kotak/orders/place
Content-Type: application/json

{
  "user_id": "user123",
  "symbol": "RELIANCE",
  "exchange": "nse_cm",
  "quantity": 1,
  "order_type": "MKT",
  "price": 0,
  "transaction_type": "B",
  "product_type": "CNC",
  "validity": "DAY"
}
```

**Parameters:**
- `symbol`: Stock symbol (e.g., "RELIANCE")
- `exchange`: Exchange code (default: "nse_cm")
- `quantity`: Order quantity
- `order_type`: "MKT" (market), "LMT" (limit)
- `price`: Price (required for limit orders)
- `transaction_type`: "B" (buy) or "S" (sell)
- `product_type`: "CNC" (cash), "MIS" (intraday), "NRML" (normal)
- `validity`: "DAY", "IOC", "GTC"

#### Modify Order
```http
POST /api/brokers/kotak/orders/modify
Content-Type: application/json

{
  "user_id": "user123",
  "order_no": "ORDER123",
  "quantity": 2,
  "price": 2500.0,
  "order_type": "LMT"
}
```

#### Cancel Order
```http
POST /api/brokers/kotak/orders/cancel
Content-Type: application/json

{
  "user_id": "user123",
  "order_no": "ORDER123"
}
```

### Reports

#### Get Order Book
```http
GET /api/brokers/kotak/orders?user_id=user123
```

#### Get Trade Book
```http
GET /api/brokers/kotak/trades?user_id=user123
```

#### Get Positions
```http
GET /api/brokers/kotak/positions?user_id=user123
```

#### Get Holdings
```http
GET /api/brokers/kotak/holdings?user_id=user123
```

### Quotes

#### Get Quotes
```http
GET /api/brokers/kotak/quotes?user_id=user123&exchange=nse_cm&symbol_code=26000
```

### Status

#### Check Authentication Status
```http
GET /api/brokers/kotak/status?user_id=user123
```

## Usage Example

### Python Client

```python
from api.kotak_neo import KotakNeoAPI

# Initialize client
client = KotakNeoAPI(
    access_token="your_api_access_token",
    mobile_number="+91XXXXXXXXXX",
    client_code="CLIENT_CODE"
)

# Step 1: Login with TOTP
result = client.login_with_totp("123456")
print(f"View token: {result['token']}")

# Step 2: Validate MPIN
result = client.validate_mpin("123456")
print(f"Trade token: {result['token']}")
print(f"Base URL: {result['baseUrl']}")

# Step 3: Place order
order = client.place_order(
    symbol="RELIANCE",
    exchange="nse_cm",
    quantity=1,
    order_type="MKT",
    transaction_type="B"
)
print(f"Order placed: {order}")

# Get positions
positions = client.get_positions()
print(f"Positions: {positions}")
```

### cURL Examples

#### TOTP Login
```bash
curl -X POST http://localhost:5000/api/brokers/kotak/login/totp \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "access_token": "your_access_token",
    "mobile_number": "+91XXXXXXXXXX",
    "client_code": "CLIENT_CODE",
    "totp": "123456"
  }'
```

#### Place Order
```bash
curl -X POST http://localhost:5000/api/brokers/kotak/orders/place \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "symbol": "RELIANCE",
    "exchange": "nse_cm",
    "quantity": 1,
    "order_type": "MKT",
    "transaction_type": "B"
  }'
```

## Error Handling

Common error codes:
- `401`: Invalid credentials/TOTP/MPIN
- `424`: Dependency failure
- `1006`: Invalid Exchange
- `1007`: Invalid Symbol
- `1009`: Invalid Quantity
- `1005`: Internal Error

## Security Notes

1. **TOTP**: Ensure device time is synced for TOTP generation
2. **Token Storage**: Currently stored in memory (use Redis/database in production)
3. **Token Expiry**: Tokens expire after 24 hours (configurable)
4. **Access Token**: Store API access token securely (from NEO App)

## Setup Requirements

1. **TOTP Registration** (one-time):
   - Go to API Dashboard → TOTP Registration
   - Verify mobile, OTP, client code
   - Scan QR with Google/Microsoft Authenticator
   - Enter TOTP → Registered

2. **API Access Token**:
   - From NEO App → Invest → Trade API → Create app
   - Copy token (pass in Authorization header)

3. **Environment Variables** (optional):
   - Store credentials in `.env` file
   - Access via `os.getenv()` in production

## Integration Status

✅ Core API client implemented  
✅ Flask routes implemented  
✅ Blueprint registered in main app  
✅ All trading operations supported  
✅ Reports and positions APIs implemented  
✅ Quotes API implemented  

## Next Steps

- [ ] Add database persistence for tokens
- [ ] Implement Redis session storage
- [ ] Add websocket support for real-time feeds
- [ ] Add error retry logic
- [ ] Add rate limiting
- [ ] Add comprehensive logging

---

**Last Updated:** 2025-12-06

