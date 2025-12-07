"""
Paper Trading API Routes
Provides endpoints for simulated trading without real broker connections.
"""

from flask import Blueprint, request, jsonify
from typing import Dict, Any
import sys
import os

# Add project root to path
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from aurum_harmony.engines.trade_execution.trade_execution import (
    PaperBrokerAdapter,
    Order,
    OrderSide,
    OrderType,
    Position
)

paper_bp = Blueprint('paper', __name__, url_prefix='/api/paper')

# Store paper trading adapters per user (in production, use database or Redis)
_user_adapters: Dict[str, PaperBrokerAdapter] = {}


def get_user_adapter(user_id: str) -> PaperBrokerAdapter:
    """Get or create paper trading adapter for a user."""
    if user_id not in _user_adapters:
        _user_adapters[user_id] = PaperBrokerAdapter(initial_balance=100000.0)
    return _user_adapters[user_id]


@paper_bp.route('/balance', methods=['GET', 'OPTIONS'])
def get_balance():
    """Get paper trading account balance."""
    if request.method == 'OPTIONS':
        return '', 200
    
    user_id = request.args.get('user_id') or request.headers.get('X-User-ID')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400
    
    try:
        adapter = get_user_adapter(user_id)
        balance = adapter.get_balance()
        portfolio_value = adapter.get_portfolio_value()
        pnl = adapter.get_pnl()
        
        return jsonify({
            'success': True,
            'balance': balance,
            'portfolio_value': portfolio_value,
            'pnl': pnl,
            'currency': 'INR'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@paper_bp.route('/positions', methods=['GET', 'OPTIONS'])
def get_positions():
    """Get open positions."""
    if request.method == 'OPTIONS':
        return '', 200
    
    user_id = request.args.get('user_id') or request.headers.get('X-User-ID')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400
    
    try:
        adapter = get_user_adapter(user_id)
        positions = adapter.get_positions()
        
        positions_list = []
        for symbol, pos in positions.items():
            positions_list.append({
                'symbol': pos.symbol,
                'quantity': pos.quantity,
                'avg_price': pos.avg_price,
                'current_price': pos.current_price,
                'unrealized_pnl': pos.unrealized_pnl,
                'side': pos.side.value,
                'opened_at': pos.opened_at
            })
        
        return jsonify({
            'success': True,
            'positions': positions_list,
            'count': len(positions_list)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@paper_bp.route('/orders', methods=['GET', 'OPTIONS'])
def get_orders():
    """Get all orders (open and filled)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    user_id = request.args.get('user_id') or request.headers.get('X-User-ID')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400
    
    try:
        adapter = get_user_adapter(user_id)
        orders = adapter.get_orders()
        
        orders_list = []
        for order in orders:
            orders_list.append({
                'broker_order_id': order.broker_order_id,
                'client_order_id': order.client_order_id,
                'symbol': order.symbol,
                'side': order.side.value,
                'quantity': order.quantity,
                'order_type': order.order_type.value,
                'limit_price': order.limit_price,
                'status': order.status.value,
                'metadata': order.metadata
            })
        
        return jsonify({
            'success': True,
            'orders': orders_list,
            'count': len(orders_list)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@paper_bp.route('/orders/history', methods=['GET', 'OPTIONS'])
def get_order_history():
    """Get order history."""
    if request.method == 'OPTIONS':
        return '', 200
    
    user_id = request.args.get('user_id') or request.headers.get('X-User-ID')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400
    
    try:
        adapter = get_user_adapter(user_id)
        history = adapter.get_order_history()
        
        history_list = []
        for order in history:
            history_list.append({
                'broker_order_id': order.broker_order_id,
                'client_order_id': order.client_order_id,
                'symbol': order.symbol,
                'side': order.side.value,
                'quantity': order.quantity,
                'order_type': order.order_type.value,
                'limit_price': order.limit_price,
                'status': order.status.value,
                'filled_price': order.metadata.get('filled_price'),
                'filled_at': order.metadata.get('filled_at'),
                'metadata': order.metadata
            })
        
        return jsonify({
            'success': True,
            'history': history_list,
            'count': len(history_list)
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@paper_bp.route('/orders', methods=['POST', 'OPTIONS'])
def place_order():
    """Place a paper trading order."""
    if request.method == 'OPTIONS':
        return '', 200
    
    user_id = request.json.get('user_id') or request.headers.get('X-User-ID')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400
    
    data = request.get_json() or {}
    
    try:
        # Validate required fields
        symbol = data.get('symbol')
        side_str = data.get('side', 'BUY').upper()
        quantity = float(data.get('quantity', 0))
        
        if not symbol:
            return jsonify({'error': 'symbol required'}), 400
        if quantity <= 0:
            return jsonify({'error': 'quantity must be positive'}), 400
        if side_str not in ['BUY', 'SELL']:
            return jsonify({'error': 'side must be BUY or SELL'}), 400
        
        side = OrderSide.BUY if side_str == 'BUY' else OrderSide.SELL
        order_type_str = data.get('order_type', 'MARKET').upper()
        order_type = OrderType.MARKET if order_type_str == 'MARKET' else OrderType.LIMIT
        limit_price = data.get('limit_price')
        
        # Create order
        order = Order(
            symbol=symbol,
            side=side,
            quantity=quantity,
            order_type=order_type,
            limit_price=float(limit_price) if limit_price else None,
            metadata={'reason': data.get('reason', 'Manual order')}
        )
        
        # Execute order
        adapter = get_user_adapter(user_id)
        result = adapter.place_order(order)
        
        return jsonify({
            'success': result.status.value != 'REJECTED',
            'order': {
                'broker_order_id': result.broker_order_id,
                'client_order_id': result.client_order_id,
                'symbol': result.symbol,
                'side': result.side.value,
                'quantity': result.quantity,
                'order_type': result.order_type.value,
                'limit_price': result.limit_price,
                'status': result.status.value,
                'filled_price': result.metadata.get('filled_price'),
                'filled_at': result.metadata.get('filled_at'),
                'metadata': result.metadata
            }
        }), 200 if result.status.value != 'REJECTED' else 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@paper_bp.route('/orders/<order_id>/cancel', methods=['POST', 'OPTIONS'])
def cancel_order(order_id: str):
    """Cancel a paper trading order."""
    if request.method == 'OPTIONS':
        return '', 200
    
    user_id = request.json.get('user_id') or request.headers.get('X-User-ID')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400
    
    try:
        adapter = get_user_adapter(user_id)
        success = adapter.cancel_order(order_id)
        
        if success:
            return jsonify({'success': True, 'message': 'Order cancelled'}), 200
        else:
            return jsonify({'success': False, 'error': 'Order not found or cannot be cancelled'}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@paper_bp.route('/portfolio', methods=['GET', 'OPTIONS'])
def get_portfolio():
    """Get complete portfolio summary."""
    if request.method == 'OPTIONS':
        return '', 200
    
    user_id = request.args.get('user_id') or request.headers.get('X-User-ID')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400
    
    try:
        adapter = get_user_adapter(user_id)
        balance = adapter.get_balance()
        positions = adapter.get_positions()
        portfolio_value = adapter.get_portfolio_value()
        pnl = adapter.get_pnl()
        
        positions_list = []
        for symbol, pos in positions.items():
            positions_list.append({
                'symbol': pos.symbol,
                'quantity': pos.quantity,
                'avg_price': pos.avg_price,
                'current_price': pos.current_price,
                'unrealized_pnl': pos.unrealized_pnl,
                'side': pos.side.value,
                'opened_at': pos.opened_at
            })
        
        return jsonify({
            'success': True,
            'balance': balance,
            'portfolio_value': portfolio_value,
            'pnl': pnl,
            'positions': positions_list,
            'positions_count': len(positions_list),
            'currency': 'INR'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@paper_bp.route('/reset', methods=['POST', 'OPTIONS'])
def reset_portfolio():
    """Reset paper trading portfolio (for testing)."""
    if request.method == 'OPTIONS':
        return '', 200
    
    user_id = request.json.get('user_id') or request.headers.get('X-User-ID')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400
    
    try:
        # Reset adapter
        _user_adapters[user_id] = PaperBrokerAdapter(initial_balance=100000.0)
        
        return jsonify({
            'success': True,
            'message': 'Portfolio reset to initial balance'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

