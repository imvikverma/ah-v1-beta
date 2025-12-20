from flask import Flask, request, jsonify
from api.hdfc_sky import get_access_token
from api.kotak_neo import get_access_token as get_kotak_access_token

app = Flask(__name__)

@app.route('/hdfc/access-token')
def hdfc_access_token():
    request_token = request.args.get('request_token')
    if not request_token:
        return jsonify({"error": "Missing request_token parameter"}), 400
    response = get_access_token(request_token)
    if response.status_code == 200:
        return jsonify(response.json())
    else:
        return jsonify({"error": response.text}), response.status_code

@app.route('/kotak/access-token')
def kotak_access_token():
    request_token = request.args.get('request_token')
    if not request_token:
        return jsonify({"error": "Missing request_token parameter"}), 400
    response = get_kotak_access_token(request_token)
    if response.status_code == 200:
        return jsonify(response.json())
    else:
        return jsonify({"error": response.text}), response.status_code

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000) 