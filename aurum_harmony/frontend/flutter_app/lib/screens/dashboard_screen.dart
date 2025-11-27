import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/auth_service.dart';
import '../widgets/account_balance_card.dart';
import '../widgets/api_key_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _status = 'Loading…';
  int _time = 0;
  bool _isError = false;
  Map<String, dynamic>? _userReport;
  bool _loadingReport = false;
  String? _userId;

  // Account balances (placeholder - will be fetched from backend in production)
  double _dematOpening = 100000.0;
  double _dematCurrent = 100000.0;
  double _dematClosing = 0.0;
  double _savingsOpening = 50000.0;
  double _savingsCurrent = 50000.0;
  double _savingsClosing = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _load();
    _loadUserReport('user001');
    _startBalanceUpdates();
  }

  Future<void> _loadUserId() async {
    final userId = await AuthService.getUserId();
    setState(() {
      _userId = userId;
    });
    if (userId != null) {
      _loadUserReport(userId);
    }
  }

  void _startBalanceUpdates() {
    // Simulate live balance updates during trading hours
    // In production, this would be a WebSocket or polling connection
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          // Simulate small changes during trading
          _dematCurrent = _dematOpening + (DateTime.now().millisecond % 1000) - 500;
          _savingsCurrent = _savingsOpening + (DateTime.now().millisecond % 500) - 250;
        });
        _startBalanceUpdates();
      }
    });
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isError = false;
      });
      final resp = await http.get(Uri.parse('$kBackendBaseUrl/health'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _status = data['status']?.toString() ?? 'OK';
          _time = (data['time'] as num?)?.toInt() ?? 0;
          _isError = false;
        });
      } else {
        setState(() {
          _status = 'Error ${resp.statusCode}';
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isError = true;
      });
    }
  }

  Future<void> _loadUserReport(String userId) async {
    setState(() {
      _loadingReport = true;
    });
    try {
      final resp = await http.get(
        Uri.parse('$kBackendBaseUrl/report/user/$userId'),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _userReport = data;
        });
      }
    } catch (e) {
      // Silently fail - report is optional
    } finally {
      setState(() {
        _loadingReport = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async {
        await _load();
        await _loadUserReport('user001');
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Backend Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isError ? Icons.error_outline : Icons.check_circle,
                        color: _isError ? Colors.redAccent : colors.secondary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Backend Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.vpn_key, size: 20),
                        tooltip: 'Manage API Keys',
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => const ApiKeyDialog(),
                          );
                        },
                      ),
                      if (_time > 0)
                        Text(
                          '${DateTime.fromMillisecondsSinceEpoch(_time * 1000).toString().substring(11, 19)}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      color: _isError ? Colors.redAccent : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Account Summary Card
          if (_userReport != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Capital',
                          '₹${_userReport!['capital'] ?? '0'}',
                          Icons.account_balance_wallet,
                        ),
                        _buildStatColumn(
                          'P&L',
                          '₹${_userReport!['pnl'] ?? '0'}',
                          Icons.trending_up,
                          color: (_userReport!['pnl'] as num? ?? 0) >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                        _buildStatColumn(
                          'Trades',
                          '${_userReport!['total_trades'] ?? 0}',
                          Icons.swap_horiz,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else if (_loadingReport)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          const SizedBox(height: 16),

          // Account Balances Section
          Row(
            children: [
              Expanded(
                child: AccountBalanceCard(
                  accountType: 'Demat',
                  openingBalance: _dematOpening,
                  currentBalance: _dematCurrent,
                  closingBalance: _dematClosing,
                  icon: Icons.account_balance,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AccountBalanceCard(
                  accountType: 'Savings',
                  openingBalance: _savingsOpening,
                  currentBalance: _savingsCurrent,
                  closingBalance: _savingsClosing,
                  icon: Icons.savings,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // System Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'System Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'AurumHarmony v1.0 Beta\n'
                    'Trading Mode: PAPER\n'
                    'Orchestrator: Idle\n\n'
                    'Future versions will show:\n'
                    '• Real-time P&L charts\n'
                    '• Risk usage vs limits\n'
                    '• Recent trades feed\n'
                    '• VIX-adjusted capacity',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white70, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}

