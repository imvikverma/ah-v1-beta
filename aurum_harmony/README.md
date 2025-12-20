# AurumHarmony Core Package

This package contains the main backend components for the AurumHarmony trading system:

- `app/` – Flask app, admin APIs, config, and the handsfree trading orchestrator.
- `engines/` – Trading‑related engines (execution, backtesting, reporting, notifications, etc.).
- `blockchain/` – Hyperledger Fabric abstraction and blockchain logging for trades/settlements.
- `APIs_and_Integrations/` – External API integrations (brokerage, data, tax, Gmail).
- `trade_history/` – Trade history viewing logic.
- `docs/` – Architecture and module documentation for this package.
- `master_codebase/` – High‑level integration entry for the whole AurumHarmony system.

## Quick Start (Backend)

1. Create and populate a `.env` file at the project root (see `.env.example`):
   - API keys (HDFC, Kotak, etc.).
   - Trading mode and risk limits.
   - Optional Fabric gateway config.
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the Flask API (example):
   ```bash
   python config/app.py
   ```
4. (Optional) Run the trading orchestrator in a loop (example sketch):
   ```bash
   # Pseudocode – you will plug in a real SignalSource later
   from aurum_harmony.app.orchestrator import TradingOrchestrator

   # orchestrator = TradingOrchestrator(signal_source=MySignalSource())
   # orchestrator.run_once()
   ```

## Safety Defaults

- The system defaults to **PAPER** trading mode unless `AURUM_TRADING_MODE=LIVE` is explicitly set.
- All orders pass through a risk engine and the `TradeExecutor`, which requires `risk_approved=True`.
- Fabric blockchain integration is **stubbed**: if `FABRIC_GATEWAY_URL` is not set, calls are logged but do not fail.

See `aurum_harmony/docs/CONFIGURATION.md` and `aurum_harmony/docs/USAGE.md` for details.