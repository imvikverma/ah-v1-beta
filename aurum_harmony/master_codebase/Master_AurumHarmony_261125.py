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
    from aurum_harmony.brokers import brokers_bp
    from aurum_harmony.paper_trading import paper_bp
    from aurum_harmony.admin import admin_bp, admin_db_bp
    from aurum_harmony.database.db import init_db
    AUTH_AVAILABLE = True
except ImportError as e:
    print(f"WARNING: Auth blueprint not available: {e}")
    import traceback
    traceback.print_exc()
    AUTH_AVAILABLE = False
    auth_bp = None
    brokers_bp = None
    paper_bp = None
    admin_bp = None
    admin_db_bp = None

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
        app.register_blueprint(auth_bp)
        app.register_blueprint(brokers_bp)
        if paper_bp:
            app.register_blueprint(paper_bp)
        if admin_bp:
            app.register_blueprint(admin_bp)
        if admin_db_bp:
            app.register_blueprint(admin_db_bp)
        print("SUCCESS: Auth, broker, paper trading, admin, and database admin blueprints registered")
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

# Global instances
vix_adj = VIXAdjustment()
ai_engine = PredictiveAIEngine()
risk_engine = risk_engine

@app.route('/health')
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
    """
    result = run_realistic_tests()
    return jsonify(result)


@app.route("/backtest/edge", methods=["GET"])
def backtest_edge():
    """
    Run an extreme VIX stress test.
    """
    result = run_edge_tests()
    return jsonify(result)

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

# Background threads
def daily_fund_cycle():
    while True:
        now = datetime.now().strftime("%H:%M")
        if now == "09:15":
            # Push funds for all active users
            pass
        elif now == "15:25":
            # Pull funds for all active users
            pass
        time.sleep(60)

# Start background services
threading.Thread(target=daily_fund_cycle, daemon=True).start()
# regulatory_workflow.start_all()  # Uncomment when live
# realtime_fetcher.start_all()

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