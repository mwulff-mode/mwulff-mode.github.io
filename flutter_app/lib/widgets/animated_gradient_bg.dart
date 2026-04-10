import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedGradientBg extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBg({super.key, required this.child});

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
        final t = _controller.value;
        final angle = t * 2 * pi;
        final beginX = 0.3 * cos(angle);
        final beginY = -0.5 + 0.3 * sin(angle);
        final endX = -0.3 * cos(angle + pi * 0.7);
        final endY = 0.8 + 0.2 * sin(angle + pi * 0.5);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(beginX, beginY),
              end: Alignment(endX, endY),
              colors: const [
                AppColors.cream, // cream
                Color(0xFFF8F0E8), // warm peach
                AppColors.creamDeep, // cream deep
                Color(0xFFFAF5F0), // soft blush
              ],
              stops: const [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
