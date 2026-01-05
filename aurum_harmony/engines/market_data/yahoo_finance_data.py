"""
Yahoo Finance Historical Data Fetcher
Free historical data for NIFTY50, BANKNIFTY, SENSEX

Yahoo Finance is FREE and provides extensive historical data.
No API key required for basic usage.
"""

from __future__ import annotations

import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import requests
from dataclasses import dataclass

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


class YahooFinanceDataFetcher:
    """
    Yahoo Finance historical data fetcher.
    
    FREE - No API key required.
    Provides extensive historical data for indices.
    """
    
    # Yahoo Finance symbol mapping for Indian indices
    SYMBOL_MAP = {
        "NIFTY50": "^NSEI",  # NSE NIFTY 50
        "NIFTY": "^NSEI",
        "BANKNIFTY": "^NSEBANK",  # NSE BANK NIFTY
        "SENSEX": "^BSESN",  # BSE SENSEX
    }
    
    BASE_URL = "https://query1.finance.yahoo.com/v8/finance/chart"
    
    def __init__(self):
        """Initialize Yahoo Finance data fetcher."""
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })
        logger.info("YahooFinanceDataFetcher initialized (FREE - no API key required)")
    
    def get_historical_data(
        self,
        symbol: str,
        start_date: datetime,
        end_date: datetime,
        interval: str = "1d"  # 1d, 1wk, 1mo, 1h, 5m, etc.
    ) -> List[HistoricalDataPoint]:
        """
        Fetch historical data from Yahoo Finance.
        
        Args:
            symbol: Symbol name (NIFTY50, BANKNIFTY, SENSEX)
            start_date: Start date
            end_date: End date
            interval: Data interval (1d, 1wk, 1mo, 1h, 5m, etc.)
            
        Returns:
            List of HistoricalDataPoint objects
        """
        try:
            # Map symbol to Yahoo Finance symbol
            yahoo_symbol = self.SYMBOL_MAP.get(symbol.upper())
            if not yahoo_symbol:
                logger.warning(f"Symbol {symbol} not mapped for Yahoo Finance")
                return []
            
            # Convert dates to timestamps
            start_timestamp = int(start_date.timestamp())
            end_timestamp = int(end_date.timestamp())
            
            # Build URL
            url = f"{self.BASE_URL}/{yahoo_symbol}"
            params = {
                "period1": start_timestamp,
                "period2": end_timestamp,
                "interval": interval,
                "events": "history",
                "includeAdjustedClose": "true"
            }
            
            # Fetch data
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            # Parse response
            result = data.get("chart", {}).get("result", [])
            if not result:
                logger.warning(f"No data returned for {symbol}")
                return []
            
            chart_data = result[0]
            timestamps = chart_data.get("timestamp", [])
            indicators = chart_data.get("indicators", {})
            quote = indicators.get("quote", [{}])[0]
            
            opens = quote.get("open", [])
            highs = quote.get("high", [])
            lows = quote.get("low", [])
            closes = quote.get("close", [])
            volumes = quote.get("volume", [])
            
            # Build data points
            data_points = []
            for i in range(len(timestamps)):
                if opens[i] is None or closes[i] is None:
                    continue
                
                timestamp = datetime.fromtimestamp(timestamps[i])
                data_point = HistoricalDataPoint(
                    timestamp=timestamp,
                    open=float(opens[i]),
                    high=float(highs[i]) if highs[i] is not None else float(opens[i]),
                    low=float(lows[i]) if lows[i] is not None else float(opens[i]),
                    close=float(closes[i]),
                    volume=int(volumes[i]) if volumes[i] is not None else 0,
                    exchange="NSE" if "NSE" in yahoo_symbol else "BSE",
                    symbol=symbol
                )
                data_points.append(data_point)
            
            logger.info(f"Fetched {len(data_points)} data points from Yahoo Finance for {symbol}")
            return data_points
            
        except Exception as e:
            logger.error(f"Error fetching Yahoo Finance data for {symbol}: {e}", exc_info=True)
            return []
    
    def get_current_price(self, symbol: str) -> Optional[float]:
        """
        Get current price from Yahoo Finance.
        
        Args:
            symbol: Symbol name
            
        Returns:
            Current price or None
        """
        try:
            end_date = datetime.now()
            start_date = end_date - timedelta(days=1)
            
            data = self.get_historical_data(symbol, start_date, end_date, interval="1d")
            if data:
                return data[-1].close
            return None
        except Exception as e:
            logger.error(f"Error fetching current price for {symbol}: {e}")
            return None


# Default instance
yahoo_finance_fetcher = YahooFinanceDataFetcher()

__all__ = [
    "YahooFinanceDataFetcher",
    "HistoricalDataPoint",
    "yahoo_finance_fetcher",
]
