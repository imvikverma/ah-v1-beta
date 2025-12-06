"""
Quick test script to diagnose HDFC Sky 403 errors
"""
import os
from dotenv import load_dotenv
import requests

load_dotenv()

api_key = os.getenv("HDFC_SKY_API_KEY")
api_secret = os.getenv("HDFC_SKY_API_SECRET")
request_token = os.getenv("HDFC_SKY_REQUEST_TOKEN")

print("\n=== HDFC Sky Credentials Check ===\n")

# Check what we have
print(f"API Key: {'✅ Found' if api_key else '❌ Missing'} ({len(api_key) if api_key else 0} chars)")
print(f"API Secret: {'✅ Found' if api_secret else '❌ Missing'} ({len(api_secret) if api_secret else 0} chars)")
print(f"Request Token: {'✅ Found' if request_token else '❌ Missing'} ({len(request_token) if request_token else 0} chars)")

if not all([api_key, api_secret, request_token]):
    print("\n❌ Missing credentials! Add them to .env file.")
    exit(1)

print("\n=== Testing Access Token Request ===\n")

url = f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={api_key}&request_token={request_token}"
data = {"api_secret": api_secret}

print(f"URL: {url}")
print(f"Request data: {{'api_secret': '***'}}")
print("\nSending request...\n")

try:
    response = requests.post(url, json=data, timeout=10)
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text[:200]}...")
    
    if response.status_code == 200:
        token_data = response.json()
        print(f"\n✅ Success! Access Token: {token_data.get('access_token', 'N/A')[:20]}...")
    elif response.status_code == 403:
        print("\n❌ 403 Forbidden - Possible causes:")
        print("  1. Invalid API Key or Secret")
        print("  2. Request token expired or invalid")
        print("  3. Request token not authorized for this API key")
        print("  4. Account/permissions issue")
        print("\nTry:")
        print("  - Get a fresh request token via OAuth")
        print("  - Verify API Key/Secret in HDFC Sky portal")
        print("  - Check if account has API access enabled")
    else:
        print(f"\n❌ Error {response.status_code}: {response.text}")
        
except Exception as e:
    print(f"\n❌ Exception: {e}")

