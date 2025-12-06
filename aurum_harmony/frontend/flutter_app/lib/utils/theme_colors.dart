import 'package:flutter/material.dart';

/// Helper utilities for theme-aware colors
/// Provides semantic color mappings that adapt to light/dark mode
class ThemeColors {
  /// Get success/green color based on theme
  static Color success(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return colors.secondary; // Green
  }

  /// Get error/red color based on theme
  static Color error(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return colors.error;
  }

  /// Get info/blue color based on theme
  static Color info(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return colors.tertiary; // Blue
  }

  /// Get warning/orange color based on theme
  static Color warning(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return colors.primary; // Saffron/Gold
  }

  /// Get text color for primary content
  static Color textPrimary(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return colors.onSurface;
  }

  /// Get text color for secondary content
  static Color textSecondary(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return colors.onSurface.withOpacity(0.7);
  }

  /// Get text color for tertiary/disabled content
  static Color textTertiary(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return colors.onSurface.withOpacity(0.5);
  }

  /// Get background color for cards/surfaces
  static Color surface(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return colors.surface;
  }

  /// Get background color for elevated surfaces
  static Color surfaceVariant(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return colors.surfaceVariant;
  }

  /// Get divider color
  static Color divider(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return colors.onSurface.withOpacity(0.12);
  }
}

