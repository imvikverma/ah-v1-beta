import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphism card widget with blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final double blurIntensity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = 16.0,
    this.blurIntensity = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? 
                 (isDark 
                   ? colors.primary.withOpacity(0.3)
                   : colors.primary.withOpacity(0.2)),
          width: borderWidth,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colors.surface.withOpacity(0.3),
                  colors.surfaceVariant.withOpacity(0.2),
                ]
              : [
                  colors.surface.withOpacity(0.6),
                  colors.surfaceVariant.withOpacity(0.4),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? colors.primary.withOpacity(0.1)
                : colors.primary.withOpacity(0.05),
            blurRadius: blurIntensity,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

