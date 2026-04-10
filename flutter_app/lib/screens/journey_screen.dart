import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/press_scale.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      animatedGradient: true,
      padding: EdgeInsets.zero,
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My Journey',
                        style: AppText.sectionTitle,
                      ),
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
                        child: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                            size: 18, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Entries
              Expanded(
                child: state.journeyLog.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount:
                            state.journeyLog.length + 1, // +1 for day label
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12, left: 20),
                              child: Text(
                                'TODAY',
                                style: AppText.caption.copyWith(
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          }
                          final entry = state.journeyLog[index - 1];
                          return _buildEntry(entry);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.path(PhosphorIconsStyle.duotone),
            size: 48,
            color: AppColors.inkTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Your journey starts here',
            style: AppText.bodyStrong.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(JourneyEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.creamDeep, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: entry.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(entry.icon, size: 16, color: entry.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.msg.replaceAll(RegExp(r'<[^>]*>'), ''),
                  style: AppText.bodyStrong.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                if (entry.context != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.context!,
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            entry.time,
            style: AppText.caption.copyWith(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
