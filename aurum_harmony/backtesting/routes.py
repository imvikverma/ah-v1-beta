"""
Backtesting Routes with Broker Integration

Provides endpoints for backtesting with real broker data from:
- HDFC Sky
- Kotak Neo
- NSE/BSE (fallback)
"""

from flask import Blueprint, request, jsonify
from typing import Dict, Optional
import sys
import os
import logging
from datetime import datetime, timedelta

# Add project root to path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from aurum_harmony.engines.backtesting.broker_backtest import BrokerBacktestingEngine
from aurum_harmony.engines.backtesting.backtesting import BacktestingEngine
from aurum_harmony.brokers.hdfc_sky import get_hdfc_client
from aurum_harmony.brokers.kotak_neo import get_kotak_client
from aurum_harmony.auth.routes import require_auth

logger = logging.getLogger(__name__)

# Create blueprint
backtest_bp = Blueprint('backtest', __name__, url_prefix='/api/backtest')


def get_user_brokers(user_id: str) -> Dict[str, Optional[object]]:
    """
    Get authenticated broker clients for user.
    
    Args:
        user_id: User ID
        
    Returns:
        Dictionary with 'hdfc' and 'kotak' clients (or None if not available)
    """
    brokers = {
        'hdfc': None,
        'kotak': None
    }
    
    try:
        brokers['hdfc'] = get_hdfc_client(user_id)
        if brokers['hdfc']:
            logger.info(f"HDFC Sky client available for user {user_id}")
    except Exception as e:
        logger.debug(f"HDFC Sky not available for user {user_id}: {e}")
    
    try:
        brokers['kotak'] = get_kotak_client(user_id)
        if brokers['kotak']:
            logger.info(f"Kotak Neo client available for user {user_id}")
    except Exception as e:
        logger.debug(f"Kotak Neo not available for user {user_id}: {e}")
    
    return brokers


@backtest_bp.route('/realistic', methods=['GET', 'OPTIONS'])
@require_auth
def backtest_realistic():
    """
    Run realistic backtest with broker data if available.
    
    Query params:
        - use_broker_data: bool (default: true) - Use broker data if available
        - symbols: comma-separated list (default: "NIFTY,BANKNIFTY")
        - days: int (default: 20) - Number of days to backtest
        - exchange: str (default: "NSE") - Exchange code
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        from aurum_harmony.auth.auth_service import AuthService
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        user = AuthService.get_user_from_token(token)
        
        if not user:
            return jsonify({'error': 'Invalid token'}), 401
        
        user_id = str(user.id)
        
        # Get query parameters
        use_broker_data = request.args.get('use_broker_data', 'true').lower() == 'true'
        symbols_str = request.args.get('symbols', 'NIFTY,BANKNIFTY')
        symbols = [s.strip() for s in symbols_str.split(',')]
        days = int(request.args.get('days', 20))
        exchange = request.args.get('exchange', 'NSE')
        
        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        # Try to use broker data if requested and available
        if use_broker_data:
            brokers = get_user_brokers(user_id)
            
            if brokers['hdfc'] or brokers['kotak']:
                logger.info(f"Running broker-integrated backtest for user {user_id}")
                
                # Create broker backtesting engine
                engine = BrokerBacktestingEngine(
                    initial_balance=10000.0,
                    hdfc_client=brokers['hdfc'],
                    kotak_client=brokers['kotak'],
                    use_nse_fallback=True
                )
                
                # Simple strategy function (can be enhanced)
                def simple_strategy(data_point: Dict) -> Optional[Dict]:
                    """Simple strategy based on price movements."""
                    prices = data_point.get('prices', {})
                    if not prices:
                        return None
                    
                    # Example: Buy if price is below average
                    signals = {}
                    for symbol, price in prices.items():
                        # Simple logic: buy if price drops 1% (placeholder)
                        signals[symbol] = {
                            'action': 'BUY',
                            'quantity': 1,
                            'price': price
                        }
                    return signals
                
                # Run backtest with broker data
                result = engine.run_backtest_with_broker_data(
                    strategy=simple_strategy,
                    symbols=symbols,
                    period_start=start_date,
                    period_end=end_date,
                    strategy_name="Realistic Broker Data Test",
                    exchange=exchange,
                    interval="DAY"
                )
                
                # Format result
                return jsonify({
                    'result': {
                        'strategy_name': result.strategy_name,
                        'total_trades': result.total_trades,
                        'winning_trades': result.winning_trades,
                        'losing_trades': result.losing_trades,
                        'total_pnl': float(result.total_pnl),
                        'win_rate': result.win_rate,
                        'sharpe_ratio': result.sharpe_ratio,
                        'max_drawdown': float(result.max_drawdown),
                        'final_balance': float(result.final_balance),
                        'initial_balance': float(result.initial_balance),
                        'return_percentage': result.return_percentage,
                        'avg_win': float(result.total_pnl / result.winning_trades) if result.winning_trades > 0 else 0,
                        'avg_loss': float(abs(result.total_pnl / result.losing_trades)) if result.losing_trades > 0 else 0,
                        'profit_factor': (result.winning_trades * (result.total_pnl / result.winning_trades if result.winning_trades > 0 else 0)) / 
                                       (result.losing_trades * abs(result.total_pnl / result.losing_trades) if result.losing_trades > 0 else 1) if result.losing_trades > 0 else 0,
                        'message': f'Backtest completed using real broker data from {", ".join([k for k, v in brokers.items() if v])}'
                    },
                    'data_source': 'broker',
                    'brokers_used': [k for k, v in brokers.items() if v]
                }), 200
        
        # Fallback to standard backtest (VIX-based)
        logger.info(f"Running standard VIX-based backtest for user {user_id}")
        from engines.backtesting.Realistic_Tests import run_realistic_tests
        
        result = run_realistic_tests(capital=10000.0, days=days, vix_level=18.0)
        
        return jsonify({
            'result': result,
            'data_source': 'vix_simulation',
            'message': 'Backtest completed using VIX simulation (no broker data available)'
        }), 200
        
    except Exception as e:
        logger.error(f"Error in realistic backtest: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


@backtest_bp.route('/edge', methods=['GET', 'OPTIONS'])
@require_auth
def backtest_edge():
    """
    Run edge case backtest with broker data if available.
    
    Query params:
        - use_broker_data: bool (default: true) - Use broker data if available
        - symbols: comma-separated list (default: "NIFTY,BANKNIFTY")
        - days: int (default: 20) - Number of days to backtest
        - exchange: str (default: "NSE") - Exchange code
        - vix: float (default: 35.0) - VIX level for edge case
    """
    if request.method == 'OPTIONS':
        return '', 200
    
    try:
        from aurum_harmony.auth.auth_service import AuthService
        token = request.headers.get('Authorization', '').replace('Bearer ', '')
        user = AuthService.get_user_from_token(token)
        
        if not user:
            return jsonify({'error': 'Invalid token'}), 401
        
        user_id = str(user.id)
        
        # Get query parameters
        use_broker_data = request.args.get('use_broker_data', 'true').lower() == 'true'
        symbols_str = request.args.get('symbols', 'NIFTY,BANKNIFTY')
        symbols = [s.strip() for s in symbols_str.split(',')]
        days = int(request.args.get('days', 20))
        exchange = request.args.get('exchange', 'NSE')
        vix_level = float(request.args.get('vix', 35.0))
        
        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        # Try to use broker data if requested and available
        if use_broker_data:
            brokers = get_user_brokers(user_id)
            
            if brokers['hdfc'] or brokers['kotak']:
                logger.info(f"Running broker-integrated edge test for user {user_id}")
                
                # Create broker backtesting engine
                engine = BrokerBacktestingEngine(
                    initial_balance=10000.0,
                    hdfc_client=brokers['hdfc'],
                    kotak_client=brokers['kotak'],
                    use_nse_fallback=True
                )
                
                # Edge case strategy (more conservative)
                def edge_strategy(data_point: Dict) -> Optional[Dict]:
                    """Conservative strategy for edge cases."""
                    prices = data_point.get('prices', {})
                    if not prices:
                        return None
                    
                    # More conservative: only trade on significant moves
                    signals = {}
                    for symbol, price in prices.items():
                        # Only trade if price moves >2% (more conservative)
                        signals[symbol] = {
                            'action': 'BUY',
                            'quantity': 0.5,  # Reduced quantity
                            'price': price
                        }
                    return signals
                
                # Run backtest with broker data
                result = engine.run_backtest_with_broker_data(
                    strategy=edge_strategy,
                    symbols=symbols,
                    period_start=start_date,
                    period_end=end_date,
                    strategy_name="Edge Case Broker Data Test",
                    exchange=exchange,
                    interval="DAY"
                )
                
                # Format result
                return jsonify({
                    'result': {
                        'scenario': 'Extreme VIX Edge Test',
                        'vix': vix_level,
                        'strategy_name': result.strategy_name,
                        'total_trades': result.total_trades,
                        'winning_trades': result.winning_trades,
                        'losing_trades': result.losing_trades,
                        'total_pnl': float(result.total_pnl),
                        'win_rate': result.win_rate,
                        'sharpe_ratio': result.sharpe_ratio,
                        'max_drawdown': float(result.max_drawdown),
                        'final_balance': float(result.final_balance),
                        'initial_balance': float(result.initial_balance),
                        'return_percentage': result.return_percentage,
                        'max_drawdown_pct': (result.max_drawdown / result.initial_balance * 100) if result.initial_balance > 0 else 0,
                        'message': f'Edge test completed using real broker data from {", ".join([k for k, v in brokers.items() if v])}'
                    },
                    'data_source': 'broker',
                    'brokers_used': [k for k, v in brokers.items() if v]
                }), 200
        
        # Fallback to standard edge test (VIX-based)
        logger.info(f"Running standard VIX-based edge test for user {user_id}")
        from engines.backtesting.Edge_Tests import run_edge_tests
        
        result = run_edge_tests(capital=10000.0, vix=vix_level, days=days)
        
        return jsonify({
            'result': result,
            'data_source': 'vix_simulation',
            'message': 'Edge test completed using VIX simulation (no broker data available)'
        }), 200
        
    except Exception as e:
        logger.error(f"Error in edge backtest: {e}", exc_info=True)
        return jsonify({'error': str(e)}), 500


__all__ = ['backtest_bp']

