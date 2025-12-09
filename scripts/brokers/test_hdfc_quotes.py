"""Test HDFC Sky quotes endpoint - this is often simpler and might work"""
import os
import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv
from api.hdfc_sky_api import HDFCSkyAPI

load_dotenv(project_root / ".env")

api_key = os.getenv("HDFC_SKY_API_KEY")
api_secret = os.getenv("HDFC_SKY_API_SECRET")
token_id = os.getenv("HDFC_SKY_TOKEN_ID")
access_token = os.getenv("HDFC_SKY_ACCESS_TOKEN")

print("=" * 70)
print("Testing HDFC Sky Quotes Endpoint")
print("=" * 70)
print()

client = HDFCSkyAPI(api_key, api_secret, token_id=token_id, access_token=access_token)

print("Testing quotes for NIFTY...")
try:
    quotes = client.get_quotes("NIFTY", "NSE")
    print("✅ Quotes endpoint works!")
    print(f"Response keys: {list(quotes.keys()) if isinstance(quotes, dict) else 'Not a dict'}")
    print(f"Response preview: {str(quotes)[:300]}...")
except Exception as e:
    print(f"❌ Error: {e}")
    print()
    print("This might help us understand the authentication pattern.")

