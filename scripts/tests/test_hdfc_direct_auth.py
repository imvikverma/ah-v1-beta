"""
Test different HDFC Sky authentication methods
"""
import os
from dotenv import load_dotenv
import requests

load_dotenv()

api_key = os.getenv("HDFC_SKY_API_KEY")
api_secret = os.getenv("HDFC_SKY_API_SECRET")

print("\n=== Testing HDFC Sky Authentication ===\n")
print(f"API Key: {api_key[:10]}... (length: {len(api_key)})")
print(f"API Secret: {api_secret[:10]}... (length: {len(api_secret)})\n")

# Try different endpoint variations
endpoints_to_try = [
    {
        "name": "Method 1: Direct POST with both in body",
        "url": "https://developer.hdfcsky.com/oapi/v1/access-token",
        "data": {"api_key": api_key, "api_secret": api_secret},
        "params": None
    },
    {
        "name": "Method 2: API key in URL, secret in body",
        "url": "https://developer.hdfcsky.com/oapi/v1/access-token",
        "data": {"api_secret": api_secret},
        "params": {"api_key": api_key}
    },
    {
        "name": "Method 3: Both in URL params",
        "url": "https://developer.hdfcsky.com/oapi/v1/access-token",
        "data": None,
        "params": {"api_key": api_key, "api_secret": api_secret}
    },
    {
        "name": "Method 4: Basic Auth with API key/secret",
        "url": "https://developer.hdfcsky.com/oapi/v1/access-token",
        "data": None,
        "params": None,
        "auth": (api_key, api_secret)
    }
]

for method in endpoints_to_try:
    print(f"Testing: {method['name']}")
    print(f"URL: {method['url']}")
    
    try:
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        
        if method.get('auth'):
            response = requests.post(
                method['url'],
                params=method['params'],
                json=method['data'],
                headers=headers,
                auth=method['auth'],
                timeout=10
            )
        else:
            response = requests.post(
                method['url'],
                params=method['params'],
                json=method['data'],
                headers=headers,
                timeout=10
            )
        
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text[:200]}")
        
        if response.status_code == 200:
            print("✅ SUCCESS!")
            token_data = response.json()
            print(f"Access Token: {token_data.get('access_token', 'N/A')[:30]}...")
            break
        elif response.status_code == 401:
            print("❌ 401 - Invalid credentials or method")
        else:
            print(f"❌ Error {response.status_code}")
        
    except Exception as e:
        print(f"❌ Exception: {e}")
    
    print()

print("\n=== Also trying form-data format ===\n")

# Try form-data format
url = "https://developer.hdfcsky.com/oapi/v1/access-token"
data = {"api_key": api_key, "api_secret": api_secret}
headers = {"Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json"}

try:
    response = requests.post(url, data=data, headers=headers, timeout=10)
    print(f"Form-data Status: {response.status_code}")
    print(f"Form-data Response: {response.text[:200]}")
    if response.status_code == 200:
        print("✅ SUCCESS with form-data!")
except Exception as e:
    print(f"❌ Exception: {e}")

