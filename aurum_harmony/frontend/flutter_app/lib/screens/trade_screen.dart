import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/paper_trading_service.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  List<Map<String, dynamic>> _positions = [];
  bool _loading = false;
  String? _error;
  bool _isAdmin = false;
  bool _indemnityAccepted = false;
  String? _userId;
  bool _paperTradingEnabled = true; // Default to paper trading

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _checkPermissions();
    _loadPositions();
  }

  Future<void> _loadUserId() async {
    final userId = await AuthService.getUserId();
    setState(() {
      _userId = userId;
    });
  }

  Future<void> _checkPermissions() async {
    final isAdmin = await AuthService.isAdmin();
    final indemnityAccepted = await AuthService.hasAcceptedIndemnity();
    setState(() {
      _isAdmin = isAdmin;
      _indemnityAccepted = indemnityAccepted;
    });
  }

  Future<void> _loadPositions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      if (_paperTradingEnabled && _userId != null) {
        // Load from paper trading API
        final result = await PaperTradingService.getPositions(_userId!);
        if (result['success'] == true) {
          final positions = (result['positions'] as List?) ?? [];
          setState(() {
            _positions = positions.cast<Map<String, dynamic>>();
            _loading = false;
          });
        } else {
          setState(() {
            _positions = [];
            _loading = false;
          });
        }
      } else {
        // TODO: Load from live broker API when available
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _positions = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load positions: $e';
        _loading = false;
      });
    }
  }

  Future<void> _showIndemnityDialog() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('Financial Risk Warning')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'IMPORTANT: HIGH RISK TRADING CONTROLS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You are about to access advanced trading controls that can result in significant financial losses. By proceeding, you acknowledge and agree to the following:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text('1. Trading involves substantial risk of loss and is not suitable for all investors.'),
              const SizedBox(height: 8),
              const Text('2. Past performance is not indicative of future results.'),
              const SizedBox(height: 8),
              const Text('3. You are solely responsible for all trading decisions and their consequences.'),
              const SizedBox(height: 8),
              const Text('4. AurumHarmony and its operators are not liable for any losses incurred.'),
              const SizedBox(height: 8),
              const Text('5. You have the necessary knowledge and experience to use these controls.'),
              const SizedBox(height: 16),
              const Text(
                'This feature requires elevated credentials and is intended for experienced traders only.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('I Accept the Risks'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      await AuthService.acceptIndemnity();
      setState(() {
        _indemnityAccepted = true;
      });
    }
  }

  Future<void> _runPrediction() async {
    // Check admin access
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied: Admin credentials required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check indemnity
    if (!_indemnityAccepted) {
      await _showIndemnityDialog();
      if (!_indemnityAccepted) {
        return; // User declined indemnity
      }
    }

    setState(() {
      _loading = true;
    });
    try {
      final token = await AuthService.getValidToken();
      final resp = await http.post(
        Uri.parse('$kBackendBaseUrl/api/orchestrator/run'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': _userId,
          'auto_execute': true, // Automatically execute approved trades
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (mounted) {
          final ordersExecuted = data['orders_executed'] ?? 0;
          final signalsProcessed = data['signals_processed'] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Orchestrator run complete: $signalsProcessed signals processed, $ordersExecuted orders executed'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          // Reload positions to show new trades
          _loadPositions();
        }
      } else {
        final error = jsonDecode(resp.body) as Map<String, dynamic>;
        throw Exception(error['error']?.toString() ?? 'Orchestrator run failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _loadPositions,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Strategy Controls Card (Admin Only)
          if (_isAdmin) ...[
            Card(
              color: colors.surfaceVariant.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: colors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Strategy Controls',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (!_indemnityAccepted)
                          Chip(
                            label: const Text('Indemnity Required'),
                            backgroundColor: Colors.orange.withOpacity(0.3),
                            labelStyle: const TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _runPrediction,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Run Prediction'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _indemnityAccepted
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Pause All Trading'),
                                      ),
                                    );
                                  }
                                : () => _showIndemnityDialog(),
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause All'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _indemnityAccepted
                          ? 'Handsfree trading is controlled by the backend orchestrator.\n'
                              'Use these controls for manual overrides.'
                          : '⚠️ You must accept the indemnity agreement to use these controls.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _indemnityAccepted
                            ? colors.onSurface.withOpacity(0.7)
                            : Colors.orange,
                        fontWeight: _indemnityAccepted ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Hidden for non-admin users - show nothing or a placeholder
            Card(
              color: colors.surfaceVariant.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: colors.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Advanced trading controls are restricted to authorized personnel only.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Paper Trading Toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    _paperTradingEnabled ? Icons.science : Icons.account_balance_wallet,
                    color: _paperTradingEnabled ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _paperTradingEnabled ? 'Paper Trading Mode' : 'Live Trading Mode',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _paperTradingEnabled
                              ? 'Simulated trading with virtual funds'
                              : 'Real money trading (requires broker connection)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _paperTradingEnabled,
                    onChanged: (value) {
                      setState(() {
                        _paperTradingEnabled = value;
                      });
                      _loadPositions();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Paper Trading Status (Automatic - no manual orders)
          if (_paperTradingEnabled)
            Card(
              color: colors.surfaceVariant.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: colors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Paper Trading (Automatic)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trades are executed automatically by the orchestrator based on AI predictions. No manual intervention required.',
                      style: TextStyle(
                        color: colors.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Open Positions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Open Positions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_positions.length}',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    )
                  else if (_positions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No open positions',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Positions will appear here when trades are executed.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._positions.map((pos) => _buildPositionTile(pos)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Manual Override Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manual Override',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Close All Positions'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Close All Positions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionTile(Map<String, dynamic> pos) {
    final unrealizedPnl = (pos['unrealized_pnl'] as num?)?.toDouble() ?? 0.0;
    final isProfit = unrealizedPnl >= 0;
    final symbol = pos['symbol'] as String? ?? 'N/A';
    final quantity = (pos['quantity'] as num?)?.toDouble() ?? 0.0;
    final avgPrice = (pos['avg_price'] as num?)?.toDouble() ?? 0.0;
    final currentPrice = (pos['current_price'] as num?)?.toDouble() ?? 0.0;
    final side = pos['side'] as String? ?? 'BUY';
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isProfit
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        child: Icon(
          isProfit ? Icons.trending_up : Icons.trending_down,
          color: isProfit ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
      title: Text(
        symbol,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$side • Qty: ${quantity.abs().toStringAsFixed(0)} • Avg: ₹${avgPrice.toStringAsFixed(2)}\nCurrent: ₹${currentPrice.toStringAsFixed(2)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${unrealizedPnl.toStringAsFixed(2)}',
            style: TextStyle(
              color: isProfit ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (_paperTradingEnabled && _userId != null)
            TextButton(
              onPressed: () => _closePosition(symbol),
              child: const Text('Close', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<void> _showPlaceOrderDialog() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final symbolController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    String selectedSide = 'BUY';
    String selectedOrderType = 'MARKET';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Place Paper Trading Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: symbolController,
                  decoration: const InputDecoration(
                    labelText: 'Symbol',
                    hintText: 'e.g., NIFTY, RELIANCE',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSide,
                  decoration: const InputDecoration(labelText: 'Side'),
                  items: const [
                    DropdownMenuItem(value: 'BUY', child: Text('BUY')),
                    DropdownMenuItem(value: 'SELL', child: Text('SELL')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedSide = value ?? 'BUY';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: '1',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedOrderType,
                  decoration: const InputDecoration(labelText: 'Order Type'),
                  items: const [
                    DropdownMenuItem(value: 'MARKET', child: Text('MARKET')),
                    DropdownMenuItem(value: 'LIMIT', child: Text('LIMIT')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedOrderType = value ?? 'MARKET';
                    });
                  },
                ),
                if (selectedOrderType == 'LIMIT') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Limit Price',
                      hintText: '0.00',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Place Order'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final quantity = double.tryParse(quantityController.text) ?? 0.0;
        final limitPrice = selectedOrderType == 'LIMIT'
            ? double.tryParse(priceController.text)
            : null;

        if (quantity <= 0) {
          throw Exception('Quantity must be positive');
        }

        if (selectedOrderType == 'LIMIT' && (limitPrice == null || limitPrice <= 0)) {
          throw Exception('Limit price is required for LIMIT orders');
        }

        setState(() {
          _loading = true;
        });

        final orderResult = await PaperTradingService.placeOrder(
          userId: _userId!,
          symbol: symbolController.text.trim().toUpperCase(),
          side: selectedSide,
          quantity: quantity,
          orderType: selectedOrderType,
          limitPrice: limitPrice,
          reason: 'Manual order from app',
        );

        if (mounted) {
          if (orderResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order placed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            _loadPositions();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText(orderResult['error']?.toString() ?? 'Order failed'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 30), // Extended duration for copying
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: SelectableText('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 30), // Extended duration for copying
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    }
  }

  Future<void> _closePosition(String symbol) async {
    if (_userId == null) return;

    // For paper trading, place a SELL order to close
    try {
      // Get position details
      final positions = await PaperTradingService.getPositions(_userId!);
      if (positions['success'] == true) {
        final posList = (positions['positions'] as List?) ?? [];
        final position = posList.firstWhere(
          (p) => (p['symbol'] as String?) == symbol,
          orElse: () => null,
        );

        if (position != null) {
          final quantity = (position['quantity'] as num?)?.toDouble() ?? 0.0;
          if (quantity > 0) {
            // Close long position
            await PaperTradingService.placeOrder(
              userId: _userId!,
              symbol: symbol,
              side: 'SELL',
              quantity: quantity,
              orderType: 'MARKET',
              reason: 'Close position',
            );
            _loadPositions();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error closing position: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

