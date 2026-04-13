import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/haptics.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Hero card at the top of the Post-Onboarding Home body. Renders three
/// states derived from AppState: default (progress toward target),
/// goal-hit (extension prompt with Push / Bank actions), and extended
/// (progress toward $3 after a push, or banked full bar at $2).
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final showPrompt = state.dailyGoalHit && !state.dailyExtensionOffered;
        if (showPrompt) {
          return _PromptCard(state: state);
        }
        return _ProgressCard(state: state);
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final AppState state;
  const _ProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final earnedDollars = AppState.starsToDollars(state.earnedToday);
    final targetDollars = AppState.starsToDollars(state.dailyGoalStars);
    final fillFraction =
        (state.earnedToday / state.dailyGoalStars).clamp(0.0, 1.0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's goal",
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.inkTertiary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '\$${earnedDollars.toStringAsFixed(2)}',
                  style: AppText.display.copyWith(color: AppColors.ink),
                ),
                TextSpan(
                  text: '  of \$${targetDollars.toStringAsFixed(2)}',
                  style: AppText.body.copyWith(
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fillFraction,
              minHeight: 10,
              backgroundColor: AppColors.creamDeep,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final AppState state;
  const _PromptCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nice, you hit today's \$2.",
            style: AppText.listItem.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Want to push for \$3 today?',
            style: AppText.body.copyWith(color: AppColors.inkSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PromptButton(
                  label: 'Push to \$3',
                  background: AppColors.primary,
                  foreground: AppColors.white,
                  onTap: () {
                    // The goal-hit celebration already fired from
                    // AppState.completeTask on the rising edge. These
                    // CTAs only record the user's response.
                    Haptics.confirm();
                    state.pushDailyGoalToThree();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PromptButton(
                  label: 'Bank it',
                  background: AppColors.white,
                  foreground: AppColors.ink,
                  onTap: () {
                    Haptics.confirm();
                    state.bankDailyGoal();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _PromptButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.ctaLabel.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}
