"""
DigiLocker KYC Integration Service

Integrates with DigiLocker API for KYC verification via OAuth2 flow.
"""

import os
import requests
import logging
from typing import Dict, Any, Optional
from urllib.parse import urlencode, parse_qs, urlparse
from datetime import datetime

logger = logging.getLogger(__name__)

# DigiLocker API endpoints
DIGILOCKER_AUTH_URL = "https://digilocker.meity.gov.in/public/oauth2/1/authorize"
DIGILOCKER_TOKEN_URL = "https://digilocker.meity.gov.in/public/oauth2/1/token"
DIGILOCKER_DOCS_URL = "https://digilocker.meity.gov.in/public/oauth2/2/files"
DIGILOCKER_FILE_URL = "https://digilocker.meity.gov.in/public/oauth2/2/file/{file_uri}"

# Get from environment variables
DIGILOCKER_CLIENT_ID = os.getenv("DIGILOCKER_CLIENT_ID", "")
DIGILOCKER_CLIENT_SECRET = os.getenv("DIGILOCKER_CLIENT_SECRET", "")
DIGILOCKER_REDIRECT_URI = os.getenv(
    "DIGILOCKER_REDIRECT_URI",
    "https://ah.saffronbolt.in/api/auth/digilocker/callback"
)


class DigiLockerService:
    """Service for DigiLocker KYC integration."""
    
    @staticmethod
    def get_authorization_url(state: str) -> str:
        """
        Generate DigiLocker OAuth authorization URL.
        
        Args:
            state: State parameter for CSRF protection (typically user_id or session_id)
            
        Returns:
            Authorization URL to redirect user to
        """
        params = {
            'response_type': 'code',
            'client_id': DIGILOCKER_CLIENT_ID,
            'redirect_uri': DIGILOCKER_REDIRECT_URI,
            'state': state,
            'scope': 'read',
        }
        return f"{DIGILOCKER_AUTH_URL}?{urlencode(params)}"
    
    @staticmethod
    def exchange_code_for_token(code: str) -> Optional[Dict[str, Any]]:
        """
        Exchange authorization code for access token.
        
        Args:
            code: Authorization code from DigiLocker callback
            
        Returns:
            Token response with access_token, or None if failed
        """
        try:
            response = requests.post(
                DIGILOCKER_TOKEN_URL,
                data={
                    'grant_type': 'authorization_code',
                    'code': code,
                    'client_id': DIGILOCKER_CLIENT_ID,
                    'client_secret': DIGILOCKER_CLIENT_SECRET,
                    'redirect_uri': DIGILOCKER_REDIRECT_URI,
                },
                headers={'Content-Type': 'application/x-www-form-urlencoded'},
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"DigiLocker token exchange failed: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            logger.error(f"Error exchanging DigiLocker code: {e}", exc_info=True)
            return None
    
    @staticmethod
    def fetch_documents(access_token: str) -> Optional[Dict[str, Any]]:
        """
        Fetch user's documents from DigiLocker.
        
        Args:
            access_token: DigiLocker access token
            
        Returns:
            Documents list or None if failed
        """
        try:
            response = requests.get(
                DIGILOCKER_DOCS_URL,
                headers={
                    'Authorization': f'Bearer {access_token}',
                    'Content-Type': 'application/json',
                },
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                logger.error(f"DigiLocker fetch documents failed: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            logger.error(f"Error fetching DigiLocker documents: {e}", exc_info=True)
            return None
    
    @staticmethod
    def fetch_document_file(access_token: str, file_uri: str) -> Optional[bytes]:
        """
        Fetch a specific document file from DigiLocker.
        
        Args:
            access_token: DigiLocker access token
            file_uri: Document URI from DigiLocker
            
        Returns:
            Document file bytes or None if failed
        """
        try:
            url = DIGILOCKER_FILE_URL.format(file_uri=file_uri)
            response = requests.get(
                url,
                headers={
                    'Authorization': f'Bearer {access_token}',
                },
                timeout=30
            )
            
            if response.status_code == 200:
                return response.content
            else:
                logger.error(f"DigiLocker fetch file failed: {response.status_code} - {response.text}")
                return None
        except Exception as e:
            logger.error(f"Error fetching DigiLocker file: {e}", exc_info=True)
            return None
    
    @staticmethod
    def parse_aadhaar_data(document_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse Aadhaar document data to extract KYC information.
        
        Args:
            document_data: Raw document data from DigiLocker
            
        Returns:
            Parsed KYC data (name, DOB, address, last 4 digits)
        """
        # DigiLocker returns XML/JSON with Aadhaar data
        # This is a placeholder - actual parsing depends on DigiLocker response format
        parsed = {
            'full_name': document_data.get('name', ''),
            'date_of_birth': document_data.get('dob', ''),
            'address': document_data.get('address', ''),
            'aadhaar_number': document_data.get('aadhaar', ''),
        }
        
        # Extract last 4 digits
        if parsed['aadhaar_number']:
            parsed['aadhaar_last4'] = parsed['aadhaar_number'][-4:]
        
        return parsed
    
    @staticmethod
    def parse_pan_data(document_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse PAN document data.
        
        Args:
            document_data: Raw document data from DigiLocker
            
        Returns:
            Parsed PAN data
        """
        return {
            'pan_number': document_data.get('pan', ''),
            'full_name': document_data.get('name', ''),
            'date_of_birth': document_data.get('dob', ''),
        }

