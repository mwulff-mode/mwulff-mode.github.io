import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/press_scale.dart';
import '../widgets/screen_scaffold.dart';

/// Temporary destination used by the Post-Onboarding Home "Earn more"
/// section cards until sub-project 3 (Earnable list component + three
/// list screens) replaces it. Renders a title, a one-line "coming soon"
/// message, and a Close button that pops the screen.
class PlaceholderListScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const PlaceholderListScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      animatedGradient: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: AppText.sectionTitle),
                ),
                PressScale(
                  onTap: () => Navigator.of(context).pop(),
                  haptic: null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.creamDeep,
                    ),
                    child: Icon(
                      PhosphorIcons.x(PhosphorIconsStyle.bold),
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.sparkle(PhosphorIconsStyle.duotone),
                      size: 48,
                      color: AppColors.inkTertiary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: AppText.bodyStrong.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
