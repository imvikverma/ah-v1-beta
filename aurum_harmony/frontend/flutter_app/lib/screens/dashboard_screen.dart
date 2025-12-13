import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/paper_trading_service.dart';
import '../widgets/account_balance_card.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_number.dart';
import '../utils/theme_colors.dart';

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

  // Historic "sacred" dashboard elements
  double _liveCapital = 10000; // Live Capital (top bar)
  double _todayPnL = 0; // Today’s P&L
  int _tradesToday = 0;
  int _maxTrades = 180;
  String _activeIndex = 'NIFTY50'; // progressive unlock: NIFTY50 → BANKNIFTY → SENSEX
  double _vixLevel = 18; // for VIX Mood Ring
  // Removed: Next Increment not required

  // Account balances (placeholder - will be fetched from backend in production)
  double _dematOpening = 100000.0;
  double _dematCurrent = 100000.0;
  double _dematClosing = 0.0;
  double _savingsOpening = 50000.0;
  double _savingsCurrent = 50000.0;
  double _savingsClosing = 0.0;

  // Paper trading state
  bool _paperTradingEnabled = true; // Default to paper trading
  Map<String, dynamic>? _paperPortfolio;
  bool _loadingPaperPortfolio = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _load();
    _loadUserReport('user001');
    _startBalanceUpdates();
    // Delay portfolio loading to respect grace period after login
    // This prevents "Session expired" error immediately after login
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _loadPaperPortfolio();
      }
    });
  }

  Future<void> _loadUserId() async {
    final userId = await AuthService.getUserId();
    setState(() {
      _userId = userId;
    });
    if (userId != null) {
      _loadUserReport(userId);
      // Delay portfolio loading to respect grace period after login
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _loadPaperPortfolio();
        }
      });
    }
  }

  Future<void> _loadPaperPortfolio() async {
    if (_userId == null || !_paperTradingEnabled) return;
    
    setState(() {
      _loadingPaperPortfolio = true;
    });
    
    try {
      final portfolio = await PaperTradingService.getPortfolio(_userId!);
      setState(() {
        _paperPortfolio = portfolio;
        if (portfolio['success'] == true) {
          final balance = portfolio['balance'] as num? ?? 0.0;
          final portfolioValue = portfolio['portfolio_value'] as num? ?? 0.0;
          final pnl = portfolio['pnl'] as num? ?? 0.0;
          
          // Update live capital with paper trading balance
          _liveCapital = portfolioValue.toDouble();
          _todayPnL = pnl.toDouble();
          
          // Update positions count
          final positions = portfolio['positions'] as List? ?? [];
          _tradesToday = positions.length;
        }
      });
    } catch (e) {
      // Handle 501 (Not Implemented) gracefully - stop retrying
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('501') || errorStr.contains('not implemented')) {
        // Worker doesn't support paper trading yet - disable it silently
        setState(() {
          _paperTradingEnabled = false;
          _loadingPaperPortfolio = false;
        });
        return;
      }
      // Silently fail for other errors - paper trading is optional
      print('Paper trading error: $e');
    } finally {
      setState(() {
        _loadingPaperPortfolio = false;
      });
    }
  }

  void _startBalanceUpdates() {
    // Update paper trading portfolio periodically
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        if (_paperTradingEnabled && _userId != null) {
          _loadPaperPortfolio();
        } else {
          // Simulate small changes during trading (fallback)
          setState(() {
            _dematCurrent = _dematOpening + (DateTime.now().millisecond % 1000) - 500;
            _savingsCurrent = _savingsOpening + (DateTime.now().millisecond % 500) - 250;
          });
        }
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
        await _loadPaperPortfolio();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                            color: ThemeColors.textSecondary(context),
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
                      if (value && _userId != null) {
                        _loadPaperPortfolio();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 1. Top bar: Live Capital (huge saffron number) + Today P&L
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Capital',
                  style: TextStyle(
                    fontSize: 12,
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedNumber(
                  value: _liveCapital,
                  prefix: '₹',
                  fractionDigits: 0,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Today\'s P&L: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeColors.textSecondary(context),
                      ),
                    ),
                    Text(
                      '₹${_todayPnL.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _todayPnL >= 0
                            ? ThemeColors.success(context)
                            : ThemeColors.error(context),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _isError ? Icons.error_outline : Icons.check_circle,
                      size: 16,
                      color: _isError
                          ? ThemeColors.error(context)
                          : colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isError ? 'Backend Error' : 'Backend OK',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isError
                            ? ThemeColors.error(context)
                            : ThemeColors.textTertiary(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Active Indices + Trades Today / Max Trades
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Indices',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChip('NIFTY50', _activeIndex == 'NIFTY50'),
                      const SizedBox(width: 8),
                      _buildChip('BANKNIFTY', _activeIndex == 'BANKNIFTY'),
                      const SizedBox(width: 8),
                      _buildChip('SENSEX', _activeIndex == 'SENSEX'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trades Today',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_tradesToday / $_maxTrades',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // VIX Mood Ring (colour circle)
                      Column(
                        children: [
                          const Text(
                            'VIX Mood',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _vixColor(context, _vixLevel),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _vixLabel(_vixLevel),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Removed: Next Increment not required
          const SizedBox(height: 16),

          // 4. Paper Trading Portfolio or Demat + Savings account balances
          _paperTradingEnabled && _paperPortfolio != null && _paperPortfolio!['success'] == true
              ? _buildPaperTradingPortfolio(context)
              : Row(
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
                    const SizedBox(width: 12),
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
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.orange.withOpacity(0.2) : Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? Colors.orange : Colors.grey.shade700,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: active ? Colors.orange : Colors.white70,
        ),
      ),
    );
  }

  Color _vixColor(BuildContext context, double vix) {
    if (vix < 15) return ThemeColors.success(context);
    if (vix < 20) return ThemeColors.success(context).withOpacity(0.7);
    if (vix < 30) return ThemeColors.warning(context);
    return ThemeColors.error(context);
  }

  String _vixLabel(double vix) {
    if (vix < 15) return 'Calm';
    if (vix < 20) return 'Normal';
    if (vix < 30) return 'Anxious';
    return 'Volatile';
  }

  // Removed: _formatCountdown - Next Increment not required

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

  Widget _buildPaperTradingPortfolio(BuildContext context) {
    if (_paperPortfolio == null) return const SizedBox.shrink();
    
    final colors = Theme.of(context).colorScheme;
    final balance = (_paperPortfolio!['balance'] as num?)?.toDouble() ?? 0.0;
    final portfolioValue = (_paperPortfolio!['portfolio_value'] as num?)?.toDouble() ?? 0.0;
    final pnl = (_paperPortfolio!['pnl'] as num?)?.toDouble() ?? 0.0;
    final positions = (_paperPortfolio!['positions'] as List?) ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Portfolio Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Paper Trading Portfolio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total P&L',
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${pnl.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: pnl >= 0
                                  ? ThemeColors.success(context)
                                  : ThemeColors.error(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portfolio Value',
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${portfolioValue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Open Positions',
                            style: TextStyle(
                              fontSize: 12,
                              color: ThemeColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${positions.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Positions List
        if (positions.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Open Positions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...positions.map((pos) {
                    final symbol = pos['symbol'] as String? ?? '';
                    final quantity = (pos['quantity'] as num?)?.toDouble() ?? 0.0;
                    final avgPrice = (pos['avg_price'] as num?)?.toDouble() ?? 0.0;
                    final currentPrice = (pos['current_price'] as num?)?.toDouble() ?? 0.0;
                    final unrealizedPnl = (pos['unrealized_pnl'] as num?)?.toDouble() ?? 0.0;
                    final side = pos['side'] as String? ?? 'BUY';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  symbol,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$side ${quantity.abs().toStringAsFixed(0)} @ ₹${avgPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ThemeColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${currentPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₹${unrealizedPnl.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: unrealizedPnl >= 0
                                      ? ThemeColors.success(context)
                                      : ThemeColors.error(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

