"""
HDFC Sky Broker Integration
Flask routes and service layer for HDFC Sky API
"""

from flask import Blueprint, request, jsonify, current_app
from typing import Dict, Optional, Union
import sys
import os
import logging

# Add project root to path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from api.hdfc_sky_api import HDFCSkyAPI

logger = logging.getLogger(__name__)

# Create blueprint
hdfc_bp = Blueprint('hdfc_sky', __name__, url_prefix='/api/brokers/hdfc')

# Store active sessions (in production, use Redis or database)
_active_sessions: Dict[str, HDFCSkyAPI] = {}


def get_hdfc_client(user_id: Union[str, int]) -> Optional[HDFCSkyAPI]:
    """
    Get or create HDFC Sky client for user.
    Priority order:
    1. Active sessions (cached)
    2. Database credentials (BrokerCredential table)
    3. Environment variables (fallback)
    
    Args:
        user_id: User ID (int) or user_code (str)
    """
    # Check active sessions first
    session_key = str(user_id)
    if session_key in _active_sessions:
        client = _active_sessions[session_key]
        if client.is_authenticated():
            return client
    
    # Try to load from database
    try:
        from aurum_harmony.database.db import db
        from aurum_harmony.database.models import BrokerCredential, User
        from aurum_harmony.database.utils.encryption import get_encryption_service
        
        # Get user_id if user_code provided
        actual_user_id = None
        if isinstance(user_id, str):
            # Assume it's user_code, find user
            user = User.query.filter_by(user_code=user_id).first()
            if user:
                actual_user_id = user.id
            else:
                logger.warning(f"User not found for user_code: {user_id}")
        else:
            actual_user_id = user_id
        
        if actual_user_id:
            # Query BrokerCredential table
            credential = BrokerCredential.query.filter_by(
                user_id=actual_user_id,
                broker_name='HDFC_SKY',
                is_active=True
            ).first()
            
            if credential:
                encryption_service = get_encryption_service()
                
                # Decrypt credentials
                api_key = encryption_service.decrypt(credential.api_key) if credential.api_key else None
                api_secret = encryption_service.decrypt(credential.api_secret) if credential.api_secret else None
                token_id = encryption_service.decrypt(credential.token_id) if credential.token_id else None
                access_token = encryption_service.decrypt(credential.access_token) if credential.access_token else None
                
                if api_key and api_secret:
                    # Create client
                    client = HDFCSkyAPI(
                        api_key=api_key,
                        api_secret=api_secret,
                        token_id=token_id,
                        access_token=access_token
                    )
                    
                    # Try to authenticate if we have access_token or token_id
                    if access_token or token_id:
                        # Client is already initialized with token, check if authenticated
                        if client.is_authenticated():
                            store_hdfc_client(session_key, client)
                            logger.info(f"Created HDFC Sky client from database for user {session_key}")
                            return client
                        else:
                            # Try to get access token if we have token_id
                            if token_id and not access_token:
                                try:
                                    # Attempt to exchange token_id for access_token
                                    # This would require making an API call
                                    logger.debug(f"Token ID available but access token missing for user {session_key}")
                                    # For now, store client anyway - it might work with token_id
                                    store_hdfc_client(session_key, client)
                                    return client
                                except Exception as e:
                                    logger.warning(f"Failed to authenticate HDFC client from DB: {e}")
                    else:
                        # No tokens, but credentials exist - store for potential future use
                        logger.debug(f"HDFC credentials found but no tokens for user {session_key}")
                        store_hdfc_client(session_key, client)
                        return client
    except Exception as e:
        logger.warning(f"Error loading HDFC Sky credentials from database: {e}")
    
    # Fallback: Try to create from environment variables
    try:
        api_key = os.getenv("HDFC_SKY_API_KEY")
        api_secret = os.getenv("HDFC_SKY_API_SECRET")
        token_id = os.getenv("HDFC_SKY_TOKEN_ID")
        access_token = os.getenv("HDFC_SKY_ACCESS_TOKEN")
        
        if api_key and api_secret:
            client = HDFCSkyAPI(
                api_key=api_key,
                api_secret=api_secret,
                token_id=token_id,
                access_token=access_token
            )
            if client.is_authenticated():
                store_hdfc_client(session_key, client)
                logger.info(f"Created HDFC Sky client from environment for user {session_key}")
                return client
    except Exception as e:
        logger.warning(f"Error creating HDFC Sky client from environment: {e}")
    
    return None


def store_hdfc_client(user_id: str, client: HDFCSkyAPI):
    """Store HDFC Sky client for user"""
    _active_sessions[user_id] = client


@hdfc_bp.route('/orders/place', methods=['POST'])
def place_order():
    """
    Place an order
    Body: {
        "user_id": "user123",
        "symbol": "NIFTY",
        "exchange": "NSE",
        "quantity": 1,
        "order_type": "MARKET",
        "price": 0,
        "transaction_type": "BUY",
        "product_type": "INTRADAY",
        "validity": "DAY"
    }
    """
    try:
        data = request.json
        user_id = data.get('user_id')
        
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400
        
        client = get_hdfc_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated. Please set HDFC_SKY_API_KEY, HDFC_SKY_API_SECRET, and HDFC_SKY_TOKEN_ID or HDFC_SKY_ACCESS_TOKEN in .env"}), 401
        
        result = client.place_order(
            symbol=data.get('symbol'),
            exchange=data.get('exchange', 'NSE'),
            quantity=int(data.get('quantity', 1)),
            order_type=data.get('order_type', 'MARKET'),
            price=float(data.get('price', 0)),
            transaction_type=data.get('transaction_type', 'BUY'),
            product_type=data.get('product_type', 'INTRADAY'),
            validity=data.get('validity', 'DAY')
        )
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        logger.error(f"Error placing order: {e}")
        return jsonify({"error": str(e)}), 400


@hdfc_bp.route('/orders/modify', methods=['POST'])
def modify_order():
    """
    Modify an order
    Body: {
        "user_id": "user123",
        "order_id": "ORDER123",
        "quantity": 2,
        "price": 2500.0,
        "order_type": "LIMIT"
    }
    """
    try:
        data = request.json
        user_id = data.get('user_id')
        order_id = data.get('order_id')
        
        if not user_id or not order_id:
            return jsonify({"error": "Missing user_id or order_id"}), 400
        
        client = get_hdfc_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.modify_order(
            order_id=order_id,
            quantity=data.get('quantity'),
            price=data.get('price'),
            order_type=data.get('order_type')
        )
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        logger.error(f"Error modifying order: {e}")
        return jsonify({"error": str(e)}), 400


@hdfc_bp.route('/orders/cancel', methods=['POST'])
def cancel_order():
    """
    Cancel an order
    Body: {
        "user_id": "user123",
        "order_id": "ORDER123"
    }
    """
    try:
        data = request.json
        user_id = data.get('user_id')
        order_id = data.get('order_id')
        
        if not user_id or not order_id:
            return jsonify({"error": "Missing user_id or order_id"}), 400
        
        client = get_hdfc_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.cancel_order(order_id)
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        logger.error(f"Error canceling order: {e}")
        return jsonify({"error": str(e)}), 400


@hdfc_bp.route('/orders', methods=['GET'])
def get_orders():
    """
    Get order book
    Query params: user_id
    """
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400
        
        client = get_hdfc_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.get_order_book()
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        logger.error(f"Error getting orders: {e}")
        return jsonify({"error": str(e)}), 400


@hdfc_bp.route('/trades', methods=['GET'])
def get_trades():
    """
    Get trade book
    Query params: user_id
    """
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400
        
        client = get_hdfc_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.get_trade_book()
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        logger.error(f"Error getting trades: {e}")
        return jsonify({"error": str(e)}), 400


@hdfc_bp.route('/quotes', methods=['GET'])
def get_quotes():
    """
    Get quotes
    Query params: user_id, symbol, exchange
    """
    try:
        user_id = request.args.get('user_id')
        symbol = request.args.get('symbol')
        exchange = request.args.get('exchange', 'NSE')
        
        if not user_id or not symbol:
            return jsonify({"error": "Missing user_id or symbol"}), 400
        
        client = get_hdfc_client(user_id)
        if not client or not client.is_authenticated():
            return jsonify({"error": "Not authenticated"}), 401
        
        result = client.get_quotes(symbol, exchange)
        
        return jsonify({
            "success": True,
            "data": result
        })
    except Exception as e:
        logger.error(f"Error getting quotes: {e}")
        return jsonify({"error": str(e)}), 400


@hdfc_bp.route('/status', methods=['GET'])
def get_status():
    """
    Get authentication status
    Query params: user_id
    """
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400
        
        client = get_hdfc_client(user_id)
        is_authenticated = client.is_authenticated() if client else False
        
        return jsonify({
            "success": True,
            "authenticated": is_authenticated,
            "has_token_id": client.token_id is not None if client else False,
            "has_access_token": client.access_token is not None if client else False
        })
    except Exception as e:
        logger.error(f"Error getting status: {e}")
        return jsonify({"error": str(e)}), 400

