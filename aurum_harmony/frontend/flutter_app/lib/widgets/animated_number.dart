import 'package:flutter/material.dart';

/// Animated number widget with smooth transitions
class AnimatedNumber extends ImplicitlyAnimatedWidget {
  final double value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final int fractionDigits;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix,
    this.fractionDigits = 2,
    super.duration = const Duration(milliseconds: 500),
    super.curve = Curves.easeOutCubic,
  });

  @override
  ImplicitlyAnimatedWidgetState<AnimatedNumber> createState() =>
      _AnimatedNumberState();
}

class _AnimatedNumberState
    extends ImplicitlyAnimatedWidgetState<AnimatedNumber> {
  Tween<double>? _valueTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _valueTween = visitor(
      _valueTween,
      widget.value,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final animatedValue = _valueTween?.evaluate(animation) ?? widget.value;
    final formattedValue = animatedValue.toStringAsFixed(widget.fractionDigits);
    
    return Text(
      '${widget.prefix ?? ''}$formattedValue${widget.suffix ?? ''}',
      style: widget.style,
    );
  }
}

