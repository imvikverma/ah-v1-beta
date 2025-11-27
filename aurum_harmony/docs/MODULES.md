# AurumHarmony Modules & APIs (Backend)

This document gives a high‑level, engine‑agnostic view of the main backend
modules and how they fit together. It is current for the stubbed engines and
can be refined as you update the core logic.

---

## 1. `aurum_harmony/app`

### `app/__init__.py`
- Provides `create_app()` Flask factory.
- Registers the `admin` blueprint from `routes.py`.

### `app/routes.py`
- Defines a minimal **admin API** over an in‑memory `User` store:
  - `GET /admin/users` – list all users.
  - `GET /admin/user/<user_code>` – fetch a single user.
  - `POST /admin/user/<user_code>` – edit user financial fields (respecting lock flags).
  - `POST /admin/user/<user_code>/lock` – lock/unlock fields like capital, trade limits, accounts.
  - `POST /admin/user/<user_code>/accounts` – add/remove linked accounts.
- Backed by `app/models.py::User`.

### `app/models.py`
- `User` model stores:
  - `user_code`, `kyc_data` (name, PAN, etc.).
  - `initial_capital` (+ lock flag).
  - `trade_limit` (trades/day, + lock flag).
  - `accounts` (demat/trading account IDs, + lock flag).
  - `is_admin` boolean.

### `app/config.py`
- Central configuration + safety limits:
  - `AppConfig` with:
    - `trading_mode` – `PAPER` (default) or `LIVE`.
    - `global_risk` – `RiskLimits(max_daily_loss, max_position_size, max_open_trades)`.
  - `load_config()` reads env vars (`AURUM_TRADING_MODE`, `AURUM_MAX_*`) and returns validated config.

### `app/orchestrator.py`
- **Handsfree trading orchestrator**:
  - `TradeSignal` – simple DTO for a trade idea (symbol, side, quantity, reason).
  - `SignalSource` protocol – any strategy that emits a list of `TradeSignal`.
  - `SimpleRiskEngine` – enforces basic caps using `AppConfig.global_risk`.
  - `TradingOrchestrator`:
    - Pulls signals from a `SignalSource`.
    - Filters them through `SimpleRiskEngine`.
    - Sends approved trades to the `TradeExecutor` (see below).

---

## 2. `aurum_harmony/engines/trade_execution`

### `trade_execution.py`
- Defines core execution primitives:
  - `OrderSide` – `BUY` / `SELL`.
  - `OrderType` – `MARKET` / `LIMIT`.
  - `OrderStatus` – `NEW`, `REJECTED`, `FILLED`, `PARTIALLY_FILLED`, `CANCELLED`.
  - `Order` dataclass – symbol, side, quantity, type, limit_price, client/broker IDs, status, metadata.
- `BrokerAdapter` protocol:
  - `place_order(order: Order) -> Order`
  - `cancel_order(broker_order_id: str) -> bool`
- `PaperBrokerAdapter`:
  - In‑memory adapter that simulates **instant fills**; no real broker calls.
- `TradeExecutor`:
  - Wraps a `BrokerAdapter` (defaults to `PaperBrokerAdapter`).
  - Requires `risk_approved: bool` for every `execute_order(...)` call.
  - Obeys `live_trading_enabled` flag (wired to `AppConfig.is_live` in the orchestrator).

---

## 3. `aurum_harmony/blockchain`

### `blockchain/fabric_client.py`
- Central abstraction for Hyperledger Fabric:
  - `FabricConfig` (`channel_name`, `chaincode_name`, optional `gateway_url`).
  - `load_fabric_config()` – reads `FABRIC_*` env vars.
  - `FabricClient`:
    - `invoke(function, args, transient=None)` – state‑changing call.
    - `query(function, args)` – read‑only call.
    - If `FABRIC_GATEWAY_URL` is **unset**, both methods log and return safe NO‑OP responses.

### `blockchain/blockchain_trade.py`
- `TradeRecord` dataclass – trade ID, user ID, symbol, side, quantity, price, timestamp, strategy, extra.
- `record_trade_on_chain(trade: TradeRecord)` – logs & forwards to `FabricClient.invoke("recordTrade", payload)`.

### `blockchain/blockchain_settlement.py`
- `SettlementRecord` dataclass – settlement ID, trade ID, status, timestamp, details.
- `record_settlement_on_chain(settlement: SettlementRecord)` – forwards to `FabricClient.invoke("recordSettlement", ...)`.

### `blockchain/blockchain_reporting.py`
- `query_trades_by_user(user_id)` – wraps `FabricClient.query("queryTradesByUser", {...})`.
- `query_trade_by_id(trade_id)` – wraps `FabricClient.query("queryTradeById", {...})`.

### `blockchain/blockchain_auth.py`
- `FabricIdentity` – placeholder for a Fabric identity (user name, MSP ID, optional cert/key paths).
- `get_default_identity()` – returns a logical `aurum_admin` identity (to be linked to a real wallet later).

---

## 4. `aurum_harmony/APIs_and_Integrations`

- `brokerage_api.py`, `data_fetcher.py`, `gmail_api.py`, `tax_api.py` are currently stubs.
- Intended responsibilities:
  - **`brokerage_api.py`** – unify broker‑specific order placement / account info for HDFC, Kotak, etc.
  - **`data_fetcher.py`** – normalized market data (real‑time + historical) feeding engines/strategies.
  - **`gmail_api.py`** – email notifications, alerts, and audit communications.
  - **`tax_api.py`** – sync with tax/government apps, compute P&L and tax liabilities.

As you update these integrations, we can extend this doc with concrete function signatures and flows.


