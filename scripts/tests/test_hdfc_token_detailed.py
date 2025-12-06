"""
Detailed test for HDFC Sky access token with request token
"""
import os
from dotenv import load_dotenv
import requests
import json

load_dotenv()

api_key = os.getenv("HDFC_SKY_API_KEY")
api_secret = os.getenv("HDFC_SKY_API_SECRET")
request_token = os.getenv("HDFC_SKY_REQUEST_TOKEN")

print("\n" + "="*60)
print("HDFC SKY ACCESS TOKEN TEST")
print("="*60)
print(f"\nAPI Key: {api_key[:15]}... (length: {len(api_key) if api_key else 0})")
print(f"API Secret: {api_secret[:15]}... (length: {len(api_secret) if api_secret else 0})")
print(f"Request Token: {request_token[:30] if request_token else 'NOT SET'}...")
print("\n" + "-"*60)

if not all([api_key, api_secret, request_token]):
    print("❌ Missing credentials!")
    print(f"  API Key: {'✅' if api_key else '❌'}")
    print(f"  API Secret: {'✅' if api_secret else '❌'}")
    print(f"  Request Token: {'✅' if request_token else '❌'}")
    exit(1)

# Test different endpoint formats
test_cases = [
    {
        "name": "Method 1: API key + request_token in URL, secret in JSON body",
        "url": f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={api_key}&request_token={request_token}",
        "data": {"api_secret": api_secret},
        "headers": {"Content-Type": "application/json", "Accept": "application/json"},
        "method": "json"
    },
    {
        "name": "Method 2: API key + request_token in URL, secret in form-data",
        "url": f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={api_key}&request_token={request_token}",
        "data": {"api_secret": api_secret},
        "headers": {"Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json"},
        "method": "form"
    },
    {
        "name": "Method 3: All in JSON body",
        "url": "https://developer.hdfcsky.com/oapi/v1/access-token",
        "data": {
            "api_key": api_key,
            "api_secret": api_secret,
            "request_token": request_token
        },
        "headers": {"Content-Type": "application/json", "Accept": "application/json"},
        "method": "json"
    },
    {
        "name": "Method 4: All in form-data",
        "url": "https://developer.hdfcsky.com/oapi/v1/access-token",
        "data": {
            "api_key": api_key,
            "api_secret": api_secret,
            "request_token": request_token
        },
        "headers": {"Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json"},
        "method": "form"
    },
    {
        "name": "Method 5: API key in URL, secret + token in body (JSON)",
        "url": f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={api_key}",
        "data": {
            "api_secret": api_secret,
            "request_token": request_token
        },
        "headers": {"Content-Type": "application/json", "Accept": "application/json"},
        "method": "json"
    },
    {
        "name": "Method 6: API key in URL, secret + token in body (form)",
        "url": f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={api_key}",
        "data": {
            "api_secret": api_secret,
            "request_token": request_token
        },
        "headers": {"Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json"},
        "method": "form"
    }
]

for i, test in enumerate(test_cases, 1):
    print(f"\n[{i}/{len(test_cases)}] Testing: {test['name']}")
    print(f"URL: {test['url'][:80]}...")
    print(f"Headers: {test['headers']}")
    print(f"Data keys: {list(test['data'].keys())}")
    
    try:
        if test['method'] == 'json':
            response = requests.post(test['url'], json=test['data'], headers=test['headers'], timeout=10)
        else:
            response = requests.post(test['url'], data=test['data'], headers=test['headers'], timeout=10)
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ SUCCESS!")
            try:
                result = response.json()
                access_token = result.get('access_token', 'N/A')
                print(f"Access Token: {access_token[:50]}...")
                print(f"Full Response: {json.dumps(result, indent=2)}")
                print("\n" + "="*60)
                print("🎉 WORKING METHOD FOUND!")
                print("="*60)
                exit(0)
            except:
                print(f"Response: {response.text[:200]}")
        else:
            print(f"❌ Error {response.status_code}")
            print(f"Response: {response.text[:200]}")
            
    except Exception as e:
        print(f"❌ Exception: {str(e)}")

print("\n" + "="*60)
print("❌ None of the methods worked")
print("="*60)
print("\nPossible issues:")
print("  1. Request token might be expired or invalid")
print("  2. API key/secret might be incorrect")
print("  3. Account might not be approved/activated")
print("  4. Endpoint URL might be different")
print("\nCheck the HDFC Sky documentation for the correct format.")

