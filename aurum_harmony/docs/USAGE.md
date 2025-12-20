# AurumHarmony Usage (Backend & Orchestrator)

This document explains how to run the AurumHarmony backend components in a safe
way, focusing on PAPER mode and guarded handsfree behaviour.

## 1. Environment & Dependencies

1. Create a Python virtual environment (recommended).
2. Install dependencies from the project root:
   ```bash
   pip install -r requirements.txt
   ```
3. Copy the `.env.example` file at the project root to `.env` and fill in:
   - API keys (HDFC, etc.).
   - Trading mode and risk limits.
   - Optional Fabric gateway configuration.

## 2. Running the Flask App

The simple HDFC example API is in `config/app.py`:

```bash
python config/app.py
```

You can later mount the `aurum_harmony/app` Flask factory into a larger app if desired.

## 3. Handsfree Trading Orchestrator (Concept)

The orchestrator lives in `aurum_harmony/app/orchestrator.py`:

- `TradingOrchestrator` expects a `SignalSource` that emits `TradeSignal` objects.
- For each signal it:
  1. Runs the signal through a risk engine (enforcing global limits).
  2. Sends approved trades to `TradeExecutor`, which defaults to PAPER mode.

Example sketch (pseudo‑code, not wired to real strategies yet):

```python
from aurum_harmony.app.orchestrator import TradingOrchestrator, TradeSignal, SignalSource
from aurum_harmony.engines.trade_execution.trade_execution import OrderSide


class DummySignalSource:
    def get_signals(self):
        # Replace with real logic (indicators, ML, etc.)
        return [
            TradeSignal(symbol="NIFTY24SEP", side=OrderSide.BUY, quantity=1, reason="demo")
        ]


if __name__ == "__main__":
    orchestrator = TradingOrchestrator(signal_source=DummySignalSource())
    results = orchestrator.run_once()
    print(results)
```

## 4. Safety Notes

- The default mode is **PAPER**; you must set `AURUM_TRADING_MODE=LIVE` explicitly
  in `.env` to enable live trading.
- All orders must pass `risk_approved` checks inside `TradeExecutor`; there is no
  direct “fire and forget” path to the broker.
- Fabric logging is safe by default: without `FABRIC_GATEWAY_URL` configured,
  all blockchain calls are logged but do not send anything to a network.

As engines and strategies mature, plug them into the `SignalSource` and risk
engine interfaces for full handsfree automation.


