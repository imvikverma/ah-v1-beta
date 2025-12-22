import 'package:flutter/material.dart';

/// Compact metric tile used for backtest / paper trading stats.
///
/// Transparent borders + soft fill so it sits nicely on dark or light
/// backgrounds and can be arranged in a responsive grid.
class MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final Color? accentColor;
  final IconData? icon;

  const MetricBox({
    super.key,
    required this.label,
    required this.value,
    this.caption = '',
    this.accentColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = accentColor ?? colors.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.onSurface.withOpacity(0.18),
          width: 1,
        ),
        color: colors.surface.withOpacity(0.05),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              caption,
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


