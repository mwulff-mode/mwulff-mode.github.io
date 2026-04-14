import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'surface.dart';

/// Horizontal list item: leading icon, title with optional subtitle, and
/// trailing chrome (default: a caret-right chevron). Built on [Surface]
/// so it picks up the canonical card radius, shadow, and background.
class ListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool disabled;

  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTrailing = trailing ??
        Icon(
          PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
          size: 16,
          color: AppColors.inkTertiary,
        );

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        leading,
        const SizedBox(width: AppSpacing.cardPad),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppText.bodyStrong.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.tight),
                Text(
                  subtitle!,
                  style: AppText.caption.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        effectiveTrailing,
      ],
    );

    final surface = Surface(
      onTap: disabled ? null : onTap,
      child: content,
    );

    if (!disabled) return surface;
    return Opacity(opacity: 0.45, child: IgnorePointer(child: surface));
  }
}
