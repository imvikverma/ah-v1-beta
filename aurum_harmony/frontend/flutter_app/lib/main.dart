import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/trade_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/admin_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'widgets/api_key_dialog.dart';

/// AurumHarmony v1.0 Beta Flutter Frontend
///
/// A comprehensive trading dashboard with:
/// - Dashboard: Account summary, backend status, system overview
/// - Trade: Strategy controls, open positions, manual overrides
/// - Reports: Trade history, performance charts, backtesting
/// - Notifications: Alerts feed with filtering
/// - Admin: User management (admin-only)

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
  bool _isLoggedIn = false;
  bool _checkingAuth = true;
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _checkAuth() async {
    final loggedIn = await AuthService.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _checkingAuth = false;
    });
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    setState(() {
      _isLoggedIn = false;
      _index = 0;
    });
  }

  Future<void> _showApiKeyDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const ApiKeyDialog(),
    );
    if (result == true) {
      // Credentials updated, refresh if needed
    }
  }

  Future<void> _toggleTheme() async {
    await _themeService.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeService.getLightTheme();
    final darkTheme = ThemeService.getDarkTheme();

    if (_checkingAuth) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: _themeService.themeMode,
        home: Scaffold(
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_isLoggedIn) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AurumHarmony v1.0 Beta',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: _themeService.themeMode,
        home: Builder(
          builder: (context) => LoginScreen(
            onLoginSuccess: () {
              setState(() {
                _isLoggedIn = true;
              });
            },
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AurumHarmony v1.0 Beta',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeService.themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AurumHarmony v1.0 Beta'),
          actions: [
            // Theme Toggle
            IconButton(
              icon: Icon(
                _themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              tooltip: _themeService.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: _toggleTheme,
            ),
            // API Key Management
            IconButton(
              icon: const Icon(Icons.vpn_key),
              tooltip: 'Manage API Keys',
              onPressed: _showApiKeyDialog,
            ),
            // Connection status indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Logout
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _handleLogout,
            ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: const [
              DashboardScreen(),
              TradeScreen(),
              ReportsScreen(),
              NotificationsScreen(),
              AdminScreen(),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Trade',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Alerts',
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
