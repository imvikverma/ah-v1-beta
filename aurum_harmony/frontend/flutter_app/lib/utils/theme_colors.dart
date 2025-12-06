import 'package:flutter/material.dart';

class ThemeColors {
  static Color success(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  static Color error(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  static Color warning(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color info(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withOpacity(0.7);
  }

  static Color primaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color secondaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
  }

  static Color tertiaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color background(BuildContext context) {
    return Theme.of(context).colorScheme.background;
  }
}

