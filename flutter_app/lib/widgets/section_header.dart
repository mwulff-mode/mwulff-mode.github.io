import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';

/// Section title row: the canonical way to introduce a section on a
/// screen. Renders the title in [AppText.title], an optional subtitle
/// in [AppText.caption], and an optional trailing action widget aligned
/// to the end of the row.
///
/// Does not add a bottom margin. The caller chooses
/// `SizedBox(height: AppSpacing.inner)` (12) or `AppSpacing.cardPad`
/// (16) below it depending on context.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppText.title.copyWith(color: t.palette.ink),
              ),
            ),
            if (action != null) action!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.tight),
          Text(
            subtitle!,
            style: AppText.caption.copyWith(color: t.palette.inkSecondary),
          ),
        ],
      ],
    );
  }
}
