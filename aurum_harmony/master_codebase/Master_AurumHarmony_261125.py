# master_codebase/aurum_harmony.py
# AurumHarmony — Final Consolidated Core — v1.0 Beta (26 Nov 2025)
# Starting capital: ₹10,000 | Revenue: SaffronBolt 70% / ZenithPulse 30%

import os
import sys
import time
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
import threading

# Ensure project root (containing `engines/`) is on sys.path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

# Import all clean engines (Ver 10)
from engines.predictive_ai.VIX_Adjustment_Logic import VIXAdjustment
from engines.predictive_ai.Predictive_AI_Engine import PredictiveAIEngine
from engines.compliance.SEBI_Compliance_Engine import compliance_engine
from engines.fund_push_pull.Dynamic_Fund_Push_Pull_Engine import fund_engine
from engines.settlement.Settlement_Engine import settlement_engine
from engines.notifications.Notifications import notifier
from engines.risk_management.Risk_Management_Engine import risk_engine
from engines.reporting.Reporting_Engine import reporting_engine
from engines.backtesting.Realistic_Tests import run_realistic_tests
from engines.backtesting.Edge_Tests import run_edge_tests
from engines.admin.Admin_Panel import app as admin_app

# Import auth and broker blueprints
try:
    from aurum_harmony.auth.routes import auth_bp
    from aurum_harmony.auth.onboarding_routes import onboarding_bp
    from aurum_harmony.brokers import brokers_bp, kotak_bp, hdfc_bp
    from aurum_harmony.paper_trading import paper_bp
    from aurum_harmony.admin import admin_bp, admin_db_bp
    from aurum_harmony.admin.db_console_routes import db_console_bp
    from aurum_harmony.auth.password_change_routes import password_change_bp
    from aurum_harmony.backtesting.routes import backtest_bp
    from aurum_harmony.database.db import init_db
    AUTH_AVAILABLE = True
except ImportError as e:
    print(f"WARNING: Auth blueprint not available: {e}")
    import traceback
    traceback.print_exc()
    AUTH_AVAILABLE = False
    auth_bp = None
    onboarding_bp = None
    brokers_bp = None
    kotak_bp = None
    hdfc_bp = None
    paper_bp = None
    admin_bp = None
    admin_db_bp = None
    backtest_bp = None

app = Flask(__name__)
# Configure CORS to handle OPTIONS requests properly
CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With"],
        "supports_credentials": True
    }
})

# Initialize database and register blueprints
if AUTH_AVAILABLE:
    try:
        init_db(app)
        
        # Smart migration: Only run if flag file doesn't exist
        # This speeds up subsequent startups significantly
        from pathlib import Path
        migration_flag = Path(os.path.join(BASE_DIR, "_local", ".db_migration_completed"))
        
        # Create _local directory if it doesn't exist
        migration_flag.parent.mkdir(parents=True, exist_ok=True)
        
        # Check if we need to run migrations
        FORCE_MIGRATION = os.getenv("FORCE_DB_MIGRATION", "false").lower() == "true"
        
        if FORCE_MIGRATION or not migration_flag.exists():
            print("Running database migrations...")
            try:
                from aurum_harmony.database.migrate import migrate_user_fields
                with app.app_context():
                    migrate_user_fields()
                    # Mark migration as completed
                    migration_flag.touch()
                    print("[OK] Database migrations completed")
            except Exception as migration_error:
                import logging
                logging.warning(f"Migration error (non-fatal): {migration_error}")
                # Don't create flag if migration failed
        else:
            print("[OK] Database migrations already completed (skipping)")
        
        app.register_blueprint(auth_bp)
        if onboarding_bp:
            app.register_blueprint(onboarding_bp)
        app.register_blueprint(password_change_bp)
        app.register_blueprint(brokers_bp)
        if kotak_bp:
            app.register_blueprint(kotak_bp)
        if hdfc_bp:
            app.register_blueprint(hdfc_bp)
        if paper_bp:
            app.register_blueprint(paper_bp)
        if admin_bp:
            app.register_blueprint(admin_bp)
        if admin_db_bp:
            app.register_blueprint(admin_db_bp)
        app.register_blueprint(db_console_bp)
        if backtest_bp:
            app.register_blueprint(backtest_bp)
        print("SUCCESS: Auth, broker, paper trading, admin, database admin, and backtesting blueprints registered")
        if kotak_bp:
            print("  - Kotak Neo broker routes registered")
        if hdfc_bp:
            print("  - HDFC Sky broker routes registered")
        if backtest_bp:
            print("  - Broker-integrated backtesting routes registered")
    except Exception as e:
        print(f"WARNING: Error initializing auth: {e}")
        import traceback
        traceback.print_exc()
        AUTH_AVAILABLE = False
else:
    print("WARNING: Auth and broker blueprints not registered")
    # Register paper trading even if auth fails (it's independent)
    try:
        from aurum_harmony.paper_trading import paper_bp
        if paper_bp:
            app.register_blueprint(paper_bp)
            print("Paper trading blueprint registered")
    except Exception as e:
        print(f"WARNING: Paper trading blueprint not available: {e}")

# Global instances (legacy - kept for backward compatibility)
vix_adj = VIXAdjustment()
ai_engine = PredictiveAIEngine()
risk_engine = risk_engine

# New integrated system (preferred)
try:
    from aurum_harmony.app.system_integration import aurum_system
except ImportError:
    aurum_system = None

@app.route('/health')
@app.route('/api/health')
def health():
    return jsonify({"status": "AurumHarmony v1.0 Beta running", "time": int(time.time())})

@app.route("/predict", methods=["POST"])
def predict():
    data = request.json
    features = data["features"]
    capital = data.get("capital", 10000)

    # 1. VIX adjustment
    vix_result = vix_adj.adjust(data["vix"], capital)
    
    # 2. AI prediction
    prediction = ai_engine.predict(features)
    
    # 3. Risk check
    risk_result = risk_engine.check_drawdown(capital, data.get("peak", capital))
    
    return jsonify(
        {
        "vix_adjustment": vix_result,
        "prediction": prediction,
        "risk": risk_result,
            "timestamp": int(time.time()),
        }
    )

@app.route('/settle', methods=['POST'])
def settle():
    """
    Expected JSON payload (historic beta API):
    {
        "user_id": "U123",
        "category": "restricted",  # NGD / restricted / semi / admin
        "current_capital": 10000,
        "gross_profit": 25000
    }
    """
    data = request.json
    result = settlement_engine.settle(
        data["user_id"],
        float(data["gross_profit"]),
        data.get("category", "restricted"),
        float(data.get("current_capital", 10000)),
    )
    return jsonify(result)


@app.route("/report/user/<user_id>", methods=["GET"])
def user_report(user_id: str):
    """
    Simple user-level PnL summary, backed by the reporting engine.
    """
    summary = reporting_engine.user_trade_summary(user_id)
    return jsonify(summary)


@app.route("/backtest/realistic", methods=["GET"])
def backtest_realistic():
    """
    Run a realistic 20-day simulation using the current VIX logic.
    
    NOTE: For broker-integrated backtesting with real data, use /api/backtest/realistic instead.
    This endpoint is kept for backward compatibility and VIX-based simulation.
    """
    result = run_realistic_tests()
    return jsonify(result)


@app.route("/backtest/edge", methods=["GET"])
def backtest_edge():
    """
    Run an extreme VIX stress test.
    
    NOTE: For broker-integrated backtesting with real data, use /api/backtest/edge instead.
    This endpoint is kept for backward compatibility and VIX-based simulation.
    """
    result = run_edge_tests()
    return jsonify(result)

@app.route("/api/unified-snapshot/health", methods=["GET", "OPTIONS"])
def get_unified_snapshot_health():
    """
    Health check for unified snapshot system.
    Returns engine availability status without fetching full snapshot.
    """
    try:
        from aurum_harmony.engines.trade_execution.broker_aggregator import BrokerAggregator
        from aurum_harmony.engines.trade_execution.broker_adapter_factory import (
            create_broker_adapter,
        )
        from aurum_harmony.brokers.hdfc_sky import get_hdfc_client
        from aurum_harmony.brokers.kotak_neo import get_kotak_client
        from aurum_harmony.paper_trading.routes import get_user_adapter
        
        # Get user_id from request
        user_id_param = request.args.get('user_id', 'default_user')
        # Try to convert to int if it's numeric, otherwise use as string
        try:
            user_id = int(user_id_param)
        except (ValueError, TypeError):
            user_id = user_id_param
        
        # Get broker clients from database (with env fallback)
        hdfc_client = get_hdfc_client(user_id)
        kotak_client = get_kotak_client(user_id)
        
        # Create minimal adapters for health check
        hdfc_nse_adapter = None
        hdfc_bse_adapter = None
        kotak_nse_adapter = None
        kotak_bse_adapter = None
        
        if hdfc_client:
            hdfc_nse_adapter = create_broker_adapter(
                use_hdfc_for_paper=True,
                hdfc_client=hdfc_client,
                initial_balance=100000.0,
            )
            hdfc_bse_adapter = create_broker_adapter(
                use_hdfc_for_paper=True,
                hdfc_client=hdfc_client,
                initial_balance=100000.0,
            )
        
        if kotak_client:
            kotak_nse_adapter = create_broker_adapter(
                use_live_data=True,
                kotak_client=kotak_client,
                initial_balance=100000.0,
            )
            kotak_bse_adapter = create_broker_adapter(
                use_live_data=True,
                kotak_client=kotak_client,
                initial_balance=100000.0,
            )
        
        paper_adapter = get_user_adapter(user_id, initial_balance=100000.0)
        
        # Create aggregator and get status
        aggregator = BrokerAggregator(
            hdfc_nse_adapter=hdfc_nse_adapter,
            hdfc_bse_adapter=hdfc_bse_adapter,
            kotak_nse_adapter=kotak_nse_adapter,
            kotak_bse_adapter=kotak_bse_adapter,
            paper_adapter=paper_adapter,
        )
        
        status = aggregator.get_status_summary()
        
        return jsonify({
            'success': True,
            'status': status,
            'message': f'{status["total_engines"]} engines configured'
        }), 200
        
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Error getting unified snapshot health: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e),
            'message': 'Failed to get health status'
        }), 500


@app.route("/api/unified-snapshot", methods=["GET", "OPTIONS"])
def get_unified_snapshot():
    """
    Get unified snapshot from all trading engines (HDFC Sky NSE/BSE, Kotak Neo NSE/BSE, Paper, Backtest).
    This endpoint aggregates data from all 8 engines into a single unified view.
    """
    try:
        from flask import request
        from aurum_harmony.engines.trade_execution.broker_aggregator import BrokerAggregator
        from aurum_harmony.engines.trade_execution.broker_adapter_factory import (
            create_broker_adapter,
        )
        from aurum_harmony.brokers.hdfc_sky import get_hdfc_client
        from aurum_harmony.brokers.kotak_neo import get_kotak_client
        from aurum_harmony.paper_trading.routes import get_user_adapter
        
        # Get user_id from request (from auth or query param)
        user_id = None
        if hasattr(request, 'current_user') and request.current_user:
            user_id = request.current_user.id  # Use int ID
        else:
            # Fallback: get from query param or use default
            user_id_param = request.args.get('user_id', 'default_user')
            # Try to convert to int if it's numeric, otherwise use as string
            try:
                user_id = int(user_id_param)
            except (ValueError, TypeError):
                user_id = user_id_param
        
        # Get broker clients from database (with env fallback)
        hdfc_client = get_hdfc_client(user_id)
        kotak_client = get_kotak_client(user_id)
        
        # Create adapters for each exchange
        hdfc_nse_adapter = None
        hdfc_bse_adapter = None
        kotak_nse_adapter = None
        kotak_bse_adapter = None
        
        if hdfc_client:
            # For now, use same client for both NSE and BSE
            # In future, could have separate clients per exchange
            hdfc_nse_adapter = create_broker_adapter(
                use_hdfc_for_paper=True,
                hdfc_client=hdfc_client,
                initial_balance=100000.0,
            )
            hdfc_bse_adapter = create_broker_adapter(
                use_hdfc_for_paper=True,
                hdfc_client=hdfc_client,
                initial_balance=100000.0,
            )
        
        if kotak_client:
            kotak_nse_adapter = create_broker_adapter(
                use_live_data=True,
                kotak_client=kotak_client,
                initial_balance=100000.0,
            )
            kotak_bse_adapter = create_broker_adapter(
                use_live_data=True,
                kotak_client=kotak_client,
                initial_balance=100000.0,
            )
        
        # Get paper trading adapter
        paper_adapter = get_user_adapter(user_id, initial_balance=100000.0)
        
        # Create aggregator and get unified snapshot
        aggregator = BrokerAggregator(
            hdfc_nse_adapter=hdfc_nse_adapter,
            hdfc_bse_adapter=hdfc_bse_adapter,
            kotak_nse_adapter=kotak_nse_adapter,
            kotak_bse_adapter=kotak_bse_adapter,
            paper_adapter=paper_adapter,
        )
        
        snapshot = aggregator.get_unified_snapshot(timeout=5.0)
        
        return jsonify({
            'success': True,
            'snapshot': snapshot.to_dict(),
            'message': f'Unified snapshot collected from {snapshot.available_engines}/{snapshot.total_engines} engines'
        }), 200
        
    except Exception as e:
        import traceback
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Error getting unified snapshot: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e),
            'message': 'Failed to collect unified snapshot'
        }), 500


@app.route("/api/orchestrator/run", methods=["POST"])
def orchestrator_run():
    """
    Run the trading orchestrator once to execute paper trades automatically.
    This endpoint triggers the orchestrator to:
    1. Fetch signals from AI engine
    2. Run through risk engine
    3. Automatically execute approved trades in paper trading mode
    """
    try:
        data = request.json or {}
        user_id = data.get('user_id')
        auto_execute = data.get('auto_execute', True)
        
        # Import orchestrator components
        from aurum_harmony.app.orchestrator import TradingOrchestrator
        from aurum_harmony.engines.trade_execution.broker_aggregator import BrokerAggregator
        from aurum_harmony.engines.trade_execution.broker_adapter_factory import (
            get_hdfc_client_from_env,
            get_kotak_client_from_env,
            create_broker_adapter,
        )
        from aurum_harmony.paper_trading.routes import get_user_adapter
        
        # Create broker aggregator for unified multi-engine support
        hdfc_client = get_hdfc_client_from_env()
        kotak_client = get_kotak_client_from_env()
        
        hdfc_nse_adapter = None
        hdfc_bse_adapter = None
        kotak_nse_adapter = None
        kotak_bse_adapter = None
        
        if hdfc_client:
            hdfc_nse_adapter = create_broker_adapter(
                use_hdfc_for_paper=True,
                hdfc_client=hdfc_client,
                initial_balance=100000.0,
            )
            hdfc_bse_adapter = create_broker_adapter(
                use_hdfc_for_paper=True,
                hdfc_client=hdfc_client,
                initial_balance=100000.0,
            )
        
        if kotak_client:
            kotak_nse_adapter = create_broker_adapter(
                use_live_data=True,
                kotak_client=kotak_client,
                initial_balance=100000.0,
            )
            kotak_bse_adapter = create_broker_adapter(
                use_live_data=True,
                kotak_client=kotak_client,
                initial_balance=100000.0,
            )
        
        paper_adapter = get_user_adapter(user_id or 'default_user', initial_balance=100000.0)
        
        broker_aggregator = BrokerAggregator(
            hdfc_nse_adapter=hdfc_nse_adapter,
            hdfc_bse_adapter=hdfc_bse_adapter,
            kotak_nse_adapter=kotak_nse_adapter,
            kotak_bse_adapter=kotak_bse_adapter,
            paper_adapter=paper_adapter,
        )
        
        # Create orchestrator with AI engine as signal source and aggregator
        # PredictiveAIEngine is already imported at the top of this file
        signal_source = PredictiveAIEngine()
        orchestrator = TradingOrchestrator(
            signal_source=signal_source,
            broker_aggregator=broker_aggregator
        )
        
        # Run orchestrator once
        orders = orchestrator.run_once()
        
        # Count executed orders
        executed_count = len([o for o in orders if o.status.value == "FILLED"])
        rejected_count = len([o for o in orders if o.status.value == "REJECTED"])
        
        return jsonify({
            'success': True,
            'signals_processed': orchestrator.execution_stats.get('total_signals', 0),
            'orders_executed': executed_count,
            'orders_rejected': rejected_count,
            'orders': [
                {
                    'symbol': o.symbol,
                    'side': o.side.value,
                    'quantity': float(o.quantity),
                    'status': o.status.value,
                    'broker_order_id': o.broker_order_id,
                }
                for o in orders
            ],
            'message': f'Orchestrator run complete: {executed_count} orders executed, {rejected_count} rejected'
        })
    except Exception as e:
        import traceback
        return jsonify({
            'success': False,
            'error': str(e),
            'traceback': traceback.format_exc()
        }), 500


@app.route("/api/scheduler/start", methods=["POST"])
@auth_bp.route("/api/scheduler/start", methods=["POST"])
def start_daily_scheduler():
    """
    Start the daily cycle scheduler for automated trading operations.
    This initializes the scheduler that handles:
    - Pre-market preparation (8:30 AM)
    - Market open (9:30 AM)
    - Auto logoff (4:30 PM)
    """
    try:
        # Import orchestrator components
        from aurum_harmony.app.orchestrator import TradingOrchestrator
        from aurum_harmony.engines.scheduling.daily_cycle_scheduler import DailyCycleScheduler
from aurum_harmony.engines.scheduling.trading_calendar import TradingCalendar

        # Create a basic orchestrator for scheduler (simplified)
        from engines.predictive_ai.Predictive_AI_Engine import PredictiveAIEngine
        signal_source = PredictiveAIEngine()

        # Create orchestrator with signal source
        orchestrator = TradingOrchestrator(signal_source=signal_source)

        # Start the daily scheduler
        orchestrator.daily_scheduler.start_scheduler()

        return jsonify({
            'success': True,
            'message': 'Daily cycle scheduler started successfully',
            'schedule': {
                'pre_market_start': '08:30 IST',
                'trading_start': '09:30 IST',
                'market_close': '16:30 IST',
                'extended_close': '17:00 IST'
            }
        }), 200

    except Exception as e:
        import traceback
        return jsonify({
            'success': False,
            'error': str(e),
            'traceback': traceback.format_exc()
        }), 500


@app.route("/api/scheduler/status", methods=["GET"])
@auth_bp.route("/api/scheduler/status", methods=["GET"])
def get_scheduler_status():
    """
    Get the current status of the daily cycle scheduler.
    """
    try:
        # Import orchestrator components
        from aurum_harmony.app.orchestrator import TradingOrchestrator
        from engines.predictive_ai.Predictive_AI_Engine import PredictiveAIEngine

        # Create a basic orchestrator to check scheduler status
        signal_source = PredictiveAIEngine()
        orchestrator = TradingOrchestrator(signal_source=signal_source)

        scheduler_status = orchestrator.daily_scheduler.get_system_status()

        return jsonify({
            'success': True,
            'scheduler_status': scheduler_status
        }), 200

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route("/api/scheduler/stop", methods=["POST"])
@auth_bp.route("/api/scheduler/stop", methods=["POST"])
def stop_daily_scheduler():
    """
    Stop the daily cycle scheduler.
    """
    try:
        # Import orchestrator components
        from aurum_harmony.app.orchestrator import TradingOrchestrator
        from engines.predictive_ai.Predictive_AI_Engine import PredictiveAIEngine

        # Create a basic orchestrator to stop scheduler
        signal_source = PredictiveAIEngine()
        orchestrator = TradingOrchestrator(signal_source=signal_source)

        orchestrator.daily_scheduler.stop_scheduler()

        return jsonify({
            'success': True,
            'message': 'Daily cycle scheduler stopped successfully'
        }), 200

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route("/api/calendar/status", methods=["GET"])
def get_market_status():
    """
    Get current market status and trading calendar information.
    """
    try:
        calendar = TradingCalendar()
        status = calendar.get_market_status()

        return jsonify({
            'success': True,
            'market_status': status
        }), 200

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route("/api/calendar/trading-days", methods=["GET"])
def get_trading_days():
    """
    Calculate trading days in a date range.

    Query parameters:
    - start_date: Start date (YYYY-MM-DD)
    - end_date: End date (YYYY-MM-DD)
    """
    try:
        from datetime import datetime

        start_date_str = request.args.get('start_date')
        end_date_str = request.args.get('end_date')

        if not start_date_str or not end_date_str:
            return jsonify({
                'success': False,
                'error': 'start_date and end_date are required'
            }), 400

        # Parse dates
        start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
        end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()

        calendar = TradingCalendar()

        trading_days = calendar.get_trading_days_in_range(start_date, end_date)
        total_trading_days = len(trading_days)
        total_calendar_days = (end_date - start_date).days + 1

        return jsonify({
            'success': True,
            'start_date': start_date_str,
            'end_date': end_date_str,
            'total_calendar_days': total_calendar_days,
            'total_trading_days': total_trading_days,
            'non_trading_days': total_calendar_days - total_trading_days,
            'trading_days': [day.isoformat() for day in trading_days]
        }), 200

    except ValueError as e:
        return jsonify({
            'success': False,
            'error': f'Invalid date format: {e}'
        }), 400
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route("/api/calendar/is-trading-day", methods=["GET"])
def check_trading_day():
    """
    Check if a specific date is a trading day.

    Query parameters:
    - date: Date to check (YYYY-MM-DD, defaults to today)
    """
    try:
        from datetime import datetime

        date_str = request.args.get('date')

        if date_str:
            check_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        else:
            check_date = datetime.now().date()

        calendar = TradingCalendar()
        day_info = calendar.get_day_info(check_date)

        return jsonify({
            'success': True,
            'date': check_date.isoformat(),
            'is_trading_day': day_info.is_trading_day,
            'reason': day_info.reason,
            'market_open_time': day_info.market_open_time,
            'market_close_time': day_info.market_close_time
        }), 200

    except ValueError as e:
        return jsonify({
            'success': False,
            'error': f'Invalid date format: {e}'
        }), 400
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route("/api/calendar/holidays", methods=["GET"])
def get_upcoming_holidays():
    """
    Get upcoming holidays and non-trading days.

    Query parameters:
    - days_ahead: Number of days to look ahead (default: 30)
    """
    try:
        days_ahead = int(request.args.get('days_ahead', 30))

        calendar = TradingCalendar()
        holidays = calendar.get_upcoming_holidays(days_ahead)

        return jsonify({
            'success': True,
            'days_ahead': days_ahead,
            'upcoming_holidays': holidays
        }), 200

    except ValueError as e:
        return jsonify({
            'success': False,
            'error': f'Invalid days_ahead parameter: {e}'
        }), 400
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/callback')
def callback():
    """
    OAuth callback endpoint for broker integrations (HDFC Sky, etc.)
    """
    request_token = request.args.get('request_token')
    if request_token:
        return jsonify({
            'message': 'Callback received',
            'request_token': request_token
        }), 200
    return jsonify({'message': 'Callback endpoint'}), 200

# Initialize complete AurumHarmony system
try:
    from aurum_harmony.app.system_integration import aurum_system
    print("[OK] AurumHarmony System initialized")
    
    # Start all background services
    aurum_system.start_all_services()
    print("[OK] All background services started")
except Exception as e:
    print(f"WARNING: Error initializing AurumHarmony system: {e}")
    import traceback
    traceback.print_exc()
    aurum_system = None

if __name__ == "__main__":
    # Run main app + admin panel
    print("Starting AurumHarmony Backend...")
    print("Main app: http://localhost:5000")
    print("Admin panel: http://localhost:5001")
    print("Press Ctrl+C to stop")
    print("")
    
    # Run main app in background thread
    threading.Thread(target=lambda: app.run(host='0.0.0.0', port=5000, debug=False), daemon=True).start()
    
    # Give main app time to start
    import time
    time.sleep(2)
    
    # Run admin panel (this will block, keeping the process alive)
    try:
        admin_app.run(host='0.0.0.0', port=5001, debug=False)
    except KeyboardInterrupt:
        print("\nShutting down...")