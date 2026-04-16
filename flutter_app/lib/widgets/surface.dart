import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';
import 'press_scale.dart';

/// Raised-card primitive. Defaults resolve from the active `EarnWiseTheme`
/// at build time: `palette.surfaceRaised` for color, `radii.card` for
/// radius, `elevation.card` for shadows. Any non-null constructor arg
/// overrides the theme-resolved default for that site only.
///
/// **Auto-hairline:** when the resolved `elevation.card` is empty AND the
/// caller did not pass an explicit `border`, Surface draws a 1px
/// `palette.hairline` border. This is what gives Plum's flat cards visual
/// separation without every call site having to opt in. Themes that ship
/// non-empty `elevation.card` (Cream) skip the hairline because the shadow
/// already provides the affordance.
///
/// This is **not** a selectable choice card. For the "choice card" pattern
/// (brand-subtle fill when selected, brand border), use `AppCard`.
class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? radius;
  final List<BoxShadow>? elevation;
  final Color? color;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final HapticIntensity? haptic;

  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPad),
    this.radius,
    this.elevation,
    this.color,
    this.border,
    this.onTap,
    this.haptic,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    final resolvedRadius = radius ?? t.radii.card;
    final resolvedElevation = elevation ?? t.elevation.card;
    final resolvedColor = color ?? t.palette.surfaceRaised;
    final resolvedBorder = border ??
        (resolvedElevation.isEmpty
            ? Border.all(color: t.palette.hairline, width: 1)
            : null);

    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(resolvedRadius),
        boxShadow: resolvedElevation,
        border: resolvedBorder,
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
