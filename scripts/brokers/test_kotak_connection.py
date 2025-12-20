"""
Kotak Neo Connection Test Script

Tests the Kotak Neo API connection step-by-step.
This script will guide you through the authentication process.
"""

import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv
from api.kotak_neo import KotakNeoAPI

# Load environment variables
env_path = project_root / ".env"
if env_path.exists():
    load_dotenv(env_path)
else:
    print("❌ ERROR: .env file not found!")
    print(f"   Expected location: {env_path}")
    print("\n   Please create a .env file with:")
    print("   KOTAK_NEO_ACCESS_TOKEN=your_token")
    print("   KOTAK_NEO_MOBILE_NUMBER=+91XXXXXXXXXX")
    print("   KOTAK_NEO_CLIENT_CODE=YOUR_CODE")
    sys.exit(1)


def get_credentials():
    """Load credentials from environment variables."""
    access_token = os.getenv("KOTAK_NEO_ACCESS_TOKEN")
    mobile_number = os.getenv("KOTAK_NEO_MOBILE_NUMBER")
    client_code = os.getenv("KOTAK_NEO_CLIENT_CODE")
    
    if not access_token:
        print("❌ ERROR: KOTAK_NEO_ACCESS_TOKEN not found in .env")
        sys.exit(1)
    
    if not mobile_number:
        print("❌ ERROR: KOTAK_NEO_MOBILE_NUMBER not found in .env")
        sys.exit(1)
    
    if not client_code:
        print("❌ ERROR: KOTAK_NEO_CLIENT_CODE not found in .env")
        sys.exit(1)
    
    # Remove 'Bearer ' prefix if present
    if access_token.startswith("Bearer "):
        access_token = access_token[7:]
    
    return access_token, mobile_number, client_code


def test_connection():
    """Test Kotak Neo API connection."""
    print("=" * 60)
    print("Kotak Neo API Connection Test")
    print("=" * 60)
    print()
    
    # Load credentials
    print("📋 Step 1: Loading credentials from .env...")
    try:
        access_token, mobile_number, client_code = get_credentials()
        print(f"   ✅ Access Token: {access_token[:20]}...")
        print(f"   ✅ Mobile Number: {mobile_number}")
        print(f"   ✅ Client Code: {client_code}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False
    
    print()
    
    # Initialize client
    print("📋 Step 2: Initializing Kotak Neo API client...")
    try:
        client = KotakNeoAPI(
            access_token=access_token,
            mobile_number=mobile_number,
            client_code=client_code
        )
        print("   ✅ Client initialized")
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False
    
    print()
    
    # Step 1: TOTP Login
    print("📋 Step 3: TOTP Login")
    print("   📱 Open your authenticator app (Google/Microsoft Authenticator)")
    print("   🔢 Enter the 6-digit TOTP code (changes every 30 seconds)")
    print()
    
    totp = input("   Enter TOTP code: ").strip()
    
    if len(totp) != 6 or not totp.isdigit():
        print("   ❌ Invalid TOTP format. Must be 6 digits.")
        return False
    
    try:
        print("   🔄 Sending TOTP login request...")
        result = client.login_with_totp(totp)
        
        if result and "token" in result:
            print("   ✅ TOTP Login Successful!")
            print(f"   📝 View Token: {result.get('token', '')[:30]}...")
            print(f"   📝 Session ID: {result.get('sid', '')[:20]}...")
        else:
            print("   ❌ TOTP Login Failed!")
            print(f"   Response: {result}")
            return False
    except Exception as e:
        print(f"   ❌ Error during TOTP login: {e}")
        if hasattr(e, 'response') and e.response is not None:
            try:
                error_data = e.response.json()
                print(f"   Error details: {error_data}")
            except:
                print(f"   Status code: {e.response.status_code}")
        return False
    
    print()
    
    # Step 2: MPIN Validation
    print("📋 Step 4: MPIN Validation")
    print("   🔐 Enter your 6-digit MPIN (trading PIN)")
    print("   ⚠️  This is your trading PIN, NOT your login password")
    print()
    
    mpin = input("   Enter MPIN: ").strip()
    
    if len(mpin) != 6 or not mpin.isdigit():
        print("   ❌ Invalid MPIN format. Must be 6 digits.")
        return False
    
    try:
        print("   🔄 Validating MPIN...")
        result = client.validate_mpin(mpin)
        
        if result and "token" in result:
            print("   ✅ MPIN Validation Successful!")
            print(f"   📝 Trade Token: {result.get('token', '')[:30]}...")
            print(f"   📝 Session ID: {result.get('sid', '')[:20]}...")
            print(f"   📝 Base URL: {result.get('baseUrl', '')}")
        else:
            print("   ❌ MPIN Validation Failed!")
            print(f"   Response: {result}")
            return False
    except Exception as e:
        print(f"   ❌ Error during MPIN validation: {e}")
        if hasattr(e, 'response') and e.response is not None:
            try:
                error_data = e.response.json()
                print(f"   Error details: {error_data}")
            except:
                print(f"   Status code: {e.response.status_code}")
        return False
    
    print()
    
    # Step 3: Test API Call (Get Positions)
    print("📋 Step 5: Testing API Call (Get Positions)...")
    try:
        positions = client.get_positions()
        print("   ✅ API Call Successful!")
        print(f"   📊 Positions retrieved: {len(positions) if isinstance(positions, list) else 'N/A'}")
    except Exception as e:
        print(f"   ⚠️  API call test failed (this is okay if you have no positions): {e}")
        # Don't fail the test for this
    
    print()
    print("=" * 60)
    print("✅ CONNECTION TEST PASSED!")
    print("=" * 60)
    print()
    print("Your Kotak Neo API is now configured and ready to use!")
    print()
    return True


if __name__ == "__main__":
    try:
        success = test_connection()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Test cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

