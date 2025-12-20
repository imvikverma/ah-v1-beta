"""
Onboarding API routes for new users.
Handles saving broker credentials, savings account, and KYC verification.
"""

from flask import Blueprint, request, jsonify, current_app
from datetime import datetime
from ..database.db import db
from ..database.models import User, BrokerCredential, KYCDocument
from ..database.utils.encryption import get_encryption_service
from .routes import require_auth

onboarding_bp = Blueprint('onboarding', __name__, url_prefix='/api/onboarding')


@onboarding_bp.route('/save-broker', methods=['POST', 'OPTIONS'])
@require_auth
def save_broker_credentials():
    """
    Save broker API credentials during onboarding.
    
    Body:
    - broker_name: HDFC_SKY or KOTAK_NEO
    - api_key: Broker API key
    - api_secret: Broker API secret
    - token_id: Optional token ID (for HDFC Sky)
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        user: User = request.current_user
        data = request.get_json() or {}
        
        broker_name = data.get('broker_name', '').upper().strip()
        api_key = data.get('api_key', '').strip()
        api_secret = data.get('api_secret', '').strip()
        token_id = data.get('token_id', '').strip() or None
        
        if not broker_name or broker_name not in ['HDFC_SKY', 'KOTAK_NEO']:
            return jsonify({'error': 'Invalid broker name. Must be HDFC_SKY or KOTAK_NEO'}), 400
        
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
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': f'{broker_name} credentials saved successfully',
            'broker': existing.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error saving broker credentials: {e}", exc_info=True)
        return jsonify({'error': f'Failed to save broker credentials: {str(e)}'}), 500


@onboarding_bp.route('/upi/verify', methods=['POST', 'OPTIONS'])
@require_auth
def verify_upi():
    """
    Verify UPI ID using Razorpay or NPCI validation.
    
    Body:
    - upi_id: UPI ID (e.g., yourname@upi)
    
    Returns:
    - success: Boolean
    - name: Account holder name (if available)
    - bonus: Paper trading bonus amount
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        user: User = request.current_user
        data = request.get_json() or {}
        
        upi_id = data.get('upi_id', '').strip().lower()
        
        if not upi_id:
            return jsonify({'error': 'UPI ID is required'}), 400
        
        # Basic UPI format validation
        if '@' not in upi_id or not upi_id.endswith(('@paytm', '@ybl', '@upi', '@okaxis', '@okhdfcbank', '@oksbi', '@okicici', '@axl', '@ibl')):
            return jsonify({
                'success': False,
                'error': 'Invalid UPI format. Use format: yourname@upi'
            }), 400
        
        # Verify UPI using Razorpay (or mock for now)
        # In production, use: razorpay_client.utility.verify_upi(upi_id)
        from ..services.upi_payment_service import UPIPaymentService
        
        # For now, simulate verification (replace with actual Razorpay API call)
        # Razorpay doesn't have a direct UPI verification API, so we'll use a mock
        # In production, you might need to use NPCI's API or Razorpay's payment link validation
        
        # Mock verification - replace with actual API call
        import re
        upi_pattern = re.compile(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z0-9]{2,64}$')
        is_valid_format = bool(upi_pattern.match(upi_id))
        
        if not is_valid_format:
            return jsonify({
                'success': False,
                'error': 'Invalid UPI ID format'
            }), 400
        
        # Simulate successful verification
        # In production: result = razorpay_client.utility.verify_upi(upi_id)
        verification_result = {
            'valid': True,
            'name': 'Verified User',  # Would come from Razorpay/NPCI API
        }
        
        if verification_result.get('valid'):
            # Update user
            user.upi_id = upi_id
            user.upi_verified = True
            user.upi_verified_at = datetime.utcnow()
            
            # Award paper trading bonus for test users
            bonus_amount = 500.0  # ₹500 paper capital bonus
            if user.is_test or user.user_type == 'new':
                user.internal_capital = getattr(user, 'internal_capital', 0.0) + bonus_amount
            
            user.updated_at = datetime.utcnow()
            db.session.commit()
            
            return jsonify({
                'success': True,
                'message': 'UPI Verified! Welcome to instant funding 🚀',
                'name': verification_result.get('name', 'User'),
                'bonus': bonus_amount if (user.is_test or user.user_type == 'new') else 0,
                'bonus_message': f'Test bonus: +₹{bonus_amount:.0f} paper capital unlocked!' if (user.is_test or user.user_type == 'new') else None,
                'user': user.to_dict()
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'Invalid UPI ID'
            }), 400
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error verifying UPI: {e}", exc_info=True)
        return jsonify({'error': f'Failed to verify UPI: {str(e)}'}), 500


@onboarding_bp.route('/save-savings-account', methods=['POST', 'OPTIONS'])
@require_auth
def save_savings_account():
    """
    Save savings account details during onboarding.
    
    Body:
    - account_number: Savings account number
    - ifsc: IFSC code
    - account_holder_name: Account holder name
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        user: User = request.current_user
        data = request.get_json() or {}
        
        account_number = data.get('account_number', '').strip()
        ifsc = data.get('ifsc', '').strip().upper()
        account_holder_name = data.get('account_holder_name', '').strip()
        
        if not account_number or not ifsc or not account_holder_name:
            return jsonify({'error': 'All fields are required: account_number, ifsc, account_holder_name'}), 400
        
        # Basic validation
        if len(ifsc) != 11:
            return jsonify({'error': 'IFSC code must be 11 characters'}), 400
        
        # Update user
        user.savings_account_number = account_number
        user.savings_account_ifsc = ifsc
        user.savings_account_holder_name = account_holder_name
        user.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Savings account details saved successfully',
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error saving savings account: {e}", exc_info=True)
        return jsonify({'error': f'Failed to save savings account: {str(e)}'}), 500


@onboarding_bp.route('/save-kyc', methods=['POST', 'OPTIONS'])
@require_auth
def save_kyc_verification():
    """
    Save KYC verification status during onboarding.
    
    Body:
    - verification_id: DigiLocker verification ID
    - verified: Boolean indicating if KYC is verified
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        user: User = request.current_user
        data = request.get_json() or {}
        
        verification_id = data.get('verification_id', '').strip()
        verified = data.get('verified', False)
        
        if verified and not verification_id:
            return jsonify({'error': 'Verification ID is required when verified is true'}), 400
        
        # Update user
        user.is_kyc_verified = verified
        user.kyc_verification_id = verification_id if verified else None
        user.kyc_verified_at = datetime.utcnow() if verified else None
        user.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'KYC verification status saved successfully',
            'user': user.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error saving KYC verification: {e}", exc_info=True)
        return jsonify({'error': f'Failed to save KYC verification: {str(e)}'}), 500


@onboarding_bp.route('/digilocker/authorize', methods=['GET', 'OPTIONS'])
@require_auth
def digilocker_authorize():
    """
    Get DigiLocker authorization URL for KYC verification.
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        user: User = request.current_user
        from ..services.digilocker_service import DigiLockerService
        
        # Generate state with user_id for CSRF protection
        state = f"user_{user.id}_{datetime.now().timestamp()}"
        
        auth_url = DigiLockerService.get_authorization_url(state)
        
        return jsonify({
            'success': True,
            'authorization_url': auth_url,
            'state': state
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Error generating DigiLocker URL: {e}", exc_info=True)
        return jsonify({'error': f'Failed to generate DigiLocker URL: {str(e)}'}), 500


@onboarding_bp.route('/digilocker/callback', methods=['GET', 'POST', 'OPTIONS'])
def digilocker_callback():
    """
    Handle DigiLocker OAuth callback.
    This endpoint is called by DigiLocker after user authorization.
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        code = request.args.get('code')
        state = request.args.get('state')
        error = request.args.get('error')
        
        if error:
            return jsonify({'error': f'DigiLocker authorization failed: {error}'}), 400
        
        if not code or not state:
            return jsonify({'error': 'Missing code or state parameter'}), 400
        
        # Extract user_id from state
        # State format: "user_{user_id}_{timestamp}"
        try:
            user_id = int(state.split('_')[1])
        except (IndexError, ValueError):
            return jsonify({'error': 'Invalid state parameter'}), 400
        
        # Exchange code for token
        from ..services.digilocker_service import DigiLockerService
        token_response = DigiLockerService.exchange_code_for_token(code)
        
        if not token_response:
            return jsonify({'error': 'Failed to exchange code for token'}), 500
        
        access_token = token_response.get('access_token')
        if not access_token:
            return jsonify({'error': 'No access token in response'}), 500
        
        # Fetch documents
        documents = DigiLockerService.fetch_documents(access_token)
        
        if not documents:
            return jsonify({'error': 'Failed to fetch documents from DigiLocker'}), 500
        
        # Parse and save KYC documents
        user = User.query.get(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Process Aadhaar and PAN documents
        kyc_data = {}
        for doc in documents.get('documents', []):
            doc_type = doc.get('type', '').upper()
            
            if doc_type == 'AADHAAR':
                aadhaar_data = DigiLockerService.parse_aadhaar_data(doc)
                kyc_data.update(aadhaar_data)
                
                # Save Aadhaar document
                kyc_doc = KYCDocument(
                    user_id=user.id,
                    document_type='AADHAAR',
                    document_number=f"XXXX-XXXX-{aadhaar_data.get('aadhaar_last4', '')}",
                    digilocker_doc_uri=doc.get('uri'),
                    aadhaar_last4=aadhaar_data.get('aadhaar_last4'),
                    full_name=aadhaar_data.get('full_name'),
                    date_of_birth=datetime.strptime(aadhaar_data.get('date_of_birth', ''), '%Y-%m-%d').date() if aadhaar_data.get('date_of_birth') else None,
                    address=aadhaar_data.get('address'),
                    verified=True,
                    verification_date=datetime.utcnow()
                )
                db.session.add(kyc_doc)
                
            elif doc_type == 'PAN':
                pan_data = DigiLockerService.parse_pan_data(doc)
                kyc_data.update(pan_data)
                
                # Save PAN document
                kyc_doc = KYCDocument(
                    user_id=user.id,
                    document_type='PAN',
                    document_number=pan_data.get('pan_number', ''),
                    digilocker_doc_uri=doc.get('uri'),
                    pan_number=pan_data.get('pan_number'),
                    full_name=pan_data.get('full_name'),
                    date_of_birth=datetime.strptime(pan_data.get('date_of_birth', ''), '%Y-%m-%d').date() if pan_data.get('date_of_birth') else None,
                    verified=True,
                    verification_date=datetime.utcnow()
                )
                db.session.add(kyc_doc)
        
        # Update user KYC status
        user.is_kyc_verified = True
        user.kyc_verification_id = f"DL-{datetime.now().timestamp()}"
        user.kyc_verified_at = datetime.utcnow()
        user.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        # Return success - frontend will handle redirect
        return jsonify({
            'success': True,
            'message': 'KYC verification completed successfully',
            'user': user.to_dict(),
            'kyc_documents': [doc.to_dict() for doc in user.kyc_documents]
        }), 200
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Error processing DigiLocker callback: {e}", exc_info=True)
        return jsonify({'error': f'Failed to process DigiLocker callback: {str(e)}'}), 500


@onboarding_bp.route('/status', methods=['GET', 'OPTIONS'])
@require_auth
def get_onboarding_status():
    """
    Get current onboarding status for the user.
    Returns which steps have been completed.
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        user: User = request.current_user
        
        # Check broker credentials
        broker_creds = BrokerCredential.query.filter_by(
            user_id=user.id,
            is_active=True
        ).first()
        has_broker = broker_creds is not None
        
        # Check savings account
        has_savings = bool(
            user.savings_account_number and
            user.savings_account_ifsc and
            user.savings_account_holder_name
        )
        
        # Check KYC
        has_kyc = user.is_kyc_verified
        
        return jsonify({
            'success': True,
            'status': {
                'broker_configured': has_broker,
                'savings_account_linked': has_savings,
                'kyc_verified': has_kyc,
                'user_type': user.user_type,
            }
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Error getting onboarding status: {e}", exc_info=True)
        return jsonify({'error': f'Failed to get onboarding status: {str(e)}'}), 500

