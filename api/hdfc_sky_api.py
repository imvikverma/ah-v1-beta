"""
HDFC Sky API Integration

Implements Client ID + OTP + PIN authentication and trading operations.
Based on HDFC Sky API Documentation: https://developer.hdfcsky.com/sky-docs/docs/intro
"""

import os
import requests
import json
import logging
from typing import Dict, Optional, List
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger(__name__)


class HDFCSkyAPI:
    """
    HDFC Sky API Client
    Handles Client ID + OTP + PIN authentication, orders, reports, positions, and quotes
    """
    
    # Base URLs
    BASE_URL = "https://developer.hdfcsky.com"  # Developer portal
    TRADING_API_BASE = "https://api.hdfcsky.com"  # Actual trading API (from real account)
    API_BASE = "https://developer.hdfcsky.com/oapi/v2"  # Developer portal API
    API_BASE_V1 = "https://developer.hdfcsky.com/oapi/v1"  # Keep v1 as fallback
    LOGIN_BASE = "https://developer.hdfcsky.com/oapi/v2"
    
    def __init__(self, api_key: str, api_secret: str, token_id: Optional[str] = None,
                 client_id: Optional[str] = None, email: Optional[str] = None, 
                 mobile: Optional[str] = None, access_token: Optional[str] = None):
        """
        Initialize HDFC Sky API client
        
        Args:
            api_key: API key from HDFC Sky developer portal
            api_secret: API secret from HDFC Sky developer portal
            token_id: Token ID from URL parameters after web login (required for API calls)
            client_id: Client ID (optional, for login)
            email: Email ID (optional, for login)
            mobile: Mobile number (optional, for login)
            access_token: JWT access token from localStorage.accessToken (optional, if from web login)
        """
        self.api_key = api_key
        self.api_secret = api_secret
        self.token_id = token_id  # This is the key! From URL params after login
        self.client_id = client_id
        self.email = email
        self.mobile = mobile
        
        # Session tokens
        # Load access_token from parameter or environment variable
        self.access_token: Optional[str] = access_token or os.getenv("HDFC_SKY_ACCESS_TOKEN")
        self.device_id: Optional[str] = os.getenv("HDFC_SKY_DEVICE_ID", "88c1aec39d454d7ca740160f461e4285")  # Default from your account
        self.session_id: Optional[str] = None
        self.token_expiry: Optional[datetime] = None
        
        # If token_id provided, set expiry (typically 24 hours, adjust as needed)
        if self.token_id:
            self.token_expiry = datetime.now() + timedelta(hours=24)
        
        # If access_token provided, also set expiry (typically 24 hours)
        if self.access_token:
            self.token_expiry = datetime.now() + timedelta(hours=24)
    
    def _get_api_headers(self, include_auth: bool = False, trading_api: bool = False) -> Dict[str, str]:
        """
        Get headers for API endpoints
        
        For Developer Portal APIs:
        - Authorization header contains JWT token directly (NO "Bearer " prefix)
        - Content-Type: application/json
        - Accept: application/json, text/plain, */*
        
        For Trading APIs (api.hdfcsky.com):
        - x-authorization-token header contains JWT token
        - x-device-id header required
        - x-device-type: "web"
        - Origin: https://hdfcsky.com
        - Referer: https://hdfcsky.com/
        """
        import platform
        
        # Get user agent (like the frontend code does)
        user_agent = f"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:145.0) Gecko/20100101 Firefox/145.0"
        
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json, text/plain, */*",
            "User-Agent": user_agent,
        }
        
        if trading_api:
            # Trading API headers (from actual trading account)
            headers["Origin"] = "https://hdfcsky.com"
            headers["Referer"] = "https://hdfcsky.com/"
            if include_auth and self.access_token:
                headers["x-authorization-token"] = self.access_token
            if self.device_id:
                headers["x-device-id"] = self.device_id
            headers["x-device-type"] = "web"
        else:
            # Developer Portal API headers
            if include_auth and self.access_token:
                # Use JWT token directly, no "Bearer " prefix (as seen in successful /oapi/v1/fetch-apps)
                headers["Authorization"] = self.access_token
        
        return headers
    
    def _get_api_params(self, include_auth: bool = False, additional_params: Optional[Dict] = None, 
                       dashboard_mode: bool = False) -> Dict[str, str]:
        """
        Get query parameters for API endpoints (based on frontend code)
        
        Args:
            include_auth: Whether to include auth params
            additional_params: Additional params to add
            dashboard_mode: If True, only use token_id (not api_key) - for dashboard APIs
        """
        params = {}
        
        if include_auth:
            if self.token_id:
                # We have token_id - use it (preferred method)
                if dashboard_mode:
                    # Dashboard APIs: only token_id in params
                    params["token_id"] = self.token_id
                else:
                    # Trading APIs: api_key, token_id, state in params
                    params["api_key"] = self.api_key
                    params["token_id"] = self.token_id
                    # state is optional, skip for now
            elif self.access_token:
                # No token_id, but we have access_token - try with just api_key
                # Some APIs might work with just api_key + Authorization header
                if not dashboard_mode:
                    params["api_key"] = self.api_key
                # Note: token_id might be required for some endpoints
        
        if additional_params:
            params.update(additional_params)
        
        return params
    
    def _get_api_data(self, include_auth: bool = False, additional_data: Optional[Dict] = None,
                     dashboard_mode: bool = False) -> Dict:
        """
        Get request body data for API endpoints (based on frontend code)
        
        Args:
            include_auth: Whether to include auth data
            additional_data: Additional data to add
            dashboard_mode: If True, don't include api_key/token_id in body - for dashboard APIs
        """
        data = {}
        
        if include_auth and self.token_id and not dashboard_mode:
            # Trading APIs: api_key, token_id, state in data
            data["api_key"] = self.api_key
            data["token_id"] = self.token_id
            # state is optional, skip for now
        # Dashboard APIs: only pass additional_data, no auth in body
        
        if additional_data:
            data.update(additional_data)
        
        return data
    
    def send_otp(self, identifier: Optional[str] = None) -> Dict:
        """
        Step 1: Send OTP to registered mobile and email
        
        Args:
            identifier: Client ID, Email, or Mobile (if not provided, uses init params)
            
        Returns:
            Response data indicating OTP sent
        """
        # Try different possible endpoint paths
        # Based on confirmed API: /oapi/v2/ (v2 is the actual version)
        possible_endpoints = [
            f"{self.API_BASE}/auth/login",  # v2 - most likely
            f"{self.API_BASE}/auth/send-otp",
            f"{self.API_BASE}/auth/token",  # For getting JWT token
            f"{self.API_BASE}/login",
            f"{self.API_BASE}/login/send-otp",
            f"{self.API_BASE}/user/login",
            f"{self.API_BASE}/user/send-otp",
            f"{self.API_BASE}/token",  # Direct token endpoint
            f"{self.API_BASE_V1}/auth/login",  # v1 fallback
            f"{self.API_BASE_V1}/auth/send-otp",
            f"{self.API_BASE_V1}/login",
        ]
        
        # Determine identifier
        if identifier:
            # Try to detect type
            if "@" in identifier:
                payload = {"email": identifier}
            elif identifier.isdigit() and len(identifier) == 10:
                payload = {"mobile": identifier}
            else:
                payload = {"client_id": identifier}
        elif self.client_id:
            payload = {"client_id": self.client_id}
        elif self.email:
            payload = {"email": self.email}
        elif self.mobile:
            payload = {"mobile": self.mobile}
        else:
            raise ValueError("Must provide client_id, email, or mobile in init or as parameter")
        
        # Try different header formats
        # Based on network request: uses Authorization header with JWT
        header_formats = [
            # Format 1: API key/secret in body for token generation
            {
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            # Format 2: API key/secret as client_id/client_token in body
            {
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            # Format 3: API key/secret in headers
            {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "X-API-Key": self.api_key,
                "X-API-Secret": self.api_secret
            },
            # Format 4: Query params
            {
                "Content-Type": "application/json",
                "Accept": "application/json"
            }
        ]
        
        last_error = None
        for endpoint in possible_endpoints:
            for idx, header_format in enumerate(header_formats):
                try:
                    headers = header_format.copy()
                    request_payload = payload.copy()
                    
                    # Format 1 & 2: Try with client_id/client_token in body
                    if idx in [0, 1]:
                        request_payload["client_id"] = self.api_key
                        request_payload["client_token"] = self.api_secret
                        # Also try api_key/api_secret
                        if idx == 1:
                            request_payload["api_key"] = self.api_key
                            request_payload["api_secret"] = self.api_secret
                    # Format 4: Query params
                    elif idx == 3:
                        url = f"{endpoint}?api_key={self.api_key}&api_secret={self.api_secret}"
                    else:
                        url = endpoint
                    
                    if idx != 3:
                        url = endpoint
                    
                    response = requests.post(url, headers=headers, json=request_payload, timeout=10)
                    
                    if response.status_code == 200:
                        return response.json()
                    elif response.status_code != 404:
                        # Got a different error, might be the right endpoint but wrong format
                        last_error = f"Status {response.status_code}: {response.text[:200]}"
                except requests.exceptions.RequestException as e:
                    last_error = str(e)
                    continue
        
        # If we get here, none of the endpoints worked
        raise requests.exceptions.HTTPError(
            f"Could not find valid endpoint. Last error: {last_error}. "
            f"Tried endpoints: {', '.join(possible_endpoints)}. "
            f"Please check HDFC Sky API documentation for the correct endpoint."
        )
    
    def login_with_otp(self, otp: str, identifier: Optional[str] = None) -> Dict:
        """
        Step 2: Login with OTP to get session
        
        Args:
            otp: 4-digit OTP sent to mobile and email
            identifier: Client ID, Email, or Mobile (if not provided, uses init params)
            
        Returns:
            Response data with session info (may need PIN validation)
        """
        url = f"{self.LOGIN_BASE}/login/validate-otp"
        headers = self._get_api_headers()
        
        # Determine identifier
        if identifier:
            if "@" in identifier:
                payload = {"email": identifier, "otp": otp}
            elif identifier.isdigit() and len(identifier) == 10:
                payload = {"mobile": identifier, "otp": otp}
            else:
                payload = {"client_id": identifier, "otp": otp}
        elif self.client_id:
            payload = {"client_id": self.client_id, "otp": otp}
        elif self.email:
            payload = {"email": self.email, "otp": otp}
        elif self.mobile:
            payload = {"mobile": self.mobile, "otp": otp}
        else:
            raise ValueError("Must provide client_id, email, or mobile in init or as parameter")
        
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        response.raise_for_status()
        
        result = response.json()
        
        # Store session info if provided
        if "data" in result:
            data = result["data"]
            self.session_id = data.get("session_id")
            # May need PIN validation before getting access token
        
        return result
    
    def validate_pin(self, pin: str) -> Dict:
        """
        Step 3: Validate PIN to get access token
        
        Args:
            pin: 4-digit PIN
            
        Returns:
            Response data with access_token
        """
        if not self.token_id:
            raise ValueError("Need token_id for PIN validation. Get it from URL params after web login.")
        
        # Dashboard API pattern: /oapi/v1/im/twofa/validate with token_id in query params only
        url = f"{self.API_BASE_V1}/im/twofa/validate"
        headers = self._get_api_headers(include_auth=False)  # No Authorization header for dashboard APIs
        
        # Only token_id in query params (no api_key)
        params = {"token_id": self.token_id}
        
        # PIN goes in request body
        payload = {
            "pin": pin
        }
        
        response = requests.post(url, headers=headers, params=params, json=payload, timeout=10)
        response.raise_for_status()
        
        result = response.json()
        
        if "data" in result:
            data = result["data"]
            self.access_token = data.get("access_token")
            # token_id remains the same
            # Set token expiry (typically 24 hours, adjust as needed)
            self.token_expiry = datetime.now() + timedelta(hours=24)
        
        return result
    
    def is_authenticated(self) -> bool:
        """Check if client is authenticated and token is valid"""
        # Need either token_id (from URL params) or access_token (JWT)
        if not self.token_id and not self.access_token:
            return False
        if self.token_expiry and datetime.now() >= self.token_expiry:
            return False
        return True
    
    # ==================== ORDERS ====================
    
    def place_order(
        self,
        symbol: str,
        exchange: str,
        quantity: int,
        order_type: str = "MARKET",
        price: float = 0,
        transaction_type: str = "BUY",
        product_type: str = "INTRADAY",
        validity: str = "DAY"
    ) -> Dict:
        """
        Place an order
        
        Args:
            symbol: Stock/Index symbol
            exchange: Exchange code (NSE, BSE)
            quantity: Order quantity
            order_type: MARKET, LIMIT, SL, SL-M
            price: Price (required for limit orders)
            transaction_type: BUY, SELL
            product_type: INTRADAY, DELIVERY, MARGIN
            validity: DAY, IOC, GTC
            
        Returns:
            Order response
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Need access_token from trading account.")
        
        # Use trading API (api.hdfcsky.com) for actual orders
        # Based on actual trading account: uses api.hdfcsky.com with x-authorization-token header
        url = f"{self.TRADING_API_BASE}/orders"
        headers = self._get_api_headers(include_auth=True, trading_api=True)
        
        # Trading API payload (adjust based on actual API format)
        payload = {
            "symbol": symbol,
            "exchange": exchange,
            "quantity": quantity,
            "order_type": order_type,
            "price": price,
            "transaction_type": transaction_type,
            "product_type": product_type,
            "validity": validity
        }
        
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        response.raise_for_status()
        return response.json()
    
    def modify_order(
        self,
        order_id: str,
        quantity: Optional[int] = None,
        price: Optional[float] = None,
        order_type: Optional[str] = None
    ) -> Dict:
        """Modify an existing order"""
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Need access_token from trading account.")
        
        # Use trading API
        url = f"{self.TRADING_API_BASE}/orders/{order_id}"
        headers = self._get_api_headers(include_auth=True, trading_api=True)
        
        payload = {}
        if quantity:
            payload["quantity"] = quantity
        if price:
            payload["price"] = price
        if order_type:
            payload["order_type"] = order_type
        
        response = requests.put(url, headers=headers, json=payload, timeout=10)
        response.raise_for_status()
        return response.json()
    
    def cancel_order(self, order_id: str) -> Dict:
        """Cancel an order"""
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Need access_token from trading account.")
        
        # Use trading API
        url = f"{self.TRADING_API_BASE}/orders/{order_id}"
        headers = self._get_api_headers(include_auth=True, trading_api=True)
        
        response = requests.delete(url, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    
    # ==================== REPORTS ====================
    
    def get_order_book(self, order_type: str = "completed") -> Dict:
        """
        Get order book (all orders)
        
        Args:
            order_type: "completed", "pending", "all" (default: "completed")
            
        Returns:
            Orders data
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Need access_token from trading account.")
        
        # Use trading API endpoint found from actual trading account
        # https://api.hdfcsky.com/api/v2/orders?type=completed&client_id=S2239332
        url = f"{self.TRADING_API_BASE}/api/v2/orders"
        headers = self._get_api_headers(include_auth=True, trading_api=True)
        params = {"type": order_type}
        
        # Add client_id if available
        if self.client_id:
            params["client_id"] = self.client_id
        
        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()
        return response.json()
    
    def get_trade_book(self) -> Dict:
        """
        Get trade book (executed trades)
        
        Returns:
            Trades data
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Need access_token from trading account.")
        
        # Use trading API endpoint found from actual trading account
        # https://api.hdfcsky.com/api/v2/trades
        url = f"{self.TRADING_API_BASE}/api/v2/trades"
        headers = self._get_api_headers(include_auth=True, trading_api=True)
        
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    
    # ==================== POSITIONS & HOLDINGS ====================
    
    def get_positions(self, position_type: str = "historical") -> Dict:
        """
        Get current positions from trading API
        
        Args:
            position_type: "historical" or "current" (default: "historical")
            
        Returns:
            Positions data
        """
        if not self.access_token:
            raise ValueError("Not authenticated. Need access_token from trading account.")
        
        # Use trading API endpoint found from actual trading account
        # https://api.hdfcsky.com/api/v2/positions?type=historical
        url = f"{self.TRADING_API_BASE}/api/v2/positions"
        headers = self._get_api_headers(include_auth=True, trading_api=True)
        params = {"type": position_type}
        
        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()
        return response.json()
    
    def get_holdings(self) -> Dict:
        """
        Get holdings (portfolio)
        
        Returns:
            Holdings data
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Need access_token from trading account.")
        
        # Use trading API endpoint found from actual trading account
        # https://api.hdfcsky.com/api/v2/holdings
        url = f"{self.TRADING_API_BASE}/api/v2/holdings"
        headers = self._get_api_headers(include_auth=True, trading_api=True)
        
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        return response.json()
    
    # ==================== QUOTES ====================
    
    def get_quotes(self, symbol: str, exchange: str = "NSE") -> Dict:
        """
        Get quotes for a symbol
        
        Args:
            symbol: Symbol to fetch
            exchange: Exchange code (NSE, BSE)
            
        Returns:
            Quote data
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Need access_token from trading account.")
        
        # Use trading API endpoint found from actual trading account
        # POST https://api.hdfcsky.com/ltp/api/v1/fetchMarketData
        url = f"{self.TRADING_API_BASE}/ltp/api/v1/fetchMarketData"
        headers = self._get_api_headers(include_auth=True, trading_api=True)
        
        # POST request with symbol and exchange in body
        payload = {
            "symbol": symbol,
            "exchange": exchange
        }
        
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        response.raise_for_status()
        return response.json()
    
    def get_funds(self, fund_type: str = "all") -> Dict:
        """
        Get account funds/balance
        
        Args:
            fund_type: "all", "available", "used", etc. (default: "all")
            
        Returns:
            Funds/balance data
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Need access_token from trading account.")
        
        # Use trading API endpoint found from actual trading account
        # https://api.hdfcsky.com/api/v3/funds/view?client_id=S2239332&type=all
        url = f"{self.TRADING_API_BASE}/api/v3/funds/view"
        headers = self._get_api_headers(include_auth=True, trading_api=True)
        params = {"type": fund_type}
        
        # Add client_id if available
        if self.client_id:
            params["client_id"] = self.client_id
        
        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()
        return response.json()
    
    def get_historical_data(
        self, 
        symbol: str, 
        exchange: str = "NSE", 
        chart_type: str = "DAY",
        series_type: str = "EQ",
        start_date: Optional[str] = None,
        end_date: Optional[str] = None
    ) -> Dict:
        """
        Get historical candlestick/price data
        
        Args:
            symbol: Symbol to fetch
            exchange: Exchange code (NSE, BSE)
            chart_type: "DAY", "MINUTE", "WEEK", "MONTH" (default: "DAY")
            series_type: "EQ" (equity), "IDX" (index), "FUT" (futures), "OPT" (options)
            start_date: Start date in YYYY-MM-DD format (default: 30 days ago)
            end_date: End date in YYYY-MM-DD format (default: today)
            
        Returns:
            Historical price data
        """
        if not self.is_authenticated():
            raise ValueError("Not authenticated. Need access_token from trading account.")
        
        # Use trading API endpoint found from actual trading account
        # https://api.hdfcsky.com/charts-api/charts/v1/fetch-candle?symbol=SENSEX&exchange=BSE&chartType=DAY&seriesType=IDX&start=2024-11-20&end=2025-12-08
        url = f"{self.TRADING_API_BASE}/charts-api/charts/v1/fetch-candle"
        headers = self._get_api_headers(include_auth=True, trading_api=True)
        
        # Set default dates if not provided
        if not end_date:
            end_date = datetime.now().strftime("%Y-%m-%d")
        if not start_date:
            start_date = (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d")
        
        params = {
            "symbol": symbol,
            "exchange": exchange,
            "chartType": chart_type,
            "seriesType": series_type,
            "start": start_date,
            "end": end_date
        }
        
        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()
        return response.json()


__all__ = ["HDFCSkyAPI"]
