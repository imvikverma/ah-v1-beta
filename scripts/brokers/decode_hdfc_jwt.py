"""
Decode HDFC Sky JWT Token to see what's inside
"""
import os
import sys
import json
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from dotenv import load_dotenv

# Load environment variables
env_path = project_root / ".env"
if env_path.exists():
    load_dotenv(env_path)

try:
    import jwt
except ImportError:
    print("❌ PyJWT not installed. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "PyJWT"])
    import jwt

def decode_jwt():
    """Decode the HDFC Sky JWT token"""
    access_token = os.getenv("HDFC_SKY_ACCESS_TOKEN")
    
    if not access_token:
        print("❌ HDFC_SKY_ACCESS_TOKEN not found in .env")
        return
    
    print("=" * 60)
    print("HDFC Sky JWT Token Decoder")
    print("=" * 60)
    print()
    print(f"Token (first 50 chars): {access_token[:50]}...")
    print()
    
    try:
        # Decode without verification (we just want to see the payload)
        payload = jwt.decode(access_token, options={"verify_signature": False})
        
        print("✅ JWT Token Decoded Successfully!")
        print()
        print("Token Payload:")
        print(json.dumps(payload, indent=2))
        print()
        
        # Check for potential token_id
        print("Looking for token_id...")
        if "client_token" in payload:
            print(f"   Found 'client_token': {payload['client_token'][:50]}...")
            print("   ⚠️  This might be the token_id, but it's encrypted/encoded")
        
        if "client_id" in payload:
            print(f"   Found 'client_id': {payload['client_id']}")
        
        if "exp" in payload:
            from datetime import datetime
            exp_timestamp = payload['exp']
            # Check if timestamp is in milliseconds (13 digits) or seconds (10 digits)
            if exp_timestamp > 1e10:
                exp_time = datetime.fromtimestamp(exp_timestamp / 1000)
                print(f"   Token expires (milliseconds): {exp_time}")
            else:
                exp_time = datetime.fromtimestamp(exp_timestamp)
                print(f"   Token expires (seconds): {exp_time}")
            
            # Check if expired
            now = datetime.now()
            if exp_time < now:
                print(f"   ⚠️  TOKEN IS EXPIRED! (expired {now - exp_time} ago)")
            else:
                print(f"   ✅ Token is valid (expires in {exp_time - now})")
        
        print()
        print("=" * 60)
        print("Next Steps:")
        print("=" * 60)
        print("1. Check browser localStorage for 'token_id' key")
        print("2. Or check if API calls work with just access_token")
        print("3. Run: python scripts/brokers/test_hdfc_connection.py")
        print()
        
    except Exception as e:
        print(f"❌ Error decoding JWT: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    decode_jwt()

