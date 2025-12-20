# Broker-Integrated Backtesting Integration Guide

## Overview

This document describes the broker-integrated backtesting system that uses real historical market data from:
- **HDFC Sky** - Primary source for historical candlestick data
- **Kotak Neo** - Secondary source for quotes and recent data
- **NSE/BSE** - Fallback source for indices (via Option Chain API)

## Architecture

### Components Created

1. **`broker_data_fetcher.py`** - Unified data fetcher for all broker sources
2. **`broker_backtest.py`** - Backtesting engine that uses broker data
3. **`backtesting/routes.py`** - Flask routes with broker integration

### Data Flow

```
User Request → Backtest Endpoint → Get User Brokers → Fetch Historical Data → Run Backtest → Return Results
```

## Integration Steps

### 1. Register Backtest Blueprint

In your main Flask app (`Master_AurumHarmony_261125.py` or `app.py`):

```python
from aurum_harmony.backtesting.routes import backtest_bp

# Register blueprint
app.register_blueprint(backtest_bp)
```

### 2. Update Existing Endpoints (Optional)

The new routes are at `/api/backtest/realistic` and `/api/backtest/edge`.

You can either:
- **Option A**: Replace existing `/backtest/realistic` and `/backtest/edge` with broker-integrated versions
- **Option B**: Keep both (old endpoints for VIX simulation, new for broker data)

### 3. User Broker Connection

Users need to connect their brokers first:
- **HDFC Sky**: `/api/brokers/hdfc/connect` or OAuth flow
- **Kotak Neo**: `/api/brokers/kotak/login/totp` then `/api/brokers/kotak/login/mpin`

## API Usage

### Realistic Backtest with Broker Data

```http
GET /api/backtest/realistic?use_broker_data=true&symbols=NIFTY,BANKNIFTY&days=20&exchange=NSE
Authorization: Bearer <token>
```

**Query Parameters:**
- `use_broker_data` (bool, default: true) - Use broker data if available
- `symbols` (string, default: "NIFTY,BANKNIFTY") - Comma-separated symbols
- `days` (int, default: 20) - Number of days to backtest
- `exchange` (string, default: "NSE") - Exchange code (NSE or BSE)

**Response:**
```json
{
  "result": {
    "strategy_name": "Realistic Broker Data Test",
    "total_trades": 100,
    "winning_trades": 65,
    "losing_trades": 35,
    "total_pnl": 15000.50,
    "win_rate": 0.65,
    "sharpe_ratio": 1.2,
    "max_drawdown": 5000.0,
    "final_balance": 25000.50,
    "initial_balance": 10000.0,
    "return_percentage": 150.0,
    "avg_win": 230.77,
    "avg_loss": -142.86,
    "profit_factor": 1.61,
    "message": "Backtest completed using real broker data from hdfc, kotak"
  },
  "data_source": "broker",
  "brokers_used": ["hdfc", "kotak"]
}
```

### Edge Case Backtest

```http
GET /api/backtest/edge?use_broker_data=true&symbols=NIFTY&days=20&vix=35.0&exchange=NSE
Authorization: Bearer <token>
```

**Additional Parameters:**
- `vix` (float, default: 35.0) - VIX level for edge case testing

## Data Source Priority

1. **HDFC Sky** (if authenticated)
   - Best for historical candlestick data
   - Supports DAY, MINUTE, WEEK, MONTH intervals
   - Works for both NSE and BSE

2. **Kotak Neo** (if authenticated)
   - Good for current quotes
   - Limited historical data (may need symbol code mapping)

3. **NSE/BSE Option Chain** (fallback)
   - Free, no authentication needed
   - Only for indices (NIFTY, BANKNIFTY, SENSEX)
   - Provides current underlying price

## Supported Symbols

### Indices (All Sources)
- NIFTY / NIFTY50
- BANKNIFTY
- SENSEX (BSE)

### Stocks (HDFC/Kotak Only)
- Any NSE/BSE listed stock (requires broker authentication)

## Fallback Behavior

If broker data is unavailable:
- Falls back to VIX-based simulation (existing `run_realistic_tests` / `run_edge_tests`)
- Returns `data_source: "vix_simulation"` in response
- Still provides useful backtesting results

## Error Handling

- **No broker connection**: Falls back to VIX simulation
- **Broker authentication failed**: Falls back to next available source
- **No data for symbol**: Logs warning, continues with available symbols
- **Network errors**: Retries with fallback sources

## Future Enhancements

1. **Historical Data Caching**: Cache broker data to reduce API calls
2. **Symbol Code Mapping**: Complete Kotak Neo symbol code mapping
3. **Multiple Strategy Support**: Allow users to select/upload strategies
4. **Real-time Backtesting**: Stream live data for real-time backtesting
5. **Performance Optimization**: Parallel data fetching from multiple sources

## Testing

Test the integration:

```bash
# 1. Connect HDFC Sky
POST /api/brokers/hdfc/connect
{
  "broker_name": "hdfc_sky",
  "api_key": "...",
  "api_secret": "..."
}

# 2. Run backtest with broker data
GET /api/backtest/realistic?use_broker_data=true&symbols=NIFTY&days=30
Authorization: Bearer <token>
```

## Notes

- Broker data provides more accurate backtesting than VIX simulation
- Historical data availability depends on broker API limits
- Some brokers may have rate limits - implement caching for production
- NSE/BSE Option Chain is free but limited to indices only

