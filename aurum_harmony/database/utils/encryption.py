"""
Credential encryption service using Fernet (symmetric encryption).
"""

import os
import base64
from typing import Optional
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

class EncryptionService:
    """Service for encrypting and decrypting sensitive data."""
    
    def __init__(self, key: Optional[str] = None):
        """
        Initialize encryption service.
        
        Args:
            key: Encryption key from environment or None to generate/load from env
        """
        if key is None:
            key = os.getenv('AURUM_ENCRYPTION_KEY')
            if not key:
                # Generate a key if none exists (for development only)
                # In production, this should be set in .env
                key = Fernet.generate_key().decode()
                print(f"⚠️  WARNING: Generated new encryption key. Set AURUM_ENCRYPTION_KEY in .env")
        
        # If key is not a valid Fernet key, derive one from it
        try:
            self.cipher = Fernet(key.encode() if isinstance(key, str) else key)
        except ValueError:
            # Key is not a valid Fernet key, derive one
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=b'aurum_harmony_salt',  # In production, use random salt
                iterations=100000,
            )
            key_bytes = kdf.derive(key.encode() if isinstance(key, str) else key)
            self.cipher = Fernet(base64.urlsafe_b64encode(key_bytes))
    
    def encrypt(self, plaintext: str) -> str:
        """
        Encrypt a string.
        
        Args:
            plaintext: String to encrypt
            
        Returns:
            Encrypted string (base64 encoded)
        """
        if not plaintext:
            return ""
        return self.cipher.encrypt(plaintext.encode('utf-8')).decode('utf-8')
    
    def decrypt(self, ciphertext: str) -> Optional[str]:
        """
        Decrypt a string.
        
        Args:
            ciphertext: Encrypted string (base64 encoded)
            
        Returns:
            Decrypted string or None if decryption fails
        """
        if not ciphertext:
            return None
        try:
            return self.cipher.decrypt(ciphertext.encode('utf-8')).decode('utf-8')
        except Exception:
            return None

# Global instance
_encryption_service: Optional[EncryptionService] = None

def get_encryption_service() -> EncryptionService:
    """Get or create global encryption service instance."""
    global _encryption_service
    if _encryption_service is None:
        _encryption_service = EncryptionService()
    return _encryption_service

