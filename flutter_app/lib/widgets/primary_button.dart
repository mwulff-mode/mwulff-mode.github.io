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
///
/// Pass `outlined: true` for a secondary-styled variant: transparent
/// fill, 1.5 px border in the accent color, and content that adopts
/// the accent color instead of the fill foreground. Use this when the
/// CTA points the user back toward a pre-requisite action rather than
/// confirming the current screen's primary intent.
///
/// Pass `trailingIcon` to render a directional arrow or similar icon
/// after the label. Shares the effective foreground color so outlined
/// variants paint the icon in the accent color automatically.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool outlined;
  final HapticIntensity haptic;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.leadingIcon,
    this.trailingIcon,
    this.outlined = false,
    this.haptic = HapticIntensity.confirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    final baseBackground = destructive ? kDestructiveRed : t.cta.background;
    final baseForeground = destructive ? Colors.white : t.cta.foreground;
    final radius = t.radii.button;

    // Outlined mode: transparent fill, content adopts the base fill color
    // as its accent (teal text on teal border, or red on red when destructive).
    final effectiveBackground =
        outlined ? Colors.transparent : baseBackground;
    final effectiveForeground = outlined ? baseBackground : baseForeground;
    final border =
        outlined ? Border.all(color: baseBackground, width: 1.5) : null;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 22, color: effectiveForeground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppText.ctaLabel.copyWith(color: effectiveForeground),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: 22, color: effectiveForeground),
        ],
      ],
    );

    return PressScale(
      onTap: onTap,
      haptic: haptic,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: effectiveBackground,
          borderRadius: BorderRadius.circular(radius),
          border: border,
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}
