import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'press_scale.dart';

/// The repeating "choice card" surface used for list items and selectable
/// rows: white background, AppRadius.card (16) radius, cream-deep 1.5 border, subtle shadow.
///
/// Supports a `selected` state (primary-pale fill, primary border) for use
/// in multi-select lists like the onboarding preference picker.
///
/// When [onTap] is non-null, the card automatically gets press-scale feedback
/// and the [haptic] (default `tick`) fires on press-in.
///
/// This only covers the *choice card* pattern. Full-width feature cards
/// (task tiles, streak cards, conversational header) intentionally stay
/// inline: they vary too much to force into a single widget.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;
  final BoxConstraints? constraints;
  final HapticIntensity? haptic;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    this.onTap,
    this.selected = false,
    this.constraints,
    this.haptic, // null by default: chrome interactions don't fire haptics
  });

  @override
  Widget build(BuildContext context) {
    final decorated = AnimatedContainer(
      duration: AppDurations.short,
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPale : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.creamDeep,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
