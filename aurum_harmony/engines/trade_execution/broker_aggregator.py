"""
Broker Aggregator Service

Fans out to all trading engines (HDFC Sky NSE/BSE, Kotak Neo NSE/BSE, Paper, Backtest)
in parallel and aggregates their responses into a UnifiedSnapshot.

This service implements the "8 engines working together" architecture per the
Holy Grail documentation.
"""

from __future__ import annotations

import logging
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Dict, Optional, List, Any
from dataclasses import dataclass

from aurum_harmony.engines.trade_execution.unified_snapshot import (
    UnifiedSnapshot,
    EngineSnapshot,
    EngineType,
    Exchange,
    UnifiedPosition,
    UnifiedBalance,
    UnifiedQuote,
)
from aurum_harmony.engines.trade_execution.exchange_router import ExchangeRouter
from aurum_harmony.engines.trade_execution.trade_execution import (
    BrokerAdapter,
    Position,
    OrderSide,
)

logger = logging.getLogger(__name__)


class BrokerAggregator:
    """
    Aggregates data from multiple trading engines in parallel.
    
    Engines:
    - HDFC Sky (NSE & BSE)
    - Kotak Neo (NSE & BSE)
    - Paper Trading
    - Backtest
    - Predictive AI (signals)
    - Compliance (limits)
    """
    
    def __init__(
        self,
        hdfc_nse_adapter: Optional[BrokerAdapter] = None,
        hdfc_bse_adapter: Optional[BrokerAdapter] = None,
        kotak_nse_adapter: Optional[BrokerAdapter] = None,
        kotak_bse_adapter: Optional[BrokerAdapter] = None,
        paper_adapter: Optional[BrokerAdapter] = None,
        max_workers: int = 8,
    ):
        """
        Initialize broker aggregator with available adapters.
        
        Args:
            hdfc_nse_adapter: HDFC Sky adapter for NSE
            hdfc_bse_adapter: HDFC Sky adapter for BSE
            kotak_nse_adapter: Kotak Neo adapter for NSE
            kotak_bse_adapter: Kotak Neo adapter for BSE
            paper_adapter: Paper trading adapter
            max_workers: Max parallel workers for fan-out
        """
        self.hdfc_nse_adapter = hdfc_nse_adapter
        self.hdfc_bse_adapter = hdfc_bse_adapter
        self.kotak_nse_adapter = kotak_nse_adapter
        self.kotak_bse_adapter = kotak_bse_adapter
        self.paper_adapter = paper_adapter
        self.max_workers = max_workers
        
        self._initialized_engines = []
        if hdfc_nse_adapter:
            self._initialized_engines.append("HDFC_SKY_NSE")
        if hdfc_bse_adapter:
            self._initialized_engines.append("HDFC_SKY_BSE")
        if kotak_nse_adapter:
            self._initialized_engines.append("KOTAK_NEO_NSE")
        if kotak_bse_adapter:
            self._initialized_engines.append("KOTAK_NEO_BSE")
        if paper_adapter:
            self._initialized_engines.append("PAPER_TRADING")
        
        logger.info(
            f"BrokerAggregator initialized with {len(self._initialized_engines)} engines: "
            f"{', '.join(self._initialized_engines)}"
        )
    
    def get_unified_snapshot(self, timeout: float = 5.0) -> UnifiedSnapshot:
        """
        Fan out to all engines in parallel and aggregate into UnifiedSnapshot.
        
        Args:
            timeout: Max seconds to wait for all engines
            
        Returns:
            UnifiedSnapshot with aggregated data from all available engines
        """
        snapshot = UnifiedSnapshot()
        start_time = time.time()
        
        # Build list of engine tasks
        tasks = []
        
        # HDFC Sky engines
        if self.hdfc_nse_adapter:
            tasks.append(("HDFC_SKY_NSE", Exchange.NSE, EngineType.HDFC_SKY_NSE, self._fetch_hdfc_snapshot, (self.hdfc_nse_adapter, Exchange.NSE)))
        if self.hdfc_bse_adapter:
            tasks.append(("HDFC_SKY_BSE", Exchange.BSE, EngineType.HDFC_SKY_BSE, self._fetch_hdfc_snapshot, (self.hdfc_bse_adapter, Exchange.BSE)))
        
        # Kotak Neo engines
        if self.kotak_nse_adapter:
            tasks.append(("KOTAK_NEO_NSE", Exchange.NSE, EngineType.KOTAK_NEO_NSE, self._fetch_kotak_snapshot, (self.kotak_nse_adapter, Exchange.NSE)))
        if self.kotak_bse_adapter:
            tasks.append(("KOTAK_NEO_BSE", Exchange.BSE, EngineType.KOTAK_NEO_BSE, self._fetch_kotak_snapshot, (self.kotak_bse_adapter, Exchange.BSE)))
        
        # Paper trading engine
        if self.paper_adapter:
            tasks.append(("PAPER_TRADING", None, EngineType.PAPER_TRADING, self._fetch_paper_snapshot, (self.paper_adapter,)))
        
        # Execute all tasks in parallel
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = {
                executor.submit(func, *args): (engine_key, exchange, engine_type)
                for engine_key, exchange, engine_type, func, args in tasks
            }
            
            for future in as_completed(futures, timeout=timeout):
                engine_key, exchange, engine_type = futures[future]
                try:
                    engine_snapshot = future.result(timeout=1.0)
                    if engine_snapshot:
                        snapshot.engine_snapshots[engine_key] = engine_snapshot
                        logger.debug(f"Engine {engine_key} snapshot collected successfully")
                except Exception as e:
                    logger.warning(f"Engine {engine_key} failed: {e}")
                    # Create error snapshot
                    error_snapshot = EngineSnapshot(
                        engine_type=engine_type,
                        exchange=exchange,
                        is_available=False,
                        error=str(e),
                    )
                    snapshot.engine_snapshots[engine_key] = error_snapshot
        
        # Aggregate all snapshots
        snapshot.aggregate()
        
        # Validate snapshot
        try:
            from aurum_harmony.engines.trade_execution.snapshot_validator import SnapshotValidator
            validation = SnapshotValidator.validate_snapshot(snapshot)
            if not validation["valid"]:
                logger.warning(f"Snapshot validation found errors: {validation['errors']}")
            if validation["warnings"]:
                logger.debug(f"Snapshot validation warnings: {validation['warnings']}")
        except Exception as e:
            logger.debug(f"Snapshot validation failed (non-critical): {e}")
        
        elapsed = time.time() - start_time
        
        # Log detailed summary
        engine_summary = []
        for engine_key, engine_snap in snapshot.engine_snapshots.items():
            status = "✅" if engine_snap.is_available else "❌"
            pos_count = len(engine_snap.positions)
            error_info = f" ({engine_snap.error})" if engine_snap.error else ""
            engine_summary.append(f"{status} {engine_key}: {pos_count} positions{error_info}")
        
        logger.info(
            f"UnifiedSnapshot collected in {elapsed:.3f}s: "
            f"{snapshot.available_engines}/{snapshot.total_engines} engines available"
        )
        logger.debug(f"Engine details: {' | '.join(engine_summary)}")
        
        return snapshot
    
    def _fetch_hdfc_snapshot(self, adapter: BrokerAdapter, exchange: Exchange) -> Optional[EngineSnapshot]:
        """Fetch snapshot from HDFC Sky adapter."""
        try:
            engine_type = EngineType.HDFC_SKY_NSE if exchange == Exchange.NSE else EngineType.HDFC_SKY_BSE
            
            # Get positions
            positions = []
            if hasattr(adapter, 'get_positions'):
                broker_positions = adapter.get_positions()
                # Handle both Dict[str, Position] and List[Position] formats
                if isinstance(broker_positions, dict):
                    for symbol, pos in broker_positions.items():
                        unified_pos = UnifiedPosition(
                            symbol=symbol,
                            exchange=exchange,
                            quantity=pos.quantity,
                            avg_price=pos.avg_price,
                            current_price=pos.current_price,
                            side=pos.side.value if hasattr(pos.side, 'value') else str(pos.side),
                            unrealized_pnl=getattr(pos, 'unrealized_pnl', 0.0),
                            opened_at=getattr(pos, 'opened_at', time.time()),
                            engine_source=engine_type,
                        )
                        positions.append(unified_pos)
                elif isinstance(broker_positions, list):
                    for pos in broker_positions:
                        symbol = getattr(pos, 'symbol', 'UNKNOWN')
                        unified_pos = UnifiedPosition(
                            symbol=symbol,
                            exchange=exchange,
                            quantity=pos.quantity,
                            avg_price=pos.avg_price,
                            current_price=pos.current_price,
                            side=pos.side.value if hasattr(pos.side, 'value') else str(pos.side),
                            unrealized_pnl=getattr(pos, 'unrealized_pnl', 0.0),
                            opened_at=getattr(pos, 'opened_at', time.time()),
                            engine_source=engine_type,
                        )
                        positions.append(unified_pos)
            
            # Get balance
            balance = None
            if hasattr(adapter, 'get_balance'):
                broker_balance = adapter.get_balance()
                # Handle both float and dict returns
                if isinstance(broker_balance, (int, float)):
                    balance = UnifiedBalance(
                        available=float(broker_balance),
                        margin_used=0.0,
                        total_equity=float(broker_balance),
                        unrealized_pnl=0.0,
                        realized_pnl=0.0,
                        engine_source=engine_type,
                        exchange=exchange,
                    )
                elif isinstance(broker_balance, dict):
                    balance = UnifiedBalance(
                        available=broker_balance.get('available', 0.0),
                        margin_used=broker_balance.get('margin_used', 0.0),
                        total_equity=broker_balance.get('total_equity', 0.0),
                        unrealized_pnl=broker_balance.get('unrealized_pnl', 0.0),
                        realized_pnl=broker_balance.get('realized_pnl', 0.0),
                        engine_source=engine_type,
                        exchange=exchange,
                    )
            
            return EngineSnapshot(
                engine_type=engine_type,
                exchange=exchange,
                positions=positions,
                balance=balance,
                is_available=True,
            )
        except Exception as e:
            logger.error(f"Error fetching HDFC {exchange.value} snapshot: {e}", exc_info=True)
            return None
    
    def _fetch_kotak_snapshot(self, adapter: BrokerAdapter, exchange: Exchange) -> Optional[EngineSnapshot]:
        """Fetch snapshot from Kotak Neo adapter."""
        try:
            engine_type = EngineType.KOTAK_NEO_NSE if exchange == Exchange.NSE else EngineType.KOTAK_NEO_BSE
            
            # Get positions
            positions = []
            if hasattr(adapter, 'get_positions'):
                broker_positions = adapter.get_positions()
                # Handle both Dict[str, Position] and List[Position] formats
                if isinstance(broker_positions, dict):
                    for symbol, pos in broker_positions.items():
                        unified_pos = UnifiedPosition(
                            symbol=symbol,
                            exchange=exchange,
                            quantity=pos.quantity,
                            avg_price=pos.avg_price,
                            current_price=pos.current_price,
                            side=pos.side.value if hasattr(pos.side, 'value') else str(pos.side),
                            unrealized_pnl=getattr(pos, 'unrealized_pnl', 0.0),
                            opened_at=getattr(pos, 'opened_at', time.time()),
                            engine_source=engine_type,
                        )
                        positions.append(unified_pos)
                elif isinstance(broker_positions, list):
                    for pos in broker_positions:
                        symbol = getattr(pos, 'symbol', 'UNKNOWN')
                        unified_pos = UnifiedPosition(
                            symbol=symbol,
                            exchange=exchange,
                            quantity=pos.quantity,
                            avg_price=pos.avg_price,
                            current_price=pos.current_price,
                            side=pos.side.value if hasattr(pos.side, 'value') else str(pos.side),
                            unrealized_pnl=getattr(pos, 'unrealized_pnl', 0.0),
                            opened_at=getattr(pos, 'opened_at', time.time()),
                            engine_source=engine_type,
                        )
                        positions.append(unified_pos)
            
            # Get balance
            balance = None
            if hasattr(adapter, 'get_balance'):
                broker_balance = adapter.get_balance()
                # Handle both float and dict returns
                if isinstance(broker_balance, (int, float)):
                    balance = UnifiedBalance(
                        available=float(broker_balance),
                        margin_used=0.0,
                        total_equity=float(broker_balance),
                        unrealized_pnl=0.0,
                        realized_pnl=0.0,
                        engine_source=engine_type,
                        exchange=exchange,
                    )
                elif isinstance(broker_balance, dict):
                    balance = UnifiedBalance(
                        available=broker_balance.get('available', 0.0),
                        margin_used=broker_balance.get('margin_used', 0.0),
                        total_equity=broker_balance.get('total_equity', 0.0),
                        unrealized_pnl=broker_balance.get('unrealized_pnl', 0.0),
                        realized_pnl=broker_balance.get('realized_pnl', 0.0),
                        engine_source=engine_type,
                        exchange=exchange,
                    )
            
            return EngineSnapshot(
                engine_type=engine_type,
                exchange=exchange,
                positions=positions,
                balance=balance,
                is_available=True,
            )
        except Exception as e:
            logger.error(f"Error fetching Kotak {exchange.value} snapshot: {e}", exc_info=True)
            return None
    
    def _fetch_paper_snapshot(self, adapter: BrokerAdapter) -> Optional[EngineSnapshot]:
        """Fetch snapshot from paper trading adapter."""
        try:
            # Import ExchangeRouter for proper exchange routing
            from aurum_harmony.engines.trade_execution.exchange_router import ExchangeRouter
            
            # Get positions
            positions = []
            if hasattr(adapter, 'get_positions'):
                broker_positions = adapter.get_positions()
                # Handle both Dict[str, Position] and List[Position] formats
                if isinstance(broker_positions, dict):
                    for symbol, pos in broker_positions.items():
                        # Determine exchange from symbol using ExchangeRouter (for index options)
                        exchange = ExchangeRouter.get_exchange_for_symbol(symbol)
                        if hasattr(pos, 'metadata') and isinstance(pos.metadata, dict) and 'exchange' in pos.metadata:
                            exchange = Exchange(pos.metadata['exchange'])
                        
                        unified_pos = UnifiedPosition(
                            symbol=symbol,
                            exchange=exchange,
                            quantity=pos.quantity,
                            avg_price=pos.avg_price,
                            current_price=pos.current_price,
                            side=pos.side.value if hasattr(pos.side, 'value') else str(pos.side),
                            unrealized_pnl=getattr(pos, 'unrealized_pnl', 0.0),
                            opened_at=getattr(pos, 'opened_at', time.time()),
                            engine_source=EngineType.PAPER_TRADING,
                        )
                        positions.append(unified_pos)
                elif isinstance(broker_positions, list):
                    for pos in broker_positions:
                        symbol = getattr(pos, 'symbol', 'UNKNOWN')
                        # Determine exchange from symbol using ExchangeRouter (for index options)
                        from aurum_harmony.engines.trade_execution.exchange_router import ExchangeRouter
                        exchange = ExchangeRouter.get_exchange_for_symbol(symbol)
                        if hasattr(pos, 'metadata') and isinstance(pos.metadata, dict) and 'exchange' in pos.metadata:
                            exchange = Exchange(pos.metadata['exchange'])
                        
                        unified_pos = UnifiedPosition(
                            symbol=symbol,
                            exchange=exchange,
                            quantity=pos.quantity,
                            avg_price=pos.avg_price,
                            current_price=pos.current_price,
                            side=pos.side.value if hasattr(pos.side, 'value') else str(pos.side),
                            unrealized_pnl=getattr(pos, 'unrealized_pnl', 0.0),
                            opened_at=getattr(pos, 'opened_at', time.time()),
                            engine_source=EngineType.PAPER_TRADING,
                        )
                        positions.append(unified_pos)
            
            # Get balance
            balance = None
            if hasattr(adapter, 'get_balance'):
                broker_balance = adapter.get_balance()
                # Handle both float and dict returns
                if isinstance(broker_balance, (int, float)):
                    balance = UnifiedBalance(
                        available=float(broker_balance),
                        margin_used=0.0,
                        total_equity=float(broker_balance),
                        unrealized_pnl=0.0,
                        realized_pnl=0.0,
                        engine_source=EngineType.PAPER_TRADING,
                    )
                elif isinstance(broker_balance, dict):
                    balance = UnifiedBalance(
                        available=broker_balance.get('available', 0.0),
                        margin_used=broker_balance.get('margin_used', 0.0),
                        total_equity=broker_balance.get('total_equity', 0.0),
                        unrealized_pnl=broker_balance.get('unrealized_pnl', 0.0),
                        realized_pnl=broker_balance.get('realized_pnl', 0.0),
                        engine_source=EngineType.PAPER_TRADING,
                    )
            
            return EngineSnapshot(
                engine_type=EngineType.PAPER_TRADING,
                positions=positions,
                balance=balance,
                is_available=True,
            )
        except Exception as e:
            logger.error(f"Error fetching paper trading snapshot: {e}", exc_info=True)
            return None


    def get_status_summary(self) -> Dict[str, Any]:
        """
        Get a quick status summary of all engines without fetching full snapshot.
        Useful for health checks and monitoring.
        
        Returns:
            Dictionary with engine availability status
        """
        status = {
            "total_engines": len(self._initialized_engines),
            "engines": {},
        }
        
        for engine_name in self._initialized_engines:
            # Check if adapter exists and is available
            adapter = None
            if engine_name == "HDFC_SKY_NSE":
                adapter = self.hdfc_nse_adapter
            elif engine_name == "HDFC_SKY_BSE":
                adapter = self.hdfc_bse_adapter
            elif engine_name == "KOTAK_NEO_NSE":
                adapter = self.kotak_nse_adapter
            elif engine_name == "KOTAK_NEO_BSE":
                adapter = self.kotak_bse_adapter
            elif engine_name == "PAPER_TRADING":
                adapter = self.paper_adapter
            
            status["engines"][engine_name] = {
                "initialized": adapter is not None,
                "available": adapter is not None and (
                    not hasattr(adapter, 'is_authenticated') or 
                    adapter.is_authenticated() if hasattr(adapter, 'is_authenticated') else True
                ),
            }
        
        return status
    
    def get_positions_by_exchange(self, exchange: Exchange) -> List[UnifiedPosition]:
        """
        Get all positions for a specific exchange from the latest snapshot.
        Note: This requires calling get_unified_snapshot() first.
        
        Args:
            exchange: Target exchange (NSE or BSE)
            
        Returns:
            List of positions for the target exchange
        """
        snapshot = self.get_unified_snapshot(timeout=2.0)
        return snapshot.get_positions_by_exchange(exchange)
    
    def get_positions_by_symbol(self, symbol: str) -> List[UnifiedPosition]:
        """
        Get all positions for a specific symbol from the latest snapshot.
        
        Args:
            symbol: Trading symbol
            
        Returns:
            List of positions for the symbol (across all exchanges)
        """
        snapshot = self.get_unified_snapshot(timeout=2.0)
        return snapshot.get_positions_by_symbol(symbol)


__all__ = ["BrokerAggregator"]

