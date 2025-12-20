"""
Broker-Integrated Backtesting Engine

Uses real historical data from HDFC Sky, Kotak Neo, and NSE/BSE
for accurate backtesting with actual market data.
"""

from __future__ import annotations

import logging
from typing import Dict, Any, List, Optional, Callable
from datetime import datetime, timedelta
from decimal import Decimal

from aurum_harmony.engines.backtesting.backtesting import BacktestingEngine, BacktestResult
from aurum_harmony.engines.market_data.broker_data_fetcher import BrokerDataFetcher, HistoricalDataPoint

logger = logging.getLogger(__name__)


class BrokerBacktestingEngine(BacktestingEngine):
    """
    Backtesting engine that uses real broker data (HDFC Sky, Kotak Neo, NSE/BSE).
    
    Features:
    - Fetches real historical data from authenticated brokers
    - More accurate backtesting with actual market prices
    - Supports multiple data sources with automatic fallback
    - Handles NSE, BSE, HDFC Sky, and Kotak Neo data
    """
    
    def __init__(
        self,
        initial_balance: float = 100000.0,
        hdfc_client: Optional[object] = None,
        kotak_client: Optional[object] = None,
        use_nse_fallback: bool = True
    ):
        """
        Initialize broker-integrated backtesting engine.
        
        Args:
            initial_balance: Starting balance for backtesting
            hdfc_client: Authenticated HDFCSkyAPI instance
            kotak_client: Authenticated KotakNeoAPI instance
            use_nse_fallback: Use NSE/BSE as fallback if brokers unavailable
        """
        super().__init__(initial_balance)
        
        # Initialize data fetcher
        self.data_fetcher = BrokerDataFetcher(
            hdfc_client=hdfc_client,
            kotak_client=kotak_client,
            use_nse_fallback=use_nse_fallback
        )
        
        logger.info("BrokerBacktestingEngine initialized with broker data support")
    
    def run_backtest_with_broker_data(
        self,
        strategy: Callable,
        symbols: List[str],
        period_start: datetime,
        period_end: datetime,
        strategy_name: str = "Broker Data Strategy",
        exchange: str = "NSE",
        interval: str = "DAY"
    ) -> BacktestResult:
        """
        Run backtest using real historical data from brokers.
        
        Args:
            strategy: Strategy function to backtest
            symbols: List of symbols to backtest (e.g., ["NIFTY", "BANKNIFTY"])
            period_start: Backtest start date
            period_end: Backtest end date
            strategy_name: Name of the strategy
            exchange: Exchange code ("NSE" or "BSE")
            interval: Data interval ("DAY", "MINUTE", "WEEK", "MONTH")
            
        Returns:
            BacktestResult with backtesting metrics
        """
        logger.info(f"Starting broker-integrated backtest: {strategy_name}")
        logger.info(f"Symbols: {symbols}, Period: {period_start} to {period_end}")
        
        # Fetch historical data for all symbols
        all_historical_data: Dict[str, List[HistoricalDataPoint]] = {}
        
        for symbol in symbols:
            logger.info(f"Fetching historical data for {symbol}...")
            historical_data = self.data_fetcher.fetch_historical_data(
                symbol=symbol,
                start_date=period_start,
                end_date=period_end,
                exchange=exchange,
                interval=interval
            )
            
            if not historical_data:
                all_historical_data[symbol] = historical_data
                logger.info(f"Fetched {len(historical_data)} data points for {symbol}")
            else:
                logger.warning(f"No historical data available for {symbol}")
        
        if not all_historical_data:
            raise ValueError("No historical data available for any symbol. Check broker connections.")
        
        # Convert historical data to format expected by base backtesting engine
        # Merge data from all symbols into unified timeline
        merged_data = self._merge_historical_data(all_historical_data, period_start, period_end)
        
        # Run standard backtest with merged data
        return self.run_backtest(
            strategy=strategy,
            historical_data=merged_data,
            period_start=period_start,
            period_end=period_end,
            strategy_name=strategy_name
        )
    
    def _merge_historical_data(
        self,
        all_historical_data: Dict[str, List[HistoricalDataPoint]],
        period_start: datetime,
        period_end: datetime
    ) -> List[Dict[str, Any]]:
        """
        Merge historical data from multiple symbols into unified timeline.
        
        Args:
            all_historical_data: Dictionary mapping symbols to their historical data
            period_start: Start date
            period_end: End date
            
        Returns:
            List of merged data points in format expected by backtesting engine
        """
        # Create a timeline of all unique timestamps
        all_timestamps = set()
        for symbol_data in all_historical_data.values():
            for data_point in symbol_data:
                all_timestamps.add(data_point.timestamp)
        
        # Sort timestamps
        sorted_timestamps = sorted(all_timestamps)
        
        # Create merged data points
        merged_data = []
        for timestamp in sorted_timestamps:
            if timestamp < period_start or timestamp > period_end:
                continue
            
            # Get prices for all symbols at this timestamp
            prices = {}
            for symbol, symbol_data in all_historical_data.items():
                # Find closest data point for this timestamp
                closest_point = None
                min_diff = timedelta.max
                
                for data_point in symbol_data:
                    diff = abs(data_point.timestamp - timestamp)
                    if diff < min_diff:
                        min_diff = diff
                        closest_point = data_point
                
                if closest_point:
                    # Use close price as the price for this timestamp
                    prices[symbol] = float(closest_point.close)
            
            if prices:
                merged_data.append({
                    "timestamp": timestamp,
                    "prices": prices
                })
        
        logger.info(f"Merged {len(merged_data)} data points from {len(all_historical_data)} symbols")
        return merged_data
    
    def get_current_prices(self, symbols: List[str], exchange: str = "NSE") -> Dict[str, float]:
        """
        Get current prices for multiple symbols from brokers.
        
        Args:
            symbols: List of symbols to fetch
            exchange: Exchange code
            
        Returns:
            Dictionary mapping symbols to their current prices
        """
        prices = {}
        for symbol in symbols:
            price = self.data_fetcher.get_current_price(symbol, exchange)
            if price:
                prices[symbol] = price
                logger.debug(f"Current price for {symbol}: ₹{price:,.2f}")
            else:
                logger.warning(f"Could not fetch current price for {symbol}")
        
        return prices


__all__ = ["BrokerBacktestingEngine"]

