"""
Alpha Vantage Historical Data Fetcher
Free tier available - 5 API calls/minute, 500 calls/day

Alpha Vantage provides free historical data with API key.
Free tier limits: 5 calls/minute, 500 calls/day
"""

from __future__ import annotations

import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import requests
import time
from dataclasses import dataclass
import os

logger = logging.getLogger(__name__)


@dataclass
class HistoricalDataPoint:
    """Historical data point."""
    timestamp: datetime
    open: float
    high: float
    low: float
    close: float
    volume: int
    exchange: str
    symbol: str


class AlphaVantageDataFetcher:
    """
    Alpha Vantage historical data fetcher.
    
    FREE TIER:
    - 5 API calls per minute
    - 500 API calls per day
    - Requires API key (free from alpha-vantage.com)
    
    Note: Alpha Vantage may not have direct Indian index data.
    This is a framework for integration if/when available.
    """
    
    BASE_URL = "https://www.alphavantage.co/query"
    
    # Rate limiting
    CALLS_PER_MINUTE = 5
    CALLS_PER_DAY = 500
    _last_call_time: float = 0.0
    _call_count_today: int = 0
    _call_reset_date: date = None
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize Alpha Vantage data fetcher.
        
        Args:
            api_key: Alpha Vantage API key (get free key from alpha-vantage.com)
        """
        self.api_key = api_key or os.getenv("ALPHA_VANTAGE_API_KEY")
        if not self.api_key:
            logger.warning("Alpha Vantage API key not provided. Set ALPHA_VANTAGE_API_KEY env var.")
        
        self.session = requests.Session()
        self._call_reset_date = datetime.now().date()
        
        if self.api_key:
            logger.info("AlphaVantageDataFetcher initialized (FREE tier: 5 calls/min, 500 calls/day)")
        else:
            logger.warning("AlphaVantageDataFetcher initialized without API key")
    
    def _check_rate_limit(self) -> bool:
        """
        Check if we can make an API call (rate limiting).
        
        Returns:
            True if call is allowed, False otherwise
        """
        now = datetime.now()
        current_date = now.date()
        
        # Reset daily counter if new day
        if current_date != self._call_reset_date:
            self._call_count_today = 0
            self._call_reset_date = current_date
        
        # Check daily limit
        if self._call_count_today >= self.CALLS_PER_DAY:
            logger.warning(f"Daily API call limit reached ({self.CALLS_PER_DAY} calls)")
            return False
        
        # Check per-minute limit
        time_since_last_call = now.timestamp() - self._last_call_time
        if time_since_last_call < (60.0 / self.CALLS_PER_MINUTE):
            wait_time = (60.0 / self.CALLS_PER_MINUTE) - time_since_last_call
            logger.debug(f"Rate limit: waiting {wait_time:.1f} seconds")
            time.sleep(wait_time)
        
        return True
    
    def _make_api_call(self, function: str, symbol: str, **params) -> Optional[Dict[str, Any]]:
        """
        Make API call to Alpha Vantage.
        
        Args:
            function: API function name
            symbol: Symbol name
            **params: Additional parameters
            
        Returns:
            API response data or None
        """
        if not self.api_key:
            logger.warning("Cannot make API call: API key not set")
            return None
        
        if not self._check_rate_limit():
            return None
        
        try:
            params.update({
                "function": function,
                "symbol": symbol,
                "apikey": self.api_key,
                "datatype": "json"
            })
            
            response = self.session.get(self.BASE_URL, params=params, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            # Check for API errors
            if "Error Message" in data:
                logger.error(f"Alpha Vantage API error: {data['Error Message']}")
                return None
            if "Note" in data:
                logger.warning(f"Alpha Vantage API note: {data['Note']}")
                return None
            
            # Update rate limiting
            self._last_call_time = time.time()
            self._call_count_today += 1
            
            return data
            
        except Exception as e:
            logger.error(f"Error making Alpha Vantage API call: {e}", exc_info=True)
            return None
    
    def get_historical_data(
        self,
        symbol: str,
        start_date: datetime,
        end_date: datetime,
        interval: str = "daily"  # daily, weekly, monthly, 1min, 5min, etc.
    ) -> List[HistoricalDataPoint]:
        """
        Fetch historical data from Alpha Vantage.
        
        Note: Alpha Vantage primarily supports US stocks.
        Indian indices may not be directly available.
        This is a framework for future integration.
        
        Args:
            symbol: Symbol name
            start_date: Start date
            end_date: End date
            interval: Data interval (daily, weekly, monthly, etc.)
            
        Returns:
            List of HistoricalDataPoint objects
        """
        try:
            # Map interval to Alpha Vantage function
            if interval in ["daily", "1d", "day"]:
                function = "TIME_SERIES_DAILY"
                time_series_key = "Time Series (Daily)"
            elif interval in ["weekly", "1wk", "week"]:
                function = "TIME_SERIES_WEEKLY"
                time_series_key = "Weekly Time Series"
            elif interval in ["monthly", "1mo", "month"]:
                function = "TIME_SERIES_MONTHLY"
                time_series_key = "Monthly Time Series"
            else:
                logger.warning(f"Unsupported interval: {interval}, using daily")
                function = "TIME_SERIES_DAILY"
                time_series_key = "Time Series (Daily)"
            
            # Note: Alpha Vantage may not support Indian indices directly
            # This would need symbol mapping or alternative data source
            logger.warning(
                f"Alpha Vantage may not support Indian indices directly. "
                f"Symbol {symbol} may need mapping or alternative source."
            )
            
            # Make API call
            data = self._make_api_call(function, symbol)
            if not data:
                return []
            
            # Parse time series data
            time_series = data.get(time_series_key, {})
            if not time_series:
                logger.warning(f"No time series data found for {symbol}")
                return []
            
            # Build data points
            data_points = []
            for date_str, values in time_series.items():
                try:
                    timestamp = datetime.strptime(date_str, "%Y-%m-%d")
                    
                    # Filter by date range
                    if timestamp < start_date or timestamp > end_date:
                        continue
                    
                    data_point = HistoricalDataPoint(
                        timestamp=timestamp,
                        open=float(values.get("1. open", 0)),
                        high=float(values.get("2. high", 0)),
                        low=float(values.get("3. low", 0)),
                        close=float(values.get("4. close", 0)),
                        volume=int(float(values.get("5. volume", 0))),
                        exchange="NSE",  # Would need to determine from symbol
                        symbol=symbol
                    )
                    data_points.append(data_point)
                except Exception as e:
                    logger.debug(f"Error parsing data point for {date_str}: {e}")
                    continue
            
            # Sort by timestamp
            data_points.sort(key=lambda x: x.timestamp)
            
            logger.info(f"Fetched {len(data_points)} data points from Alpha Vantage for {symbol}")
            return data_points
            
        except Exception as e:
            logger.error(f"Error fetching Alpha Vantage data for {symbol}: {e}", exc_info=True)
            return []
    
    def get_current_price(self, symbol: str) -> Optional[float]:
        """
        Get current price from Alpha Vantage.
        
        Args:
            symbol: Symbol name
            
        Returns:
            Current price or None
        """
        try:
            data = self._make_api_call("GLOBAL_QUOTE", symbol)
            if not data:
                return None
            
            quote = data.get("Global Quote", {})
            price = quote.get("05. price")
            
            if price:
                return float(price)
            return None
            
        except Exception as e:
            logger.error(f"Error fetching current price for {symbol}: {e}")
            return None


# Default instance (will be None if no API key)
alpha_vantage_fetcher = AlphaVantageDataFetcher()

__all__ = [
    "AlphaVantageDataFetcher",
    "HistoricalDataPoint",
    "alpha_vantage_fetcher",
]
