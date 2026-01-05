"""
KYC Routes for DigiLocker Integration
Handles OAuth flow and document verification
"""

from flask import Blueprint, request, jsonify, redirect, url_for
from functools import wraps
import logging
from datetime import datetime, timedelta
import secrets

from aurum_harmony.APIs_and_Integrations.digilocker_api import digilocker_api
from aurum_harmony.database.db import db
from aurum_harmony.database.models import User, KYCDocument
from aurum_harmony.auth.auth_service import AuthService

logger = logging.getLogger(__name__)

kyc_bp = Blueprint('kyc', __name__, url_prefix='/api/kyc')


def require_auth(f):
    """Decorator to require authentication."""
    @wraps(f)
    def wrapper(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'Authorization required'}), 401
        
        if token.startswith('Bearer '):
            token = token[7:]
        
        try:
            user = AuthService.get_user_from_token(token)
        except Exception as e:
            logger.error(f"Error getting user from token: {e}")
            return jsonify({'error': 'Invalid token'}), 401
        
        if not user:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        request.current_user = user
        return f(*args, **kwargs)
    return wrapper


@kyc_bp.route('/digilocker/authorize', methods=['POST'])
@require_auth
def initiate_digilocker_oauth():
    """
    Initiate DigiLocker OAuth flow.
    Returns authorization URL for frontend redirect.
    """
    try:
        user = request.current_user
        
        # Generate state for CSRF protection
        state = secrets.token_urlsafe(32)
        
        # Store state in session or database (simplified - use session in production)
        # For now, we'll include user_id in state (not ideal, but works)
        state_with_user = f"{user.id}:{state}"
        
        # Generate authorization URL
        auth_data = digilocker_api.generate_authorization_url(state=state_with_user)
        
        return jsonify({
            'success': True,
            'authorization_url': auth_data['authorization_url'],
            'state': state
        }), 200
        
    except Exception as e:
        logger.error(f"DigiLocker OAuth initiation failed: {e}", exc_info=True)
        return jsonify({'error': f'Failed to initiate OAuth: {str(e)}'}), 500


@kyc_bp.route('/digilocker/callback', methods=['GET', 'POST'])
def digilocker_callback():
    """
    Handle DigiLocker OAuth callback.
    This endpoint receives the authorization code and exchanges it for tokens.
    """
    try:
        code = request.args.get('code')
        state = request.args.get('state')
        error = request.args.get('error')
        
        if error:
            logger.error(f"DigiLocker OAuth error: {error}")
            return redirect(f"/onboarding?error={error}")
        
        if not code or not state:
            return redirect("/onboarding?error=missing_code_or_state")
        
        # Extract user_id from state (simplified - use proper session in production)
        try:
            user_id_str, _ = state.split(':', 1)
            user_id = int(user_id_str)
        except (ValueError, IndexError):
            return redirect("/onboarding?error=invalid_state")
        
        # Get user
        user = User.query.get(user_id)
        if not user:
            return redirect("/onboarding?error=user_not_found")
        
        # Exchange code for token
        token_data = digilocker_api.exchange_code_for_token(code, state)
        
        access_token = token_data.get('access_token')
        refresh_token = token_data.get('refresh_token')
        expires_in = token_data.get('expires_in', 3600)
        
        # Store tokens (encrypted in production)
        user.digilocker_access_token = access_token  # TODO: Encrypt
        user.digilocker_refresh_token = refresh_token  # TODO: Encrypt
        user.digilocker_token_expires_at = datetime.utcnow() + timedelta(seconds=expires_in)
        db.session.commit()
        
        # Fetch user profile and documents
        try:
            profile = digilocker_api.get_user_profile(access_token)
            documents = digilocker_api.list_documents(access_token)
            kyc_data = digilocker_api.extract_kyc_data(documents, profile)
            
            # Save KYC documents
            for doc_type, doc_info in kyc_data.get('documents', {}).items():
                existing = KYCDocument.query.filter_by(
                    user_id=user.id,
                    document_type=doc_type.upper()
                ).first()
                
                if existing:
                    existing.document_uri = doc_info.get('uri')
                    existing.document_name = doc_info.get('name')
                    existing.digilocker_doc_uri = doc_info.get('uri')
                    existing.metadata = {
                        'type': doc_info.get('type'),
                        'date': doc_info.get('date'),
                    }
                    existing.updated_at = datetime.utcnow()
                else:
                    kyc_doc = KYCDocument(
                        user_id=user.id,
                        document_type=doc_type.upper(),
                        document_name=doc_info.get('name'),
                        document_uri=doc_info.get('uri'),
                        digilocker_doc_uri=doc_info.get('uri'),
                        verification_method='DIGILOCKER',
                        metadata={
                            'type': doc_info.get('type'),
                            'date': doc_info.get('date'),
                        }
                    )
                    db.session.add(kyc_doc)
            
            # Update user KYC status
            if kyc_data.get('aadhaar_number') or kyc_data.get('pan_number'):
                user.kyc_verified = True
                user.kyc_verified_at = datetime.utcnow()
                user.kyc_verification_method = 'DIGILOCKER'
            
            # Update user profile from KYC data
            if kyc_data.get('name') and not user.username:
                user.username = kyc_data.get('name')
            if kyc_data.get('date_of_birth') and not user.date_of_birth:
                try:
                    user.date_of_birth = datetime.strptime(kyc_data.get('date_of_birth'), '%Y-%m-%d').date()
                except:
                    pass
            
            db.session.commit()
            
            logger.info(f"KYC verification completed for user {user.user_code}")
            
            return redirect("/onboarding?kyc=verified")
            
        except Exception as e:
            logger.error(f"Failed to fetch KYC documents: {e}", exc_info=True)
            # Still redirect, but with warning
            return redirect("/onboarding?kyc=partial")
        
    except Exception as e:
        logger.error(f"DigiLocker callback failed: {e}", exc_info=True)
        return redirect(f"/onboarding?error={str(e)}")


@kyc_bp.route('/status', methods=['GET'])
@require_auth
def get_kyc_status():
    """Get KYC verification status for current user."""
    try:
        user = request.current_user
        
        kyc_docs = KYCDocument.query.filter_by(user_id=user.id).all()
        
        return jsonify({
            'success': True,
            'kyc_verified': user.kyc_verified,
            'kyc_verified_at': user.kyc_verified_at.isoformat() if user.kyc_verified_at else None,
            'verification_method': user.kyc_verification_method,
            'documents': [doc.to_dict() for doc in kyc_docs]
        }), 200
        
    except Exception as e:
        logger.error(f"Failed to get KYC status: {e}", exc_info=True)
        return jsonify({'error': f'Failed to get KYC status: {str(e)}'}), 500


@kyc_bp.route('/documents', methods=['GET'])
@require_auth
def list_kyc_documents():
    """List all KYC documents for current user."""
    try:
        user = request.current_user
        
        # Refresh token if needed
        if user.digilocker_access_token and user.digilocker_token_expires_at:
            if datetime.utcnow() >= user.digilocker_token_expires_at:
                if user.digilocker_refresh_token:
                    try:
                        token_data = digilocker_api.refresh_access_token(user.digilocker_refresh_token)
                        user.digilocker_access_token = token_data.get('access_token')
                        user.digilocker_refresh_token = token_data.get('refresh_token')
                        expires_in = token_data.get('expires_in', 3600)
                        user.digilocker_token_expires_at = datetime.utcnow() + timedelta(seconds=expires_in)
                        db.session.commit()
                    except Exception as e:
                        logger.error(f"Token refresh failed: {e}")
        
        # Fetch fresh documents from DigiLocker
        if user.digilocker_access_token:
            try:
                documents = digilocker_api.list_documents(user.digilocker_access_token)
                return jsonify({
                    'success': True,
                    'documents': documents,
                    'source': 'digilocker'
                }), 200
            except Exception as e:
                logger.error(f"Failed to fetch DigiLocker documents: {e}")
        
        # Fallback to database
        kyc_docs = KYCDocument.query.filter_by(user_id=user.id).all()
        return jsonify({
            'success': True,
            'documents': [doc.to_dict() for doc in kyc_docs],
            'source': 'database'
        }), 200
        
    except Exception as e:
        logger.error(f"Failed to list KYC documents: {e}", exc_info=True)
        return jsonify({'error': f'Failed to list documents: {str(e)}'}), 500
