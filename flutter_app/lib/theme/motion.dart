import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Motion durations for the EarnWise app.
///
/// Use these instead of inlining `Duration(milliseconds: …)` in any
/// animation widget (`AnimatedContainer`, `AnimatedOpacity`, `AnimationController`,
/// etc.). Five tiers cover everything from press feedback to multi-beat hero
/// reveals. See `docs/superpowers/specs/2026-04-08-flutter-motion-system-design.md`
/// Section 1 for the full rationale.
class AppDurations {
  AppDurations._();

  /// Press-scale snap-back, micro feedback. 120ms.
  static const instant = Duration(milliseconds: 120);

  /// Toggles, tiny state flips (currency pill, nav tab). 220ms.
  static const short = Duration(milliseconds: 220);

  /// Default for state changes (task card → completed, earn-more unlock). 320ms.
  static const medium = Duration(milliseconds: 320);

  /// Page transitions, entrance reveals. 480ms.
  static const long = Duration(milliseconds: 480);

  /// Multi-beat moments (ring fill, gift reveal stages, RewardGlow). 900ms.
  static const hero = Duration(milliseconds: 900);
}

/// Motion curves for the EarnWise app.
///
/// Tuned for "playful warmth" — slightly softer than `Curves.easeOutCubic`,
/// no overshoot except on `pop` (used for reward flourishes).
class AppCurves {
  AppCurves._();

  /// Primary deceleration. Default for entrances and reveals.
  static const warmOut = Cubic(0.2, 0.9, 0.1, 1);

  /// Symmetric. Reversible transitions (toggles, expand/collapse).
  static const warmInOut = Cubic(0.45, 0, 0.15, 1);

  /// Slight overshoot. Reward flourishes, badge bumps. Replaces `elasticOut`.
  static const pop = Cubic(0.3, 1.4, 0.6, 1);

  /// Idle / breathing motion only.
  static const gentle = Curves.easeInOut;
}

/// Spring presets used by motion widgets.
class AppSprings {
  AppSprings._();

  /// Spring used by `PressScale` for press-in / press-out.
  /// Slightly underdamped for a confident settle.
  static final pressSettle = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 0.85,
  );
}
