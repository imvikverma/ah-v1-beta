# AurumHarmony - Index Options Trading System

## Core Concept

**AurumHarmony is a Handsfree Intraday Options Trading System** that trades **Index Options** using Option Chain data and other metrics.

## Key Points

### What We Trade
- ✅ **Index Options** (Call Options - CE, Put Options - PE)
- ✅ **Only 3 Indices**: NIFTY50, BANKNIFTY, SENSEX
- ✅ **Low Premium, High Frequency** trades
- ✅ **Intraday Only** (no delivery)

### What We DON'T Trade
- ❌ Individual stocks (RELIANCE, TCS, INFY, etc.)
- ❌ Underlying indices themselves
- ❌ Futures contracts
- ❌ Delivery trades

## Option Symbol Format

When placing trades, option symbols should include:
- **Underlying**: NIFTY50, BANKNIFTY, or SENSEX
- **Strike Price**: e.g., 25000, 45000, 70000
- **Option Type**: CE (Call) or PE (Put)

### Examples:
```
NIFTY50-25000-CE    (NIFTY50 Call Option, Strike 25000)
NIFTY50-25000-PE    (NIFTY50 Put Option, Strike 25000)
BANKNIFTY-45000-CE  (BANKNIFTY Call Option, Strike 45000)
SENSEX-70000-PE     (SENSEX Put Option, Strike 70000)
```

## Lot Sizes
- **NIFTY50**: 50 units per lot
- **BANKNIFTY**: 15 units per lot
- **SENSEX**: 10 units per lot

## System Architecture

### 8 Golden Guardrails Engines
1. **Predictive AI** - 15-min signal, >70% confidence
2. **ML Training** - Weekly retrain on 30-day data
3. **Compliance** - Real-time SEBI checks + dynamic order splitting
4. **Fund Push/Pull** - 09:15/15:25 via Razorpay + IMPS
5. **Trade Execution** - 5-min HFT, max 4 trades per 15-min cycle
6. **Settlement** - EOD with 39% tax lock + rounding buffer
7. **Reporting** - Daily/weekly/annual with Hyperledger hash
8. **Notifications** - Max 5/day, tiered alerts

### Trading Cycle
- **15-minute AI directional cycle** - Predictive AI generates signals
- **5-minute HFT execution layer** - Executes trades based on signals
- **VIX-based capacity scaling** - 50-100% based on market volatility

## Testing

Use `test_paper_trade.ps1` to test paper trading with index options:

```powershell
# Example: Buy 10 lots of NIFTY50 25000 Call Option
.\scripts\test_paper_trade.ps1 -Token "your_token" -Symbol "NIFTY50-25000-CE" -Side "BUY" -Quantity 10

# Example: Sell 5 lots of BANKNIFTY 45000 Put Option
.\scripts\test_paper_trade.ps1 -Token "your_token" -Symbol "BANKNIFTY-45000-PE" -Side "SELL" -Quantity 5
```

## References

- `Other_Files/Final Implementation Guide Ver 11.md` - Complete system specification
- `rules.md` - Trading rules and user categories
- `aurum_harmony/engines/market_data/nse_option_chain.py` - Option chain data fetcher

