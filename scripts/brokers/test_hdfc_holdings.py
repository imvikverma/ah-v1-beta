"""Quick test for HDFC Sky holdings endpoint"""
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

client = HDFCSkyAPI(api_key, api_secret, token_id=token_id, access_token=access_token)

print("Testing holdings endpoint...")
try:
    holdings = client.get_holdings()
    print("✅ Holdings endpoint works!")
    print(f"Response: {holdings}")
except Exception as e:
    print(f"❌ Error: {e}")

