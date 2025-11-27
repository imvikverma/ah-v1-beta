from flask import Flask, request, jsonify, redirect
from dotenv import load_dotenv
import os
import requests

load_dotenv()

app = Flask(__name__)

@app.route('/')
def home():
    return "Aurum Harmony Flask API is running!"

@app.route('/hdfc/access-token')
def get_hdfc_access_token():
    HDFC_SKY_API_KEY = os.getenv("HDFC_SKY_API_KEY")
    HDFC_SKY_API_SECRET = os.getenv("HDFC_SKY_API_SECRET")
    request_token = "your_request_token_here"  # Replace with your actual request token

    url = f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={HDFC_SKY_API_KEY}&request_token={request_token}"
    data = {"api_secret": HDFC_SKY_API_SECRET}

    print("API Key:", HDFC_SKY_API_KEY)
    print("API Secret:", HDFC_SKY_API_SECRET)
    print("Request Token:", request_token)
    print("URL:", url)
    print("Payload:", data)

    response = requests.post(url, json=data)
    print("Status Code:", response.status_code)
    print("Response Text:", response.text)

    if response.status_code == 200:
        return jsonify(response.json())
    else:
        return jsonify({"error": response.text}), response.status_code

@app.route('/get-login-url')
def get_login_url():
    api_key = os.getenv("HDFC_SKY_API_KEY")
    redirect_uri = "http://localhost:5000/callback"
    login_url = f"https://developer.hdfcsky.com/oauth/authorize?api_key={api_key}&redirect_uri={redirect_uri}"
    return redirect(login_url)

@app.route('/callback')
def callback():
    request_token = request.args.get('request_token')
    # Exchange request_token for access_token (call your get_access_token function)
    # Store the access_token (for now, print or return it)
    return f"Your request token is: {request_token}"

@app.route('/postback', methods=['POST'])
def postback():
    data = request.get_json()
    return "Postback received: " + str(data), 200

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)