"""
Database models for AurumHarmony.
"""

from datetime import datetime, date
from .db import db
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Float, Date, JSON
from sqlalchemy.orm import relationship
import json

class User(db.Model):
    """
    User model for authentication and user management.
    """
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20), unique=True, nullable=True, index=True)
    password_hash = Column(String(255), nullable=False)
    user_code = Column(String(50), unique=True, nullable=False, index=True)
    is_admin = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Signup improvements fields
    username = Column(String(100), nullable=True, index=True)  # Display name
    profile_picture_url = Column(String(500), nullable=True)  # Profile picture URL
    email_verified = Column(Boolean, default=False, nullable=False)  # Email verification status
    email_verification_token = Column(String(255), nullable=True)  # Email verification token
    terms_accepted = Column(Boolean, default=False, nullable=False)  # Terms & Conditions acceptance
    terms_accepted_at = Column(DateTime, nullable=True)  # When terms were accepted
    
    # Additional user profile fields
    date_of_birth = Column(Date, nullable=True)  # Used for birthday fee waivers
    anniversary = Column(Date, nullable=True)  # Used for anniversary fee discounts
    initial_capital = Column(Float, default=10000.0, nullable=False)
    max_trades_per_index = Column(Text, nullable=True)  # JSON string: {"NIFTY50": 50, "BANKNIFTY": 30}
    max_accounts_allowed = Column(Integer, default=1, nullable=False)
    
    # Savings account & UPI fields (for onboarding)
    savings_account_number = Column(String(50), nullable=True)
    savings_account_ifsc = Column(String(20), nullable=True)
    savings_account_holder_name = Column(String(100), nullable=True)
    upi_id = Column(String(100), nullable=True)  # UPI ID (e.g., yourname@upi)
    upi_verified = Column(Boolean, default=False, nullable=False)
    upi_verified_at = Column(DateTime, nullable=True)
    
    # KYC verification
    is_kyc_verified = Column(Boolean, default=False, nullable=False)
    kyc_verification_id = Column(String(100), nullable=True)  # DigiLocker verification ID
    kyc_verified_at = Column(DateTime, nullable=True)
    
    # High-level user type & flags (used for onboarding / admin / test flows)
    user_type = Column(String(20), default='new', nullable=False)  # e.g. 'new', 'existing', 'admin', 'test'
    is_test = Column(Boolean, default=False, nullable=False)
    internal_capital = Column(Float, default=0.0, nullable=False)  # Internal ledger capital
    
    # Capital & Settlement tracking
    accumulated_profit = Column(Float, default=0.0, nullable=False)  # Profit since last increment
    capital_allocation = Column(JSON, nullable=True)  # Per-index/broker allocation matrix
    last_increment_date = Column(DateTime, nullable=True)  # When capital was last incremented
    brokerage_fees_tracked = Column(Float, default=0.0, nullable=False)  # Total brokerage fees (for reporting)
    
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    broker_credentials = relationship('BrokerCredential', back_populates='user', cascade='all, delete-orphan')
    sessions = relationship('Session', back_populates='user', cascade='all, delete-orphan')
    
    def to_dict(self, include_sensitive=False):
        """Convert user to dictionary, optionally including sensitive data."""
        # Parse max_trades_per_index JSON if it exists
        max_trades = {}
        if self.max_trades_per_index:
            try:
                max_trades = json.loads(self.max_trades_per_index)
            except (json.JSONDecodeError, TypeError):
                max_trades = {}
        
        data = {
            'id': self.id,
            'email': self.email,
            'phone': self.phone,
            'username': getattr(self, 'username', None),
            'profile_picture_url': getattr(self, 'profile_picture_url', None),
            'email_verified': getattr(self, 'email_verified', False),
            'user_code': self.user_code,
            'is_admin': self.is_admin,
            'is_active': self.is_active,
            'force_password_change': getattr(self, 'force_password_change', False),
            'date_of_birth': self.date_of_birth.isoformat() if self.date_of_birth else None,
            'anniversary': self.anniversary.isoformat() if self.anniversary else None,
            'initial_capital': self.initial_capital,
            'max_trades_per_index': max_trades,
            'max_accounts_allowed': self.max_accounts_allowed,
            'savings_account_number': getattr(self, 'savings_account_number', None),
            'savings_account_ifsc': getattr(self, 'savings_account_ifsc', None),
            'savings_account_holder_name': getattr(self, 'savings_account_holder_name', None),
            'upi_id': getattr(self, 'upi_id', None),
            'upi_verified': getattr(self, 'upi_verified', False),
            'upi_verified_at': getattr(self, 'upi_verified_at').isoformat() if getattr(self, 'upi_verified_at', None) else None,
            'is_kyc_verified': getattr(self, 'is_kyc_verified', False),
            'kyc_verification_id': getattr(self, 'kyc_verification_id', None),
            'kyc_verified_at': getattr(self, 'kyc_verified_at').isoformat() if getattr(self, 'kyc_verified_at', None) else None,
            'user_type': getattr(self, 'user_type', 'new'),
            'is_test': getattr(self, 'is_test', False),
            'internal_capital': getattr(self, 'internal_capital', 0.0),
            'accumulated_profit': getattr(self, 'accumulated_profit', 0.0),
            'capital_allocation': getattr(self, 'capital_allocation', None),
            'last_increment_date': getattr(self, 'last_increment_date').isoformat() if getattr(self, 'last_increment_date', None) else None,
            'brokerage_fees_tracked': getattr(self, 'brokerage_fees_tracked', 0.0),
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
        if include_sensitive:
            data['password_hash'] = self.password_hash
        return data
    
    def __repr__(self):
        return f'<User {self.user_code} ({self.email})>'


class BrokerCredential(db.Model):
    """
    Encrypted broker API credentials per user.
    """
    __tablename__ = 'broker_credentials'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    broker_name = Column(String(50), nullable=False, index=True)  # HDFC_SKY, KOTAK_NEO, etc.
    
    # Encrypted fields
    api_key = Column(Text, nullable=True)  # Encrypted
    api_secret = Column(Text, nullable=True)  # Encrypted
    token_id = Column(Text, nullable=True)  # Encrypted (for HDFC Sky)
    access_token = Column(Text, nullable=True)  # Encrypted
    refresh_token = Column(Text, nullable=True)  # Encrypted
    
    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    expires_at = Column(DateTime, nullable=True)
    last_validated = Column(DateTime, nullable=True)
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship('User', back_populates='broker_credentials')
    
    def to_dict(self, include_credentials=False):
        """Convert to dictionary, optionally including decrypted credentials."""
        data = {
            'id': self.id,
            'user_id': self.user_id,
            'broker_name': self.broker_name,
            'is_active': self.is_active,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'last_validated': self.last_validated.isoformat() if self.last_validated else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
        if include_credentials:
            # Note: In production, decrypt here using encryption service
            data['api_key'] = self.api_key
            data['api_secret'] = self.api_secret
            data['token_id'] = self.token_id
            data['access_token'] = self.access_token
            data['refresh_token'] = self.refresh_token
        return data
    
    def __repr__(self):
        return f'<BrokerCredential {self.broker_name} for User {self.user_id}>'


class Session(db.Model):
    """
    User session tokens for authentication.
    """
    __tablename__ = 'sessions'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    session_token = Column(String(255), unique=True, nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_accessed = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship('User', back_populates='sessions')
    
    def is_expired(self):
        """Check if session has expired."""
        return datetime.utcnow() > self.expires_at
    
    def to_dict(self):
        """Convert session to dictionary."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'session_token': self.session_token,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_accessed': self.last_accessed.isoformat() if self.last_accessed else None,
        }
    
    def __repr__(self):
        return f'<Session {self.session_token[:10]}... for User {self.user_id}>'


class KYCDocument(db.Model):
    """
    KYC documents fetched from DigiLocker.
    """
    __tablename__ = 'kyc_documents'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    document_type = Column(String(50), nullable=False)  # AADHAAR, PAN, etc.
    document_number = Column(String(100), nullable=True)  # Masked: XXXX-XXXX-1234
    document_url = Column(Text, nullable=True)  # Encrypted storage URL
    verified = Column(Boolean, default=False, nullable=False)
    verification_date = Column(DateTime, nullable=True)
    digilocker_doc_uri = Column(String(255), nullable=True)  # DigiLocker reference
    aadhaar_last4 = Column(String(4), nullable=True)  # Last 4 digits of Aadhaar
    pan_number = Column(String(10), nullable=True)  # PAN number
    full_name = Column(String(200), nullable=True)  # Name from Aadhaar
    date_of_birth = Column(Date, nullable=True)  # DOB from Aadhaar
    address = Column(Text, nullable=True)  # Address from Aadhaar
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship('User', backref='kyc_documents')
    
    def to_dict(self):
        """Convert to dictionary."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'document_type': self.document_type,
            'document_number': self.document_number,
            'verified': self.verified,
            'verification_date': self.verification_date.isoformat() if self.verification_date else None,
            'aadhaar_last4': self.aadhaar_last4,
            'pan_number': self.pan_number,
            'full_name': self.full_name,
            'date_of_birth': self.date_of_birth.isoformat() if self.date_of_birth else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
    
    def __repr__(self):
        return f'<KYCDocument {self.document_type} for User {self.user_id}>'


class ProfitTracking(db.Model):
    """
    Profit tracking for settlement and capital increment calculations.
    """
    __tablename__ = 'profit_tracking'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    period_start = Column(DateTime, nullable=False)  # Start of tracking period
    gross_profit = Column(Float, nullable=False)  # Gross profit (after broker auto-deductions)
    brokerage_fees = Column(Float, default=0.0, nullable=False)  # Brokerage fees (tracked for reporting)
    loss_buffer = Column(Float, default=0.0, nullable=False)  # Loss/latency buffer (1% if losses)
    platform_fee = Column(Float, nullable=False)  # Platform fee (30% → ZenithPulse)
    tax_locked = Column(Float, nullable=False)  # Tax locked (39% → Savings)
    net_to_savings = Column(Float, nullable=False)  # Net profit to savings (after rounding)
    rounding_buffer = Column(Float, default=0.0, nullable=False)  # Rounding buffer (stays in demat)
    accumulated_profit = Column(Float, default=0.0, nullable=False)  # Accumulated profit for increment check
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship('User', backref='profit_tracking')
    
    def to_dict(self):
        """Convert to dictionary."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'period_start': self.period_start.isoformat() if self.period_start else None,
            'gross_profit': self.gross_profit,
            'brokerage_fees': self.brokerage_fees,
            'loss_buffer': self.loss_buffer,
            'platform_fee': self.platform_fee,
            'tax_locked': self.tax_locked,
            'net_to_savings': self.net_to_savings,
            'rounding_buffer': self.rounding_buffer,
            'accumulated_profit': self.accumulated_profit,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
    
    def __repr__(self):
        return f'<ProfitTracking for User {self.user_id} - Gross: ₹{self.gross_profit:,.2f}>'
