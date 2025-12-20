"""
Kotak Neo API Implementation

Real-time market data and trading integration for Kotak Neo broker.
Supports live 5-minute candles and historical data fetching.
"""

import requests
import logging
import json
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional, Union
import time
import yfinance as yf  # Fallback for when broker API fails

logger = logging.getLogger(__name__)


class KotakNeoAPI:
    """
    Kotak Neo API client for market data and trading.

    Supports:
    - Live market data (5-min candles)
    - Historical data fetching
    - Real-time quotes
    - Order placement and management
    """

    BASE_URL = "https://api.kotakneo.com"  # Placeholder - update with actual API URL
    TIMEOUT = 30

    def __init__(self, access_token: str, mobile_number: str, client_code: str):
        """
        Initialize Kotak Neo API client.

        Args:
            access_token: Kotak Neo access token
            mobile_number: User's mobile number
            client_code: Kotak Neo client code
        """
        self.access_token = access_token
        self.mobile_number = mobile_number
        self.client_code = client_code
        self.token_expires_at = None
        self.session = requests.Session()

        # Configure session
        self.session.headers.update({
            'User-Agent': 'AurumHarmony/1.0',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': f'Bearer {self.access_token}'
        })

        logger.info("Kotak Neo API client initialized")

    def authenticate(self) -> bool:
        """
        Authenticate with Kotak Neo API.

        Returns:
            True if authentication successful, False otherwise
        """
        try:
            # Kotak Neo authentication flow
            auth_payload = {
                'mobile_number': self.mobile_number,
                'client_code': self.client_code,
                'access_token': self.access_token,
            }

            response = self.session.post(
                f"{self.BASE_URL}/auth/verify",
                json=auth_payload,
                timeout=self.TIMEOUT
            )

            if response.status_code == 200:
                data = response.json()

                # Set token expiration (typically 1 day)
                expires_in = data.get('expires_in', 86400)  # Default 24 hours
                self.token_expires_at = datetime.now() + timedelta(seconds=expires_in)

                logger.info("Kotak Neo authentication successful")
                return True
            else:
                logger.error(f"Kotak Neo authentication failed: {response.status_code} - {response.text}")
                return False

        except Exception as e:
            logger.error(f"Kotak Neo authentication error: {e}")
            return False

    def is_authenticated(self) -> bool:
        """
        Check if client is authenticated and token is valid.

        Returns:
            True if authenticated and token valid, False otherwise
        """
        if not self.access_token or not self.token_expires_at:
            return False

        # Check if token is still valid (with 5 minute buffer)
        return datetime.now() < (self.token_expires_at - timedelta(minutes=5))

    def refresh_authentication(self) -> bool:
        """
        Refresh authentication token.

        Returns:
            True if refresh successful, False otherwise
        """
        try:
            response = self.session.post(
                f"{self.BASE_URL}/auth/refresh",
                json={
                    'mobile_number': self.mobile_number,
                    'client_code': self.client_code
                },
                timeout=self.TIMEOUT
            )

            if response.status_code == 200:
                data = response.json()
                self.access_token = data.get('access_token')

                expires_in = data.get('expires_in', 86400)
                self.token_expires_at = datetime.now() + timedelta(seconds=expires_in)

                self.session.headers.update({
                    'Authorization': f'Bearer {self.access_token}'
                })

                logger.info("Kotak Neo token refresh successful")
                return True
            else:
                logger.error(f"Kotak Neo token refresh failed: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"Kotak Neo token refresh error: {e}")
            return False

    def get_live_candles(self, symbol: str, interval: str = "5MINUTE", count: int = 50) -> List[Dict[str, Any]]:
        """
        Get live 5-minute candles for a symbol.

        Args:
            symbol: Trading symbol (e.g., "NIFTY25JAN24150CE")
            interval: Candle interval ("1MINUTE", "5MINUTE", "15MINUTE", etc.)
            count: Number of candles to fetch

        Returns:
            List of candle data dictionaries
        """
        if not self.is_authenticated():
            if not self.refresh_authentication():
                logger.error("Not authenticated with Kotak Neo")
                return []

        try:
            params = {
                'symbol': symbol,
                'interval': interval,
                'count': count,
                'exchange': 'NSE',
                'client_code': self.client_code
            }

            response = self.session.get(
                f"{self.BASE_URL}/market-data/candles",
                params=params,
                timeout=self.TIMEOUT
            )

            if response.status_code == 200:
                data = response.json()
                candles = data.get('candles', [])

                # Transform to standardized format
                standardized_candles = []
                for candle in candles:
                    standardized_candles.append({
                        'timestamp': datetime.fromtimestamp(candle['timestamp']),
                        'open': float(candle['open']),
                        'high': float(candle['high']),
                        'low': float(candle['low']),
                        'close': float(candle['close']),
                        'volume': int(candle.get('volume', 0)),
                        'symbol': symbol,
                        'exchange': 'NSE'
                    })

                logger.info(f"Fetched {len(standardized_candles)} live candles for {symbol}")
                return standardized_candles
            else:
                logger.error(f"Failed to fetch live candles: {response.status_code} - {response.text}")
                return []

        except Exception as e:
            logger.error(f"Error fetching live candles: {e}")
            return []

    def get_historical_data(self, symbol: str, from_date: datetime, to_date: datetime,
                          interval: str = "DAY") -> List[Dict[str, Any]]:
        """
        Get historical market data.

        Args:
            symbol: Trading symbol
            from_date: Start date
            to_date: End date
            interval: Data interval

        Returns:
            List of historical data points
        """
        if not self.is_authenticated():
            if not self.refresh_authentication():
                logger.error("Not authenticated with Kotak Neo")
                return []

        try:
            params = {
                'symbol': symbol,
                'from_date': from_date.strftime('%Y-%m-%d'),
                'to_date': to_date.strftime('%Y-%m-%d'),
                'interval': interval,
                'exchange': 'NSE',
                'client_code': self.client_code
            }

            response = self.session.get(
                f"{self.BASE_URL}/market-data/historical",
                params=params,
                timeout=self.TIMEOUT
            )

            if response.status_code == 200:
                data = response.json()
                historical_data = data.get('data', [])

                # Transform to standardized format
                standardized_data = []
                for item in historical_data:
                    standardized_data.append({
                        'timestamp': datetime.fromtimestamp(item['timestamp']),
                        'open': float(item['open']),
                        'high': float(item['high']),
                        'low': float(item['low']),
                        'close': float(item['close']),
                        'volume': int(item.get('volume', 0)),
                        'symbol': symbol,
                        'exchange': 'NSE'
                    })

                logger.info(f"Fetched {len(standardized_data)} historical data points for {symbol}")
                return standardized_data
            else:
                logger.error(f"Failed to fetch historical data: {response.status_code} - {response.text}")
                return []

        except Exception as e:
            logger.error(f"Error fetching historical data: {e}")
            return []

    def get_quote(self, symbol: str) -> Optional[Dict[str, Any]]:
        """
        Get real-time quote for a symbol.

        Args:
            symbol: Trading symbol

        Returns:
            Quote data dictionary or None if failed
        """
        if not self.is_authenticated():
            if not self.refresh_authentication():
                logger.error("Not authenticated with Kotak Neo")
                return None

        try:
            response = self.session.get(
                f"{self.BASE_URL}/market-data/quote",
                params={'symbol': symbol, 'exchange': 'NSE'},
                timeout=self.TIMEOUT
            )

            if response.status_code == 200:
                data = response.json()
                quote = data.get('quote', {})

                return {
                    'symbol': symbol,
                    'price': float(quote.get('last_price', 0)),
                    'change': float(quote.get('change', 0)),
                    'change_percent': float(quote.get('change_percent', 0)),
                    'volume': int(quote.get('volume', 0)),
                    'timestamp': datetime.now(),
                    'exchange': 'NSE'
                }
            else:
                logger.error(f"Failed to get quote: {response.status_code} - {response.text}")
                return None

        except Exception as e:
            logger.error(f"Error getting quote: {e}")
            return None

    def get_market_status(self) -> Dict[str, Any]:
        """
        Get current market status (open/closed/holidays).

        Returns:
            Market status information
        """
        try:
            response = self.session.get(
                f"{self.BASE_URL}/market-data/status",
                timeout=self.TIMEOUT
            )

            if response.status_code == 200:
                data = response.json()
                return {
                    'market_open': data.get('market_open', False),
                    'next_opening_time': data.get('next_opening_time'),
                    'last_trading_day': data.get('last_trading_day'),
                    'holidays': data.get('holidays', []),
                    'status': data.get('status', 'unknown')
                }
            else:
                return {
                    'market_open': False,
                    'status': 'error',
                    'error': f'HTTP {response.status_code}'
                }

        except Exception as e:
            logger.error(f"Error getting market status: {e}")
            return {
                'market_open': False,
                'status': 'error',
                'error': str(e)
            }

    @staticmethod
    def get_yfinance_fallback(symbol: str, start_date: datetime, end_date: datetime,
                            interval: str = "1d") -> List[Dict[str, Any]]:
        """
        Fallback method using yfinance when broker API fails.

        Args:
            symbol: Trading symbol (will be converted to yfinance format)
            start_date: Start date
            end_date: End date
            interval: Data interval ("1d", "1h", "5m", etc.)

        Returns:
            List of standardized data points
        """
        try:
            # Convert symbol to yfinance format
            yf_symbol = symbol
            if 'NIFTY' in symbol and 'CE' in symbol or 'PE' in symbol:
                # For options, use NIFTY index
                yf_symbol = '^NSEI'
            elif 'BANKNIFTY' in symbol:
                yf_symbol = '^NSEBANK'
            elif 'SENSEX' in symbol:
                yf_symbol = '^BSESN'
            elif symbol in ['NIFTY', 'NIFTY50']:
                yf_symbol = '^NSEI'
            elif symbol == 'BANKNIFTY':
                yf_symbol = '^NSEBANK'
            elif symbol == 'SENSEX':
                yf_symbol = '^BSESN'

            # Download data from yfinance
            data = yf.download(
                yf_symbol,
                start=start_date,
                end=end_date,
                interval=interval,
                progress=False
            )

            if data.empty:
                logger.warning(f"No data found for {symbol} via yfinance")
                return []

            # Convert to standardized format
            standardized_data = []
            for index, row in data.iterrows():
                standardized_data.append({
                    'timestamp': index.to_pydatetime(),
                    'open': float(row['Open']) if not pd.isna(row['Open']) else 0.0,
                    'high': float(row['High']) if not pd.isna(row['High']) else 0.0,
                    'low': float(row['Low']) if not pd.isna(row['Low']) else 0.0,
                    'close': float(row['Close']) if not pd.isna(row['Close']) else 0.0,
                    'volume': int(row['Volume']) if not pd.isna(row['Volume']) else 0,
                    'symbol': symbol,
                    'exchange': 'NSE',
                    'source': 'yfinance_fallback'
                })

            logger.info(f"Fetched {len(standardized_data)} data points via yfinance fallback for {symbol}")
            return standardized_data

        except Exception as e:
            logger.error(f"yfinance fallback failed for {symbol}: {e}")
            return []

    def get_live_5min_candles(self, symbol: str, count: int = 50) -> List[Dict[str, Any]]:
        """
        Get live 5-minute candles - specific method for the orchestrator.

        Args:
            symbol: Trading symbol
            count: Number of candles to fetch

        Returns:
            List of 5-minute candle data
        """
        return self.get_live_candles(symbol, interval="5MINUTE", count=count)
