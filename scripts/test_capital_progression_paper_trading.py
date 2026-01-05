"""
Test Capital Progression Paper Trading with Kotak Neo Live Data
Tests paper trading with capital progression: 10K → 50K → 1L → 5L → 15L
"""

import sys
import os
from pathlib import Path
from datetime import datetime
import time
import json

# Fix Windows console encoding for Unicode
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv
load_dotenv()

from api.kotak_neo import KotakNeoAPI
from aurum_harmony.engines.trade_execution.live_data_paper_adapter import LiveDataPaperAdapter
from aurum_harmony.engines.capital_progression import CapitalProgressionManager
from aurum_harmony.engines.trade_execution.trade_execution import Order, OrderSide, OrderType
from typing import Optional
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def test_kotak_connection() -> Optional[KotakNeoAPI]:
    """Test and authenticate Kotak Neo connection"""
    print("=" * 60)
    print("Testing Kotak Neo Connection")
    print("=" * 60)
    
    access_token = os.getenv('KOTAK_NEO_ACCESS_TOKEN')
    mobile_number = os.getenv('KOTAK_NEO_MOBILE_NUMBER')
    client_code = os.getenv('KOTAK_NEO_CLIENT_CODE')
    
    if not all([access_token, mobile_number, client_code]):
        print("[ERROR] Missing Kotak Neo credentials in .env")
        print("   Required: KOTAK_NEO_ACCESS_TOKEN, KOTAK_NEO_MOBILE_NUMBER, KOTAK_NEO_CLIENT_CODE")
        return None
    
    try:
        # Check for saved tokens in environment
        view_token = os.getenv('KOTAK_NEO_VIEW_TOKEN')
        view_sid = os.getenv('KOTAK_NEO_VIEW_SID')
        trade_token = os.getenv('KOTAK_NEO_TRADE_TOKEN')
        trade_sid = os.getenv('KOTAK_NEO_TRADE_SID')
        base_url = os.getenv('KOTAK_NEO_BASE_URL')
        
        client = KotakNeoAPI(
            access_token=access_token,
            mobile_number=mobile_number,
            client_code=client_code
        )
        
        # If we have saved tokens, try to use them
        if all([view_token, view_sid, trade_token, trade_sid, base_url]):
            try:
                client.view_token = view_token
                client.view_sid = view_sid
                client.trade_token = trade_token
                client.trade_sid = trade_sid
                client.base_url = base_url
                if client.is_authenticated():
                    print("[OK] Using saved Kotak Neo tokens")
                    return client
            except Exception as e:
                print(f"[INFO] Saved tokens invalid, need to re-authenticate: {e}")
        
        if not client.is_authenticated():
            print("[WARNING] Not authenticated. Need TOTP and MPIN for login.")
            print("[INFO] For interactive login, run: python scripts\\brokers\\test_kotak_connection.py")
            print("[INFO] Then add tokens to .env file:")
            print("   KOTAK_NEO_VIEW_TOKEN=<token>")
            print("   KOTAK_NEO_VIEW_SID=<sid>")
            print("   KOTAK_NEO_TRADE_TOKEN=<token>")
            print("   KOTAK_NEO_TRADE_SID=<sid>")
            print("   KOTAK_NEO_BASE_URL=<base_url>")
            return None
        
        if client.is_authenticated():
            print("[OK] Kotak Neo authenticated successfully")
            return client
        else:
            print("[ERROR] Authentication failed")
            return None
            
    except Exception as e:
        print(f"[ERROR] Error connecting to Kotak Neo: {e}")
        import traceback
        traceback.print_exc()
        return None


def test_live_price_fetch(kotak_client: KotakNeoAPI):
    """Test fetching live prices from Kotak Neo"""
    print("\n" + "=" * 60)
    print("Testing Live Price Fetch")
    print("=" * 60)
    
    try:
        # Test NIFTY50 price
        print("Fetching NIFTY50 price...")
        quotes = kotak_client.get_quotes(exchange="nse_fo", symbol_code="26000")
        print(f"[OK] NIFTY50 quotes: {json.dumps(quotes, indent=2)[:200]}...")
        
        # Test BANKNIFTY price
        print("\nFetching BANKNIFTY price...")
        quotes = kotak_client.get_quotes(exchange="nse_fo", symbol_code="26009")
        print(f"[OK] BANKNIFTY quotes: {json.dumps(quotes, indent=2)[:200]}...")
        
        return True
    except Exception as e:
        print(f"[ERROR] Error fetching live prices: {e}")
        import traceback
        traceback.print_exc()
        return False


def run_capital_progression_test():
    """Run paper trading test with capital progression"""
    print("\n" + "=" * 60)
    print("Capital Progression Paper Trading Test")
    print("=" * 60)
    
    # Step 1: Connect to Kotak Neo
    kotak_client = test_kotak_connection()
    if not kotak_client:
        print("[ERROR] Cannot proceed without Kotak Neo connection")
        return False
    
    # Step 2: Test live price fetching
    if not test_live_price_fetch(kotak_client):
        print("[WARNING] Live price fetch failed, but continuing with test...")
    
    # Step 3: Initialize capital progression
    progression = CapitalProgressionManager()
    print(f"\n[INFO] Capital Progression Schedule:")
    summary = progression.get_progression_summary()
    for level in summary['levels']:
        print(f"   Day {level['start_day']}-{level['end_day']}: ₹{level['capital']:,.2f}")
    
    # Step 4: Create paper trading adapter with initial capital
    initial_capital = progression.get_current_capital()
    print(f"\n[INFO] Starting with capital: Rs. {initial_capital:,.2f}")
    
    try:
        adapter = LiveDataPaperAdapter(
            kotak_client=kotak_client,
            initial_balance=initial_capital,
            price_update_interval=5
        )
        print("[OK] LiveDataPaperAdapter created")
    except Exception as e:
        print(f"[ERROR] Error creating adapter: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    # Step 5: Run progression test
    print("\n" + "=" * 60)
    print("Starting Capital Progression Test")
    print("=" * 60)
    print("\nNote: This is a simulation. In production, this would run daily.")
    print("For now, we'll simulate day-by-day progression.\n")
    
    results = []
    
    for day in range(1, progression.total_days + 1):
        level_info = progression.get_level_info(day)
        current_capital = level_info['capital']
        
        print(f"\n{'='*60}")
        print(f"Day {day} - Capital: ₹{current_capital:,.2f}")
        print(f"{'='*60}")
        print(f"Level: Days {level_info['level_start']}-{level_info['level_end']}")
        print(f"Progress: {level_info['progress_percent']:.1f}% of level")
        print(f"Days remaining in level: {level_info['days_remaining_in_level']}")
        
        # Update adapter balance if capital changed
        if day > 1:
            prev_capital = progression.get_capital_for_day(day - 1)
            if current_capital != prev_capital:
                # Capital increased - add the difference
                capital_increase = current_capital - prev_capital
                current_balance = float(adapter.get_balance())
                new_balance = current_balance + capital_increase
                adapter.update_balance(new_balance)
                print(f"[INFO] Capital increased by Rs. {capital_increase:,.2f}")
                print(f"   Previous balance: Rs. {current_balance:,.2f}")
                print(f"   New balance: Rs. {new_balance:,.2f}")
        
        # Get current balance and stats
        balance = float(adapter.get_balance())
        portfolio_value = float(adapter.get_portfolio_value())
        pnl = float(adapter.get_pnl())
        stats = adapter.get_statistics()
        
        print(f"\n[STATUS] Account Status:")
        print(f"   Balance: Rs. {balance:,.2f}")
        print(f"   Portfolio Value: Rs. {portfolio_value:,.2f}")
        print(f"   PnL: Rs. {pnl:,.2f} ({pnl/current_capital*100:.2f}%)")
        print(f"   Total Trades: {stats.get('total_trades', 0)}")
        print(f"   Win Rate: {stats.get('win_rate', 0):.1f}%")
        
        results.append({
            "day": day,
            "capital": current_capital,
            "balance": balance,
            "portfolio_value": portfolio_value,
            "pnl": pnl,
            "pnl_percent": (pnl / current_capital * 100) if current_capital > 0 else 0,
            "stats": stats,
        })
        
        # Simulate day progression (in production, this would be daily)
        if day < progression.total_days:
            print(f"\n[INFO] Simulating day progression...")
            time.sleep(1)  # Small delay for readability
    
    # Final summary
    print("\n" + "=" * 60)
    print("Final Test Summary")
    print("=" * 60)
    
    final_result = results[-1]
    print(f"\n[RESULTS] Final Results:")
    print(f"   Total Days: {progression.total_days}")
    print(f"   Final Capital: Rs. {final_result['capital']:,.2f}")
    print(f"   Final Balance: Rs. {final_result['balance']:,.2f}")
    print(f"   Final Portfolio Value: Rs. {final_result['portfolio_value']:,.2f}")
    print(f"   Total PnL: Rs. {final_result['pnl']:,.2f} ({final_result['pnl_percent']:.2f}%)")
    print(f"   Total Trades: {final_result['stats'].get('total_trades', 0)}")
    print(f"   Final Win Rate: {final_result['stats'].get('win_rate', 0):.1f}%")
    
    # Save results
    results_file = project_root / "_local" / "logs" / f"capital_progression_test_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    results_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(results_file, 'w', encoding='utf-8') as f:
        json.dump({
            "test_date": datetime.now().isoformat(),
            "progression_summary": summary,
            "daily_results": results,
        }, f, indent=2, ensure_ascii=False)
    
    print(f"\n[INFO] Results saved to: {results_file}")
    
    return True


if __name__ == "__main__":
    try:
        success = run_capital_progression_test()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n[WARNING] Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n[ERROR] Test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
