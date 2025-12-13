import 'package:flutter/material.dart';

/// AurumHarmony Color Scheme
/// Saffron/Gold themed colors for light and dark modes
class AurumColors {
  // Primary Saffron/Gold Gradients
  static const Color saffronLight = Color(0xFFFF9933); // #FF9933
  static const Color saffronDark = Color(0xFFCC7A00); // #CC7A00
  static const Color goldLight = Color(0xFFFFD700); // #FFD700
  static const Color goldDark = Color(0xFFCCAC00); // #CCAC00
  
  // Background Colors
  static const Color lightBackground = Color(0xFFFFFFFF); // White
  static const Color darkBackground = Color(0xFF121212); // #121212
  
  // Surface Colors
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color darkSurface = Color(0xFF1E1E1E);
  
  // Accent Colors
  static const Color accentBlue = Color(0xFF3498db);
  static const Color accentPurple = Color(0xFF9b59b6);
  static const Color accentGreen = Color(0xFF2ecc71);
  static const Color accentRed = Color(0xFFe74c3c);
  static const Color accentOrange = Color(0xFFf39c12);
  
  // Text Colors
  static const Color lightText = Color(0xFF212121);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  
  // Gradient Definitions
  static const LinearGradient saffronGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [saffronLight, goldLight],
  );
  
  static const LinearGradient darkSaffronGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [saffronDark, goldDark],
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, accentPurple],
  );
  
  // Success/Error/Warning Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);
  
  // Chart Colors (Saffron variants)
  static const List<Color> chartColors = [
    saffronLight,
    goldLight,
    accentBlue,
    accentPurple,
    accentGreen,
    accentOrange,
  ];
  
  // Shadow Colors
  static Color lightShadow = Colors.black.withOpacity(0.1);
  static Color darkShadow = Colors.black.withOpacity(0.3);
  
  // Helper method to get gradient based on theme
  static LinearGradient getSaffronGradient(bool isDark) {
    return isDark ? darkSaffronGradient : saffronGradient;
  }
  
  // Helper to create a shimmer gradient for animations
  static LinearGradient getShimmerGradient(bool isDark) {
    final baseColor = isDark ? saffronDark : saffronLight;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.3),
        baseColor,
        baseColor.withOpacity(0.3),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }
}

