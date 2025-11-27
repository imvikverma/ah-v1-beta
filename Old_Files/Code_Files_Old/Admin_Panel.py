from flask import Flask, render_template, request, jsonify

app = Flask(__name__, template_folder='templates')

users = {"user1": {"tier": "Alpha Innovator", "ic": 7500, "trades_day": 27, "category": "Alpha-Beta", "demats": 4}}
tiers = {"Alpha-Beta": ["Alpha Innovator", "Beta Explorer"]}
ic_limits = {"Alpha-Beta": [7500, 100000]}
trades_day_limits = {"Alpha-Beta": [27, 45]}

@app.route('/admin')
def admin_panel():
    return render_template('admin.html', users=users, tiers=tiers, ic_limits=ic_limits, trades_day_limits=trades_day_limits)

@app.route('/admin/update', methods=['POST'])
def update_user():
    data = request.json
    user_id = data.get('user_id')
    if user_id in users:
        users[user_id].update(data)
        return jsonify({"status": "success"})
    return jsonify({"status": "error"})

if __name__ == '__main__':
    app.run(debug=True)