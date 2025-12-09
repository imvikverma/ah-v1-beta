"""
Diagnostic script to test HDFC Sky positions endpoint with detailed output
"""
import os
import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv
from api.hdfc_sky_api import HDFCSkyAPI
import requests

load_dotenv(project_root / ".env")

def diagnose_positions():
    """Test positions endpoint with detailed diagnostics"""
    print("=" * 70)
    print("HDFC Sky Positions Endpoint Diagnostic")
    print("=" * 70)
    print()
    
    # Load credentials
    api_key = os.getenv("HDFC_SKY_API_KEY")
    api_secret = os.getenv("HDFC_SKY_API_SECRET")
    token_id = os.getenv("HDFC_SKY_TOKEN_ID")
    access_token = os.getenv("HDFC_SKY_ACCESS_TOKEN")
    
    if not token_id:
        print("❌ HDFC_SKY_TOKEN_ID not found in .env")
        return
    
    print(f"✅ Token ID: {token_id[:30]}...")
    if access_token:
        print(f"✅ Access Token: {access_token[:30]}...")
    print()
    
    # Test endpoints
    endpoints = [
        "https://developer.hdfcsky.com/oapi/v1/im/positions",
        "https://developer.hdfcsky.com/oapi/v1/positions",
        "https://developer.hdfcsky.com/oapi/v2/im/positions",
        "https://developer.hdfcsky.com/oapi/v2/positions",
    ]
    
    patterns = [
        ("Pattern 1: token_id only", {"token_id": token_id}, False),
        ("Pattern 2: api_key + token_id", {"api_key": api_key, "token_id": token_id}, False),
        ("Pattern 3: token_id + Authorization", {"token_id": token_id}, True),
        ("Pattern 4: api_key + token_id + Authorization", {"api_key": api_key, "token_id": token_id}, True),
    ]
    
    import platform
    user_agent = f"Mozilla/5.0 ({platform.system()}; {platform.machine()}) Python/{platform.python_version()}"
    
    for endpoint in endpoints:
        print(f"\n{'='*70}")
        print(f"Testing: {endpoint}")
        print(f"{'='*70}")
        
        for pattern_name, params, use_auth in patterns:
            if use_auth and not access_token:
                continue
                
            headers = {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "User-Agent": user_agent,
            }
            
            if use_auth:
                auth_header = access_token
                if not auth_header.startswith("Bearer "):
                    auth_header = f"Bearer {auth_header}"
                headers["Authorization"] = auth_header
            
            print(f"\n  {pattern_name}:")
            print(f"    URL: {endpoint}")
            print(f"    Params: {list(params.keys())}")
            print(f"    Headers: {list(headers.keys())}")
            
            try:
                response = requests.get(endpoint, headers=headers, params=params, timeout=10)
                print(f"    Status: {response.status_code}")
                
                if response.status_code == 200:
                    print(f"    ✅ SUCCESS!")
                    try:
                        data = response.json()
                        print(f"    Response keys: {list(data.keys()) if isinstance(data, dict) else 'Not a dict'}")
                        print(f"    Response preview: {str(data)[:200]}...")
                    except:
                        print(f"    Response: {response.text[:200]}")
                    break  # Success! Stop trying other patterns
                elif response.status_code == 401:
                    print(f"    ❌ 401 Unauthorized")
                    try:
                        error_data = response.json()
                        print(f"    Error: {error_data}")
                    except:
                        print(f"    Error text: {response.text[:200]}")
                elif response.status_code == 404:
                    print(f"    ⚠️  404 Not Found (endpoint doesn't exist)")
                else:
                    print(f"    ⚠️  Status {response.status_code}")
                    print(f"    Response: {response.text[:200]}")
            except Exception as e:
                print(f"    ❌ Exception: {e}")
        
        print()
    
    print("\n" + "=" * 70)
    print("💡 Next Steps:")
    print("=" * 70)
    print("1. If all patterns return 401, the token_id might be expired")
    print("2. If all return 404, the endpoint path might be different")
    print("3. Check browser Network tab when viewing positions on HDFC Sky portal")
    print("4. Look for API calls to positions-related endpoints")
    print()

if __name__ == "__main__":
    diagnose_positions()

