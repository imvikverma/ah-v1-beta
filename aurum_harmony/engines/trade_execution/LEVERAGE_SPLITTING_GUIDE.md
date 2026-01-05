# Leverage-Based Order Splitting Guide

**Last Updated:** January 5, 2026

## Overview

The `LeverageAwareAdapter` now **automatically splits orders** instead of rejecting them when exposure limits are exceeded. This ensures maximum capital utilization while respecting 3× leverage limits.

---

## How It Works

### Before (Rejection)
- ❌ Order exceeds exposure limit → **REJECTED**
- ❌ No execution, capital underutilized

### After (Automatic Splitting)
- ✅ Order exceeds exposure limit → **AUTOMATICALLY SPLIT**
- ✅ Execute what fits within available exposure
- ✅ Remaining quantity tracked for later execution
- ✅ Maximum capital utilization

---

## Splitting Logic

### Step 1: Calculate Available Exposure
```
Available Exposure = Max Exposure - Current Exposure
Max Exposure = Capital × Leverage (3×)
```

### Step 2: Check Order Fit
- If `Order Exposure ≤ Available Exposure` → Execute full order
- If `Order Exposure > Available Exposure` → Split order

### Step 3: Calculate Split Quantity
```
Price Per Unit = Order Exposure / Order Quantity
Max Quantity = Available Exposure / Price Per Unit
Split Quantity = Floor(Max Quantity)  # Round down for lot-based trading
```

### Step 4: Execute Split Order
- Execute `Split Quantity` units
- Track remaining quantity in order metadata
- Log split details for monitoring

---

## Example Scenarios

### Scenario 1: Full Execution
- **Capital**: ₹10,000
- **Max Exposure**: ₹30,000 (3×)
- **Current Exposure**: ₹15,000
- **Available Exposure**: ₹15,000
- **Order**: NIFTY50 BUY, ₹12,000 exposure
- **Result**: ✅ Full order executed (₹12,000 < ₹15,000)

### Scenario 2: Partial Execution (Split)
- **Capital**: ₹10,000
- **Max Exposure**: ₹30,000 (3×)
- **Current Exposure**: ₹20,000
- **Available Exposure**: ₹10,000
- **Order**: BANKNIFTY BUY, ₹15,000 exposure
- **Result**: ✅ Split order executed
  - Executed: ₹10,000 exposure (fits within available)
  - Remaining: ₹5,000 exposure (tracked for later)

### Scenario 3: Multi-Index Split
- **Capital**: ₹10,000
- **Max Exposure**: ₹30,000 (3×)
- **Current Exposure**: 
  - NIFTY50: ₹10,000
  - BANKNIFTY: ₹10,000
  - **Total**: ₹20,000
- **Available Exposure**: ₹10,000
- **Order**: SENSEX BUY, ₹15,000 exposure
- **Result**: ✅ Split order executed
  - Executed: ₹10,000 exposure (SENSEX)
  - Remaining: ₹5,000 exposure (tracked)

---

## Order Metadata

When an order is split, the metadata includes:

```python
{
    "split_executed": True,
    "executed_quantity": 100.0,  # Units executed
    "remaining_quantity": 50.0,  # Units remaining
    "executed_exposure": 10000.0,  # Exposure executed
    "remaining_exposure": 5000.0,  # Exposure remaining
    "split_reason": "Order split due to exposure limit..."
}
```

---

## Benefits

1. **Maximum Capital Utilization**: Never waste available exposure
2. **No Rejections**: Orders are always partially executed if possible
3. **Automatic Management**: System handles splitting transparently
4. **Multi-Index Support**: Works across NIFTY50, BANKNIFTY, SENSEX simultaneously
5. **Leverage Compliance**: Always respects 3× leverage limit

---

## Integration

The `LeverageAwareAdapter` automatically handles splitting:

```python
from aurum_harmony.engines.trade_execution.leverage_aware_adapter import LeverageAwareAdapter

# Create adapter
adapter = LeverageAwareAdapter(
    broker_adapter=base_adapter,
    capital=10000.0,
    user_category="admin",
    leverage_multiplier=3.0
)

# Place order (will auto-split if needed)
order = Order(symbol="NIFTY50", side=OrderSide.BUY, quantity=150)
result = adapter.place_order(order)

# Check if split occurred
if result.metadata.get("split_executed"):
    print(f"Executed: {result.metadata['executed_quantity']} units")
    print(f"Remaining: {result.metadata['remaining_quantity']} units")
```

---

## Monitoring

The system logs split operations:

```
INFO: Order split and partially filled: NIFTY50 BUY 100.00 of 150.00 units. 
      Exposure: ₹30,000.00 / ₹30,000.00 (100.0%)
INFO: Remaining: 50.00 units (₹5,000.00 exposure) will be executed when exposure becomes available
```

---

**Status**: ✅ Fully Implemented - Orders are automatically split instead of rejected
