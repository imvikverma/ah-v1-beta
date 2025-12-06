import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadPositions();
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
    // TODO: Replace with actual /positions endpoint when available
    // For now, show placeholder
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _positions = [];
      _loading = false;
    });
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
      final resp = await http.post(
        Uri.parse('$kBackendBaseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'features': [1.0, 2.0, 3.0], // Placeholder
          'vix': 15.0,
          'capital': 10000,
          'peak': 10000,
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Prediction: ${data['prediction']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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
                                : _showIndemnityDialog,
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
    final pnl = (pos['pnl'] as num?) ?? 0.0;
    final isProfit = pnl >= 0;
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
        pos['symbol'] ?? 'N/A',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${pos['side'] ?? 'N/A'} • Qty: ${pos['quantity'] ?? 0} • Avg: ₹${pos['avg_price'] ?? '0'}',
      ),
      trailing: Text(
        '₹${pnl.toStringAsFixed(2)}',
        style: TextStyle(
          color: isProfit ? Colors.greenAccent : Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

