import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'press_scale.dart';

/// Raised-card primitive. The foundation every feature card in the app is
/// built on: a `Container` with a semantic background color, a semantic
/// border-radius, and a semantic elevation. Wraps in [PressScale] when
/// [onTap] is non-null.
///
/// This is **not** a selectable choice card. For the "choice card" pattern
/// (primary-pale fill when selected, primary border), use [AppCard]
/// instead. A later cleanup can rebuild AppCard on top of Surface, but
/// they are deliberately kept as separate widgets for now.
class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow> elevation;
  final Color color;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final HapticIntensity? haptic;

  Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPad),
    this.radius = AppRadius.card,
    List<BoxShadow>? elevation,
    this.color = AppColors.surfaceRaised,
    this.border,
    this.onTap,
    this.haptic,
  }) : elevation = elevation ?? AppElevation.card;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevation,
        border: border,
      ),
      child: child,
    );
    if (onTap == null) return decorated;
    return PressScale(
      onTap: onTap,
      haptic: haptic,
      child: decorated,
    );
  }
}
