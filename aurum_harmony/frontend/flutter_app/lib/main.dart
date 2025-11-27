import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/trade_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/admin_screen.dart';

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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AurumHarmony v1.0 Beta',
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AurumHarmony v1.0 Beta'),
          actions: [
            // Connection status indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
