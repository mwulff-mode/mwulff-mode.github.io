import 'package:flutter/services.dart';

/// Single source of truth for the EarnWise haptic policy.
///
/// Every haptic in the app must go through these methods. No raw
/// `HapticFeedback.*` calls anywhere else in `lib/`.
///
/// **Policy (revised after first user test):**
/// - CTA confirmation: primary buttons (Continue with Google, Let's get
///   started, That's me, future Cashout)
/// - Reward moments: task completion, goal completion, hero moments;
///   subtle, never casino-like
/// - Error prevention: form mistakes, blocked actions
/// - No haptic on chrome (nav switch, currency toggle, conv card open, AppCard rows,
///   task card press-in). The visual + transition is the confirmation
class Haptics {
  Haptics._();

  /// Internal guard for `celebrate()`. Each `momentId` fires at most once
  /// per app run. Different moments are independent.
  static final Set<String> _firedMoments = <String>{};

  /// CTA confirmation: fires when the user presses a primary action button
  /// (Continue with Google/Apple/Email, Let's get started, Continue, That's
  /// me, future Cashout). Light impact: a soft, confident "yes."
  static void confirm() {
    HapticFeedback.lightImpact();
  }

  /// Completing a single task (profile / survey / game / daily_*).
  /// Light impact. Same intensity as `confirm`, different semantic moment.
  static void reward() {
    HapticFeedback.lightImpact();
  }

  /// Milestone: goal completed, all-tasks unlocked. Medium impact.
  static void milestone() {
    HapticFeedback.mediumImpact();
  }

  /// Rare hero moments: welcome gift reveal, legend reached.
  ///
  /// Medium impact (was heavy in the first iteration -- heavy felt
  /// casino-like, per user feedback). Each [momentId] fires at most once per
  /// app run. Use the constants in `CelebrateMoments` to avoid typos.
  static void celebrate(String momentId) {
    if (_firedMoments.contains(momentId)) return;
    _firedMoments.add(momentId);
    HapticFeedback.mediumImpact();
  }

  /// Error prevention: form validation failures, blocked actions, "you
  /// can't do that right now." Heavy impact, no guard. No call sites yet
  /// (added for the future error states).
  static void warning() {
    HapticFeedback.heavyImpact();
  }

  /// Test-only: clear the celebrate guard between tests.
  /// Not for production use.
  static void debugResetCelebrateGuard() {
    _firedMoments.clear();
  }
}

/// Canonical momentId constants for `Haptics.celebrate`. Call sites must use
/// these to avoid typos.
class CelebrateMoments {
  CelebrateMoments._();

  /// Welcome screen → home gift reveal (125 Stars).
  static const welcomeGift = 'welcome_gift';

  /// `state.isLegend` becomes true after `advanceGoal()` on the last goal.
  static const legendReached = 'legend_reached';
}
