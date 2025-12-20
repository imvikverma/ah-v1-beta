#!/usr/bin/env python3
"""
Test script for the Daily Cycle Scheduler

Tests the automated daily trading cycle functionality.
"""

import time
import sys
from datetime import datetime, timedelta

def test_scheduler_initialization():
    """Test scheduler initialization."""
    print("Testing Daily Cycle Scheduler initialization...")

    try:
        from aurum_harmony.app.orchestrator import TradingOrchestrator
        from aurum_harmony.engines.scheduling.daily_cycle_scheduler import DailyCycleScheduler
        from engines.predictive_ai.Predictive_AI_Engine import PredictiveAIEngine

        # Create signal source
        signal_source = PredictiveAIEngine()

        # Create orchestrator
        orchestrator = TradingOrchestrator(signal_source=signal_source)

        # Check if scheduler was initialized
        assert hasattr(orchestrator, 'daily_scheduler'), "Scheduler not initialized"
        assert orchestrator.daily_scheduler is not None, "Scheduler is None"

        # Check scheduler attributes
        scheduler = orchestrator.daily_scheduler
        assert hasattr(scheduler, 'regulatory_monitor'), "Regulatory monitor not initialized"
        assert hasattr(scheduler, 'market_intelligence'), "Market intelligence not initialized"

        print("✓ Scheduler initialization successful")
        return True

    except Exception as e:
        print(f"✗ Scheduler initialization failed: {e}")
        return False

def test_scheduler_status():
    """Test scheduler status reporting."""
    print("Testing scheduler status reporting...")

    try:
        from aurum_harmony.app.orchestrator import TradingOrchestrator
        from engines.predictive_ai.Predictive_AI_Engine import PredictiveAIEngine

        signal_source = PredictiveAIEngine()
        orchestrator = TradingOrchestrator(signal_source=signal_source)

        status = orchestrator.daily_scheduler.get_system_status()

        required_keys = ['market_open', 'system_active', 'pre_market_prepared', 'scheduler_running']
        for key in required_keys:
            assert key in status, f"Missing status key: {key}"

        print(f"✓ Scheduler status: {status}")
        return True

    except Exception as e:
        print(f"✗ Scheduler status test failed: {e}")
        return False

def test_regulatory_monitor():
    """Test regulatory monitor functionality."""
    print("Testing regulatory monitor...")

    try:
        from aurum_harmony.engines.compliance.regulatory_monitor import RegulatoryMonitor

        monitor = RegulatoryMonitor()

        # Test update checking (this may not find real updates in test environment)
        updates = monitor.check_for_updates()
        assert isinstance(updates, list), "Updates should be a list"

        # Test critical updates
        critical = monitor.get_critical_updates()
        assert isinstance(critical, list), "Critical updates should be a list"

        print(f"✓ Regulatory monitor working - found {len(updates)} updates, {len(critical)} critical")
        return True

    except Exception as e:
        print(f"✗ Regulatory monitor test failed: {e}")
        return False

def test_market_intelligence():
    """Test market intelligence engine."""
    print("Testing market intelligence engine...")

    try:
        from aurum_harmony.engines.market_intelligence.market_intelligence import MarketIntelligenceEngine

        engine = MarketIntelligenceEngine()

        # Test intelligence gathering (this may not find real events in test environment)
        events = engine.gather_intelligence()
        assert isinstance(events, list), "Events should be a list"

        # Test sentiment analysis
        sentiment = engine.get_market_sentiment()
        assert 'overall' in sentiment, "Sentiment should have overall key"
        assert sentiment['overall'] in ['positive', 'negative', 'neutral'], "Invalid sentiment value"

        print(f"✓ Market intelligence working - found {len(events)} events, sentiment: {sentiment['overall']}")
        return True

    except Exception as e:
        print(f"✗ Market intelligence test failed: {e}")
        return False

def test_scheduler_methods():
    """Test that orchestrator has all required scheduler methods."""
    print("Testing orchestrator scheduler integration methods...")

    try:
        from aurum_harmony.app.orchestrator import TradingOrchestrator
        from engines.predictive_ai.Predictive_AI_Engine import PredictiveAIEngine

        signal_source = PredictiveAIEngine()
        orchestrator = TradingOrchestrator(signal_source=signal_source)

        # Check that all required methods exist
        required_methods = [
            'start_trading_session',
            'stop_trading_session',
            'get_open_positions',
            'square_off_position',
            'calculate_daily_pnl',
            'process_daily_settlement',
            'update_user_capital_after_settlement',
            'generate_performance_report',
            'generate_settlement_report',
            'generate_risk_report',
            'close_broker_connections',
            'save_system_state',
            'reset_daily_counters',
            'archive_daily_logs',
            'update_system_status',
            'check_database_connection',
            'check_broker_connections',
            'check_market_data_feeds',
            'check_risk_engine_status',
            'check_settlement_engine_status'
        ]

        for method in required_methods:
            assert hasattr(orchestrator, method), f"Missing method: {method}"

        print(f"✓ All {len(required_methods)} scheduler integration methods present")
        return True

    except Exception as e:
        print(f"✗ Scheduler methods test failed: {e}")
        return False

def run_tests():
    """Run all daily scheduler tests."""
    print("=" * 60)
    print("DAILY CYCLE SCHEDULER TEST SUITE")
    print("=" * 60)
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    tests = [
        ("Scheduler Initialization", test_scheduler_initialization),
        ("Scheduler Status", test_scheduler_status),
        ("Regulatory Monitor", test_regulatory_monitor),
        ("Market Intelligence", test_market_intelligence),
        ("Scheduler Methods", test_scheduler_methods),
    ]

    passed = 0
    total = len(tests)

    for test_name, test_func in tests:
        print(f"[{test_name}]")
        if test_func():
            passed += 1
        print()

    print("=" * 60)
    print("TEST RESULTS SUMMARY")
    print("=" * 60)
    print(f"Total Tests: {total}")
    print(f"Passed: {passed}")
    print(f"Failed: {total - passed}")
    print(f"Success Rate: {(passed/total*100):.1f}%")
    print()

    if passed == total:
        print("🎉 ALL TESTS PASSED! Daily Cycle Scheduler is ready!")
        return True
    else:
        print("⚠️  Some tests failed. Please review the issues above.")
        return False

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)
