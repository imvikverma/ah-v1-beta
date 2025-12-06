"""
Flask routes for broker credential management.
"""

import os
from flask import Blueprint, request, jsonify, redirect, url_for
from datetime import datetime, timedelta
from ..database.db import db
from ..database.models import BrokerCredential
from ..database.utils.encryption import get_encryption_service
from ..auth.routes import require_auth

brokers_bp = Blueprint('brokers', __name__, url_prefix='/api/brokers')

# Supported brokers
SUPPORTED_BROKERS = ['HDFC_SKY', 'KOTAK_NEO', 'MANGAL_KESHAV']


@brokers_bp.route('/list', methods=['GET'])
@require_auth
def list_brokers():
    """Get list of user's connected brokers."""
    user = request.current_user
    
    credentials = BrokerCredential.query.filter_by(
        user_id=user.id,
        is_active=True
    ).all()
    
    return jsonify({
        'brokers': [cred.to_dict() for cred in credentials],
        'available_brokers': SUPPORTED_BROKERS
    }), 200


@brokers_bp.route('/connect', methods=['POST'])
@require_auth
def connect_broker():
    """
    Connect a broker using manual credentials.
    
    NOTE: HDFC Sky does NOT support OAuth - use manual entry only.
    All brokers (HDFC Sky, Kotak Neo, etc.) use manual API key/secret entry.
    
    Required fields:
    - api_key: Broker API key (Consumer Key)
    - api_secret: Broker API secret (Consumer Secret)
    - token_id: Optional request token (for HDFC Sky if required)
    """
    user = request.current_user
    data = request.get_json() or {}
    
    broker_name = data.get('broker_name', '').upper()
    
    if broker_name not in SUPPORTED_BROKERS:
        return jsonify({'error': f'Unsupported broker: {broker_name}'}), 400
    
    # HDFC Sky does NOT support OAuth - reject OAuth requests
    if broker_name == 'HDFC_SKY' and data.get('oauth', False):
        return jsonify({
            'error': 'HDFC Sky does not support OAuth. Please use manual credential entry.',
            'broker': broker_name,
            'required_fields': ['api_key', 'api_secret', 'token_id (optional)']
        }), 400
    
    # Manual credential entry (for all brokers)
    api_key = data.get('api_key', '').strip()
    api_secret = data.get('api_secret', '').strip()
    token_id = data.get('token_id', '').strip() or None
    
    if not api_key or not api_secret:
        return jsonify({'error': 'API key and secret are required'}), 400
    
    # Encrypt credentials
    encryption_service = get_encryption_service()
    encrypted_key = encryption_service.encrypt(api_key)
    encrypted_secret = encryption_service.encrypt(api_secret)
    encrypted_token_id = encryption_service.encrypt(token_id) if token_id else None
    
    # Check if credential already exists
    existing = BrokerCredential.query.filter_by(
        user_id=user.id,
        broker_name=broker_name
    ).first()
    
    if existing:
        # Update existing
        existing.api_key = encrypted_key
        existing.api_secret = encrypted_secret
        existing.token_id = encrypted_token_id
        existing.is_active = True
        existing.updated_at = datetime.utcnow()
    else:
        # Create new
        existing = BrokerCredential(
            user_id=user.id,
            broker_name=broker_name,
            api_key=encrypted_key,
            api_secret=encrypted_secret,
            token_id=encrypted_token_id,
            is_active=True
        )
        db.session.add(existing)
    
    try:
        db.session.commit()
        return jsonify({
            'message': f'{broker_name} connected successfully',
            'broker': existing.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to save credentials: {str(e)}'}), 500


@brokers_bp.route('/oauth/callback', methods=['GET'])
def oauth_callback():
    """
    OAuth callback endpoint for broker authorization.
    Extracts request token and associates it with user session.
    
    Note: HDFC Sky doesn't use OAuth, but this endpoint is available
    for other brokers that might use OAuth in the future.
    """
    request_token = request.args.get('requestToken') or request.args.get('request_token')
    state = request.args.get('state')  # Optional: can contain user_id or session info
    
    if not request_token:
        return jsonify({'error': 'No request token received'}), 400
    
    # Try to get user from Authorization header (if authenticated)
    user = None
    auth_header = request.headers.get('Authorization', '')
    if auth_header.startswith('Bearer '):
        token = auth_header[7:]
        from ..auth.auth_service import AuthService
        user = AuthService.get_user_from_token(token)
    
    # If no user from auth, try to get from state parameter
    if not user and state:
        try:
            # State could contain user_id or session info
            # For now, we'll require authentication
            pass
        except:
            pass
    
    if not user:
        # Return token for user to complete manually
        return jsonify({
            'message': 'OAuth callback received. Please complete broker connection with this token.',
            'request_token': request_token[:20] + '...',  # Don't expose full token
            'note': 'Use this token when connecting the broker manually'
        }), 200
    
    # If user is authenticated, we could auto-associate the token
    # For now, return success and let user complete connection
    return jsonify({
        'message': 'OAuth callback received',
        'request_token': request_token[:20] + '...',
        'user_id': user.id,
        'note': 'Use this request_token when connecting the broker'
    }), 200


@brokers_bp.route('/<broker_name>/status', methods=['GET'])
@require_auth
def broker_status(broker_name):
    """Check if broker credentials are valid and test them."""
    user = request.current_user
    broker_name = broker_name.upper()
    
    credential = BrokerCredential.query.filter_by(
        user_id=user.id,
        broker_name=broker_name,
        is_active=True
    ).first()
    
    if not credential:
        return jsonify({
            'connected': False,
            'message': f'{broker_name} not connected'
        }), 200
    
    # Test credentials by making an API call
    encryption_service = get_encryption_service()
    is_valid = False
    error_message = None
    
    try:
        if broker_name == 'HDFC_SKY':
            # Test HDFC Sky credentials
            import os
            import requests
            from datetime import datetime
            
            api_key = encryption_service.decrypt(credential.api_key) if credential.api_key else None
            api_secret = encryption_service.decrypt(credential.api_secret) if credential.api_secret else None
            request_token = encryption_service.decrypt(credential.token_id) if credential.token_id else None
            
            if not api_key or not api_secret:
                error_message = 'Missing API key or secret'
            else:
                # Try to get access token (this validates credentials)
                if request_token:
                    url = f"https://developer.hdfcsky.com/oapi/v1/access-token?api_key={api_key}&request_token={request_token}"
                    response = requests.post(
                        url,
                        json={'api_secret': api_secret},
                        timeout=10
                    )
                    if response.status_code == 200:
                        is_valid = True
                        # Update access token if received
                        token_data = response.json()
                        if 'access_token' in token_data:
                            credential.access_token = encryption_service.encrypt(token_data['access_token'])
                            credential.last_validated = datetime.utcnow()
                            db.session.commit()
                    else:
                        error_message = f'HDFC Sky API error: {response.status_code}'
                else:
                    # Can't test without request token, but credentials exist
                    is_valid = None  # Unknown
                    error_message = 'Request token required for validation'
        
        elif broker_name == 'KOTAK_NEO':
            # Test Kotak Neo credentials
            # TODO: Implement Kotak Neo API test
            is_valid = None  # Unknown for now
            error_message = 'Kotak Neo validation not yet implemented'
        
        else:
            # Other brokers - just check if credentials exist
            is_valid = credential.api_key is not None and credential.api_secret is not None
    
    except Exception as e:
        error_message = f'Validation error: {str(e)}'
        is_valid = False
    
    return jsonify({
        'connected': True,
        'valid': is_valid,
        'broker': credential.to_dict(),
        'message': f'{broker_name} is connected' + (f' and valid' if is_valid else (f' but validation failed: {error_message}' if error_message else ' (validation unknown)')),
        'error': error_message
    }), 200


@brokers_bp.route('/disconnect', methods=['POST'])
@require_auth
def disconnect_broker():
    """Disconnect a broker by deactivating credentials."""
    user = request.current_user
    data = request.get_json() or {}
    
    broker_name = data.get('broker_name', '').upper()
    
    if not broker_name:
        return jsonify({'error': 'Broker name is required'}), 400
    
    credential = BrokerCredential.query.filter_by(
        user_id=user.id,
        broker_name=broker_name
    ).first()
    
    if not credential:
        return jsonify({'error': 'Broker not found'}), 404
    
    credential.is_active = False
    credential.updated_at = datetime.utcnow()
    
    try:
        db.session.commit()
        return jsonify({
            'message': f'{broker_name} disconnected successfully'
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Failed to disconnect: {str(e)}'}), 500

