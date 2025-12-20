"""
Test HDFC Sky Paper Trading
Tests paper trading with live data from HDFC Sky
"""

import os
import sys
from pathlib import Path
import time

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv
load_dotenv(project_root / ".env")

from aurum_harmony.engines.trade_execution.trade_execution import (
    Order,
    OrderSide,
    OrderType,
    OrderStatus
)
from aurum_harmony.engines.trade_execution.broker_adapter_factory import (
    get_hdfc_client_from_env,
    create_broker_adapter
)

print("=" * 70)
print("HDFC Sky Paper Trading Test")
print("=" * 70)
print()

# Get HDFC client
hdfc_client = get_hdfc_client_from_env()

if not hdfc_client:
    print("❌ HDFC Sky client not available. Check your .env file.")
    sys.exit(1)

if not hdfc_client.is_authenticated():
    print("❌ HDFC Sky client not authenticated. Set HDFC_SKY_TOKEN_ID or HDFC_SKY_ACCESS_TOKEN.")
    sys.exit(1)

print("✅ HDFC Sky client authenticated")
print()

# Create paper adapter
print("📋 Creating HDFC Sky Paper Adapter...")
adapter = create_broker_adapter(
    use_hdfc_for_paper=True,
    hdfc_client=hdfc_client,
    initial_balance=100000.0
)

print(f"✅ Adapter created: {type(adapter).__name__}")
print(f"💰 Initial Balance: ₹{adapter.get_balance():,.2f}")
print()

# Test 1: Place a BUY order
print("📋 Test 1: Place BUY Order (NIFTY)")
print("-" * 70)
order1 = Order(
    symbol="NIFTY",
    side=OrderSide.BUY,
    quantity=1,
    order_type=OrderType.MARKET,
    metadata={"exchange": "NSE"}
)

result1 = adapter.place_order(order1)
print(f"   Order ID: {result1.client_order_id}")
print(f"   Status: {result1.status.value}")
print(f"   Broker Order ID: {result1.broker_order_id}")
if result1.status == OrderStatus.FILLED:
    exec_price = result1.metadata.get("execution_price", "N/A")
    print(f"   Execution Price: ₹{exec_price:,.2f}")
    print(f"   Data Source: {result1.metadata.get('data_source', 'N/A')}")
    print(f"   Execution Mode: {result1.metadata.get('execution_mode', 'N/A')}")
print(f"   Current Balance: ₹{adapter.get_balance():,.2f}")
print()

# Test 2: Place a SELL order
print("📋 Test 2: Place SELL Order (NIFTY)")
print("-" * 70)
order2 = Order(
    symbol="NIFTY",
    side=OrderSide.SELL,
    quantity=1,
    order_type=OrderType.MARKET,
    metadata={"exchange": "NSE"}
)

result2 = adapter.place_order(order2)
print(f"   Order ID: {result2.client_order_id}")
print(f"   Status: {result2.status.value}")
if result2.status == OrderStatus.FILLED:
    exec_price = result2.metadata.get("execution_price", "N/A")
    print(f"   Execution Price: ₹{exec_price:,.2f}")
print(f"   Current Balance: ₹{adapter.get_balance():,.2f}")
print()

# Test 3: Get positions
print("📋 Test 3: Get Positions")
print("-" * 70)
positions = adapter.get_positions()
if positions:
    for pos in positions:
        print(f"   Symbol: {pos.symbol}")
        print(f"   Quantity: {pos.quantity}")
        print(f"   Avg Price: ₹{pos.avg_price:,.2f}")
        print(f"   Current Price: ₹{pos.current_price:,.2f}")
        print(f"   Unrealized P&L: ₹{pos.unrealized_pnl:,.2f}")
else:
    print("   No open positions")
print()

# Test 4: Get statistics
print("📋 Test 4: Trading Statistics")
print("-" * 70)
stats = adapter.get_statistics()
for key, value in stats.items():
    if isinstance(value, float):
        print(f"   {key}: ₹{value:,.2f}")
    else:
        print(f"   {key}: {value}")
print()

print("=" * 70)
print("✅ Paper Trading Test Complete!")
print("=" * 70)
print()
print("💡 This uses REAL market data from HDFC Sky but SIMULATES trades")
print("💡 Perfect for testing strategies without risking real money!")
print()

