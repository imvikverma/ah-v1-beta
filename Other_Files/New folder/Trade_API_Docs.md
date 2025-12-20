Complete & Up-to-Date Documentation Summary for Automation Integration

Prepared exclusively for the AurumHarmony core team – Golden Guardrails + 15-min AI Strategy Switch ready

---

## 1. SBI Securities (SBICAP Securities) Trade API

| Item                    | Details |
|-------------------------|--------|
| Public Docs Availability| Very limited – mostly behind client login |
| Cost                    | Free for clients (only standard brokerage) |
| Best For                | Basic automation, margin calculations |
| Not Ideal For           | Ultra-low latency or heavy websocket usage |
| Approval Needed         | Yes – email support@sbisecurities.in with client ID |

### Key Features
- REST-based (no native websocket)
- Live quotes, order placement, positions, historical data (tick level up to 7 years)
- Margin calculator API very useful for VIX-based scaling

### Important Endpoints
- Place Order → `POST https://api.sbisecurities.in/trade/order/place`
- Order Book → `GET https://api.sbisecurities.in/trade/order/book`
- Positions → `GET https://api.sbisecurities.in/trade/positions`

### Sample Python Order (Community Verified)
```python
import requests

headers = {
    "Authorization": "Bearer your_session_token",
    "X-API-Key": "your_api_key"
}

payload = {
    "symbol": "BANKNIFTY24DECFUT",
    "exchange": "NSE",
    "qty": 15,
    "price": 48000,
    "side": "BUY",
    "order_type": "MARKET"
}

r = requests.post("https://api.sbisecurities.in/trade/order/place", json=payload, headers=headers)
print(r.json())