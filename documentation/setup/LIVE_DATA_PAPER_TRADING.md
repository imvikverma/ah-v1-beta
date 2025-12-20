# Live Data Paper Trading Setup

**Use real-time market data from Kotak Neo for paper trading tests!**

---

## 🎯 What This Does

- ✅ **Fetches live prices** from Kotak Neo API (real-time market data)
- ✅ **Executes trades in paper mode** (no real money at risk)
- ✅ **Perfect for testing** with actual market conditions
- ✅ **No account funding needed** - uses paper balance

---

## 🚀 Quick Start

### Step 1: Test the Integration

Run the test script:

```powershell
python scripts/brokers/test_live_data_paper_trading.py
```

**What it does:**
1. Loads your Kotak Neo credentials
2. Authenticates (you'll enter TOTP and MPIN)
3. Fetches live prices for NIFTY50, BANKNIFTY
4. Places a test paper order
5. Shows statistics

---

## 📊 How It Works

### Architecture

```
┌─────────────────┐
│  Kotak Neo API  │ ← Fetches real-time market data
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ LiveDataPaperAdapter    │ ← Uses live prices
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Paper Trading Execution  │ ← Executes in paper mode
└─────────────────────────┘
```

### Supported Symbols

Currently mapped symbols:
- **NIFTY50** → NSE Futures & Options (code: 26000)
- **BANKNIFTY** → NSE Futures & Options (code: 26009)
- **SENSEX** → BSE Futures & Options (code: 1)

**Note:** More symbols can be added to the mapping as needed.

---

## 🔧 Integration

### Using in Your Code

```python
from api.kotak_neo import KotakNeoAPI
from aurum_harmony.engines.trade_execution.live_data_paper_adapter import LiveDataPaperAdapter

# Initialize Kotak Neo client (authenticated)
kotak_client = KotakNeoAPI(...)
kotak_client.login_with_totp(totp)
kotak_client.validate_mpin(mpin)

# Create live data paper adapter
paper_adapter = LiveDataPaperAdapter(
    kotak_client=kotak_client,
    initial_balance=100000.0  # Starting paper balance
)

# Place orders (uses live prices, paper execution)
order = Order(symbol="NIFTY50", side=OrderSide.BUY, quantity=1.0)
result = paper_adapter.place_order(order)
```

---

## 📈 Features

### Live Price Fetching
- Fetches real-time prices from Kotak Neo
- Caches prices for 5 seconds (reduces API calls)
- Falls back to simulated prices if live data unavailable

### Paper Execution
- All trades execute in paper mode
- No real money at risk
- Tracks balance, positions, P&L

### Thread-Safe
- Safe for concurrent operations
- Lock-protected for multi-threaded trading

---

## 🧪 Testing

### Test Script

```powershell
python scripts/brokers/test_live_data_paper_trading.py
```

**Expected Output:**
```
✅ TOTP login successful
✅ MPIN validation successful
✅ Adapter created
✅ NIFTY50: ₹20,123.45 (Live from Kotak Neo)
✅ Order filled at ₹20,123.45
✅ Live Data Paper Trading Test Complete!
```

---

## ⚙️ Configuration

### Symbol Mapping

To add more symbols, edit:
`aurum_harmony/engines/trade_execution/live_data_paper_adapter.py`

Add to `SYMBOL_MAPPING`:
```python
SYMBOL_MAPPING = {
    "NIFTY50": {"exchange": "nse_fo", "symbol_code": "26000"},
    "BANKNIFTY": {"exchange": "nse_fo", "symbol_code": "26009"},
    "SENSEX": {"exchange": "bse_fo", "symbol_code": "1"},
    # Add more symbols here
}
```

### Price Cache Duration

Default: 5 seconds
- Adjust in `_get_live_price()` method
- Change `if age < 5:` to your preferred duration

---

## 🆘 Troubleshooting

### "Live price unavailable"
- Check Kotak Neo authentication
- Verify symbol mapping exists
- Check API response format (may need adjustment)

### "Invalid price format"
- Kotak Neo API response format may have changed
- Check `_get_live_price()` parsing logic
- Add logging to see actual response

### "Symbol not found in mapping"
- Add symbol to `SYMBOL_MAPPING`
- Or use fallback to simulated prices

---

## 📝 Notes

- **API Rate Limits:** Price cache reduces API calls (5-second cache)
- **Market Hours:** Live prices only available during market hours
- **Fallback:** System automatically falls back to simulated prices if live data unavailable
- **No Real Money:** All trades are paper trades, no real funds used

---

## ✅ Benefits

1. **Real Market Conditions** - Test with actual market prices
2. **No Risk** - Paper trading means no real money
3. **Realistic Testing** - See how strategies perform with live data
4. **No Funding Needed** - Test without funding your account

---

**Perfect for testing your trading strategies with real market data!** 🚀

