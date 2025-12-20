"""
Exchange Router

Routes orders and queries to the correct exchange (NSE vs BSE) based on symbol
and configuration. Helps the aggregator determine which adapter to use for each
symbol.
"""

from __future__ import annotations

import logging
from typing import Optional, Dict, List
from enum import Enum

from aurum_harmony.engines.trade_execution.unified_snapshot import Exchange

logger = logging.getLogger(__name__)


class ExchangeRouter:
    """
    Routes symbols to exchanges (NSE vs BSE).
    
    For index options (NIFTY50, BANKNIFTY, SENSEX):
    - NIFTY50, BANKNIFTY → NSE
    - SENSEX → BSE
    
    For other symbols, uses configuration or defaults to NSE.
    """
    
    # Index options mapping
    INDEX_EXCHANGE_MAP: Dict[str, Exchange] = {
        "NIFTY50": Exchange.NSE,
        "NIFTY": Exchange.NSE,
        "BANKNIFTY": Exchange.NSE,
        "FINNIFTY": Exchange.NSE,
        "MIDCPNIFTY": Exchange.NSE,
        "SENSEX": Exchange.BSE,
        "BANKEX": Exchange.BSE,
    }
    
    # Default exchange for unknown symbols
    DEFAULT_EXCHANGE = Exchange.NSE
    
    @classmethod
    def get_exchange_for_symbol(cls, symbol: str) -> Exchange:
        """
        Determine exchange for a symbol.
        
        Args:
            symbol: Trading symbol (e.g., "NIFTY50", "RELIANCE")
            
        Returns:
            Exchange (NSE or BSE)
        """
        symbol_upper = symbol.strip().upper()
        
        # Check index options first
        for index, exchange in cls.INDEX_EXCHANGE_MAP.items():
            if index in symbol_upper:
                logger.debug(f"Symbol {symbol} mapped to {exchange.value} (index: {index})")
                return exchange
        
        # Default to NSE for unknown symbols
        logger.debug(f"Symbol {symbol} using default exchange: {cls.DEFAULT_EXCHANGE.value}")
        return cls.DEFAULT_EXCHANGE
    
    @classmethod
    def get_exchanges_for_symbols(cls, symbols: List[str]) -> Dict[str, Exchange]:
        """
        Get exchange mapping for multiple symbols.
        
        Args:
            symbols: List of trading symbols
            
        Returns:
            Dictionary mapping symbol -> Exchange
        """
        return {symbol: cls.get_exchange_for_symbol(symbol) for symbol in symbols}
    
    @classmethod
    def filter_symbols_by_exchange(cls, symbols: List[str], exchange: Exchange) -> List[str]:
        """
        Filter symbols that belong to a specific exchange.
        
        Args:
            symbols: List of trading symbols
            exchange: Target exchange
            
        Returns:
            List of symbols that belong to the target exchange
        """
        return [
            symbol 
            for symbol in symbols 
            if cls.get_exchange_for_symbol(symbol) == exchange
        ]
    
    @classmethod
    def is_nse_symbol(cls, symbol: str) -> bool:
        """Check if symbol belongs to NSE."""
        return cls.get_exchange_for_symbol(symbol) == Exchange.NSE
    
    @classmethod
    def is_bse_symbol(cls, symbol: str) -> bool:
        """Check if symbol belongs to BSE."""
        return cls.get_exchange_for_symbol(symbol) == Exchange.BSE


__all__ = ["ExchangeRouter"]

