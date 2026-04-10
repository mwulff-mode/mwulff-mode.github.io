import 'dart:math';
import 'package:flutter/material.dart';

/// A warm orange-pink radial gradient anchored at the top of the screen
/// with a very slow, subtle drift animation. Designed to layer on top of
/// a cream background without causing jank on Flutter web.
///
/// The animation is intentionally slow (15 s period) and only shifts the
/// gradient center by a small amount, so the per-frame cost is minimal.
class TopGlow extends StatefulWidget {
  const TopGlow({super.key});

  @override
  State<TopGlow> createState() => _TopGlowState();
}

class _TopGlowState extends State<TopGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value * 2 * pi;
          // Subtle horizontal drift: center wanders ±0.15 around 0.0
          final cx = 0.4 + 0.15 * sin(t);
          // Subtle vertical drift: center wanders around -0.6 (top area)
          final cy = -1.2 + 0.08 * cos(t * 0.7);

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(cx, cy),
                radius: 1.0,
                colors: const [
                  Color(0x50FFFFFF), // white, ~31% opacity
                  Color(0x28FFFFFF), // white, ~16%
                  Color(0x00FFFFFF), // fades to transparent
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}
