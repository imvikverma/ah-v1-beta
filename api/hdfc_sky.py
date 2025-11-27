from dotenv import load_dotenv
import os
import requests
import json
from flask import Flask, request, redirect, jsonify

load_dotenv()

HDFC_SKY_API_KEY = os.getenv("HDFC_SKY_API_KEY")
HDFC_SKY_API_SECRET = os.getenv("HDFC_SKY_API_SECRET")

# Use the environment variables directly
api_key = HDFC_SKY_API_KEY
request_token = "21e724dfdf9b440b9e0aac78e49f752d1530186681"  # Update if changed
api_secret = HDFC_SKY_API_SECRET

url = f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={api_key}&request_token={request_token}"
data = {"api_secret": api_secret}
response = requests.post(url, json=data)

if response.status_code == 200:
    print("Access Token:", response.json().get("access_token"))
else:
    print("Error:", response.status_code, response.text)

if __name__ == "__main__":
    print("HDFC_SKY_API_KEY:", HDFC_SKY_API_KEY)
    print("HDFC_SKY_API_SECRET:", HDFC_SKY_API_SECRET)

app = Flask(__name__)

TOKEN_FILE = "hdfc_access_token.json"

def save_token(token):
    with open(TOKEN_FILE, "w") as f:
        json.dump(token, f)

def load_token():
    if os.path.exists(TOKEN_FILE):
        with open(TOKEN_FILE) as f:
            return json.load(f)
    return None

@app.route('/get-login-url')
def get_login_url():
    api_key = os.getenv("HDFC_SKY_API_KEY")
    redirect_uri = "http://localhost:5000/callback"
    login_url = f"https://developer.hdfcsky.com/oauth/authorize?api_key={api_key}&redirect_uri={redirect_uri}"
    return redirect(login_url)

@app.route('/callback')
def callback():
    request_token = request.args.get('request_token')
    api_key = os.getenv("HDFC_SKY_API_KEY")
    api_secret = os.getenv("HDFC_SKY_API_SECRET")
    url = f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={api_key}&request_token={request_token}"
    data = {"api_secret": api_secret}
    response = requests.post(url, json=data)
    if response.status_code == 200:
        token_data = response.json()
        save_token(token_data)
        return f"Access token saved: {token_data.get('access_token')}"
    else:
        return f"Error: {response.text}", 400

@app.route('/hdfc/use-api')
def use_api():
    token_data = load_token()
    if not token_data:
        return "No access token found. Please authenticate first.", 401
    access_token = token_data.get("access_token")
    # Example API call using the access token
    # headers = {"Authorization": f"Bearer {access_token}"}
    # response = requests.get("https://developer.hdfcsky.com/oapi/v1/some-endpoint", headers=headers)
    return jsonify({"access_token": access_token})

from hfc.fabric import Client  # Add the missing import

def store_token_on_fabric(token_id, token_value):
    c = Client(net_profile="network.json")
    c.new_channel('mychannel')
    # Set up user, org, etc. as per your network config
    response = c.chaincode_invoke(
        requestor='Admin',
        channel_name='mychannel',
        peers=['peer0.org1.example.com'],
        args=[token_id, token_value],
        cc_name='tokencc',  # your chaincode name
        fcn='PutToken'
    )
    return response

def get_access_token(request_token):
    api_key = os.getenv("HDFC_SKY_API_KEY")
    api_secret = os.getenv("HDFC_SKY_API_SECRET")
    url = f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={api_key}&request_token={request_token}"
    data = {"api_secret": api_secret}
    response = requests.post(url, json=data)
    return response

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)