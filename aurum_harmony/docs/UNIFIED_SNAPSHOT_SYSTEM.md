# Unified Snapshot System

## Overview

The Unified Snapshot System aggregates data from all trading engines (HDFC Sky NSE/BSE, Kotak Neo NSE/BSE, Paper Trading, Backtest) into a single, normalized view. This implements the "8 engines working together" architecture per the Holy Grail documentation.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Unified Snapshot System                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐│
│  │ HDFC Sky │  │ Kotak Neo│  │  Paper   │  │ Backtest ││
│  │  NSE/BSE │  │  NSE/BSE │  │ Trading  │  │  Engine  ││
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘│
│       │             │             │             │       │
│       └─────────────┴─────────────┴─────────────┘       │
│                        │                                  │
│                        ▼                                  │
│              ┌──────────────────┐                         │
│              │ BrokerAggregator │                         │
│              │  (Parallel Fan)  │                         │
│              └────────┬─────────┘                         │
│                       │                                    │
│                       ▼                                    │
│              ┌──────────────────┐                         │
│              │ UnifiedSnapshot  │                         │
│              │  (Normalized)     │                         │
│              └────────┬─────────┘                         │
│                       │                                    │
│         ┌─────────────┴─────────────┐                     │
│         │                           │                     │
│         ▼                           ▼                     │
│  ┌──────────────┐          ┌──────────────┐            │
│  │ Orchestrator │          │   Frontend   │            │
│  │  (Auto-Run)  │          │  (Dashboard) │            │
│  └──────────────┘          └──────────────┘            │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Components

### 1. Unified Data Models (`unified_snapshot.py`)

- **`UnifiedPosition`**: Normalized position across all engines
- **`UnifiedBalance`**: Aggregated balance from all engines
- **`UnifiedQuote`**: Best bid/ask across engines
- **`EngineSnapshot`**: Per-engine data container
- **`UnifiedSnapshot`**: Master aggregated view

### 2. Broker Aggregator (`broker_aggregator.py`)

- **Parallel Execution**: Uses `ThreadPoolExecutor` to query all engines simultaneously
- **Timeout Protection**: 5-second default timeout per engine
- **Error Handling**: Gracefully handles engine failures without breaking the system
- **Normalization**: Converts broker-specific formats to unified models

### 3. API Endpoints

#### `/api/unified-snapshot`
- **GET** `/api/unified-snapshot`
- Returns aggregated JSON from all available engines
- Includes engine availability status and error messages
- Includes summary stats (total exposure, P&L, position counts)

#### `/api/unified-snapshot/health`
- **GET** `/api/unified-snapshot/health`
- Lightweight health check without fetching full snapshot
- Returns engine availability status only
- Useful for monitoring and health checks

### 4. Frontend Integration

- **`UnifiedSnapshotService`**: Flutter service to fetch and parse unified snapshot
- **Dashboard**: Uses aggregated balance and positions
- **Trade Screen**: Shows positions from all engines

## Usage

### Backend (Python)

```python
from aurum_harmony.engines.trade_execution.broker_aggregator import BrokerAggregator
from aurum_harmony.engines.trade_execution.broker_adapter_factory import (
    get_hdfc_client_from_env,
    get_kotak_client_from_env,
    create_broker_adapter,
)

# Create adapters
hdfc_client = get_hdfc_client_from_env()
kotak_client = get_kotak_client_from_env()

hdfc_nse_adapter = create_broker_adapter(
    use_hdfc_for_paper=True,
    hdfc_client=hdfc_client,
) if hdfc_client else None

# Create aggregator
aggregator = BrokerAggregator(
    hdfc_nse_adapter=hdfc_nse_adapter,
    hdfc_bse_adapter=hdfc_bse_adapter,
    kotak_nse_adapter=kotak_nse_adapter,
    kotak_bse_adapter=kotak_bse_adapter,
    paper_adapter=paper_adapter,
)

# Get unified snapshot
snapshot = aggregator.get_unified_snapshot(timeout=5.0)

# Access aggregated data
all_positions = snapshot.all_positions
aggregated_balance = snapshot.aggregated_balance
```

### Frontend (Flutter/Dart)

```dart
import '../services/unified_snapshot_service.dart';

// Get full snapshot
final snapshot = await UnifiedSnapshotService.getUnifiedSnapshot();

// Get aggregated positions
final positions = await UnifiedSnapshotService.getAggregatedPositions();

// Get aggregated balance
final balance = await UnifiedSnapshotService.getAggregatedBalance();

// Get summary stats
final summary = await UnifiedSnapshotService.getSummary();
```

## Engine Configuration

### HDFC Sky
- **NSE**: Uses HDFC Sky adapter with NSE exchange
- **BSE**: Uses HDFC Sky adapter with BSE exchange
- **Credentials**: `HDFC_SKY_API_KEY`, `HDFC_SKY_API_SECRET`, `HDFC_SKY_TOKEN_ID`

### Kotak Neo
- **NSE**: Uses Kotak Neo adapter with NSE exchange
- **BSE**: Uses Kotak Neo adapter with BSE exchange
- **Credentials**: `KOTAK_NEO_ACCESS_TOKEN`, `KOTAK_NEO_MOBILE_NUMBER`, `KOTAK_NEO_CLIENT_CODE`
- **Auth Flow**: TOTP → MPIN (see `api/kotak_neo.py`)

### Paper Trading
- Always available (fallback)
- Uses in-memory adapter with simulated positions

## Testing

Run the test script to validate the system:

```powershell
.\scripts\test_unified_snapshot.ps1
```

Or test manually:

```bash
# Get unified snapshot (requires auth token)
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:5000/api/unified-snapshot
```

## Error Handling

- **Engine Failures**: If an engine fails, it's marked as unavailable but doesn't break the system
- **Timeout**: Engines that don't respond within 5 seconds are skipped
- **Partial Data**: System works with any combination of available engines
- **Fallback**: Frontend falls back to paper trading API if unified snapshot unavailable

## Performance

- **Parallel Execution**: All engines queried simultaneously (not sequential)
- **Timeout**: 5-second default per engine
- **Caching**: Consider adding caching for snapshot data (future enhancement)

## Features

### Position Deduplication
- Same symbol+exchange from multiple engines are automatically merged
- Quantities are aggregated, prices use weighted averages
- Metadata tracks source engines

### Data Validation
- Automatic validation of snapshot data
- Checks for consistency (P&L calculations, balance math)
- Warns about duplicate positions, negative values, etc.
- Non-blocking: validation errors don't break the system

### Query Helpers
```python
# Get positions by exchange
nse_positions = snapshot.get_positions_by_exchange(Exchange.NSE)

# Get positions by symbol
nifty_positions = snapshot.get_positions_by_symbol("NIFTY50")

# Get positions by engine
paper_positions = snapshot.get_positions_by_engine(EngineType.PAPER_TRADING)

# Get total exposure
total_exposure = snapshot.get_total_exposure()

# Get total P&L
total_pnl = snapshot.get_total_unrealized_pnl()
```

## Future Enhancements

1. **Caching**: Cache snapshot data to reduce API calls
2. **WebSocket**: Real-time updates instead of polling
3. **More Engines**: Add Predictive AI and Compliance engines to aggregator
4. **Exchange Routing**: Smart routing based on exchange (NSE vs BSE)
5. **Load Balancing**: Distribute load across multiple broker instances
6. **Retry Logic**: Automatic retry for failed engine queries

## Exchange Routing

The `ExchangeRouter` class automatically routes symbols to the correct exchange:

- **NIFTY50, BANKNIFTY, FINNIFTY, MIDCPNIFTY** → NSE
- **SENSEX, BANKEX** → BSE
- **Unknown symbols** → NSE (default)

```python
from aurum_harmony.engines.trade_execution.exchange_router import ExchangeRouter

# Get exchange for a symbol
exchange = ExchangeRouter.get_exchange_for_symbol("NIFTY50")  # Returns Exchange.NSE
exchange = ExchangeRouter.get_exchange_for_symbol("SENSEX")   # Returns Exchange.BSE

# Filter symbols by exchange
nse_symbols = ExchangeRouter.filter_symbols_by_exchange(["NIFTY50", "SENSEX"], Exchange.NSE)
# Returns: ["NIFTY50"]
```

## Related Files

- `aurum_harmony/engines/trade_execution/unified_snapshot.py` - Core data models
- `aurum_harmony/engines/trade_execution/broker_aggregator.py` - Aggregation service
- `aurum_harmony/engines/trade_execution/exchange_router.py` - Exchange routing logic
- `aurum_harmony/engines/trade_execution/snapshot_validator.py` - Data validation
- `aurum_harmony/app/orchestrator.py` - Uses aggregator for risk checks
- `aurum_harmony/master_codebase/Master_AurumHarmony_261125.py` - API endpoints
- `aurum_harmony/frontend/flutter_app/lib/services/unified_snapshot_service.dart` - Frontend service
- `aurum_harmony/frontend/flutter_app/lib/screens/dashboard_screen.dart` - Dashboard integration
- `aurum_harmony/frontend/flutter_app/lib/screens/trade_screen.dart` - Trade screen integration
- `scripts/test_unified_snapshot.ps1` - Basic test script
- `scripts/test_unified_snapshot_integration.ps1` - Comprehensive integration test

