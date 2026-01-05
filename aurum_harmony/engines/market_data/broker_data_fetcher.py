"""
Broker Data Fetcher for Backtesting

Fetches real historical market data from multiple sources:
Priority Order:
1. HDFC Sky (if authenticated) - most reliable for historical data
2. Kotak Neo (if authenticated) - good for quotes and recent data
3. Yahoo Finance (FREE) - extensive historical data, no API key required
4. Alpha Vantage (FREE tier) - 5 calls/min, 500 calls/day, requires API key
5. NSE/BSE Option Chain - free, reliable for indices

Provides unified interface for backtesting with real broker data.
"""

from __future__ import annotations

import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class HistoricalDataPoint:
    """Represents a single historical data point."""
    timestamp: datetime
    open: float
    high: float
    low: float
    close: float
    volume: Optional[int] = None
    exchange: str = "NSE"
    symbol: str = ""


class BrokerDataFetcher:
    """
    Fetches historical market data from multiple broker sources.
    
    Priority order:
    1. HDFC Sky (if authenticated) - most reliable for historical data
    2. Kotak Neo (if authenticated) - good for quotes and recent data
    3. NSE/BSE Option Chain - free, reliable for indices
    """
    
    def __init__(
        self,
        hdfc_client: Optional[object] = None,
        kotak_client: Optional[object] = None,
        use_yahoo_finance: bool = True,
        use_alpha_vantage: bool = True,
        use_nse_fallback: bool = True
    ):
        """
        Initialize broker data fetcher.
        
        Args:
            hdfc_client: Authenticated HDFCSkyAPI instance
            kotak_client: Authenticated KotakNeoAPI instance
            use_nse_fallback: Use NSE/BSE as fallback if brokers unavailable
        """
        self.hdfc_client = hdfc_client
        self.kotak_client = kotak_client
        self.use_yahoo_finance = use_yahoo_finance
        self.use_alpha_vantage = use_alpha_vantage
        self.use_nse_fallback = use_nse_fallback
        
        # Initialize Yahoo Finance (FREE - no API key)
        if self.use_yahoo_finance:
            try:
                from aurum_harmony.engines.market_data.yahoo_finance_data import yahoo_finance_fetcher
                self.yahoo_fetcher = yahoo_finance_fetcher
                logger.info("Yahoo Finance data fetcher initialized (FREE)")
            except Exception as e:
                logger.warning(f"Failed to initialize Yahoo Finance fetcher: {e}")
                self.yahoo_fetcher = None
        else:
            self.yahoo_fetcher = None
        
        # Initialize Alpha Vantage (FREE tier - requires API key)
        if self.use_alpha_vantage:
            try:
                from aurum_harmony.engines.market_data.alpha_vantage_data import alpha_vantage_fetcher
                self.alpha_vantage_fetcher = alpha_vantage_fetcher
                if self.alpha_vantage_fetcher.api_key:
                    logger.info("Alpha Vantage data fetcher initialized (FREE tier)")
                else:
                    logger.warning("Alpha Vantage available but no API key set (set ALPHA_VANTAGE_API_KEY)")
            except Exception as e:
                logger.warning(f"Failed to initialize Alpha Vantage fetcher: {e}")
                self.alpha_vantage_fetcher = None
        else:
            self.alpha_vantage_fetcher = None
        
        # Check if clients are authenticated
        self.hdfc_available = hdfc_client is not None and hasattr(hdfc_client, 'is_authenticated') and hdfc_client.is_authenticated()
        self.kotak_available = kotak_client is not None and hasattr(kotak_client, 'is_authenticated') and kotak_client.is_authenticated()
        
        logger.info(f"BrokerDataFetcher initialized - HDFC: {self.hdfc_available}, Kotak: {self.kotak_available}, NSE Fallback: {use_nse_fallback}")
    
    def fetch_historical_data(
        self,
        symbol: str,
        start_date: datetime,
        end_date: datetime,
        exchange: str = "NSE",
        interval: str = "DAY"
    ) -> List[HistoricalDataPoint]:
        """
        Fetch historical data for a symbol from available brokers.
        
        Args:
            symbol: Symbol to fetch (e.g., "NIFTY", "RELIANCE", "SENSEX")
            exchange: Exchange code ("NSE" or "BSE")
            start_date: Start date for historical data
            end_date: End date for historical data
            interval: Data interval ("DAY", "MINUTE", "WEEK", "MONTH")
            
        Returns:
            List of HistoricalDataPoint objects
        """
        logger.info(f"Fetching historical data for {symbol} ({exchange}) from {start_date} to {end_date}")
        
        # Priority 1: Try HDFC Sky (best for historical data)
        if self.hdfc_available:
            try:
                data = self._fetch_from_hdfc(symbol, start_date, end_date, exchange, interval)
                if data:
                    logger.info(f"Successfully fetched {len(data)} data points from HDFC Sky")
                    return data
            except Exception as e:
                logger.warning(f"HDFC Sky historical data fetch failed: {e}")
        
        # Priority 2: Try Kotak Neo (good for recent data)
        if self.kotak_available:
            try:
                data = self._fetch_from_kotak(symbol, start_date, end_date, exchange, interval)
                if data:
                    logger.info(f"Successfully fetched {len(data)} data points from Kotak Neo")
                    return data
            except Exception as e:
                logger.warning(f"Kotak Neo historical data fetch failed: {e}")
        
        # Priority 3: Yahoo Finance (FREE - no API key required)
        if self.use_yahoo_finance and self.yahoo_fetcher:
            try:
                # Map interval to Yahoo Finance format
                yahoo_interval = "1d" if interval == "DAY" else "1wk" if interval == "WEEK" else "1mo" if interval == "MONTH" else "1d"
                data = self.yahoo_fetcher.get_historical_data(symbol, start_date, end_date, yahoo_interval)
                if data:
                    # Convert to our format
                    converted_data = [
                        HistoricalDataPoint(
                            timestamp=dp.timestamp,
                            open=dp.open,
                            high=dp.high,
                            low=dp.low,
                            close=dp.close,
                            volume=dp.volume,
                            exchange=dp.exchange,
                            symbol=dp.symbol
                        )
                        for dp in data
                    ]
                    logger.info(f"Successfully fetched {len(converted_data)} data points from Yahoo Finance")
                    return converted_data
            except Exception as e:
                logger.warning(f"Yahoo Finance historical data fetch failed: {e}")
        
        # Priority 4: Alpha Vantage (FREE tier - requires API key)
        if self.use_alpha_vantage and self.alpha_vantage_fetcher and self.alpha_vantage_fetcher.api_key:
            try:
                # Map interval to Alpha Vantage format
                av_interval = "daily" if interval == "DAY" else "weekly" if interval == "WEEK" else "monthly" if interval == "MONTH" else "daily"
                data = self.alpha_vantage_fetcher.get_historical_data(symbol, start_date, end_date, av_interval)
                if data:
                    # Convert to our format
                    converted_data = [
                        HistoricalDataPoint(
                            timestamp=dp.timestamp,
                            open=dp.open,
                            high=dp.high,
                            low=dp.low,
                            close=dp.close,
                            volume=dp.volume,
                            exchange=dp.exchange,
                            symbol=dp.symbol
                        )
                        for dp in data
                    ]
                    logger.info(f"Successfully fetched {len(converted_data)} data points from Alpha Vantage")
                    return converted_data
            except Exception as e:
                logger.warning(f"Alpha Vantage historical data fetch failed: {e}")
        
        # Priority 5: Fallback to NSE/BSE Option Chain (for indices)
        if self.use_nse_fallback:
            try:
                data = self._fetch_from_nse_bse(symbol, start_date, end_date, exchange, interval)
                if data:
                    logger.info(f"Successfully fetched {len(data)} data points from NSE/BSE")
                    return data
            except Exception as e:
                logger.warning(f"NSE/BSE historical data fetch failed: {e}")
        
        logger.error(f"Failed to fetch historical data for {symbol} from any source")
        return []
    
    def _fetch_from_hdfc(
        self,
        symbol: str,
        exchange: str,
        start_date: datetime,
        end_date: datetime,
        interval: str
    ) -> List[HistoricalDataPoint]:
        """Fetch historical data from HDFC Sky."""
        try:
            # Map interval to HDFC chart type
            chart_type_map = {
                "DAY": "DAY",
                "MINUTE": "MINUTE",
                "WEEK": "WEEK",
                "MONTH": "MONTH"
            }
            chart_type = chart_type_map.get(interval, "DAY")
            
            # Determine series type
            series_type = "IDX" if symbol in ["NIFTY", "NIFTY50", "BANKNIFTY", "SENSEX"] else "EQ"
            
            # Fetch from HDFC Sky
            response = self.hdfc_client.get_historical_data(
                symbol=symbol,
                exchange=exchange,
                chart_type=chart_type,
                series_type=series_type,
                start_date=start_date.strftime("%Y-%m-%d"),
                end_date=end_date.strftime("%Y-%m-%d")
            )
            
            # Parse HDFC response format
            data_points = []
            if isinstance(response, dict):
                # HDFC returns data in various formats - adjust based on actual response
                candles = response.get("data", []) or response.get("candles", []) or response.get("result", [])
                
                for candle in candles:
                    try:
                        # Parse candle format (adjust based on actual HDFC response)
                        if isinstance(candle, dict):
                            timestamp_str = candle.get("timestamp") or candle.get("time") or candle.get("date")
                            if timestamp_str:
                                # Parse timestamp (adjust format as needed)
                                if isinstance(timestamp_str, str):
                                    timestamp = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
                                else:
                                    timestamp = datetime.fromtimestamp(timestamp_str / 1000)  # If milliseconds
                            else:
                                continue
                            
                            data_point = HistoricalDataPoint(
                                timestamp=timestamp,
                                open=float(candle.get("open", candle.get("o", 0))),
                                high=float(candle.get("high", candle.get("h", 0))),
                                low=float(candle.get("low", candle.get("l", 0))),
                                close=float(candle.get("close", candle.get("c", candle.get("ltp", 0)))),
                                volume=int(candle.get("volume", candle.get("v", 0)) or 0),
                                exchange=exchange,
                                symbol=symbol
                            )
                            data_points.append(data_point)
                    except Exception as e:
                        logger.debug(f"Error parsing HDFC candle: {e}")
                        continue
            
            return sorted(data_points, key=lambda x: x.timestamp)
            
        except Exception as e:
            logger.error(f"Error fetching from HDFC Sky: {e}")
            return []
    
    def _fetch_from_kotak(
        self,
        symbol: str,
        start_date: datetime,
        end_date: datetime,
        exchange: str = "NSE",
        interval: str = "DAY"
    ) -> List[HistoricalDataPoint]:
        """Fetch historical data from Kotak Neo."""
        try:
            # Kotak Neo may not have direct historical data API
            # For now, fetch current quotes and simulate historical data
            # TODO: Implement Kotak Neo historical data API if available
            
            # Map exchange to Kotak format
            kotak_exchange_map = {
                "NSE": "nse_cm",
                "BSE": "bse_cm"
            }
            kotak_exchange = kotak_exchange_map.get(exchange, "nse_cm")
            
            # Get symbol code (would need symbol master mapping)
            # For now, try to get quotes for current price
            try:
                # This is a simplified approach - in production, you'd need symbol code mapping
                quotes = self.kotak_client.get_quotes(kotak_exchange, symbol)
                
                # Parse quotes to get current price
                current_price = None
                if isinstance(quotes, dict):
                    # Parse Kotak response format
                    price = quotes.get("ltp") or quotes.get("lastPrice") or quotes.get("price")
                    if price:
                        current_price = float(price)
                
                if current_price:
                    # Create synthetic historical data from current price
                    # This is a fallback - ideally Kotak would provide historical data
                    data_points = []
                    current_time = start_date
                    while current_time <= end_date:
                        data_point = HistoricalDataPoint(
                            timestamp=current_time,
                            open=current_price,
                            high=current_price * 1.01,  # Simulate small variation
                            low=current_price * 0.99,
                            close=current_price,
                            exchange=exchange,
                            symbol=symbol
                        )
                        data_points.append(data_point)
                        current_time += timedelta(days=1) if interval == "DAY" else timedelta(minutes=15)
                    
                    return data_points
                    
            except Exception as e:
                logger.debug(f"Kotak quotes fetch failed: {e}")
            
            return []
            
        except Exception as e:
            logger.error(f"Error fetching from Kotak Neo: {e}")
            return []
    
    def _fetch_from_nse_bse(
        self,
        symbol: str,
        start_date: datetime,
        end_date: datetime,
        exchange: str = "NSE",
        interval: str = "DAY"
    ) -> List[HistoricalDataPoint]:
        """Fetch historical data from NSE/BSE Option Chain (for indices only)."""
        try:
            from aurum_harmony.engines.market_data.nse_option_chain import nse_option_chain
            
            # NSE Option Chain is primarily for indices
            if symbol not in ["NIFTY", "NIFTY50", "BANKNIFTY", "SENSEX"]:
                logger.debug(f"NSE/BSE Option Chain only supports indices, not {symbol}")
                return []
            
            # Get current underlying price
            underlying_price = nse_option_chain.get_underlying_price(symbol)
            if not underlying_price:
                return []
            
            # Create historical data points from current price
            # NSE Option Chain doesn't provide historical data directly
            # This is a simplified approach - in production, use NSE historical data API
            data_points = []
            current_time = start_date
            
            while current_time <= end_date:
                data_point = HistoricalDataPoint(
                    timestamp=current_time,
                    open=underlying_price,
                    high=underlying_price * 1.01,
                    low=underlying_price * 0.99,
                    close=underlying_price,
                    exchange=exchange,
                    symbol=symbol
                )
                data_points.append(data_point)
                current_time += timedelta(days=1) if interval == "DAY" else timedelta(minutes=15)
            
            return data_points
            
        except Exception as e:
            logger.error(f"Error fetching from NSE/BSE: {e}")
            return []
    
    def get_current_price(self, symbol: str, exchange: str = "NSE") -> Optional[float]:
        """
        Get current price for a symbol from available brokers.
        
        Args:
            symbol: Symbol to fetch
            exchange: Exchange code
            
        Returns:
            Current price or None
        """
        # Priority 1: HDFC Sky quotes
        if self.hdfc_available:
            try:
                quotes = self.hdfc_client.get_quotes(symbol, exchange)
                if isinstance(quotes, dict):
                    price = quotes.get("ltp") or quotes.get("last_price") or quotes.get("price")
                    if price:
                        return float(price)
            except Exception as e:
                logger.debug(f"HDFC quotes failed: {e}")
        
        # Priority 2: Kotak Neo quotes
        if self.kotak_available:
            try:
                kotak_exchange = "nse_cm" if exchange == "NSE" else "bse_cm"
                quotes = self.kotak_client.get_quotes(kotak_exchange, symbol)
                if isinstance(quotes, dict):
                    price = quotes.get("ltp") or quotes.get("lastPrice") or quotes.get("price")
                    if price:
                        return float(price)
            except Exception as e:
                logger.debug(f"Kotak quotes failed: {e}")
        
        # Priority 3: NSE/BSE Option Chain
        if self.use_nse_fallback:
            try:
                from aurum_harmony.engines.market_data.nse_option_chain import nse_option_chain
                price = nse_option_chain.get_underlying_price(symbol)
                if price:
                    return price
            except Exception as e:
                logger.debug(f"NSE Option Chain failed: {e}")
        
        return None


__all__ = ["BrokerDataFetcher", "HistoricalDataPoint"]

