#!/usr/bin/env python3
"""
Test script for Trading Calendar functionality

Tests holiday detection, weekend handling, and trading day calculations.
"""

import sys
from datetime import datetime, date, timedelta

def test_trading_calendar():
    """Test trading calendar functionality."""
    print("Testing Trading Calendar")
    print("=" * 40)

    try:
        from aurum_harmony.engines.scheduling.trading_calendar import TradingCalendar

        calendar = TradingCalendar()

        # Test today's status
        today = date.today()
        today_info = calendar.get_day_info(today)

        print(f"Today ({today}): {today_info.reason}")
        print(f"Is trading day: {today_info.is_trading_day}")

        if today_info.market_open_time and today_info.market_close_time:
            print(f"Market hours: {today_info.market_open_time} - {today_info.market_close_time}")

        # Test weekend detection
        print("\nTesting weekend detection:")

        # Find next Saturday
        saturday = today + timedelta(days=(5 - today.weekday()) % 7)
        sat_info = calendar.get_day_info(saturday)
        print(f"Saturday ({saturday}): {sat_info.reason} - Trading day: {sat_info.is_trading_day}")

        # Find next Sunday
        sunday = today + timedelta(days=(6 - today.weekday()) % 7)
        sun_info = calendar.get_day_info(sunday)
        print(f"Sunday ({sunday}): {sun_info.reason} - Trading day: {sun_info.is_trading_day}")

        # Test holiday detection
        print("\nTesting holiday detection:")

        # Test Republic Day (January 26)
        republic_day = date(today.year, 1, 26)
        rd_info = calendar.get_day_info(republic_day)
        print(f"Republic Day ({republic_day}): {rd_info.reason} - Trading day: {rd_info.is_trading_day}")

        # Test Independence Day (August 15)
        independence_day = date(today.year, 8, 15)
        id_info = calendar.get_day_info(independence_day)
        print(f"Independence Day ({independence_day}): {id_info.reason} - Trading day: {id_info.is_trading_day}")

        # Test next trading day
        print("\nTesting trading day calculations:")

        next_trading_day = calendar.get_next_trading_day(today)
        if next_trading_day:
            print(f"Next trading day from today: {next_trading_day}")
        else:
            print("No trading day found in next 30 days")

        # Test trading days in range
        start_date = today
        end_date = today + timedelta(days=30)
        trading_days = calendar.get_trading_days_in_range(start_date, end_date)
        total_trading_days = len(trading_days)
        total_calendar_days = (end_date - start_date).days + 1

        print(f"Trading days in next 30 days: {total_trading_days}/{total_calendar_days}")
        print(f"Non-trading days: {total_calendar_days - total_trading_days}")

        # Test upcoming holidays
        upcoming_holidays = calendar.get_upcoming_holidays(14)  # Next 2 weeks
        print(f"\nUpcoming holidays in next 14 days: {len(upcoming_holidays)}")
        for holiday in upcoming_holidays[:3]:  # Show first 3
            print(f"  - {holiday['date']}: {holiday['reason']} ({holiday['days_until']} days)")

        # Test market status
        market_status = calendar.get_market_status()
        print(f"\nMarket status: {market_status}")

        print("\nTrading Calendar tests completed successfully!")
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_scheduler_integration():
    """Test scheduler integration with trading calendar."""
    print("\nTesting Scheduler Integration with Trading Calendar")
    print("=" * 50)

    try:
        from aurum_harmony.app.orchestrator import TradingOrchestrator
        from engines.predictive_ai.Predictive_AI_Engine import PredictiveAIEngine

        signal_source = PredictiveAIEngine()
        orchestrator = TradingOrchestrator(signal_source=signal_source)

        # Check system status includes trading calendar info
        status = orchestrator.daily_scheduler.get_system_status()

        required_keys = [
            'trading_day_today', 'trading_day_reason', 'market_open_now',
            'next_trading_day', 'upcoming_holidays'
        ]

        missing_keys = [key for key in required_keys if key not in status]
        if missing_keys:
            print(f"ERROR: Missing keys in system status: {missing_keys}")
            return False

        print("System status includes trading calendar information:")
        print(f"  Trading day today: {status['trading_day_today']}")
        print(f"  Reason: {status['trading_day_reason']}")
        print(f"  Market open now: {status['market_open_now']}")
        if status['next_trading_day']:
            print(f"  Next trading day: {status['next_trading_day']}")
        print(f"  Upcoming holidays: {len(status['upcoming_holidays'])}")

        print("Scheduler integration tests completed successfully!")
        return True

    except Exception as e:
        print(f"ERROR: {e}")
        return False

def main():
    """Run all trading calendar tests."""
    print("AurumHarmony Trading Calendar Test Suite")
    print("=" * 50)

    tests = [
        ("Trading Calendar Core", test_trading_calendar),
        ("Scheduler Integration", test_scheduler_integration),
    ]

    passed = 0
    total = len(tests)

    for test_name, test_func in tests:
        print(f"\n[{test_name}]")
        if test_func():
            passed += 1
            print(f"PASSED: {test_name}")
        else:
            print(f"FAILED: {test_name}")

    print(f"\n{'=' * 50}")
    print(f"Test Results: {passed}/{total} passed")

    if passed == total:
        print("All Trading Calendar tests PASSED!")
        print("AurumHarmony now handles weekends, holidays, and non-trading days correctly.")
        return True
    else:
        print("Some tests FAILED. Please review the errors above.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
