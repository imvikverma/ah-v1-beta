"""
Kotak Neo sandbox token helper.

IMPORTANT:
- Real API key / secret / request_token MUST NOT be hard-coded in source.
- Set them as environment variables before running:
    KOTAK_NEO_API_KEY
    KOTAK_NEO_REQUEST_TOKEN
    KOTAK_NEO_API_SECRET
"""

import os
import sys

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from api.kotak_neo import KotakNeoClient

api_key = os.getenv("KOTAK_NEO_API_KEY")
request_token = os.getenv("KOTAK_NEO_REQUEST_TOKEN")
api_secret = os.getenv("KOTAK_NEO_API_SECRET")

if not all([api_key, request_token, api_secret]):
    raise RuntimeError(
        "Kotak Neo credentials missing. "
        "Please set KOTAK_NEO_API_KEY, KOTAK_NEO_REQUEST_TOKEN, "
        "and KOTAK_NEO_API_SECRET in your environment."
    )

try:
    client = KotakNeoClient(use_sandbox=True)
    result = client.get_access_token(request_token)
    
    if "error" in result:
        print(f"Error: {result.get('status_code', 'Unknown')} - {result.get('error', 'Unknown error')}")
        sys.exit(1)
    
    print("Access Token:", result.get("access_token"))
    print("Token Data:", result)
    
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)

