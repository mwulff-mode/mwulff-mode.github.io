import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';
import 'press_scale.dart';

/// Destructive red used by Sign Out and every other `destructive: true`
/// usage. Deliberately hardcoded because destructive UI does not change
/// color across themes. Mirrors the `_kSignOutRed` that used to live
/// inline on `profile_screen.dart`.
const Color kDestructiveRed = Color(0xFFDC2626);

/// Shared primary CTA. Full-width by default, 60 px tall, reads colors
/// and radius from the active `EarnWiseTheme.cta` + `radii.button`.
///
/// Pass `destructive: true` for the Sign Out button and any future
/// destructive confirm. This overrides the theme-resolved background
/// with `kDestructiveRed` regardless of which theme is active.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final IconData? leadingIcon;
  final HapticIntensity haptic;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.leadingIcon,
    this.haptic = HapticIntensity.confirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    final background = destructive ? kDestructiveRed : t.cta.background;
    final foreground = destructive ? Colors.white : t.cta.foreground;
    final radius = t.radii.button;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 22, color: foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppText.ctaLabel.copyWith(color: foreground),
        ),
      ],
    );

    return PressScale(
      onTap: onTap,
      haptic: haptic,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}
