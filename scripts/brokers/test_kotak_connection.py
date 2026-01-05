"""
Test Kotak Neo API Connection
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

from api.kotak_neo import KotakNeoAPI

def test_kotak_connection():
    """Test Kotak Neo API connection"""
    print("=" * 50)
    print("Kotak Neo API Connection Test")
    print("=" * 50)
    print()
    
    # Get credentials from environment
    access_token = os.getenv('KOTAK_NEO_ACCESS_TOKEN')
    mobile_number = os.getenv('KOTAK_NEO_MOBILE_NUMBER')
    client_code = os.getenv('KOTAK_NEO_CLIENT_CODE')
    
    # Check required credentials
    if not access_token or not mobile_number or not client_code:
        print("❌ ERROR: Missing required credentials")
        print("   Required: KOTAK_NEO_ACCESS_TOKEN, KOTAK_NEO_MOBILE_NUMBER, KOTAK_NEO_CLIENT_CODE")
        print("   Run: .\\scripts\\brokers\\setup_kotak_credentials.ps1")
        return False
    
    print("✅ Credentials found in environment")
    print(f"   Access Token: {access_token[:30]}...")
    print(f"   Mobile Number: {mobile_number}")
    print(f"   Client Code: {client_code}")
    print()
    
    # Create client
    try:
        print("Creating Kotak Neo API client...")
        client = KotakNeoAPI(
            access_token=access_token,
            mobile_number=mobile_number,
            client_code=client_code
        )
        print("✅ Client created")
        print()
        
        # Check if already authenticated (has tokens from previous session)
        print("Checking authentication status...")
        if client.is_authenticated():
            print("✅ Client is authenticated (using existing tokens)")
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
                print("   Tokens may have expired, need to login again")
                return False
        else:
            print("⚠️  Client not authenticated")
            print("   You need to login with TOTP and MPIN")
            print()
            print("   Steps:")
            print("   1. Get 6-digit TOTP from your authenticator app")
            print("   2. Get your 6-digit MPIN")
            print("   3. Run interactive login:")
            print()
            
            # Interactive login
            try:
                totp = input("   Enter 6-digit TOTP: ").strip()
                if len(totp) != 6 or not totp.isdigit():
                    print("❌ Invalid TOTP format")
                    return False
                
                print("   Logging in with TOTP...")
                login_result = client.login_with_totp(totp)
                print("✅ TOTP login successful")
                print()
                
                mpin = input("   Enter 6-digit MPIN: ").strip()
                if len(mpin) != 6 or not mpin.isdigit():
                    print("❌ Invalid MPIN format")
                    return False
                
                print("   Validating MPIN...")
                validate_result = client.validate_mpin(mpin)
                print("✅ MPIN validation successful")
                print()
                
                # Now try to get account info
                print("Fetching account information...")
                account_info = client.get_account_info()
                print("✅ Account info retrieved:")
                print(f"   {account_info}")
                
                print()
                print("💡 Tip: Tokens are valid for 24 hours")
                print("   You can save tokens to .env for future use:")
                print("   KOTAK_NEO_VIEW_TOKEN=<token>")
                print("   KOTAK_NEO_VIEW_SID=<sid>")
                print("   KOTAK_NEO_TRADE_TOKEN=<token>")
                print("   KOTAK_NEO_TRADE_SID=<sid>")
                print("   KOTAK_NEO_BASE_URL=<base_url>")
                
                return True
                
            except KeyboardInterrupt:
                print("\n❌ Login cancelled")
                return False
            except Exception as e:
                print(f"❌ Login failed: {e}")
                import traceback
                traceback.print_exc()
                return False
            
    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_kotak_connection()
    sys.exit(0 if success else 1)
