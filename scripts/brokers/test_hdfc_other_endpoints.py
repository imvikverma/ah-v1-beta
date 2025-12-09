"""Test HDFC Sky endpoints that don't require positions"""
import os
import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv
from api.hdfc_sky_api import HDFCSkyAPI
import requests

load_dotenv(project_root / ".env")

api_key = os.getenv("HDFC_SKY_API_KEY")
api_secret = os.getenv("HDFC_SKY_API_SECRET")
token_id = os.getenv("HDFC_SKY_TOKEN_ID")
access_token = os.getenv("HDFC_SKY_ACCESS_TOKEN")

print("=" * 70)
print("Testing HDFC Sky Endpoints (Non-Positions)")
print("=" * 70)
print()

client = HDFCSkyAPI(api_key, api_secret, token_id=token_id, access_token=access_token)

# Test endpoints that should work even without positions
endpoints_to_test = [
    ("Account Info", "/oapi/v1/dashboard/apps", "GET"),
    ("Fetch Apps", "/oapi/v1/fetch-apps", "POST"),
    ("Quotes (NIFTY)", "/oapi/v1/quotes", "GET", {"symbol": "NIFTY", "exchange": "NSE"}),
]

import platform
user_agent = f"Mozilla/5.0 ({platform.system()}; {platform.machine()}) Python/{platform.python_version()}"

for name, endpoint, method, *extra in endpoints_to_test:
    print(f"\n{'='*70}")
    print(f"Testing: {name} ({endpoint})")
    print(f"{'='*70}")
    
    url = f"https://developer.hdfcsky.com{endpoint}"
    
    # Try JWT Authorization pattern (like /oapi/v1/fetch-apps)
    if access_token:
        try:
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json, text/plain, */*",
                "User-Agent": user_agent,
                "Authorization": access_token,  # JWT directly, no Bearer prefix
            }
            
            if method == "GET":
                params = extra[0] if extra else {}
                response = requests.get(url, headers=headers, params=params, timeout=10)
            else:
                data = extra[0] if extra else {}
                response = requests.post(url, headers=headers, json=data, timeout=10)
            
            if response.status_code == 200:
                print(f"✅ SUCCESS with JWT Authorization pattern!")
                try:
                    result = response.json()
                    print(f"   Response keys: {list(result.keys()) if isinstance(result, dict) else 'Not a dict'}")
                    print(f"   Response preview: {str(result)[:200]}...")
                except:
                    print(f"   Response: {response.text[:200]}")
            else:
                print(f"   Status: {response.status_code}")
                print(f"   Response: {response.text[:200]}")
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    # Try Dashboard_API_CALL pattern (only token_id in params)
    if token_id:
        try:
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "User-Agent": user_agent,
            }
            params = {"token_id": token_id}
            if extra:
                params.update(extra[0])
            
            if method == "GET":
                response = requests.get(url, headers=headers, params=params, timeout=10)
            else:
                response = requests.post(url, headers=headers, params=params, json={}, timeout=10)
            
            if response.status_code == 200:
                print(f"✅ SUCCESS with Dashboard_API_CALL pattern!")
                try:
                    result = response.json()
                    print(f"   Response keys: {list(result.keys()) if isinstance(result, dict) else 'Not a dict'}")
                except:
                    print(f"   Response: {response.text[:200]}")
            else:
                print(f"   Status: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error: {e}")

print("\n" + "=" * 70)
print("💡 Summary:")
print("=" * 70)
print("If any endpoint works, authentication is correct!")
print("Positions endpoint will work once account is funded and has positions.")
print()

