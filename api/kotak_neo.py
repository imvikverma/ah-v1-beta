"""
Kotak Neo API Integration
Implements TOTP-based authentication and trading operations
Based on Kotak Neo API Documentation
"""

import os
import requests
import json
from typing import Dict, Optional, List
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()


class KotakNeoAPI:
    """
    Kotak Neo API Client
    Handles authentication, orders, reports, positions, and quotes
    """
    
    # Base URLs
    LOGIN_BASE_URL = "https://mis.kotaksecurities.com"
    API_HEADER_KEY = "neo-fin-key"
    API_HEADER_VALUE = "neotradeapi"
    
    def __init__(self, access_token: str, mobile_number: str, client_code: str):
        """
        Initialize Kotak Neo API client
        
        Args:
            access_token: API access token from NEO App → Invest → Trade API
            mobile_number: Mobile number in format +91XXXXXXXXXX
            client_code: Client code (UCC)
        """
        self.access_token = access_token
        self.mobile_number = mobile_number
        self.client_code = client_code
        
        # Session tokens (set after login)
        self.view_token: Optional[str] = None
        self.view_sid: Optional[str] = None
        self.trade_token: Optional[str] = None
        self.trade_sid: Optional[str] = None
        self.base_url: Optional[str] = None
        self.token_expiry: Optional[datetime] = None
        
    def _get_login_headers(self, include_auth: bool = False, include_sid: bool = False) -> Dict[str, str]:
        """Get headers for login endpoints"""
        headers = {
            "Authorization": self.access_token,
            self.API_HEADER_KEY: self.API_HEADER_VALUE,
            "Content-Type": "application/json"
        }
        if include_auth and self.view_token:
            headers["Auth"] = self.view_token
        if include_sid and self.view_sid:
            headers["Sid"] = self.view_sid
        return headers
    
    def _get_api_headers(self) -> Dict[str, str]:
        """Get headers for API endpoints (after login)"""
        if not self.trade_token or not self.trade_sid:
            raise ValueError("Not authenticated. Please login first.")
        
        return {
            "Auth": self.trade_token,
            "Sid": self.trade_sid,
            self.API_HEADER_KEY: self.API_HEADER_VALUE,
            "Content-Type": "application/x-www-form-urlencoded"
        }
    
    def login_with_totp(self, totp: str) -> Dict:
        """
        Step 1: Login with TOTP to get view token and sid
        
        Args:
            totp: 6-digit TOTP from authenticator app
            
        Returns:
            Response data with view_token and view_sid
        """
        url = f"{self.LOGIN_BASE_URL}/login/1.0/tradeApiLogin"
        headers = self._get_login_headers()
        
        payload = {
            "mobileNumber": self.mobile_number,
            "ucc": self.client_code,
            "totp": totp
        }
        
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        
        data = response.json()
        if "data" in data:
            self.view_token = data["data"].get("token")
            self.view_sid = data["data"].get("sid")
            return data["data"]
        else:
            raise ValueError(f"Login failed: {data}")
    
    def validate_mpin(self, mpin: str) -> Dict:
        """
        Step 2: Validate MPIN to get trade token, sid, and baseUrl
        
        Args:
            mpin: 6-digit MPIN
            
        Returns:
            Response data with trade_token, trade_sid, and base_url
        """
        if not self.view_token or not self.view_sid:
            raise ValueError("Please complete TOTP login first.")
        
        url = f"{self.LOGIN_BASE_URL}/login/1.0/tradeApiValidate"
        headers = self._get_login_headers(include_auth=True, include_sid=True)
        
        payload = {
            "mpin": mpin
        }
        
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        
        data = response.json()
        if "data" in data:
            self.trade_token = data["data"].get("token")
            self.trade_sid = data["data"].get("sid")
            self.base_url = data["data"].get("baseUrl")
            # Set token expiry (typically 24 hours, adjust as needed)
            self.token_expiry = datetime.now() + timedelta(hours=24)
            return data["data"]
        else:
            raise ValueError(f"MPIN validation failed: {data}")
    
    def is_authenticated(self) -> bool:
        """Check if client is authenticated and token is valid"""
        if not self.trade_token or not self.trade_sid or not self.base_url:
            return False
        if self.token_expiry and datetime.now() >= self.token_expiry:
            return False
        return True
    
    # ==================== ORDERS ====================
    
    def place_order(self, symbol: str, exchange: str, quantity: int, 
                   order_type: str = "MKT", price: float = 0, 
                   transaction_type: str = "B", product_type: str = "CNC",
                   validity: str = "DAY") -> Dict:
        """
        Place an order
        
        Args:
            symbol: Stock symbol (e.g., "RELIANCE-EQ")
            exchange: Exchange code (e.g., "nse_cm")
            quantity: Order quantity
            order_type: Order type - "MKT" (market), "LMT" (limit), etc.
            price: Price (required for limit orders)
            transaction_type: "B" (buy) or "S" (sell)
            product_type: "CNC" (cash), "MIS" (intraday), "NRML" (normal)
            validity: "DAY" (day), "IOC" (immediate or cancel), "GTC" (good till cancel)
            
        Returns:
            Order response
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/quick/order/rule/ms/place"
        headers = self._get_api_headers()
        
        j_data = {
            "am": "NO",  # After market order
            "dq": "0",   # Disclosed quantity
            "es": exchange,  # Exchange segment
            "mp": "0",   # Market protection
            "pc": product_type,  # Product code
            "pf": "N",   # Price format
            "pr": str(price) if price > 0 else "0",  # Price
            "pt": order_type,  # Price type
            "qt": str(quantity),  # Quantity
            "rt": validity,  # Retention type
            "tp": "0",   # Trigger price
            "ts": f"{symbol}-EQ",  # Trading symbol
            "tt": transaction_type  # Transaction type
        }
        
        # Form-encoded with jData as JSON string
        data = {"jData": json.dumps(j_data)}
        
        response = requests.post(url, headers=headers, data=data)
        response.raise_for_status()
        return response.json()
    
    def modify_order(self, order_no: str, quantity: Optional[int] = None,
                    price: Optional[float] = None, order_type: Optional[str] = None) -> Dict:
        """
        Modify an existing order
        
        Args:
            order_no: Order number
            quantity: New quantity (optional)
            price: New price (optional)
            order_type: New order type (optional)
            
        Returns:
            Modification response
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/quick/order/vr/modify"
        headers = self._get_api_headers()
        
        j_data = {"no": order_no, "am": "NO"}
        if quantity:
            j_data["qt"] = str(quantity)
        if price:
            j_data["pr"] = str(price)
        if order_type:
            j_data["pt"] = order_type
        
        data = {"jData": json.dumps(j_data)}
        
        response = requests.post(url, headers=headers, data=data)
        response.raise_for_status()
        return response.json()
    
    def cancel_order(self, order_no: str) -> Dict:
        """
        Cancel an order
        
        Args:
            order_no: Order number to cancel
            
        Returns:
            Cancellation response
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/quick/order/cancel"
        headers = self._get_api_headers()
        
        j_data = {"on": order_no, "am": "NO"}
        data = {"jData": json.dumps(j_data)}
        
        response = requests.post(url, headers=headers, data=data)
        response.raise_for_status()
        return response.json()
    
    def exit_cover_order(self, order_no: str) -> Dict:
        """Exit a cover order"""
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/quick/order/co/exit"
        headers = self._get_api_headers()
        
        j_data = {"on": order_no, "am": "NO"}
        data = {"jData": json.dumps(j_data)}
        
        response = requests.post(url, headers=headers, data=data)
        response.raise_for_status()
        return response.json()
    
    def exit_bracket_order(self, order_no: str) -> Dict:
        """Exit a bracket order"""
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/quick/order/bo/exit"
        headers = self._get_api_headers()
        
        j_data = {"on": order_no, "am": "NO"}
        data = {"jData": json.dumps(j_data)}
        
        response = requests.post(url, headers=headers, data=data)
        response.raise_for_status()
        return response.json()
    
    # ==================== REPORTS ====================
    
    def get_order_book(self) -> Dict:
        """Get order book (all orders)"""
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/quick/user/orders"
        headers = self._get_api_headers()
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    
    def get_order_history(self, order_no: str) -> Dict:
        """
        Get order history for a specific order
        
        Args:
            order_no: Order number
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/quick/order/history"
        headers = self._get_api_headers()
        
        j_data = {"nOrdNo": order_no}
        data = {"jData": json.dumps(j_data)}
        
        response = requests.post(url, headers=headers, data=data)
        response.raise_for_status()
        return response.json()
    
    def get_trade_book(self) -> Dict:
        """Get trade book (executed trades)"""
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/quick/user/trades"
        headers = self._get_api_headers()
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    
    # ==================== POSITIONS & HOLDINGS ====================
    
    def get_positions(self) -> Dict:
        """Get current positions"""
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/quick/user/positions"
        headers = self._get_api_headers()
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    
    def get_holdings(self) -> Dict:
        """Get holdings (portfolio)"""
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/portfolio/v1/holdings"
        headers = self._get_api_headers()
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    
    # ==================== QUOTES ====================
    
    def get_quotes(self, exchange: str, symbol_code: str) -> Dict:
        """
        Get quotes for a symbol
        
        Args:
            exchange: Exchange code (e.g., "nse_cm")
            symbol_code: Symbol code (e.g., "26000" for NIFTY)
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Please login first.")
        
        url = f"{self.base_url}/script-details/1.0/quotes/neosymbol/{exchange}|{symbol_code}/all"
        # Quotes endpoint uses Authorization only, not Auth/Sid
        headers = {
            "Authorization": self.access_token,
            "Content-Type": "application/json"
        }
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    
    # ==================== INSTRUMENTS ====================
    
    def get_scrip_master_paths(self) -> Dict:
        """Get scrip master file paths"""
        if not self.base_url:
            raise ValueError("Please complete login first.")
        
        url = f"{self.base_url}/script-details/1.0/masterscrip/file-paths"
        # Uses Authorization only
        headers = {
            "Authorization": self.access_token,
            "Content-Type": "application/json"
        }
        
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()


# Convenience function for backward compatibility
def get_access_token(request_token: str) -> requests.Response:
    """
    Legacy function - Kotak Neo doesn't use request tokens
    This is kept for compatibility but should not be used
    """
    raise NotImplementedError(
        "Kotak Neo uses TOTP-based authentication, not request tokens. "
        "Use KotakNeoAPI class with login_with_totp() and validate_mpin() methods."
    )
