"""
Kotak Neo Broker Integration
Flask routes and service layer for Kotak Neo API
"""

from flask import Blueprint, request, jsonify
from typing import Dict, Optional
import sys
import os

# Add project root to path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from api.kotak_neo import KotakNeoAPI

# Create blueprint
kotak_bp = Blueprint('kotak_neo', __name__, url_prefix='/api/brokers/kotak')

# Store active sessions (in production, use Redis or database)
_active_sessions: Dict[str, KotakNeoAPI] = {}


def get_kotak_client(user_id: str) -> Optional[KotakNeoAPI]:
    """
    Get or create Kotak Neo client for user.
    Checks stored tokens first, then active sessions.
    """
    # Check active sessions first
    if user_id in _active_sessions:
        client = _active_sessions[user_id]
        if client.is_authenticated():
            return client
    
    # Try to load from stored tokens
    try:
        from aurum_harmony.database.kotak_tokens import token_storage
        from aurum_harmony.engines.trade_execution.broker_adapter_factory import get_kotak_client_from_env
        
        token_data = token_storage.get_tokens(user_id)
        if token_data:
            # Create client from stored tokens
            client = get_kotak_client_from_env()
            if client:
                client.view_token = token_data["view_token"]
                client.view_sid = token_data["view_sid"]
                client.trade_token = token_data["trade_token"]
                client.trade_sid = token_data["trade_sid"]
                client.base_url = token_data["base_url"]
                # Set expiry
                from datetime import datetime
                expires_at = datetime.fromisoformat(token_data["expires_at"])
                client.token_expiry = expires_at
                
                if client.is_authenticated():
                    store_kotak_client(user_id, client)
                    logger.info(f"Restored Kotak client from stored tokens for user {user_id}")
                    return client
    except Exception as e:
        logger.warning(f"Error loading stored tokens: {e}")
    
    return None


def store_kotak_client(user_id: str, client: KotakNeoAPI):
    """Store Kotak Neo client for user"""
    _active_sessions[user_id] = client


@kotak_bp.route('/login/totp', methods=['POST'])
def login_totp():
    """
    Step 1: Login with TOTP
    Body: {
        "user_id": "user123",
        "access_token": "api_access_token",
        "mobile_number": "+91XXXXXXXXXX",
        "client_code": "CLIENT_CODE",
        "totp": "123456"
    }
    """
    try:
        data = request.json
        user_id = data.get('user_id')
        access_token = data.get('access_token')
        mobile_number = data.get('mobile_number')
        client_code = data.get('client_code')
        totp = data.get('totp')
        
        if not all([user_id, access_token, mobile_number, client_code, totp]):
            return jsonify({"error": "Missing required fields"}), 400
        
        # Create client and login
        client = KotakNeoAPI(access_token, mobile_number, client_code)
        result = client.login_with_totp(totp)
        
        # Store client (with view token only)
        store_kotak_client(user_id, client)
        
        return jsonify({
            "success": True,
            "message": "TOTP login successful",
            "data": {
                "view_token": result.get("token"),
                "view_sid": result.get("sid"),
                "kType": result.get("kType")
            }
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@kotak_bp.route('/login/mpin', methods=['POST'])
def validate_mpin():
    """
    Step 2: Validate MPIN
    Body: {
        "user_id": "user123",
        "mpin": "123456"
    }
    """
    try:
        data = request.json
        user_id = data.get('user_id')
        mpin = data.get('mpin')
        
        if not user_id or not mpin:
            return jsonify({"error": "Missing user_id or mpin"}), 400
        
        client = get_kotak_client(user_id)
        if not client:
            return jsonify({"error": "Please complete TOTP login first"}), 401
        
        result = client.validate_mpin(mpin)
        
        # Store tokens for future use (one-time setup)
        try:
            from aurum_harmony.database.kotak_tokens import token_storage
            token_storage.store_tokens(
                user_id=user_id,
                view_token=client.view_token or "",
                view_sid=client.view_sid or "",
                trade_token=result.get("token", ""),
                trade_sid=result.get("sid", ""),
                base_url=result.get("baseUrl", "")
            )
        except Exception as e:
            logger.warning(f"Error storing tokens: {e}")
        
        return jsonify({
            "success": True,
            "message": "MPIN validation successful. Tokens stored for future use.",
            "data": {
                "trade_token": result.get("token"),
                "trade_sid": result.get("sid"),
                "base_url": result.get("baseUrl"),
                "kType": result.get("kType"),
                "tokens_stored": True
            }
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@kotak_bp.route('/orders/place', methods=['POST'])
def place_order():
    """
    Place an order
    Body: {
        "user_id": "user123",
        "symbol": "RELIANCE",
        "exchange": "nse_cm",
        "quantity": 1,
        "order_type": "MKT",
        "price": 0,
        "transaction_type": "B",
        "product_type": "CNC",
        "validity": "DAY"
    }
    """
    try:
        data = request.json
        user_id = data.get('user_id')
        
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400
        
        client = get_kotak_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated. Please complete login first"}), 401
        
        result = client.place_order(
            symbol=data.get('symbol'),
            exchange=data.get('exchange', 'nse_cm'),
            quantity=int(data.get('quantity', 1)),
            order_type=data.get('order_type', 'MKT'),
            price=float(data.get('price', 0)),
            transaction_type=data.get('transaction_type', 'B'),
            product_type=data.get('product_type', 'CNC'),
            validity=data.get('validity', 'DAY')
        )
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@kotak_bp.route('/orders/modify', methods=['POST'])
def modify_order():
    """
    Modify an order
    Body: {
        "user_id": "user123",
        "order_no": "ORDER123",
        "quantity": 2,
        "price": 2500.0,
        "order_type": "LMT"
    }
    """
    try:
        data = request.json
        user_id = data.get('user_id')
        order_no = data.get('order_no')
        
        if not user_id or not order_no:
            return jsonify({"error": "Missing user_id or order_no"}), 400
        
        client = get_kotak_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.modify_order(
            order_no=order_no,
            quantity=data.get('quantity'),
            price=data.get('price'),
            order_type=data.get('order_type')
        )
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@kotak_bp.route('/orders/cancel', methods=['POST'])
def cancel_order():
    """
    Cancel an order
    Body: {
        "user_id": "user123",
        "order_no": "ORDER123"
    }
    """
    try:
        data = request.json
        user_id = data.get('user_id')
        order_no = data.get('order_no')
        
        if not user_id or not order_no:
            return jsonify({"error": "Missing user_id or order_no"}), 400
        
        client = get_kotak_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.cancel_order(order_no)
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@kotak_bp.route('/orders', methods=['GET'])
def get_orders():
    """
    Get order book
    Query params: user_id
    """
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400
        
        client = get_kotak_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.get_order_book()
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@kotak_bp.route('/trades', methods=['GET'])
def get_trades():
    """
    Get trade book
    Query params: user_id
    """
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400
        
        client = get_kotak_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.get_trade_book()
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@kotak_bp.route('/positions', methods=['GET'])
def get_positions():
    """
    Get positions
    Query params: user_id
    """
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400
        
        client = get_kotak_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.get_positions()
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@kotak_bp.route('/holdings', methods=['GET'])
def get_holdings():
    """
    Get holdings
    Query params: user_id
    """
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400
        
        client = get_kotak_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.get_holdings()
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@kotak_bp.route('/quotes', methods=['GET'])
def get_quotes():
    """
    Get quotes
    Query params: user_id, exchange, symbol_code
    """
    try:
        user_id = request.args.get('user_id')
        exchange = request.args.get('exchange', 'nse_cm')
        symbol_code = request.args.get('symbol_code')
        
        if not user_id or not symbol_code:
            return jsonify({"error": "Missing user_id or symbol_code"}), 400
        
        client = get_kotak_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.get_quotes(exchange, symbol_code)
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@kotak_bp.route('/status', methods=['GET'])
def get_status():
    """
    Get authentication status (checks stored tokens)
    Query params: user_id
    """
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400
        
        # Check for stored tokens first
        try:
            from aurum_harmony.database.kotak_tokens import token_storage
            has_stored = token_storage.has_valid_tokens(user_id)
        except Exception:
            has_stored = False
        
        # Check active session
        client = get_kotak_client(user_id)
        is_authenticated = client.is_authenticated() if client else False
        
        return jsonify({
            "success": True,
            "authenticated": is_authenticated or has_stored,
            "has_stored_tokens": has_stored,
            "has_view_token": client.view_token is not None if client else False,
            "has_trade_token": client.trade_token is not None if client else False
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400

