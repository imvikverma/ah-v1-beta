# Leverage & Multi-Index Trading Guide

**Last Updated:** January 5, 2026

## Overview

AurumHarmony implements **3× leverage** across **3 indices simultaneously** (NIFTY50, BANKNIFTY, SENSEX) as per rules.md.

---

## Leverage Implementation

### Leverage Multiplier
- **Admin/Restricted/Semi-Restricted**: **3× leverage**
- **NGD**: 1.5× leverage

### How It Works

1. **Base Capital**: The capital amounts (₹10,000, ₹50,000, etc.) are the BASE trading capital
2. **Max Exposure**: Maximum exposure = Base Capital × Leverage Multiplier
3. **Exposure Tracking**: Total exposure across ALL indices must not exceed max exposure

### Example

**Day 1-5: ₹10,000 Capital**
- Base Capital: ₹10,000
- Leverage: 3×
- **Max Exposure: ₹30,000** (can be distributed across NIFTY50, BANKNIFTY, SENSEX)

**Day 21-25: ₹15,00,000 Capital**
- Base Capital: ₹15,00,000
- Leverage: 3×
- **Max Exposure: ₹45,00,000** (can be distributed across all 3 indices)

---

## Multi-Index Simultaneous Trading

### Allowed Indices
- **NIFTY50** (NSE)
- **BANKNIFTY** (NSE)
- **SENSEX** (BSE)

### How Simultaneous Trading Works

1. **Total Exposure Limit**: Combined exposure across all 3 indices must not exceed `Capital × 3`
2. **Per-Index Allocation**: The system can allocate exposure across indices based on:
   - Signal confidence
   - Market conditions
   - Risk management rules
3. **Dynamic Distribution**: Exposure can be distributed as:
   - Equal: ₹10,000 per index (for ₹30,000 max exposure)
   - Weighted: More exposure to higher-confidence signals
   - Adaptive: AI-driven allocation based on opportunity

### Example Scenarios

**Scenario 1: Equal Distribution**
- Capital: ₹10,000
- Max Exposure: ₹30,000
- NIFTY50: ₹10,000 exposure
- BANKNIFTY: ₹10,000 exposure
- SENSEX: ₹10,000 exposure
- **Total: ₹30,000** ✅

**Scenario 2: Weighted Distribution**
- Capital: ₹10,000
- Max Exposure: ₹30,000
- NIFTY50: ₹15,000 exposure (high confidence)
- BANKNIFTY: ₹10,000 exposure (medium confidence)
- SENSEX: ₹5,000 exposure (low confidence)
- **Total: ₹30,000** ✅

**Scenario 3: Single Index Focus**
- Capital: ₹10,000
- Max Exposure: ₹30,000
- NIFTY50: ₹30,000 exposure (very high confidence)
- BANKNIFTY: ₹0 exposure
- SENSEX: ₹0 exposure
- **Total: ₹30,000** ✅

---

## Implementation Details

### LeverageAwareAdapter

The `LeverageAwareAdapter` wraps any `BrokerAdapter` and enforces leverage limits:

```python
from aurum_harmony.engines.trade_execution.leverage_aware_adapter import LeverageAwareAdapter

# Create leverage-aware adapter
adapter = LeverageAwareAdapter(
    broker_adapter=base_adapter,
    capital=10000.0,
    user_category="admin",
    leverage_multiplier=3.0
)
```

### Key Features

1. **Exposure Calculation**: Tracks total exposure across all positions
2. **Leverage Validation**: Rejects orders that would exceed max exposure
3. **Multi-Index Support**: Tracks exposure per index (NIFTY50, BANKNIFTY, SENSEX)
4. **Real-time Monitoring**: Provides exposure status and utilization

### Exposure Status

```python
exposure_status = adapter.get_exposure_status()
# Returns:
# {
#     "capital": 10000.0,
#     "leverage_multiplier": 3.0,
#     "max_exposure": 30000.0,
#     "current_exposure": 15000.0,
#     "exposure_by_index": {
#         "NIFTY50": 10000.0,
#         "BANKNIFTY": 5000.0,
#         "SENSEX": 0.0
#     },
#     "utilization_percent": 50.0,
#     "available_exposure": 15000.0
# }
```

---

## Capital Progression with Leverage

### Progression Schedule

| Days | Base Capital | Leverage | Max Exposure |
|------|--------------|----------|--------------|
| 1-5 | ₹10,000 | 3× | ₹30,000 |
| 6-10 | ₹50,000 | 3× | ₹1,50,000 |
| 11-15 | ₹1,00,000 | 3× | ₹3,00,000 |
| 16-20 | ₹5,00,000 | 3× | ₹15,00,000 |
| 21-25 | ₹15,00,000 | 3× | ₹45,00,000 |

### Notes

- Capital amounts are **BASE capital** (not including leverage)
- Leverage is **applied separately** to calculate max exposure
- The "30% leverage margin" in rules.md refers to options margin requirements, not a capital reduction
- Max exposure can be distributed across all 3 indices simultaneously

---

## Testing

Run the capital progression test to verify leverage and multi-index support:

```powershell
python scripts\test_capital_progression_simple.py
```

This will show:
- Capital progression day by day
- Max exposure with 3× leverage
- Exposure status across all indices
- Utilization percentage

---

## Integration

The `LeverageAwareAdapter` should be used when:
1. Testing capital progression
2. Paper trading with live data
3. Live trading (wraps the actual broker adapter)

Example integration:

```python
from aurum_harmony.engines.trade_execution.broker_adapter_factory import create_broker_adapter
from aurum_harmony.engines.trade_execution.leverage_aware_adapter import LeverageAwareAdapter

# Create base adapter
base_adapter = create_broker_adapter(
    use_live_data=True,
    initial_balance=10000.0,
    kotak_client=kotak_client
)

# Wrap with leverage-aware adapter
adapter = LeverageAwareAdapter(
    broker_adapter=base_adapter,
    capital=10000.0,
    user_category="admin",
    leverage_multiplier=3.0
)
```

---

## Compliance

- ✅ Leverage limits enforced per rules.md
- ✅ Multi-index trading supported (NIFTY50, BANKNIFTY, SENSEX)
- ✅ Total exposure tracked across all indices
- ✅ Order rejection when exposure limit exceeded
- ✅ Real-time exposure monitoring

---

**Status**: ✅ Fully Implemented and Tested
