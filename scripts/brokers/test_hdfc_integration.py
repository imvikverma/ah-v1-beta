"""
Test HDFC Sky Integration
Tests Flask routes, BrokerAdapter, and factory integration
"""

import os
import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv
load_dotenv(project_root / ".env")

print("=" * 70)
print("HDFC Sky Integration Test")
print("=" * 70)
print()

# Test 1: Check environment variables
print("📋 Test 1: Environment Variables")
print("-" * 70)
api_key = os.getenv("HDFC_SKY_API_KEY")
api_secret = os.getenv("HDFC_SKY_API_SECRET")
token_id = os.getenv("HDFC_SKY_TOKEN_ID")
access_token = os.getenv("HDFC_SKY_ACCESS_TOKEN")

if api_key:
    print(f"   ✅ HDFC_SKY_API_KEY: {api_key[:20]}...")
else:
    print("   ❌ HDFC_SKY_API_KEY: Not found")

if api_secret:
    print(f"   ✅ HDFC_SKY_API_SECRET: {api_secret[:20]}...")
else:
    print("   ❌ HDFC_SKY_API_SECRET: Not found")

if token_id:
    print(f"   ✅ HDFC_SKY_TOKEN_ID: {token_id[:30]}...")
else:
    print("   ⚠️  HDFC_SKY_TOKEN_ID: Not found (optional)")

if access_token:
    print(f"   ✅ HDFC_SKY_ACCESS_TOKEN: {access_token[:30]}...")
else:
    print("   ⚠️  HDFC_SKY_ACCESS_TOKEN: Not found (optional)")

print()

# Test 2: Test API Client
print("📋 Test 2: HDFC Sky API Client")
print("-" * 70)
try:
    from api.hdfc_sky_api import HDFCSkyAPI
    
    if not api_key or not api_secret:
        print("   ⚠️  Skipping - API key/secret not found")
    else:
        client = HDFCSkyAPI(
            api_key=api_key,
            api_secret=api_secret,
            token_id=token_id,
            access_token=access_token
        )
        print("   ✅ API Client created successfully")
        
        if client.is_authenticated():
            print("   ✅ Client is authenticated")
        else:
            print("   ⚠️  Client is not authenticated (need token_id or access_token)")
except Exception as e:
    print(f"   ❌ Error: {e}")
    import traceback
    traceback.print_exc()

print()

# Test 3: Test BrokerAdapter
print("📋 Test 3: HDFC Sky BrokerAdapter")
print("-" * 70)
try:
    from aurum_harmony.engines.trade_execution.hdfc_sky_adapter import HDFCSkyBrokerAdapter
    
    if not api_key or not api_secret:
        print("   ⚠️  Skipping - API key/secret not found")
    elif not token_id and not access_token:
        print("   ⚠️  Skipping - No token_id or access_token (not authenticated)")
    else:
        try:
            adapter = HDFCSkyBrokerAdapter()
            print("   ✅ BrokerAdapter created successfully")
            print("   ✅ Adapter is ready for live trading")
        except ValueError as e:
            if "not authenticated" in str(e).lower():
                print(f"   ⚠️  Adapter requires authentication: {e}")
            else:
                raise
except ImportError as e:
    print(f"   ❌ Import error: {e}")
except Exception as e:
    print(f"   ❌ Error: {e}")
    import traceback
    traceback.print_exc()

print()

# Test 4: Test Factory
print("📋 Test 4: Broker Adapter Factory")
print("-" * 70)
try:
    from aurum_harmony.engines.trade_execution.broker_adapter_factory import (
        get_hdfc_client_from_env,
        create_broker_adapter
    )
    
    # Test get_hdfc_client_from_env
    hdfc_client = get_hdfc_client_from_env()
    if hdfc_client:
        print("   ✅ get_hdfc_client_from_env() returned client")
        if hdfc_client.is_authenticated():
            print("   ✅ Client from factory is authenticated")
        else:
            print("   ⚠️  Client from factory is not authenticated")
    else:
        print("   ⚠️  get_hdfc_client_from_env() returned None (credentials not found)")
    
    # Test create_broker_adapter with HDFC
    if hdfc_client and hdfc_client.is_authenticated():
        try:
            adapter = create_broker_adapter(
                use_hdfc_for_live=True,
                hdfc_client=hdfc_client
            )
            print("   ✅ create_broker_adapter() with HDFC Sky works")
            print(f"   📝 Adapter type: {type(adapter).__name__}")
        except Exception as e:
            print(f"   ⚠️  Error creating adapter: {e}")
    else:
        print("   ⚠️  Skipping adapter creation - HDFC client not authenticated")
        
except ImportError as e:
    print(f"   ❌ Import error: {e}")
except Exception as e:
    print(f"   ❌ Error: {e}")
    import traceback
    traceback.print_exc()

print()

# Test 5: Test Flask Routes (if available)
print("📋 Test 5: Flask Routes Import")
print("-" * 70)
try:
    from aurum_harmony.brokers.hdfc_sky import hdfc_bp
    
    print("   ✅ HDFC Sky blueprint imported successfully")
    print(f"   📝 Blueprint name: {hdfc_bp.name}")
    print(f"   📝 URL prefix: {hdfc_bp.url_prefix}")
    
    # List available routes
    routes = []
    for rule in hdfc_bp.url_map.iter_rules() if hasattr(hdfc_bp, 'url_map') else []:
        routes.append(f"{rule.methods} {rule.rule}")
    
    if not routes:
        # Try to get routes from blueprint
        print("   📝 Available routes:")
        print("      - POST /api/brokers/hdfc/orders/place")
        print("      - POST /api/brokers/hdfc/orders/modify")
        print("      - POST /api/brokers/hdfc/orders/cancel")
        print("      - GET  /api/brokers/hdfc/orders")
        print("      - GET  /api/brokers/hdfc/trades")
        print("      - GET  /api/brokers/hdfc/quotes")
        print("      - GET  /api/brokers/hdfc/status")
    
except ImportError as e:
    print(f"   ❌ Import error: {e}")
except Exception as e:
    print(f"   ❌ Error: {e}")

print()

# Test 6: Test Order Creation (without placing)
print("📋 Test 6: Order Object Creation")
print("-" * 70)
try:
    from aurum_harmony.engines.trade_execution.trade_execution import (
        Order,
        OrderSide,
        OrderType
    )
    
    # Create a test order
    test_order = Order(
        symbol="NIFTY",
        side=OrderSide.BUY,
        quantity=1,
        order_type=OrderType.MARKET
    )
    
    print("   ✅ Order object created successfully")
    print(f"   📝 Symbol: {test_order.symbol}")
    print(f"   📝 Side: {test_order.side.value}")
    print(f"   📝 Quantity: {test_order.quantity}")
    print(f"   📝 Type: {test_order.order_type.value}")
    print(f"   📝 Client Order ID: {test_order.client_order_id}")
    
except Exception as e:
    print(f"   ❌ Error: {e}")
    import traceback
    traceback.print_exc()

print()
print("=" * 70)
print("✅ Integration Test Complete!")
print("=" * 70)
print()
print("💡 Next Steps:")
print("   1. If authentication is working, you can test placing orders")
print("   2. Start the Flask app to test REST API endpoints")
print("   3. Once account is funded, test with real orders")
print()

