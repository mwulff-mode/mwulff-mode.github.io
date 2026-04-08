import 'package:flutter/services.dart';

/// Single source of truth for the EarnWise haptic policy.
///
/// Every haptic in the app must go through these four methods. No raw
/// `HapticFeedback.*` calls anywhere else in `lib/`. See
/// `docs/superpowers/specs/2026-04-08-flutter-motion-system-design.md`
/// Section 2 for the full call-site map and policy notes.
class Haptics {
  Haptics._();

  /// Internal guard for `celebrate()`. Each `momentId` fires at most once
  /// per app run. Different moments are independent.
  static final Set<String> _firedMoments = <String>{};

  /// Ordinary state changes: nav switch, currency toggle, tap on `AppCard`-based
  /// rows. Quiet, non-intrusive.
  static void tick() {
    HapticFeedback.selectionClick();
  }

  /// Completing a single task (profile / survey / game / daily_*).
  /// Slightly stronger than tick — "something real just happened."
  static void reward() {
    HapticFeedback.lightImpact();
  }

  /// Milestone: goal completed, all-tasks unlocked.
  static void milestone() {
    HapticFeedback.mediumImpact();
  }

  /// Rare hero moments: welcome gift reveal, legend reached.
  /// Each [momentId] fires at most once per app run. Use the constants in
  /// `CelebrateMoments` to avoid typos.
  static void celebrate(String momentId) {
    if (_firedMoments.contains(momentId)) return;
    _firedMoments.add(momentId);
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
