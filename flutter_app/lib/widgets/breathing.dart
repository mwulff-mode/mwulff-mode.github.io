import 'dart:math';
import 'package:flutter/material.dart';

/// A very quiet idle scale oscillation for elements that should feel alive
/// when nothing is happening. Cosine-driven (single peak per period),
/// no opacity, no position.
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
    if (disable) {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.value = 0;
      }
    } else if (!_controller.isAnimating) {
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
        // (1 - cos(t·2π)) / 2 produces a smooth single peak (0 → 1 → 0)
        // over the full period — one full breath in/out per [period].
        // Equivalent to sin²(t·π); more natural feel than abs(sin).
        final t = (1 - cos(_controller.value * 2 * pi)) / 2;
        final scale = 1.0 + (t * widget.amplitude);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
