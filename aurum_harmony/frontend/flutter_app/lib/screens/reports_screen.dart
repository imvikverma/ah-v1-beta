import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/auth_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _userReport;
  Map<String, dynamic>? _backtestResult;
  bool _loading = false;
  String? _error;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await AuthService.getUserId();
    setState(() {
      _selectedUserId = userId;
    });
    if (_selectedUserId != null) {
      _loadUserReport();
    } else {
      setState(() {
        _error = 'Please login to view reports';
      });
    }
  }

  Future<void> _loadUserReport() async {
    if (_selectedUserId == null) {
      setState(() {
        _error = 'User ID not available';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }
      
      final resp = await http.get(
        Uri.parse('$kBackendBaseUrl/report/user/$_selectedUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _userReport = data;
        });
      } else if (resp.statusCode == 401) {
        setState(() {
          _error = 'Authentication expired. Please login again.';
        });
      } else {
        final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _error = errorData['error']?.toString() ?? 'Error ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _runBacktest(String type) async {
    setState(() {
      _loading = true;
      _backtestResult = null;
    });
    try {
      final token = await AuthService.getValidToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }
      
      final endpoint = type == 'realistic'
          ? '/backtest/realistic'
          : '/backtest/edge';
      final resp = await http.get(
        Uri.parse('$kBackendBaseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _backtestResult = {
            'type': type,
            ...data,
          };
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$type backtest completed successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (resp.statusCode == 401) {
        throw Exception('Authentication expired. Please login again.');
      } else {
        final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
        throw Exception(errorData['error']?.toString() ?? 'Backtest failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText('Backtest error: $e'),
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
      onRefresh: _loadUserReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Report Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Trade History & Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () {
                          // TODO: Show filter dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Filter by date, symbol, strategy'),
                            ),
                          );
                        },
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
                  else if (_userReport != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReportRow('User ID', _userReport!['user_id']?.toString() ?? _selectedUserId ?? 'N/A'),
                        _buildReportRow('Total Trades', '${_userReport!['total_trades'] ?? 0}'),
                        if (_userReport!['capital'] != null)
                          _buildReportRow('Capital', '₹${_userReport!['capital']}'),
                        if (_userReport!['net_profit'] != null)
                          _buildReportRow('Net P&L', '₹${_userReport!['net_profit']}',
                              color: (_userReport!['net_profit'] as num? ?? 0) >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent),
                        if (_userReport!['pnl'] != null)
                          _buildReportRow('P&L', '₹${_userReport!['pnl']}',
                              color: (_userReport!['pnl'] as num? ?? 0) >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent),
                        if (_userReport!['win_rate'] != null)
                          _buildReportRow('Win Rate', '${((_userReport!['win_rate'] as num? ?? 0) * 100).toStringAsFixed(1)}%'),
                        if (_userReport!['wins'] != null && _userReport!['losses'] != null)
                          _buildReportRow('Wins / Losses', '${_userReport!['wins']} / ${_userReport!['losses']}'),
                        if (_userReport!['gross_profit'] != null)
                          _buildReportRow('Gross Profit', '₹${_userReport!['gross_profit']}', color: Colors.greenAccent),
                        if (_userReport!['gross_loss'] != null)
                          _buildReportRow('Gross Loss', '₹${_userReport!['gross_loss']}', color: Colors.redAccent),
                      ],
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No report data available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Performance Charts Placeholder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Charts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Equity Curve & Drawdown Charts',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Coming in v1.1',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backtesting Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backtesting',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _runBacktest('realistic'),
                          icon: const Icon(Icons.science),
                          label: const Text('Realistic Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading
                              ? null
                              : () => _runBacktest('edge'),
                          icon: const Icon(Icons.warning),
                          label: const Text('Edge Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.secondary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_backtestResult != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Backtest Results (${_backtestResult!['type'] ?? 'unknown'}):',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_backtestResult!['result'] != null) ...[
                      _buildReportRow('Total Trades', '${_backtestResult!['result']['total_trades'] ?? 0}'),
                      _buildReportRow('Win Rate', '${(_backtestResult!['result']['win_rate'] ?? 0).toStringAsFixed(1)}%'),
                      _buildReportRow('Total P&L', '₹${(_backtestResult!['result']['total_pnl'] ?? 0).toStringAsFixed(2)}',
                          color: (_backtestResult!['result']['total_pnl'] as num? ?? 0) >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent),
                      _buildReportRow('Max Drawdown', '₹${(_backtestResult!['result']['max_drawdown'] ?? 0).toStringAsFixed(2)}',
                          color: Colors.orangeAccent),
                      _buildReportRow('Sharpe Ratio', '${(_backtestResult!['result']['sharpe_ratio'] ?? 0).toStringAsFixed(2)}'),
                      if (_backtestResult!['result']['message'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _backtestResult!['result']['message'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ] else
                      Text(
                        _backtestResult.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

