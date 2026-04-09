import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// A single conversational-card entry.
///
/// [message] is what the card says.
/// [icon], [color], [bg] control the leading icon badge.
class ConvCard {
  final String message;
  final IconData icon;
  final Color color;
  final Color bg;

  const ConvCard({
    required this.message,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

// ---------------------------------------------------------------------------
// Editable table — each row is:
//   last action  ×  situation  →  message + icon
//
// The first matching row wins. Order matters: put the most specific
// conditions at the top, broad fallbacks at the bottom.
//
// Situation key:
//   last  = state.lastCompletedTask   (null when fresh account)
//   done  = state.completedTasks
//   goal  = state.goalIndex           (0 = onboarding)
//   daily = state.dailyTasksCompleted (0-3, only after onboarding)
// ---------------------------------------------------------------------------

ConvCard resolveConvCard(AppState state) {
  final last = state.lastCompletedTask;
  final done = state.completedTasks;
  final goal = state.goalIndex;
  final daily = state.dailyTasksCompleted;

  // ── Onboarding (goal 0) ──────────────────────────────────────────────

  // Fresh account — never completed anything
  if (goal == 0 && last == null) {
    return ConvCard(
      message: 'A good place to start is your Profile',
      icon: PhosphorIcons.userCircle(PhosphorIconsStyle.duotone),
      color: AppColors.primary,
      bg: AppColors.primaryPale,
    );
  }

  // Just finished profile → nudge to survey
  if (goal == 0 && last == 'profile' && !done.contains('survey')) {
    return ConvCard(
      message: 'Nice! Now try a quick survey for \$0.50',
      icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
      color: AppColors.taskSurvey,
      bg: AppColors.taskSurveyBg,
    );
  }

  // Just finished survey → nudge to game
  if (goal == 0 && last == 'survey' && !done.contains('game')) {
    return ConvCard(
      message: 'One more — pick a game to play',
      icon: PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
      color: AppColors.taskGame,
      bg: AppColors.taskGameBg,
    );
  }

  // Came back with profile done but survey still open (session resume)
  if (goal == 0 && done.contains('profile') && !done.contains('survey')) {
    return ConvCard(
      message: 'Next up: a quick survey for \$0.50',
      icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
      color: AppColors.taskSurvey,
      bg: AppColors.taskSurveyBg,
    );
  }

  // Came back with profile + survey done but game still open
  if (goal == 0 &&
      done.contains('profile') &&
      done.contains('survey') &&
      !done.contains('game')) {
    return ConvCard(
      message: 'One more — pick a game to play',
      icon: PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
      color: AppColors.taskGame,
      bg: AppColors.taskGameBg,
    );
  }

  // All three onboarding tasks done, goal hasn't advanced yet
  if (goal == 0) {
    return ConvCard(
      message: 'Goal complete! Get ready for the next one',
      icon: PhosphorIcons.trophy(PhosphorIconsStyle.fill),
      color: state.ringColor,
      bg: state.ringColor.withValues(alpha: 0.12),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────

  if (state.isLegend) {
    return ConvCard(
      message: "You've earned it all — keep stacking dollars",
      icon: PhosphorIcons.crown(PhosphorIconsStyle.fill),
      color: const Color(0xFFD4AF37),
      bg: const Color(0xFFFDF6E3),
    );
  }

  // ── Close to next goal ───────────────────────────────────────────────

  final remaining = state.currentGoal.goalStars - state.stars;
  if (remaining > 0 && remaining <= 1000) {
    return ConvCard(
      message:
          'Just \$${(remaining / AppState.starsPerDollar).toStringAsFixed(2)} more to your next goal',
      icon: PhosphorIcons.target(PhosphorIconsStyle.duotone),
      color: AppColors.accent,
      bg: AppColors.accentLight,
    );
  }

  // ── Daily tasks (goal > 0) ───────────────────────────────────────────

  // Just finished a daily survey
  if (last == 'daily_survey' && daily < 3) {
    return ConvCard(
      message: 'Survey done — ${3 - daily} tasks left today',
      icon: PhosphorIcons.lightning(PhosphorIconsStyle.duotone),
      color: AppColors.accent,
      bg: AppColors.accentLight,
    );
  }

  // Just finished daily play
  if (last == 'daily_play' && daily < 3) {
    return ConvCard(
      message: 'Game time logged — ${3 - daily} more to go',
      icon: PhosphorIcons.flame(PhosphorIconsStyle.fill),
      color: const Color(0xFFFF6B35),
      bg: const Color(0xFFFFF4ED),
    );
  }

  // Just finished daily offer
  if (last == 'daily_offer' && daily < 3) {
    return ConvCard(
      message: 'Offer checked — ${3 - daily} tasks left',
      icon: PhosphorIcons.lightning(PhosphorIconsStyle.duotone),
      color: AppColors.accent,
      bg: AppColors.accentLight,
    );
  }

  // No daily tasks done yet today (or session resume with 0)
  if (daily == 0) {
    return ConvCard(
      message: "Today's tasks are ready — start with a survey",
      icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
      color: AppColors.taskSurvey,
      bg: AppColors.taskSurveyBg,
    );
  }

  // Generic daily progress: 1 done
  if (daily == 1) {
    return ConvCard(
      message: 'Two more daily tasks to keep stacking',
      icon: PhosphorIcons.lightning(PhosphorIconsStyle.duotone),
      color: AppColors.accent,
      bg: AppColors.accentLight,
    );
  }

  // Generic daily progress: 2 done
  if (daily == 2) {
    return ConvCard(
      message: 'Just one more — almost there',
      icon: PhosphorIcons.flame(PhosphorIconsStyle.fill),
      color: const Color(0xFFFF6B35),
      bg: const Color(0xFFFFF4ED),
    );
  }

  // All daily tasks done
  return ConvCard(
    message: 'All caught up — every Star adds to your balance',
    icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
    color: AppColors.accent,
    bg: AppColors.accentLight,
  );
}
