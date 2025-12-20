# Kotak Neo API Summary (Prep for Integration)

This is a clean, structured summary of the Kotak Neo API documentation (from Kotak Neo API Documentation.docx).  
Key focus: Login flow, orders, reports, quotes, websocket.  
All endpoints are HTTPS. Use English queries for any tool calls if needed.

### 1. Getting Started & Authentication
- **TOTP Registration** (one-time):
  - On API Dashboard → TOTP Registration.
  - Verify mobile, OTP, client code.
  - Scan QR with Google/Microsoft Authenticator.
  - Enter TOTP → Registered.

- **API Access Token**: From NEO App → Invest → Trade API → Create app → Copy token (pass in Authorization header for login).

- **Login Flow** (3 steps, TOTP-based):
  1. **Login with TOTP** (get view token/sid):
     - POST https://mis.kotaksecurities.com/login/1.0/tradeApiLogin
     - Headers: Authorization: <access_token>, neo-fin-key: neotradeapi, Content-Type: application/json
     - Body: { "mobileNumber": "+91XXXXXXXXXX", "ucc": "<client_code>", "totp": "<6_digit_totp>" }
     - Response: { "data": { "token": "view_jwt", "sid": "view_sid", "rid": "...", "kType": "View", ... } }

  2. **Validate MPIN** (get trade token/sid/baseUrl):
     - POST https://mis.kotaksecurities.com/login/1.0/tradeApiValidate
     - Headers: Authorization: <access_token>, neo-fin-key: neotradeapi, sid: <view_sid>, Auth: <view_token>, Content-Type: application/json
     - Body: { "mpin": "<6_digit_mpin>" }
     - Response: { "data": { "token": "trade_jwt", "sid": "trade_sid", "baseUrl": "https://cis.kotaksecurities.com", "kType": "Trade", ... } }

- **Post-Login**: Use baseUrl for all APIs. Headers: Auth: <trade_token>, Sid: <trade_sid>, neo-fin-key: neotradeapi (most calls).

### 2. Instruments
- Scripmaster Files: GET <baseUrl>/script-details/1.0/masterscrip/file-paths (Authorization only, no neo-fin-key/Auth/Sid).

### 3. Orders
- Bodies: application/x-www-form-urlencoded with jData=JSON string.
- Common jData fields: am: "NO", dq: "0", es: "nse_cm", mp: "0", pc: "CNC", pf: "N", pr: "0", pt: "MKT", qt: "1", rt: "DAY", tp: "0", ts: "SYMBOL-EQ", tt: "B" (buy/sell).

- **Place Order**: POST <baseUrl>/quick/order/rule/ms/place
- **Modify Order**: POST <baseUrl>/quick/order/vr/modify (add "no": "<orderNo>" in jData)
- **Cancel Order**: POST <baseUrl>/quick/order/cancel jData={"on":"<orderNo>","am":"NO"}
- **Exit Cover**: POST <baseUrl>/quick/order/co/exit jData={"on":"<orderNo>","am":"NO"}
- **Exit Bracket**: POST <baseUrl>/quick/order/bo/exit jData={"on":"<orderNo>","am":"NO"}

### 4. Order Report APIs
- **Order Book**: GET <baseUrl>/quick/user/orders
- **Order History**: POST <baseUrl>/quick/order/history jData={"nOrdNo":"<orderNo>"}
- **Trade Book**: GET <baseUrl>/quick/user/trades

### 5. Positions
- **Positions**: GET <baseUrl>/quick/user/positions

### 6. Holdings
- **Holdings**: GET <baseUrl>/portfolio/v1/holdings

### 7. Limits
- Not detailed in provided content (truncated). Assume GET <baseUrl>/quick/user/limits or similar – check full doc if needed.

### 8. Margins
- Not detailed (truncated). Likely GET/POST for margin calculation.

### 9. Quotes
- **Quotes**: GET <baseUrl>/script-details/1.0/quotes/neosymbol/nse_cm|26000/all (Authorization only, no neo-fin-key/Auth/Sid)

### 10. NEO Websocket
- Not fully detailed (truncated). Likely for real-time feeds (quotes, orders). Use baseUrl + websocket endpoint.

### 11. Troubleshooting & FAQs
- Common Errors: 401 Invalid credentials/TOTP/MPIN, 424 Dependency failure, 1006 Invalid Exchange, 1007 Invalid Symbol, 1009 Invalid Quantity, 1005 Internal Error.
- Tips: Sync device time for TOTP, retry transients, validate symbols with scrip master.

### 12. cURL Examples (Ready to Use)
- Login: As above.
- Orders: As above (place, modify, cancel).
- Reports: As above.
- Quotes: As above.

### Notes for Integration (Worker Code)
- Use fetch for POST/GET.
- Store tokens in KV (viewToken, tradeToken, sid, baseUrl).
- Headers: Always Content-Type: application/json or urlencoded as needed.
- For Orders: Use FormData or urlencode jData.
- Rotate keys if leaked (e.g., access_token).

This prep is ready for Worker code. If GitHub is green, say “GitHub green” for the full code.