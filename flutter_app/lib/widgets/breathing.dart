import 'dart:math';
import 'package:flutter/material.dart';

/// A very quiet idle scale oscillation for elements that should feel alive
/// when nothing is happening. Sine-driven, no opacity, no position.
///
/// Auto-starts on mount, auto-disposes. Disables on
/// `MediaQuery.disableAnimations`.
class Breathing extends StatefulWidget {
  final Widget child;
  final Duration period;

  /// Maximum scale delta. The widget oscillates between `1.0` and
  /// `1.0 + amplitude`. Default is `0.015` (subtle).
  final double amplitude;

  const Breathing({
    super.key,
    required this.child,
    this.period = const Duration(seconds: 5),
    this.amplitude = 0.015,
  });

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _disabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disable && !_disabled) {
      _disabled = true;
      _controller.stop();
      _controller.value = 0;
    } else if (!disable && !_controller.isAnimating) {
      _disabled = false;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sine wave: 0 → 1 → 0 over the period. abs() folds the negative
        // half so the scale only oscillates outward (1.0 → 1+amp → 1.0).
        final t = sin(_controller.value * 2 * pi);
        final scale = 1.0 + (t.abs() * widget.amplitude);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
