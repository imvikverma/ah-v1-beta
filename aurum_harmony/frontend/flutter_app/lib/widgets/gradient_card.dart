import 'package:flutter/material.dart';

/// Simple reusable gradient card used by the redesign plan.
///
/// This is a non-breaking enhancement: it is not wired anywhere yet.
/// We can incrementally adopt it on Dashboard / Reports / Admin.
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry borderRadius;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final double elevation;

  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.elevation = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final gradientColors = colors ??
        [
          scheme.primary.withOpacity(0.25),
          scheme.secondary.withOpacity(0.12),
        ];

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: elevation,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: gradientColors,
            ),
          ),
          child: Container(
            padding: padding,
            // subtle overlay for readability
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.05),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}


