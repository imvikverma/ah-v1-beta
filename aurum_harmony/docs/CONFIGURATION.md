# AurumHarmony Configuration

This file lists the main environment variables and configuration knobs for the
backend and orchestrator. Create a `.env` in the project root based on these.

## Trading Mode & Risk Limits

- **`AURUM_TRADING_MODE`**
  - Values: `PAPER` (default) or `LIVE`
  - Controls whether the `TradeExecutor` uses paper or live mode.
- **`AURUM_MAX_DAILY_LOSS`**
  - Default: `5000`
  - Maximum allowed daily loss (base currency units) before trading should stop.
- **`AURUM_MAX_POSITION_SIZE`**
  - Default: `50000`
  - Maximum notional size per position.
- **`AURUM_MAX_OPEN_TRADES`**
  - Default: `5`
  - Maximum number of simultaneous open trades across the system.

These values are consumed by `aurum_harmony/app/config.py` and enforced by the
simple risk engine in `aurum_harmony/app/orchestrator.py`.

## Brokerage / API Keys

Set these only in your local `.env` (never commit real keys to Git):

- **`HDFC_SKY_API_KEY`**
- **`HDFC_SKY_API_SECRET`**

Add similar variables for other brokers (Kotak Neo, etc.) as you integrate them.

## Hyperledger Fabric

The Fabric integration is intentionally safe and stubbed:

- **`FABRIC_CHANNEL_NAME`**
  - Default: `aurumchannel`
- **`FABRIC_CHAINCODE_NAME`**
  - Default: `aurum_cc`
- **`FABRIC_GATEWAY_URL`**
  - If set (e.g. `http://localhost:8080`), `FabricClient` will attempt to call
    this REST/gRPC gateway.
  - If **not set**, all Fabric calls are logged **NO‑OPs** so development is safe.

## Flask App

For the example app in `config/app.py`:

- You can also set standard Flask variables like `FLASK_ENV`, `FLASK_DEBUG`, etc.

Refer to `.env.example` at the project root for a concrete template.


