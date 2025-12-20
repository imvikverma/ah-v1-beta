"""
NSE Option Chain Data Fetcher

Fetches live option chain data from NSE India for NIFTY50, BANKNIFTY, SENSEX.
Uses NSE's get-quote API for derivatives.

This provides:
- All strike prices
- Call and Put premiums
- Open Interest (OI)
- Volume
- Greeks (if available)
"""

from __future__ import annotations

import logging
import requests
from typing import Dict, Any, List, Optional
from datetime import datetime
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class OptionData:
    """Represents option data for a single strike."""
    strike: float
    call_premium: Optional[float] = None
    put_premium: Optional[float] = None
    call_oi: Optional[int] = None
    put_oi: Optional[int] = None
    call_volume: Optional[int] = None
    put_volume: Optional[int] = None
    timestamp: datetime = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()


class NSEOptionChainFetcher:
    """
    Fetches option chain data from NSE India.
    
    Uses NSE's get-quote API for derivatives:
    https://www.nseindia.com/get-quote/derivatives/{SYMBOL}/{SYMBOL}-{INDEX}
    
    Example:
    - NIFTY: https://www.nseindia.com/get-quote/derivatives/NIFTY/NIFTY-50
    - BANKNIFTY: https://www.nseindia.com/get-quote/derivatives/BANKNIFTY/BANKNIFTY
    """
    
    BASE_URL = "https://www.nseindia.com"
    API_BASE = "https://www.nseindia.com/api"
    
    # Symbol mappings
    SYMBOL_MAPPING = {
        "NIFTY50": {"symbol": "NIFTY", "index": "NIFTY-50", "exchange": "NSE"},
        "NIFTY": {"symbol": "NIFTY", "index": "NIFTY-50", "exchange": "NSE"},
        "BANKNIFTY": {"symbol": "BANKNIFTY", "index": "BANKNIFTY", "exchange": "NSE"},
        "SENSEX": {"symbol": "SENSEX", "index": "SENSEX", "exchange": "BSE"},  # BSE - different endpoint
    }
    
    # BSE base URL (different from NSE)
    BSE_BASE_URL = "https://www.bseindia.com"
    BSE_API_BASE = "https://api.bseindia.com"
    
    def __init__(self):
        """Initialize NSE option chain fetcher."""
        self.session = requests.Session()
        # NSE requires proper headers to avoid blocking
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept": "application/json",
            "Accept-Language": "en-US,en;q=0.9",
            "Referer": "https://www.nseindia.com/",
        })
        self._cache: Dict[str, Dict[str, Any]] = {}
        self._cache_timeout = 5  # seconds
    
    def _get_nse_cookies(self) -> None:
        """Get NSE cookies by visiting the main page first."""
        try:
            self.session.get(f"{self.BASE_URL}/", timeout=5)
        except Exception as e:
            logger.debug(f"Error getting NSE cookies: {e}")
    
    def get_option_chain(self, symbol: str) -> Optional[Dict[str, Any]]:
        """
        Get full option chain for a symbol.
        
        Args:
            symbol: Symbol name (NIFTY50, BANKNIFTY, SENSEX)
            
        Returns:
            Option chain data with all strikes, premiums, OI, etc.
        """
        try:
            # Check cache
            if symbol in self._cache:
                cached = self._cache[symbol]
                age = (datetime.now() - cached.get("timestamp", datetime.min)).total_seconds()
                if age < self._cache_timeout:
                    return cached.get("data")
            
            symbol_upper = symbol.upper()
            if symbol_upper not in self.SYMBOL_MAPPING:
                logger.warning(f"No mapping for symbol: {symbol}")
                return None
            
            mapping = self.SYMBOL_MAPPING[symbol_upper]
            exchange = mapping.get("exchange", "NSE")
            
            # Handle BSE (SENSEX) differently
            if exchange == "BSE":
                return self._get_bse_option_chain(symbol)
            
            # NSE handling
            nse_symbol = mapping["symbol"]
            nse_index = mapping["index"]
            
            # Get cookies first
            self._get_nse_cookies()
            
            # Fetch option chain data
            # NSE API endpoint for option chain
            url = f"{self.API_BASE}/option-chain-indices"
            params = {"symbol": nse_symbol}
            
            response = self.session.get(url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            # Cache the result
            self._cache[symbol] = {
                "data": data,
                "timestamp": datetime.now()
            }
            
            logger.info(f"Fetched option chain for {symbol}")
            return data
            
        except Exception as e:
            logger.warning(f"Error fetching option chain for {symbol}: {e}")
            return None
    
    def _get_bse_option_chain(self, symbol: str) -> Optional[Dict[str, Any]]:
        """
        Get BSE option chain for SENSEX.
        
        Uses BSE's option chain page:
        https://www.bseindia.com/markets/Derivatives/DeriReports/DeriOptionchain.html
        
        BSE uses different endpoints and format than NSE.
        """
        try:
            # BSE option chain page URL
            base_url = "https://www.bseindia.com/markets/Derivatives/DeriReports/DeriOptionchain.html"
            
            # BSE API endpoint for option chain data
            # Based on BSE's internal API structure
            api_url = f"{self.BSE_BASE_URL}/SensexTicker/GetDerivativeOptionChainData"
            
            # Parameters for SENSEX option chain
            params = {
                "Underlying": "SENSEX",
                "InstrumentType": "Index Option",  # or "Index Futures"
                "ExpiryDate": "",  # Empty for all expiries, or specific date
            }
            
            # Update headers for BSE
            headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                "Accept": "application/json, text/plain, */*",
                "Accept-Language": "en-US,en;q=0.9",
                "Referer": base_url,
                "Origin": self.BSE_BASE_URL,
            }
            
            try:
                # First, visit the page to get cookies
                self.session.get(base_url, headers=headers, timeout=10)
                
                # Then fetch the option chain data
                response = self.session.get(api_url, params=params, headers=headers, timeout=10)
                
                if response.status_code == 200:
                    data = response.json()
                    self._cache[symbol] = {
                        "data": data,
                        "timestamp": datetime.now()
                    }
                    logger.info(f"Fetched BSE option chain for {symbol}")
                    return data
                else:
                    logger.debug(f"BSE API returned status {response.status_code}")
            except Exception as e:
                logger.debug(f"BSE API attempt failed: {e}")
            
            # Fallback: Try alternative BSE endpoints
            # BSE may use different API structure
            alt_url = f"{self.BSE_API_BASE}/BseIndiaAPI/api/GetFnoChainData/w"
            alt_params = {
                "scripcode": "99926000",  # SENSEX scrip code
                "series": "EQ"
            }
            
            try:
                response = self.session.get(alt_url, params=alt_params, timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    self._cache[symbol] = {
                        "data": data,
                        "timestamp": datetime.now()
                    }
                    logger.info(f"Fetched BSE option chain (alternative endpoint) for {symbol}")
                    return data
            except Exception as e:
                logger.debug(f"BSE alternative endpoint failed: {e}")
            
            logger.warning(f"BSE option chain not yet fully implemented for {symbol}. May need web scraping or third-party API.")
            return None
            
        except Exception as e:
            logger.warning(f"Error fetching BSE option chain for {symbol}: {e}")
            return None
    
    def get_underlying_price(self, symbol: str) -> Optional[float]:
        """
        Get underlying index price from option chain.
        
        Args:
            symbol: Symbol name
            
        Returns:
            Current underlying price
        """
        option_chain = self.get_option_chain(symbol)
        if not option_chain:
            return None
        
        try:
            # Parse NSE response format
            # NSE returns data in specific format - adjust based on actual response
            if "records" in option_chain:
                underlying_price = option_chain["records"].get("underlyingValue")
                if underlying_price:
                    return float(underlying_price)
            
            # Alternative format
            if "underlyingValue" in option_chain:
                return float(option_chain["underlyingValue"])
            
            return None
            
        except Exception as e:
            logger.warning(f"Error parsing underlying price: {e}")
            return None
    
    def get_option_premium(self, symbol: str, strike: float, option_type: str = "CE") -> Optional[float]:
        """
        Get option premium for a specific strike.
        
        Args:
            symbol: Symbol name
            strike: Strike price
            option_type: "CE" (Call) or "PE" (Put)
            
        Returns:
            Option premium or None
        """
        option_chain = self.get_option_chain(symbol)
        if not option_chain:
            return None
        
        try:
            # Parse option chain to find specific strike
            # Format depends on NSE API response structure
            if "records" in option_chain and "data" in option_chain["records"]:
                for option_data in option_chain["records"]["data"]:
                    if option_data.get("strikePrice") == strike:
                        if option_type == "CE":
                            return option_data.get("CE", {}).get("lastPrice")
                        else:
                            return option_data.get("PE", {}).get("lastPrice")
            
            return None
            
        except Exception as e:
            logger.warning(f"Error getting option premium: {e}")
            return None


# Global instance
nse_option_chain = NSEOptionChainFetcher()

__all__ = ["NSEOptionChainFetcher", "OptionData", "nse_option_chain"]

