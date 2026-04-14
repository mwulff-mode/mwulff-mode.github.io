import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'surface.dart';

/// Icon-on-top tile: leading (usually a 44-size CategoryIconSquare),
/// inner gap, title, tight gap, subtitle. Used for the "Earn More"
/// trio on the home and onboarding screens.
///
/// VerticalTile does **not** wrap itself in [Expanded]. Callers are
/// responsible for sizing. Typical usage:
///
/// ```dart
/// Row(
///   children: [
///     Expanded(child: VerticalTile(...)),
///     SizedBox(width: AppSpacing.rowGap),
///     Expanded(child: VerticalTile(...)),
///     SizedBox(width: AppSpacing.rowGap),
///     Expanded(child: VerticalTile(...)),
///   ],
/// )
/// ```
///
/// This is documented as the "Tile trio" pattern in `docs/design-system.md`.
class VerticalTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool disabled;

  const VerticalTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(height: AppSpacing.inner),
        Text(
          title,
          style: AppText.bodyStrong.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.tight),
        Text(
          subtitle,
          style: AppText.caption.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );

    final surface = Surface(
      radius: AppRadius.feature,
      onTap: disabled ? null : onTap,
      child: content,
    );

    if (!disabled) return surface;
    return Opacity(opacity: 0.45, child: IgnorePointer(child: surface));
  }
}
