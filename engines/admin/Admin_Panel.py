# engines/admin/Admin_Panel.py
from flask import Flask, render_template, request, jsonify
from flask_cors import CORS
import time

app = Flask(__name__, template_folder="../../templates")
CORS(app, resources={r"/*": {"origins": "*"}})

# In-memory user DB (replace with PostgreSQL in production)
users_db = {
    "user001": {
        "user_id": "user001",
        "user_code": "U001",
        "tier": "Empower Start",
        "capital": 10000,
        "trades_today": 0,
        "max_trades": 45,
        "accounts": 1,
        "status": "active",
        "last_settlement": 0,
    }
}


@app.route("/admin")
def admin_dashboard():
    # Pass list of user dicts to the template
    return render_template("admin.html", users=list(users_db.values()))


@app.route("/admin/users", methods=["GET"])
def get_users():
    return jsonify(list(users_db.values()))


@app.route("/admin/update", methods=["POST"])
def update_user():
    data = request.json
    user_id = data.get("user_id")
    if user_id in users_db:
        users_db[user_id].update(data)
        result = {"status": "success", "user_id": user_id, "timestamp": int(time.time())}
    else:
        result = {"status": "error", "message": "User not found"}

    # Hyperledger log placeholder
    # hyperledger_client.log_admin_action(result)

    return jsonify(result)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=False)


