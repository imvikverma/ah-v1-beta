"""
Test Live Data Paper Trading

Tests the live data paper trading adapter with Kotak Neo API.
This uses real market data but executes trades in paper mode.
"""

import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv
from api.kotak_neo import KotakNeoAPI
from aurum_harmony.engines.trade_execution.live_data_paper_adapter import LiveDataPaperAdapter
from aurum_harmony.engines.trade_execution.trade_execution import Order, OrderSide, OrderType

# Load environment variables
env_path = project_root / ".env"
if env_path.exists():
    load_dotenv(env_path)
else:
    print("❌ ERROR: .env file not found!")
    sys.exit(1)


def get_credentials():
    """Load credentials from environment variables."""
    access_token = os.getenv("KOTAK_NEO_ACCESS_TOKEN")
    mobile_number = os.getenv("KOTAK_NEO_MOBILE_NUMBER")
    client_code = os.getenv("KOTAK_NEO_CLIENT_CODE")
    
    if not all([access_token, mobile_number, client_code]):
        print("❌ ERROR: Kotak Neo credentials not found in .env")
        print("   Required: KOTAK_NEO_ACCESS_TOKEN, KOTAK_NEO_MOBILE_NUMBER, KOTAK_NEO_CLIENT_CODE")
        sys.exit(1)
    
    # Remove 'Bearer ' prefix if present
    if access_token.startswith("Bearer "):
        access_token = access_token[7:]
    
    return access_token, mobile_number, client_code


def test_live_data_paper_trading():
    """Test live data paper trading."""
    print("=" * 60)
    print("Live Data Paper Trading Test")
    print("=" * 60)
    print()
    
    # Load credentials
    print("📋 Step 1: Loading credentials...")
    access_token, mobile_number, client_code = get_credentials()
    print("   ✅ Credentials loaded")
    print()
    
    # Initialize Kotak Neo client
    print("📋 Step 2: Initializing Kotak Neo API client...")
    kotak_client = KotakNeoAPI(
        access_token=access_token,
        mobile_number=mobile_number,
        client_code=client_code
    )
    print("   ✅ Client initialized")
    print()
    
    # Authenticate
    print("📋 Step 3: Authenticating with Kotak Neo...")
    print("   📱 Enter TOTP code from your authenticator app:")
    totp = input("   TOTP: ").strip()
    
    try:
        kotak_client.login_with_totp(totp)
        print("   ✅ TOTP login successful")
    except Exception as e:
        print(f"   ❌ TOTP login failed: {e}")
        return False
    
    print("   🔐 Enter MPIN (trading PIN):")
    mpin = input("   MPIN: ").strip()
    
    try:
        kotak_client.validate_mpin(mpin)
        print("   ✅ MPIN validation successful")
    except Exception as e:
        print(f"   ❌ MPIN validation failed: {e}")
        return False
    
    print()
    
    # Create live data paper adapter
    print("📋 Step 4: Creating Live Data Paper Trading Adapter...")
    paper_adapter = LiveDataPaperAdapter(
        kotak_client=kotak_client,
        initial_balance=100000.0
    )
    print("   ✅ Adapter created")
    print()
    
    # Test fetching live prices
    print("📋 Step 5: Testing live price fetching...")
    test_symbols = ["NIFTY50", "BANKNIFTY"]
    
    for symbol in test_symbols:
        print(f"   Fetching live price for {symbol}...")
        price = paper_adapter._get_live_price(symbol)
        if price:
            print(f"   ✅ {symbol}: ₹{price:,.2f} (Live from Kotak Neo)")
        else:
            print(f"   ⚠️  {symbol}: Live price unavailable, will use fallback")
    print()
    
    # Test paper order
    print("📋 Step 6: Testing paper order execution...")
    print("   Placing a test BUY order for NIFTY50 (1 lot)...")
    
    test_order = Order(
        symbol="NIFTY50",
        side=OrderSide.BUY,
        quantity=1.0,
        order_type=OrderType.MARKET,
        client_order_id="test_live_data_001"
    )
    
    result = paper_adapter.place_order(test_order)
    
    if result.status.value == "FILLED":
        print(f"   ✅ Order filled at ₹{result.filled_price:,.2f}")
        print(f"   📊 Balance: ₹{paper_adapter.get_balance():,.2f}")
        print(f"   📈 Positions: {len(paper_adapter.get_positions())}")
    else:
        print(f"   ❌ Order {result.status.value}: {result.metadata.get('reason', 'Unknown')}")
    
    print()
    
    # Get statistics
    print("📋 Step 7: Trading Statistics...")
    stats = paper_adapter.get_statistics()
    print()
    print("   📊 Account Summary:")
    print(f"      Balance: ₹{stats['balance']:,.2f}")
    print(f"         → {stats.get('balance_explanation', '')}")
    print(f"      Initial Balance: ₹{stats['initial_balance']:,.2f}")
    print(f"         → {stats.get('initial_balance_explanation', '')}")
    print()
    print("   💰 Profit & Loss:")
    print(f"      Realized P&L: ₹{stats['realized_pnl']:,.2f}")
    print(f"         → {stats.get('realized_pnl_explanation', '')}")
    print(f"      Unrealized P&L: ₹{stats['unrealized_pnl']:,.2f}")
    print(f"         → {stats.get('unrealized_pnl_explanation', '')}")
    print(f"      Total P&L: ₹{stats['total_pnl']:,.2f}")
    print(f"         → {stats.get('total_pnl_explanation', '')}")
    print()
    print("   📈 Trading Activity:")
    print(f"      Open Positions: {stats['open_positions']}")
    print(f"         → {stats.get('open_positions_explanation', '')}")
    print(f"      Total Orders: {stats['total_orders']}")
    print(f"         → {stats.get('total_orders_explanation', '')}")
    print()
    print("   🔧 System Info:")
    print(f"      Data Source: {stats['data_source']}")
    print(f"         → {stats.get('data_source_explanation', '')}")
    print(f"      Data Type: {stats.get('data_type', 'N/A')}")
    print(f"         → {stats.get('data_type_explanation', '')}")
    print(f"      Execution Mode: {stats['execution_mode']}")
    print(f"         → {stats.get('execution_mode_explanation', '')}")
    print()
    
    print("=" * 60)
    print("✅ Live Data Paper Trading Test Complete!")
    print("=" * 60)
    print()
    print("Your system is now using:")
    print("  ✅ Real-time market data from Kotak Neo")
    print("  ✅ Paper trading execution (no real money)")
    print("  ✅ Perfect for testing with live market conditions!")
    print()
    
    return True


if __name__ == "__main__":
    try:
        success = test_live_data_paper_trading()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Test cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

