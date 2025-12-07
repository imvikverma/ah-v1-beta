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
    
    # Additional user profile fields
    date_of_birth = Column(Date, nullable=True)  # Used for birthday fee waivers
    anniversary = Column(Date, nullable=True)  # Used for anniversary fee discounts
    initial_capital = Column(Float, default=10000.0, nullable=False)
    max_trades_per_index = Column(Text, nullable=True)  # JSON string: {"NIFTY50": 50, "BANKNIFTY": 30}
    max_accounts_allowed = Column(Integer, default=1, nullable=False)
    
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
            'user_code': self.user_code,
            'is_admin': self.is_admin,
            'is_active': self.is_active,
            'date_of_birth': self.date_of_birth.isoformat() if self.date_of_birth else None,
            'anniversary': self.anniversary.isoformat() if self.anniversary else None,
            'initial_capital': self.initial_capital,
            'max_trades_per_index': max_trades,
            'max_accounts_allowed': self.max_accounts_allowed,
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

