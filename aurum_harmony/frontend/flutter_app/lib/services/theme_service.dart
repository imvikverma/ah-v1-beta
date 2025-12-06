import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Service for managing Light and Dark modes
/// Persists theme preference and provides theme data
/// Singleton pattern to ensure all widgets use the same instance
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark;
  
  // Singleton instance
  static ThemeService? _instance;
  
  /// Get the singleton instance
  static ThemeService get instance {
    _instance ??= ThemeService._internal();
    return _instance!;
  }
  
  // Private constructor for singleton
  ThemeService._internal() {
    _loadTheme();
  }
  
  // Public constructor that returns the singleton
  factory ThemeService() => instance;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Load saved theme preference
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => ThemeMode.dark,
        );
        notifyListeners();
      }
    } catch (e) {
      // Default to dark mode on error
      _themeMode = ThemeMode.dark;
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _saveTheme();
    notifyListeners();
  }

  /// Set theme mode explicitly
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveTheme();
      notifyListeners();
    }
  }

  /// Save theme preference
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeMode.toString());
    } catch (e) {
      // Silently fail - theme will reset on next app start
    }
  }

  /// Get light theme
  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xfff9a826), // Saffron/Gold
        secondary: Color(0xff4caf50), // Green
        tertiary: Color(0xff2196f3), // Blue
        surface: Color(0xffffffff),
        surfaceVariant: Color(0xfff5f5f5),
        background: Color(0xfffafafa),
        error: Color(0xffd32f2f),
        onPrimary: Color(0xffffffff),
        onSecondary: Color(0xffffffff),
        onSurface: Color(0xff212121),
        onBackground: Color(0xff212121),
      ),
      scaffoldBackgroundColor: const Color(0xfffafafa),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xffffffff),
        foregroundColor: Color(0xff212121),
        elevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xff212121)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xfff5f5f5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffe0e0e0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffe0e0e0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xfff9a826), width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xffffffff),
        selectedItemColor: Color(0xfff9a826),
        unselectedItemColor: Color(0xff757575),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Get dark theme
  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xfff9a826), // Saffron/Gold
        secondary: Color(0xff4caf50), // Green
        tertiary: Color(0xff2196f3), // Blue
        surface: Color(0xff11172b),
        surfaceVariant: Color(0xff1a1f35),
        background: Color(0xff050816),
        error: Color(0xffef5350),
        onPrimary: Color(0xff212121),
        onSecondary: Color(0xff212121),
        onSurface: Color(0xffffffff),
        onBackground: Color(0xffffffff),
      ),
      scaffoldBackgroundColor: const Color(0xff050816),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff050816),
        foregroundColor: Color(0xffffffff),
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xffffffff)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xff11172b),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xff11172b),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xff1a1f35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xff1a1f35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xfff9a826), width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xff050816),
        selectedItemColor: Color(0xfff9a826),
        unselectedItemColor: Color(0xff757575),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

