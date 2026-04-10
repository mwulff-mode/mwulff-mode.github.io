import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Warm gradient background. Uses a static gradient instead of a per-frame
/// animation to avoid jank on Flutter web.
class AnimatedGradientBg extends StatelessWidget {
  final Widget child;

  const AnimatedGradientBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.2, -0.5),
          end: Alignment(0.3, 1.0),
          colors: [
            AppColors.cream,
            Color(0xFFF8F0E8),
            AppColors.creamDeep,
            Color(0xFFFAF5F0),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: child,
    );
  }
}
