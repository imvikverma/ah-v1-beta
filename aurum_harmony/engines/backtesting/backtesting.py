"""
Backtesting Engine for AurumHarmony

Provides comprehensive backtesting capabilities for trading strategies
with realistic market simulation and edge case testing.
"""

from __future__ import annotations

import logging
from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass
from datetime import datetime, timedelta
from decimal import Decimal

# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class BacktestResult:
    """Result of a backtesting run."""
    strategy_name: str
    period_start: datetime
    period_end: datetime
    total_trades: int
    winning_trades: int
    losing_trades: int
    total_pnl: float
    win_rate: float
    sharpe_ratio: float
    max_drawdown: float
    final_balance: float
    initial_balance: float
    return_percentage: float
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


class BacktestingEngine:
    """
    Comprehensive backtesting engine.
    
    Features:
    - Historical data simulation
    - Realistic market conditions
    - Edge case testing
    - Performance metrics calculation
    - Strategy comparison
    """
    
    def __init__(self, initial_balance: float = 100000.0):
        """
        Initialize backtesting engine.
        
        Args:
            initial_balance: Starting balance for backtests
        """
        if initial_balance <= 0:
            raise ValueError(f"Initial balance must be positive, got: {initial_balance}")
        
        self.initial_balance = Decimal(str(initial_balance))
        self.backtest_results: List[BacktestResult] = []
        logger.info(f"BacktestingEngine initialized with balance: ₹{initial_balance:,.2f}")
    
    def run_backtest(
        self,
        strategy: Callable,
        historical_data: List[Dict[str, Any]],
        period_start: datetime,
        period_end: datetime,
        strategy_name: str = "Custom Strategy"
    ) -> BacktestResult:
        """
        Run a backtest on historical data.
        
        Args:
            strategy: Strategy function that generates signals
            historical_data: Historical market data
            period_start: Backtest period start
            period_end: Backtest period end
            strategy_name: Name of the strategy
            
        Returns:
            BacktestResult object
        """
        try:
            logger.info(f"Starting backtest: {strategy_name} from {period_start} to {period_end}")
            
            # Initialize backtest state
            balance = self.initial_balance
            positions: Dict[str, Any] = {}
            trades: List[Dict[str, Any]] = []
            pnl_history: List[float] = []
            max_balance = balance
            max_drawdown = Decimal("0")
            
            # Process historical data
            for data_point in historical_data:
                # Get signals from strategy
                signals = strategy(data_point)
                
                # Execute signals (simplified)
                for signal in signals:
                    # Simulate trade execution
                    trade_result = self._simulate_trade(signal, data_point, balance, positions)
                    if trade_result:
                        trades.append(trade_result)
                        balance = Decimal(str(trade_result["balance_after"]))
                        pnl_history.append(float(trade_result.get("pnl", 0)))
                        
                        # Track drawdown
                        if balance > max_balance:
                            max_balance = balance
                        drawdown = (max_balance - balance) / max_balance
                        if drawdown > max_drawdown:
                            max_drawdown = drawdown
            
            # Calculate metrics
            total_trades = len(trades)
            winning_trades = sum(1 for t in trades if t.get("pnl", 0) > 0)
            losing_trades = sum(1 for t in trades if t.get("pnl", 0) < 0)
            total_pnl = sum(t.get("pnl", 0) for t in trades)
            win_rate = (winning_trades / total_trades * 100) if total_trades > 0 else 0.0
            
            # Calculate Sharpe ratio (simplified)
            sharpe_ratio = self._calculate_sharpe_ratio(pnl_history)
            
            # Calculate return percentage
            return_pct = float((balance - self.initial_balance) / self.initial_balance * 100)
            
            result = BacktestResult(
                strategy_name=strategy_name,
                period_start=period_start,
                period_end=period_end,
                total_trades=total_trades,
                winning_trades=winning_trades,
                losing_trades=losing_trades,
                total_pnl=float(total_pnl),
                win_rate=win_rate,
                sharpe_ratio=sharpe_ratio,
                max_drawdown=float(max_drawdown),
                final_balance=float(balance),
                initial_balance=float(self.initial_balance),
                return_percentage=return_pct,
                metadata={
                    "data_points": len(historical_data),
                    "period_days": (period_end - period_start).days,
                }
            )
            
            self.backtest_results.append(result)
            
            logger.info(
                f"Backtest completed: {strategy_name} - "
                f"{total_trades} trades, P&L: ₹{total_pnl:,.2f}, "
                f"Return: {return_pct:.2f}%, Win rate: {win_rate:.1f}%"
            )
            
            return result
            
        except Exception as e:
            logger.error(f"Error running backtest: {e}", exc_info=True)
            raise
    
    def _simulate_trade(
        self,
        signal: Dict[str, Any],
        market_data: Dict[str, Any],
        current_balance: Decimal,
        positions: Dict[str, Any]
    ) -> Optional[Dict[str, Any]]:
        """
        Simulate a trade execution.
        
        Args:
            signal: Trading signal
            market_data: Current market data
            current_balance: Current account balance
            positions: Current positions
            
        Returns:
            Trade result dictionary or None if trade couldn't execute
        """
        try:
            symbol = signal.get("symbol")
            side = signal.get("side")
            quantity = signal.get("quantity", 0)
            price = market_data.get("price", 0)
            
            if not symbol or quantity <= 0 or price <= 0:
                return None
            
            order_value = Decimal(str(price)) * Decimal(str(quantity))
            
            # Check balance for BUY orders
            if side == "BUY" and current_balance < order_value:
                return None
            
            # Execute trade
            if side == "BUY":
                new_balance = current_balance - order_value
                pnl = 0.0  # No P&L until position is closed
            else:  # SELL
                # Calculate P&L if closing a position
                pnl = 0.0
                if symbol in positions:
                    entry_price = positions[symbol].get("avg_price", price)
                    pnl = float((Decimal(str(price)) - Decimal(str(entry_price))) * Decimal(str(quantity)))
                new_balance = current_balance + order_value + Decimal(str(pnl))
            
            return {
                "symbol": symbol,
                "side": side,
                "quantity": quantity,
                "price": price,
                "pnl": pnl,
                "balance_after": float(new_balance),
                "timestamp": market_data.get("timestamp", datetime.now().isoformat()),
            }
            
        except Exception as e:
            logger.error(f"Error simulating trade: {e}")
            return None
    
    def _calculate_sharpe_ratio(self, returns: List[float], risk_free_rate: float = 0.05) -> float:
        """
        Calculate Sharpe ratio.
        
        Args:
            returns: List of returns
            risk_free_rate: Risk-free rate (annual)
            
        Returns:
            Sharpe ratio
        """
        if not returns or len(returns) < 2:
            return 0.0
        
        try:
            import statistics
            mean_return = statistics.mean(returns)
            std_return = statistics.stdev(returns) if len(returns) > 1 else 0.0
            
            if std_return == 0:
                return 0.0
            
            # Annualized Sharpe ratio (assuming daily returns)
            sharpe = (mean_return - risk_free_rate / 252) / std_return * (252 ** 0.5)
            return sharpe
        except Exception:
            return 0.0
    
    def compare_strategies(self, results: List[BacktestResult]) -> Dict[str, Any]:
        """
        Compare multiple backtest results.
        
        Args:
            results: List of BacktestResult objects
            
        Returns:
            Comparison dictionary
        """
        if not results:
            return {"error": "No results to compare"}
        
        best_return = max(results, key=lambda r: r.return_percentage)
        best_sharpe = max(results, key=lambda r: r.sharpe_ratio)
        best_win_rate = max(results, key=lambda r: r.win_rate)
        
        return {
            "total_strategies": len(results),
            "best_return": {
                "strategy": best_return.strategy_name,
                "return": best_return.return_percentage,
            },
            "best_sharpe": {
                "strategy": best_sharpe.strategy_name,
                "sharpe": best_sharpe.sharpe_ratio,
            },
            "best_win_rate": {
                "strategy": best_win_rate.strategy_name,
                "win_rate": best_win_rate.win_rate,
            },
            "average_return": sum(r.return_percentage for r in results) / len(results),
            "average_sharpe": sum(r.sharpe_ratio for r in results) / len(results),
        }
    
    def get_backtest_history(self) -> List[BacktestResult]:
        """Get all backtest results."""
        return self.backtest_results.copy()


# Default instance
backtesting_engine = BacktestingEngine()

__all__ = [
    "BacktestingEngine",
    "BacktestResult",
    "backtesting_engine",
]
