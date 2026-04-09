import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'animated_gradient_bg.dart';

/// Thin wrapper around the repeated `Scaffold → SafeArea → Padding` pattern
/// used on most screens.
///
/// Defaults match the app convention:
///   - cream background
///   - safe-area inset
///   - horizontal gutter padding (`AppLayout.gutter`)
///
/// Escape hatches for screens that don't fit the default shell:
///   - `padding: EdgeInsets.zero` — opt out of the default gutter (e.g. screens
///      that use a top-level `Stack` or manage their own per-section padding).
///   - `safeArea: false` — opt out of `SafeArea` when the screen needs to bleed
///      into system insets and compute padding manually.
///   - `animatedGradient: true` — wrap the body in [AnimatedGradientBg].
class ScreenScaffold extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool safeArea;
  final bool animatedGradient;
  final Widget? bottomNavigationBar;

  const ScreenScaffold({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.safeArea = true,
    this.animatedGradient = false,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: AppLayout.gutter);

    Widget content = child;
    if (effectivePadding != EdgeInsets.zero) {
      content = Padding(padding: effectivePadding, child: content);
    }
    if (safeArea) {
      content = SafeArea(child: content);
    }
    if (animatedGradient) {
      content = AnimatedGradientBg(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.cream,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
