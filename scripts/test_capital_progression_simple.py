"""
Simple Capital Progression Test (Without Live Data)
Tests the capital progression logic without requiring broker authentication
"""

import sys
import os
from pathlib import Path
from datetime import datetime
import time
import json

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv
load_dotenv()

from aurum_harmony.engines.capital_progression import CapitalProgressionManager
from aurum_harmony.engines.trade_execution.trade_execution import PaperBrokerAdapter
from aurum_harmony.engines.trade_execution.leverage_aware_adapter import LeverageAwareAdapter
from decimal import Decimal
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def test_capital_progression_logic():
    """Test capital progression logic without live data"""
    print("=" * 60)
    print("Capital Progression Logic Test (Simple Mode)")
    print("=" * 60)
    print("\nThis test validates the capital progression schedule")
    print("without requiring broker authentication.\n")
    
    # Initialize capital progression
    progression = CapitalProgressionManager()
    print(f"[INFO] Capital Progression Schedule:")
    summary = progression.get_progression_summary()
    for level in summary['levels']:
        print(f"   Day {level['start_day']}-{level['end_day']}: Rs. {level['capital']:,.2f}")
    
    # Create paper trading adapter with initial capital
    initial_capital = progression.get_current_capital()
    print(f"\n[INFO] Starting with capital: Rs. {initial_capital:,.2f}")
    
    try:
        base_adapter = PaperBrokerAdapter(initial_balance=initial_capital)
        # Wrap with leverage-aware adapter (3× leverage for admin category)
        adapter = LeverageAwareAdapter(
            broker_adapter=base_adapter,
            capital=initial_capital,
            user_category="admin",
            leverage_multiplier=3.0
        )
        print("[OK] LeverageAwareAdapter created with 3× leverage")
        print(f"    Base Capital: Rs. {initial_capital:,.2f}")
        print(f"    Max Exposure: Rs. {initial_capital * 3:,.2f} (3× leverage)")
        print(f"    Trading Indices: NIFTY50, BANKNIFTY, SENSEX (simultaneous)")
    except Exception as e:
        print(f"[ERROR] Error creating adapter: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    # Run progression test
    print("\n" + "=" * 60)
    print("Running Capital Progression Test")
    print("=" * 60)
    print("\nNote: This simulates day-by-day progression.\n")
    
    results = []
    
    for day in range(1, progression.total_days + 1):
        level_info = progression.get_level_info(day)
        current_capital = level_info['capital']
        
        print(f"\n{'='*60}")
        print(f"Day {day} - Capital: Rs. {current_capital:,.2f}")
        print(f"{'='*60}")
        print(f"Level: Days {level_info['level_start']}-{level_info['level_end']}")
        print(f"Progress: {level_info['progress_percent']:.1f}% of level")
        print(f"Days remaining in level: {level_info['days_remaining_in_level']}")
        print(f"Max Exposure: Rs. {level_info['max_exposure']:,.2f} (with {level_info['leverage_multiplier']}× leverage)")
        
        # Update adapter balance if capital changed
        if day > 1:
            prev_capital = progression.get_capital_for_day(day - 1)
            if current_capital != prev_capital:
                # Capital increased - add the difference
                capital_increase = current_capital - prev_capital
                current_balance = float(adapter.broker_adapter.get_balance())
                new_balance = current_balance + capital_increase
                adapter.broker_adapter.update_balance(new_balance)
                
                # Update leverage-aware adapter capital
                adapter.capital = Decimal(str(current_capital))
                adapter.max_exposure = adapter.capital * Decimal(str(adapter.leverage_multiplier))
                
                print(f"[INFO] Capital increased by Rs. {capital_increase:,.2f}")
                print(f"   Previous balance: Rs. {current_balance:,.2f}")
                print(f"   New balance: Rs. {new_balance:,.2f}")
                print(f"   New max exposure: Rs. {float(adapter.max_exposure):,.2f} (3× leverage)")
        
        # Get current balance and stats
        balance = float(adapter.get_balance())
        stats = adapter.get_statistics()
        
        # Get exposure status
        exposure_status = adapter.get_exposure_status()
        
        print(f"\n[STATUS] Account Status:")
        print(f"   Balance: Rs. {balance:,.2f}")
        print(f"   Total Orders: {stats.get('total_orders', 0)}")
        print(f"   Open Positions: {stats.get('open_positions', 0)}")
        print(f"\n[LEVERAGE] Exposure Status:")
        print(f"   Capital: Rs. {exposure_status['capital']:,.2f}")
        print(f"   Leverage: {exposure_status['leverage_multiplier']}×")
        print(f"   Max Exposure: Rs. {exposure_status['max_exposure']:,.2f}")
        print(f"   Current Exposure: Rs. {exposure_status['current_exposure']:,.2f}")
        print(f"   Utilization: {exposure_status['utilization_percent']:.1f}%")
        print(f"   Available Exposure: Rs. {exposure_status['available_exposure']:,.2f}")
        
        if exposure_status['exposure_by_index']:
            print(f"\n[INDICES] Exposure by Index:")
            for idx, exp in exposure_status['exposure_by_index'].items():
                print(f"   {idx}: Rs. {exp:,.2f}")
        
        results.append({
            "day": day,
            "capital": current_capital,
            "balance": balance,
            "stats": stats,
        })
        
        # Simulate day progression
        if day < progression.total_days:
            print(f"\n[INFO] Simulating day progression...")
            time.sleep(0.5)  # Small delay for readability
    
    # Final summary
    print("\n" + "=" * 60)
    print("Final Test Summary")
    print("=" * 60)
    
    final_result = results[-1]
    print(f"\n[RESULTS] Final Results:")
    print(f"   Total Days: {progression.total_days}")
    print(f"   Final Capital: Rs. {final_result['capital']:,.2f}")
    print(f"   Final Balance: Rs. {final_result['balance']:,.2f}")
    
    # Save results
    results_file = project_root / "_local" / "logs" / f"capital_progression_simple_test_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    results_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(results_file, 'w', encoding='utf-8') as f:
        json.dump({
            "test_date": datetime.now().isoformat(),
            "progression_summary": summary,
            "daily_results": results,
        }, f, indent=2, ensure_ascii=False)
    
    print(f"\n[INFO] Results saved to: {results_file}")
    print("\n[OK] Capital progression logic test completed successfully!")
    print("\nNext step: Run with live data after authenticating Kotak Neo:")
    print("   1. python scripts\\brokers\\test_kotak_connection.py")
    print("   2. Add tokens to .env file")
    print("   3. python scripts\\test_capital_progression_paper_trading.py")
    
    return True


if __name__ == "__main__":
    try:
        success = test_capital_progression_logic()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n[WARNING] Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n[ERROR] Test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
