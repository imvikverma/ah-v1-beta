"""
DigiLocker API Integration for KYC Compliance
Government of India's digital document storage service integration
"""

import os
import requests
import logging
from typing import Dict, Optional, List, Any
from urllib.parse import urlencode, parse_qs, urlparse
import secrets
import hashlib
import base64

logger = logging.getLogger(__name__)


class DigiLockerAPI:
    """
    DigiLocker OAuth 2.0 API client for KYC document verification.
    
    Features:
    - OAuth 2.0 authorization flow
    - Document fetching (Aadhaar, PAN)
    - Document verification
    """
    
    # DigiLocker API endpoints
    AUTHORIZE_URL = "https://digilocker.meity.gov.in/public/oauth2/1/authorize"
    TOKEN_URL = "https://digilocker.meity.gov.in/public/oauth2/1/token"
    DOCUMENTS_URL = "https://digilocker.meity.gov.in/public/oauth2/2/files"
    DOCUMENT_URL = "https://digilocker.meity.gov.in/public/oauth2/2/file/{file_uri}"
    USER_PROFILE_URL = "https://digilocker.meity.gov.in/public/oauth2/1/user"
    
    # Required scopes for KYC documents
    REQUIRED_SCOPES = [
        "read",  # Read documents
        "profile",  # Read user profile
    ]
    
    def __init__(self, client_id: Optional[str] = None, client_secret: Optional[str] = None, 
                 redirect_uri: Optional[str] = None):
        """
        Initialize DigiLocker API client.
        
        Args:
            client_id: DigiLocker Client ID (from .env or parameter)
            client_secret: DigiLocker Client Secret (from .env or parameter)
            redirect_uri: OAuth callback URL
        """
        self.client_id = client_id or os.getenv("DIGILOCKER_CLIENT_ID")
        self.client_secret = client_secret or os.getenv("DIGILOCKER_CLIENT_SECRET")
        self.redirect_uri = redirect_uri or os.getenv("DIGILOCKER_REDIRECT_URI", 
                                                      "https://ah.saffronbolt.in/auth/digilocker/callback")
        
        if not self.client_id:
            logger.warning("DigiLocker Client ID not configured. KYC features will be limited.")
        if not self.client_secret:
            logger.warning("DigiLocker Client Secret not configured. KYC features will be limited.")
    
    def generate_authorization_url(self, state: Optional[str] = None) -> Dict[str, Any]:
        """
        Generate DigiLocker OAuth authorization URL.
        
        Args:
            state: Optional state parameter for CSRF protection
            
        Returns:
            Dict with authorization_url and state
        """
        if not self.client_id:
            raise ValueError("DigiLocker Client ID not configured")
        
        # Generate state if not provided
        if not state:
            state = secrets.token_urlsafe(32)
        
        # Build authorization URL
        params = {
            "response_type": "code",
            "client_id": self.client_id,
            "redirect_uri": self.redirect_uri,
            "scope": " ".join(self.REQUIRED_SCOPES),
            "state": state,
        }
        
        authorization_url = f"{self.AUTHORIZE_URL}?{urlencode(params)}"
        
        return {
            "authorization_url": authorization_url,
            "state": state
        }
    
    def exchange_code_for_token(self, code: str, state: Optional[str] = None) -> Dict[str, Any]:
        """
        Exchange authorization code for access token.
        
        Args:
            code: Authorization code from callback
            state: State parameter (should match original)
            
        Returns:
            Dict with access_token, refresh_token, expires_in, etc.
        """
        if not self.client_id or not self.client_secret:
            raise ValueError("DigiLocker credentials not configured")
        
        data = {
            "grant_type": "authorization_code",
            "code": code,
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "redirect_uri": self.redirect_uri,
        }
        
        try:
            response = requests.post(self.TOKEN_URL, data=data, timeout=30)
            response.raise_for_status()
            token_data = response.json()
            
            logger.info("DigiLocker token exchange successful")
            return token_data
            
        except requests.exceptions.RequestException as e:
            logger.error(f"DigiLocker token exchange failed: {e}")
            raise Exception(f"Failed to exchange code for token: {str(e)}")
    
    def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """
        Refresh access token using refresh token.
        
        Args:
            refresh_token: Refresh token from initial token exchange
            
        Returns:
            Dict with new access_token, refresh_token, expires_in
        """
        if not self.client_id or not self.client_secret:
            raise ValueError("DigiLocker credentials not configured")
        
        data = {
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "client_id": self.client_id,
            "client_secret": self.client_secret,
        }
        
        try:
            response = requests.post(self.TOKEN_URL, data=data, timeout=30)
            response.raise_for_status()
            token_data = response.json()
            
            logger.info("DigiLocker token refresh successful")
            return token_data
            
        except requests.exceptions.RequestException as e:
            logger.error(f"DigiLocker token refresh failed: {e}")
            raise Exception(f"Failed to refresh token: {str(e)}")
    
    def get_user_profile(self, access_token: str) -> Dict[str, Any]:
        """
        Get user profile information from DigiLocker.
        
        Args:
            access_token: DigiLocker access token
            
        Returns:
            Dict with user profile (name, dob, aadhaar, etc.)
        """
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }
        
        try:
            response = requests.get(self.USER_PROFILE_URL, headers=headers, timeout=30)
            response.raise_for_status()
            profile = response.json()
            
            logger.info("DigiLocker user profile fetched successfully")
            return profile
            
        except requests.exceptions.RequestException as e:
            logger.error(f"DigiLocker profile fetch failed: {e}")
            raise Exception(f"Failed to fetch user profile: {str(e)}")
    
    def list_documents(self, access_token: str) -> List[Dict[str, Any]]:
        """
        List all available documents in user's DigiLocker.
        
        Args:
            access_token: DigiLocker access token
            
        Returns:
            List of document metadata
        """
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }
        
        try:
            response = requests.get(self.DOCUMENTS_URL, headers=headers, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            documents = data.get("documents", [])
            logger.info(f"DigiLocker documents list fetched: {len(documents)} documents")
            return documents
            
        except requests.exceptions.RequestException as e:
            logger.error(f"DigiLocker documents list failed: {e}")
            raise Exception(f"Failed to list documents: {str(e)}")
    
    def get_document(self, access_token: str, file_uri: str) -> Dict[str, Any]:
        """
        Fetch specific document from DigiLocker.
        
        Args:
            access_token: DigiLocker access token
            file_uri: Document URI from list_documents
            
        Returns:
            Dict with document data (base64 encoded PDF, metadata, etc.)
        """
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }
        
        url = self.DOCUMENT_URL.format(file_uri=file_uri)
        
        try:
            response = requests.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            document = response.json()
            
            logger.info(f"DigiLocker document fetched: {file_uri}")
            return document
            
        except requests.exceptions.RequestException as e:
            logger.error(f"DigiLocker document fetch failed: {e}")
            raise Exception(f"Failed to fetch document: {str(e)}")
    
    def extract_kyc_data(self, documents: List[Dict[str, Any]], 
                        profile: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Extract KYC data from DigiLocker documents and profile.
        
        Args:
            documents: List of documents from list_documents
            profile: User profile from get_user_profile
            
        Returns:
            Dict with extracted KYC data (aadhaar, pan, name, dob, address)
        """
        kyc_data = {
            "aadhaar_number": None,
            "pan_number": None,
            "name": None,
            "date_of_birth": None,
            "address": None,
            "gender": None,
            "documents": {}
        }
        
        # Extract from profile if available
        if profile:
            kyc_data["name"] = profile.get("name")
            kyc_data["date_of_birth"] = profile.get("dob")
            kyc_data["gender"] = profile.get("gender")
        
        # Extract from documents
        for doc in documents:
            doc_type = doc.get("type", "").upper()
            doc_name = doc.get("name", "")
            file_uri = doc.get("uri")
            
            if "AADHAAR" in doc_type or "AADHAAR" in doc_name.upper():
                kyc_data["documents"]["aadhaar"] = {
                    "uri": file_uri,
                    "name": doc_name,
                    "type": doc_type,
                    "date": doc.get("date"),
                }
                # Try to extract Aadhaar number from document name or metadata
                # Note: Full Aadhaar number should not be stored, only last 4 digits
                if "number" in doc:
                    aadhaar_full = str(doc.get("number", ""))
                    if len(aadhaar_full) >= 4:
                        kyc_data["aadhaar_number"] = f"XXXX-XXXX-{aadhaar_full[-4:]}"
            
            elif "PAN" in doc_type or "PAN" in doc_name.upper():
                kyc_data["documents"]["pan"] = {
                    "uri": file_uri,
                    "name": doc_name,
                    "type": doc_type,
                    "date": doc.get("date"),
                }
                # Extract PAN number
                if "number" in doc:
                    kyc_data["pan_number"] = doc.get("number")
        
        return kyc_data


# Global instance
digilocker_api = DigiLockerAPI()
