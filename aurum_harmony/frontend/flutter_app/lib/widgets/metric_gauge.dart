import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

/// Simple speedometer-style gauge for performance metrics like
/// win rate, profit factor, drawdown, etc.
class MetricGauge extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Color? accentColor;

  const MetricGauge({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.unit = '',
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = accentColor ?? colors.primary;
    final clamped = value.clamp(min, max);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colors.surface.withOpacity(0.16),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 120,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: min,
                  maximum: max,
                  showTicks: false,
                  showLabels: false,
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.22,
                    thicknessUnit: GaugeSizeUnit.factor,
                    cornerStyle: CornerStyle.bothCurve,
                    color: colors.onSurface.withOpacity(0.18),
                  ),
                  ranges: <GaugeRange>[
                    GaugeRange(
                      startValue: min,
                      endValue: min + (max - min) * 0.4,
                      color: Colors.transparent,
                    ),
                    GaugeRange(
                      startValue: min + (max - min) * 0.4,
                      endValue: min + (max - min) * 0.7,
                      color: Colors.transparent,
                    ),
                    GaugeRange(
                      startValue: min + (max - min) * 0.7,
                      endValue: max,
                      color: Colors.transparent,
                    ),
                  ],
                  pointers: <GaugePointer>[
                    NeedlePointer(
                      value: clamped,
                      enableAnimation: true,
                      animationDuration: 900,
                      needleColor: accent,
                      needleLength: 0.7,
                      needleStartWidth: 2,
                      needleEndWidth: 8,
                      knobStyle: KnobStyle(
                        color: colors.surface.withOpacity(0.9),
                        borderColor: accent,
                        borderWidth: 3,
                        knobRadius: 0.08,
                      ),
                    ),
                    RangePointer(
                      value: clamped,
                      width: 0.22,
                      sizeUnit: GaugeSizeUnit.factor,
                      gradient: SweepGradient(
                        colors: [
                          accent.withOpacity(0.2),
                          accent.withOpacity(0.8),
                        ],
                      ),
                      cornerStyle: CornerStyle.bothCurve,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            unit.isNotEmpty
                                ? '${clamped.toStringAsFixed(1)}$unit'
                                : clamped.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      positionFactor: 0.1,
                      angle: 90,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


