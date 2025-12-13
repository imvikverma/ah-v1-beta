import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'aurum_colors.dart';

class AurumTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: ColorScheme.light(
      primary: AurumColors.saffronLight,
      secondary: AurumColors.goldLight,
      tertiary: AurumColors.accentBlue,
      background: AurumColors.lightBackground,
      surface: AurumColors.lightSurface,
      error: AurumColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: AurumColors.lightText,
      onSurface: AurumColors.lightText,
      onError: Colors.white,
    ),
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AurumColors.lightBackground,
      foregroundColor: AurumColors.lightText,
      iconTheme: const IconThemeData(color: AurumColors.saffronLight),
      titleTextStyle: GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AurumColors.lightText,
      ),
    ),
    
    // Card Theme
    cardTheme: const CardThemeData(
      elevation: 4,
      shadowColor: AurumColors.lightShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AurumColors.lightSurface,
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AurumColors.saffronLight,
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AurumColors.accentBlue,
        side: const BorderSide(color: AurumColors.accentBlue, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AurumColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AurumColors.saffronLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AurumColors.saffronLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AurumColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      displayLarge: GoogleFonts.orbitron(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AurumColors.lightText,
      ),
      displayMedium: GoogleFonts.orbitron(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AurumColors.lightText,
      ),
      displaySmall: GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AurumColors.lightText,
      ),
      headlineLarge: GoogleFonts.orbitron(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AurumColors.lightText,
      ),
      headlineMedium: GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AurumColors.lightText,
      ),
      headlineSmall: GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AurumColors.lightText,
      ),
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        color: AurumColors.lightText,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        color: AurumColors.lightText,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        color: AurumColors.lightTextSecondary,
      ),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AurumColors.lightSurface,
      selectedItemColor: AurumColors.saffronLight,
      unselectedItemColor: AurumColors.lightTextSecondary,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
  
  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color Scheme
    colorScheme: ColorScheme.dark(
      primary: AurumColors.saffronDark,
      secondary: AurumColors.goldDark,
      tertiary: AurumColors.accentBlue,
      background: AurumColors.darkBackground,
      surface: AurumColors.darkSurface,
      error: AurumColors.error,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onBackground: AurumColors.darkText,
      onSurface: AurumColors.darkText,
      onError: Colors.white,
    ),
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AurumColors.darkBackground,
      foregroundColor: AurumColors.darkText,
      iconTheme: const IconThemeData(color: AurumColors.saffronDark),
      titleTextStyle: GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AurumColors.darkText,
      ),
    ),
    
    // Card Theme
    cardTheme: const CardThemeData(
      elevation: 4,
      shadowColor: AurumColors.darkShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AurumColors.darkSurface,
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AurumColors.saffronDark,
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AurumColors.accentBlue,
        side: const BorderSide(color: AurumColors.accentBlue, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AurumColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AurumColors.saffronDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AurumColors.saffronDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AurumColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      displayLarge: GoogleFonts.orbitron(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AurumColors.darkText,
      ),
      displayMedium: GoogleFonts.orbitron(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AurumColors.darkText,
      ),
      displaySmall: GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AurumColors.darkText,
      ),
      headlineLarge: GoogleFonts.orbitron(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AurumColors.darkText,
      ),
      headlineMedium: GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AurumColors.darkText,
      ),
      headlineSmall: GoogleFonts.orbitron(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AurumColors.darkText,
      ),
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        color: AurumColors.darkText,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        color: AurumColors.darkText,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        color: AurumColors.darkTextSecondary,
      ),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AurumColors.darkSurface,
      selectedItemColor: AurumColors.saffronDark,
      unselectedItemColor: AurumColors.darkTextSecondary,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}

