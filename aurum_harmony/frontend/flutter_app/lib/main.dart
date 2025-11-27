import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Simple Flutter frontend for AurumHarmony v1.0 Beta.
///
/// This is a thin client:
/// - Dashboard calls /health
/// - Admin list calls /admin/users

const String kBackendBaseUrl = 'http://localhost:5000';
const String kAdminBaseUrl = 'http://localhost:5001';

void main() {
  runApp(const AurumHarmonyApp());
}

class AurumHarmonyApp extends StatefulWidget {
  const AurumHarmonyApp({super.key});

  @override
  State<AurumHarmonyApp> createState() => _AurumHarmonyAppState();
}

class _AurumHarmonyAppState extends State<AurumHarmonyApp> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xfff9a826),
        secondary: Color(0xff4caf50),
        surface: Color(0xff11172b),
      ),
      scaffoldBackgroundColor: const Color(0xff050816),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff050816),
        elevation: 0,
        centerTitle: false,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AurumHarmony v1.0 Beta',
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AurumHarmony v1.0 Beta'),
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: const [
              DashboardScreen(),
              AdminScreen(),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xff050816),
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey,
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _status = 'Loading…';
  int _time = 0;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                        color:
                            _isError ? Colors.redAccent : colors.secondary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Backend status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_time > 0)
                        Text(
                          _time.toString(),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This is a minimal v1.0 Beta dashboard.\n'
                    'Future versions will show per‑user P&L, risk, and VIX‑adjusted capacity.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await http.get(Uri.parse('$kAdminBaseUrl/admin/users'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        setState(() {
          _users = data.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() {
          _error = 'Error ${resp.statusCode}';
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No users found.\nSeed users via the backend admin API.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final u = _users[index];
          return Card(
            child: ListTile(
              title: Text(
                u['user_id'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Tier: ${u['tier']} • Capital: ₹${u['capital']} • Max trades/day: ${u['max_trades']}',
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: (u['status'] == 'active'
                          ? Colors.green
                          : Colors.orange)
                      .withOpacity(0.15),
                  border: Border.all(
                    color: u['status'] == 'active'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ),
                child: Text(
                  (u['status'] ?? '').toString(),
                  style: TextStyle(
                    color: u['status'] == 'active'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


