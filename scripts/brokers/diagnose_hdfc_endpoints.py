"""
Diagnostic script to find HDFC Sky API endpoints
Tests various possible endpoint combinations
"""

import os
import sys
import requests
from pathlib import Path
from dotenv import load_dotenv

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

load_dotenv(project_root / ".env")

api_key = os.getenv("HDFC_SKY_API_KEY")
api_secret = os.getenv("HDFC_SKY_API_SECRET")
mobile = os.getenv("HDFC_SKY_MOBILE", "8700096343")

print("=" * 70)
print("HDFC Sky API Endpoint Diagnostic")
print("=" * 70)
print()
print(f"API Key: {api_key[:20]}...")
print(f"Mobile: {mobile}")
print()

# Base URLs to try
base_urls = [
    "https://developer.hdfcsky.com",
    "https://api.hdfcsky.com",
    "https://api.hdfcsec.com",
    "https://hdfcsky.com/api",
]

# Endpoint paths to try
endpoint_paths = [
    "/oapi/v1/auth/send-otp",
    "/oapi/v1/login/send-otp",
    "/oapi/v1/send-otp",
    "/oapi/v1/otp/send",
    "/api/v1/auth/send-otp",
    "/api/v1/login/send-otp",
    "/api/v1/send-otp",
    "/api/v1/otp/send",
    "/auth/send-otp",
    "/login/send-otp",
    "/send-otp",
    "/otp/send",
]

# Header formats to try
header_formats = [
    {
        "name": "X-API-Key headers",
        "headers": {
            "Content-Type": "application/json",
            "X-API-Key": api_key,
            "X-API-Secret": api_secret
        }
    },
    {
        "name": "Query params",
        "headers": {
            "Content-Type": "application/json"
        }
    },
    {
        "name": "Basic Auth",
        "headers": {
            "Content-Type": "application/json"
        },
        "auth": (api_key, api_secret)
    }
]

payload = {"mobile": mobile}

print("Testing endpoint combinations...")
print()

results = []
for base_url in base_urls:
    for endpoint_path in endpoint_paths:
        for header_format in header_formats:
            url = base_url + endpoint_path
            
            headers = header_format["headers"].copy()
            auth = header_format.get("auth")
            
            # Add query params if needed
            if header_format["name"] == "Query params":
                url += f"?api_key={api_key}&api_secret={api_secret}"
            
            try:
                response = requests.post(
                    url,
                    headers=headers,
                    json=payload,
                    auth=auth,
                    timeout=5
                )
                
                status = response.status_code
                result_text = response.text[:200] if response.text else ""
                
                # Categorize results
                if status == 200:
                    print(f"✅ SUCCESS! Status {status}")
                    print(f"   URL: {url}")
                    print(f"   Format: {header_format['name']}")
                    print(f"   Response: {result_text}")
                    print()
                    results.append(("SUCCESS", url, header_format["name"], status, result_text))
                elif status == 400:
                    print(f"⚠️  Bad Request (might be correct endpoint, wrong format)")
                    print(f"   URL: {url}")
                    print(f"   Format: {header_format['name']}")
                    print(f"   Response: {result_text}")
                    print()
                    results.append(("BAD_REQUEST", url, header_format["name"], status, result_text))
                elif status == 401:
                    print(f"⚠️  Unauthorized (might be correct endpoint, wrong auth)")
                    print(f"   URL: {url}")
                    print(f"   Format: {header_format['name']}")
                    print()
                    results.append(("UNAUTHORIZED", url, header_format["name"], status, result_text))
                elif status != 404:
                    print(f"ℹ️  Status {status}")
                    print(f"   URL: {url}")
                    print(f"   Format: {header_format['name']}")
                    print(f"   Response: {result_text[:100]}")
                    print()
                    results.append(("OTHER", url, header_format["name"], status, result_text))
                    
            except requests.exceptions.RequestException as e:
                # Skip connection errors silently
                pass

print()
print("=" * 70)
print("Summary")
print("=" * 70)

if not results:
    print("❌ No endpoints responded (all 404 or connection errors)")
    print()
    print("This suggests:")
    print("  1. The endpoint path is different")
    print("  2. Authentication might be done through web portal only")
    print("  3. Need to check HDFC Sky API documentation")
else:
    print(f"Found {len(results)} non-404 responses:")
    for result_type, url, format_name, status, response_text in results:
        print(f"  [{result_type}] {url} ({format_name}) - Status {status}")

print()
print("Next Steps:")
print("  1. Check HDFC Sky API documentation for correct endpoint")
print("  2. Look for 'Authentication' or 'Login' section")
print("  3. Check if authentication is done via web portal, not direct API")
print()

