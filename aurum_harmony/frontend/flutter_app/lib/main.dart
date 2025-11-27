import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/trade_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/admin_screen.dart';
import 'services/auth_service.dart';
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

  @override
  void initState() {
    super.initState();
    _checkAuth();
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

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xfff9a826), // Gold/Saffron
        secondary: Color(0xff4caf50), // Green
        surface: Color(0xff11172b),
      ),
      scaffoldBackgroundColor: const Color(0xff050816),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff050816),
        elevation: 0,
        centerTitle: false,
      ),
    );

    if (_checkingAuth) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          backgroundColor: const Color(0xff050816),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!_isLoggedIn) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AurumHarmony v1.0 Beta',
        theme: theme,
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
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AurumHarmony v1.0 Beta'),
          actions: [
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
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
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
