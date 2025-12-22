import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/network_logo.dart';
import 'broker_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String? _selectedBroker;
  String _userName = "Loading...";
  String _userTier = "Loading...";
  String _userCapital = "Loading...";
  bool _isAdmin = false;
  bool _isLoading = true;

  final ThemeService _themeService = ThemeService.instance;

  final List<Map<String, dynamic>> _brokers = [
    {"name": "Kotak Neo", "status": "active", "code": "kotak_neo"},
    {"name": "HDFC Sky", "status": "active", "code": "hdfc_sky"},
    {"name": "ICICI Direct Breeze", "status": "premium", "code": "icici_breeze"},
    {"name": "Axis", "status": "upcoming", "code": "axis"},
    {"name": "NSE", "status": "upcoming", "code": "nse"},
    {"name": "BSE", "status": "upcoming", "code": "bse"},
    {"name": "Angel One", "status": "upcoming", "code": "angel_one"},
    {"name": "Choice Broking", "status": "upcoming", "code": "choice"},
    {"name": "MangalKeshav Securities", "status": "upcoming", "code": "mangal_keshav"},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _themeService.addListener(_onThemeChanged);
    _isDarkMode = _themeService.isDarkMode;
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {
      _isDarkMode = _themeService.isDarkMode;
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();
      final isAdmin = await AuthService.isAdminUser();

      // Mock user data - replace with actual API call
      setState(() {
        _userName = "Vikram Verma"; // Replace with actual user data
        _userTier = isAdmin ? "Admin" : "Gold Tier";
        _userCapital = isAdmin ? "Unlimited" : "₹15,00,000";
        _isAdmin = isAdmin ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userName = "User";
        _userTier = "Standard";
        _userCapital = "₹10,000";
        _isAdmin = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTheme() async {
    await _themeService.toggleTheme();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _navigateToBrokerSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BrokerSettingsScreen()),
    );
  }

  void _navigateToAdminPanel() {
    // TODO: Navigate to admin panel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Admin panel coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color gradientStart = _isDarkMode ? Color(0xFFCC7A00) : Color(0xFFFF9933);
    Color gradientEnd = _isDarkMode ? Color(0xFFCCAC00) : Color(0xFFFFD700);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Settings"),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Card
          _buildSectionCard(
            title: "Profile",
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                  // TODO: Replace with actual user profile image
                  // backgroundImage: CachedNetworkImageProvider(userProfileImageUrl),
                ),
                SizedBox(height: 16),
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headline6?.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "$_userTier • $_userCapital Capital",
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyText2?.color,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Broker Settings
          _buildSectionCard(
            title: "Broker Settings",
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            child: Column(
              children: [
                ListTile(
                  leading: NetworkLogo(providerName: "Kotak Neo", size: 30), // Current broker
                  title: Text("Current Broker: Kotak Neo"),
                  subtitle: Text("Active • Connected"),
                  trailing: Icon(Icons.chevron_right),
                  onTap: _navigateToBrokerSettings,
                ),
                Divider(),
                ..._brokers.where((b) => b["status"] == "active").take(2).map((broker) => ListTile(
                  leading: NetworkLogo(providerName: broker["name"], size: 24),
                  title: Text(broker["name"]),
                  subtitle: Text("Available"),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                )),
                ListTile(
                  title: Text(
                    "Configure Brokers",
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(Icons.settings, color: Theme.of(context).primaryColor),
                  onTap: _navigateToBrokerSettings,
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Bank Account Settings
          _buildSectionCard(
            title: "Bank Account",
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            child: ListTile(
              leading: Icon(Icons.account_balance, color: Theme.of(context).primaryColor),
              title: Text("Savings Account"),
              subtitle: Text("HDFC • ****1234"),
              trailing: Icon(Icons.chevron_right),
              onTap: _navigateToBrokerSettings,
            ),
          ),

          SizedBox(height: 24),

          // Appearance Settings
          _buildSectionCard(
            title: "Appearance",
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            child: SwitchListTile(
              title: Text("Dark Mode"),
              subtitle: Text("Toggle between light and dark themes"),
              value: _isDarkMode,
              onChanged: (val) async {
                await _toggleTheme();
              },
              secondary: Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          SizedBox(height: 24),

          // Notifications Settings
          _buildSectionCard(
            title: "Notifications",
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text("Trade Alerts"),
                  subtitle: Text("Get notified when trades execute"),
                  value: true, // TODO: Load from preferences
                  onChanged: (val) {
                    // TODO: Save preference
                  },
                  secondary: Icon(Icons.notifications_active),
                ),
                SwitchListTile(
                  title: Text("Market Signals"),
                  subtitle: Text("Receive market prediction alerts"),
                  value: true, // TODO: Load from preferences
                  onChanged: (val) {
                    // TODO: Save preference
                  },
                  secondary: Icon(Icons.trending_up),
                ),
                SwitchListTile(
                  title: Text("Settlement Updates"),
                  subtitle: Text("Notifications for profit distributions"),
                  value: true, // TODO: Load from preferences
                  onChanged: (val) {
                    // TODO: Save preference
                  },
                  secondary: Icon(Icons.account_balance_wallet),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Security Settings
          _buildSectionCard(
            title: "Security",
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                  title: Text("Change Password"),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to password change
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Password change coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.security, color: Theme.of(context).primaryColor),
                  title: Text("Two-Factor Authentication"),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to 2FA setup
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('2FA setup coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Admin Panel (Hidden unless admin)
          if (_isAdmin) ...[
            _buildSectionCard(
              title: "Administration",
              gradientStart: gradientStart,
              gradientEnd: gradientEnd,
              child: ListTile(
                leading: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.purple,
                ),
                title: Text("Admin Panel"),
                subtitle: Text("Advanced system controls"),
                trailing: Icon(Icons.chevron_right),
                onTap: _navigateToAdminPanel,
              ),
            ),
            SizedBox(height: 24),
          ],

          // Help & Support
          _buildSectionCard(
            title: "Help & Support",
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
                  title: Text("FAQ"),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Open FAQ
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('FAQ coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.contact_support, color: Theme.of(context).primaryColor),
                  title: Text("Contact Support"),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Open support
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Support chat coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                  title: Text("About AurumHarmony"),
                  subtitle: Text("Version 1.0 Beta"),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'AurumHarmony',
                      applicationVersion: '1.0 Beta',
                      applicationLegalese: '© 2025 AurumHarmony. All rights reserved.',
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Logout Button
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color gradientStart,
    required Color gradientEnd,
    required Widget child,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradientStart.withOpacity(0.2),
              gradientEnd.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headline6?.color,
              ),
            ),
            SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
