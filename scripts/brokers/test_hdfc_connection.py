        """
Test HDFC Sky API Connection
Tests authentication and basic API calls
"""

import sys
import os
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv
load_dotenv()

from api.hdfc_sky_api import HDFCSkyAPI

def test_hdfc_connection():
    """Test HDFC Sky API connection"""
    print("=" * 50)
    print("HDFC Sky API Connection Test")
    print("=" * 50)
    print()
    
    # Get credentials from environment
    api_key = os.getenv('HDFC_SKY_API_KEY')
    api_secret = os.getenv('HDFC_SKY_API_SECRET')
    token_id = os.getenv('HDFC_SKY_TOKEN_ID')
    access_token = os.getenv('HDFC_SKY_ACCESS_TOKEN')
    
    # Check required credentials
    if not api_key or not api_secret:
        print("❌ ERROR: Missing required credentials")
        print("   Required: HDFC_SKY_API_KEY, HDFC_SKY_API_SECRET")
        print("   Run: .\\scripts\\brokers\\setup_hdfc_sky.ps1")
        return False
    
    print("✅ Credentials found in environment")
    print(f"   API Key: {api_key[:20]}...")
    print(f"   Token ID: {token_id if token_id else 'Not set'}")
    print(f"   Access Token: {'Set' if access_token else 'Not set'}")
    print()
    
    # Create client
    try:
        print("Creating HDFC Sky API client...")
        client = HDFCSkyAPI(
            api_key=api_key,
            api_secret=api_secret,
            token_id=token_id,
            access_token=access_token
        )
        print("✅ Client created")
        print()
        
        # Check authentication
        print("Checking authentication...")
        if client.is_authenticated():
            print("✅ Client is authenticated")
            print()
            
            # Try to get account info
            print("Fetching account information...")
            try:
                account_info = client.get_account_info()
                print("✅ Account info retrieved:")
                print(f"   {account_info}")
                return True
            except Exception as e:
                print(f"⚠️  Could not fetch account info: {e}")
                print("   This might be normal if token_id or access_token is missing")
                print("   You may need to complete OAuth flow to get access_token")
                return False
        else:
            print("⚠️  Client not authenticated")
            print("   You need to:")
            print("   1. Get token_id from URL after web login, OR")
            print("   2. Complete OAuth flow to get access_token")
            print()
            print("   For OAuth flow:")
            print("   - Visit: https://developer.hdfcsky.com")
            print("   - Complete login and get token_id from URL")
            print("   - Or use OAuth endpoints to get access_token")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_hdfc_connection()
    sys.exit(0 if success else 1)
