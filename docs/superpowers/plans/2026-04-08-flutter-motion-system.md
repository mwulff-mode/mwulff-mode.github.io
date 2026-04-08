# Flutter Motion System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the prototype's ad-hoc motion (inline durations, scattered curves, no press feedback, no haptics) with a small shared motion vocabulary, three reusable widgets, and a centralized haptic policy. Apply across every screen.

**Architecture:** Five new files (`motion.dart`, `haptics.dart`, `press_scale.dart`, `reward_glow.dart`, `breathing.dart`) define the system. Existing files migrate inline animation timings and curves to tokens, wrap tappables with `PressScale`, and call `Haptics.*` instead of raw `HapticFeedback.*`. `AppCard` is refactored to use `PressScale` internally so its existing call sites get press feedback for free.

**Tech Stack:** Flutter 3.x · Dart · `flutter/material.dart` · `flutter/services.dart` (HapticFeedback) · `flutter/physics.dart` (SpringSimulation) · `flutter_test` for widget tests.

**Spec:** `docs/superpowers/specs/2026-04-08-flutter-motion-system-design.md`

---

## File Structure

### New files

| File | Responsibility |
|---|---|
| `flutter_app/lib/theme/motion.dart` | `AppDurations` and `AppCurves` constant classes — the entire motion vocabulary. Plus `AppSprings.pressSettle` for `PressScale`. |
| `flutter_app/lib/services/haptics.dart` | `Haptics` static methods (`tick`, `reward`, `milestone`, `celebrate(momentId)`) and `CelebrateMoments` constants. Single source of truth for the haptic policy. |
| `flutter_app/lib/widgets/press_scale.dart` | `PressScale` widget + `HapticIntensity` enum. Wraps any tappable with spring-driven scale feedback and optional haptic. |
| `flutter_app/lib/widgets/reward_glow.dart` | `RewardGlow` widget + `RewardGlowController`. Three-beat celebration flourish (scale → glow → settle). |
| `flutter_app/lib/widgets/breathing.dart` | `Breathing` widget. Sine-driven idle scale oscillation. |
| `flutter_app/test/widgets/press_scale_test.dart` | Three widget tests for `PressScale`: tap-fires-onTap, disabled-blocks-onTap, reduced-motion-no-crash. |

### Modified files

| File | Change |
|---|---|
| `flutter_app/lib/widgets/fade_route.dart` | Default `duration` → `AppDurations.long`. |
| `flutter_app/lib/widgets/app_toast.dart` | `_fadeDuration` → `AppDurations.long`. |
| `flutter_app/lib/widgets/app_card.dart` | Refactored to use `PressScale` internally when `onTap != null`. New `haptic` param. `AnimatedContainer` duration → `AppDurations.short`. |
| `flutter_app/lib/screens/welcome_screen.dart` | All durations / curves → tokens. CTAs wrapped with `PressScale(haptic: null)`. Logo wrapped with `Breathing`. |
| `flutter_app/lib/screens/trust_carousel_screen.dart` | `AnimatedSwitcher` duration → token. CTA wrapped with `PressScale(haptic: null)`. Tap-to-advance wrapped with `PressScale(haptic: tick)`. 3000ms carousel pacing whitelisted. |
| `flutter_app/lib/screens/onboarding_screen.dart` | All durations / curves → tokens. Back button wrapped with `PressScale(haptic: null)`. CTAs wrapped with `PressScale(haptic: null)`. Preference rows inherit press feedback via `AppCard` refactor. |
| `flutter_app/lib/screens/journey_screen.dart` | Close button wrapped with `PressScale(haptic: null)`. No motion edits — pure layout file. |
| `flutter_app/lib/screens/home_screen.dart` | All inline durations / curves → tokens. All tappables wrapped with `PressScale`. Gift overlay uses `RewardGlow` instead of inline `ScaleTransition + elasticOut`. Goal ring wrapped with `RewardGlow` triggered on goal completion. `_completeTask` calls `Haptics.reward()` / `milestone()` / `celebrate(legendReached)`. |

### Out of scope (not migrated)

- `lib/widgets/animated_gradient_bg.dart` — ambient 8s loop, whitelisted.
- `lib/widgets/typewriter_text.dart` — content pacing, whitelisted (also out of gate scope since it uses `Timer.periodic`, not `duration:`).
- `lib/widgets/progress_ring.dart`, `screen_scaffold.dart`, `bottom_sheet_shell.dart` — no motion code.
- `lib/playground/ring_playground.dart` — playground, not user-facing.
- `lib/state/app_state.dart` — state logic, no motion.

---

## Task 1: Create motion tokens

**Files:**
- Create: `flutter_app/lib/theme/motion.dart`

- [ ] **Step 1: Write the file**

```dart
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
```

- [ ] **Step 2: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/theme/motion.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd flutter_app
git add lib/theme/motion.dart
git commit -m "Add motion tokens (durations, curves, springs)"
```

---

## Task 2: Create haptics service

**Files:**
- Create: `flutter_app/lib/services/haptics.dart`

- [ ] **Step 1: Write the file**

```dart
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
```

- [ ] **Step 2: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/services/haptics.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd flutter_app
git add lib/services/haptics.dart
git commit -m "Add Haptics service with per-moment celebrate guard"
```

---

## Task 3: Create PressScale widget (TDD)

**Files:**
- Create: `flutter_app/lib/widgets/press_scale.dart`
- Create: `flutter_app/test/widgets/press_scale_test.dart`

- [ ] **Step 1: Write the failing test file**

```dart
// flutter_app/test/widgets/press_scale_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/widgets/press_scale.dart';

void main() {
  group('PressScale', () {
    testWidgets('calls onTap on release', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressScale(
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('tap me'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressScale(
                enabled: false,
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('tap me'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    testWidgets('does not crash when disableAnimations is true',
        (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: PressScale(
                  onTap: () => tapped = true,
                  child: const SizedBox(
                    width: 100,
                    height: 100,
                    child: Text('tap me'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd flutter_app && flutter test test/widgets/press_scale_test.dart`
Expected: FAIL with "Target of URI doesn't exist: 'package:earnwise_mvp/widgets/press_scale.dart'"

- [ ] **Step 3: Write the PressScale widget**

```dart
// flutter_app/lib/widgets/press_scale.dart
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../services/haptics.dart';
import '../theme/motion.dart';

/// Haptic intensity to fire on press-in. Maps 1:1 to the [Haptics] service.
/// Use `null` (the default) when no haptic is wanted.
///
/// Note: there is no `celebrate` variant. Celebrate haptics are reserved
/// for hero moments triggered manually by screen code (e.g. gift reveal,
/// legend reached) and require a `momentId` for the per-session guard, which
/// the enum cannot carry. PressScale call sites that need a celebrate
/// haptic should fire it separately via `Haptics.celebrate(momentId)`.
enum HapticIntensity { tick, reward, milestone }

/// Wraps any tappable child with spring-driven press feedback and an optional
/// haptic on press-in.
///
/// On press-in: scales `child` to [pressedScale] via the `pressSettle` spring.
/// On press-out: scales back to `1.0` via the same spring.
/// On release inside bounds: fires [onTap].
///
/// When [enabled] is false, the widget renders the child but does not respond
/// to taps and does not animate.
///
/// When `MediaQuery.disableAnimations` is true, the spring is skipped — but
/// the haptic and `onTap` callback still fire (motion is hidden, not feedback).
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final HapticIntensity? haptic;
  final bool enabled;

  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.haptic,
    this.enabled = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(
      vsync: this,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disable) {
      _controller.value = target;
      return;
    }
    final simulation = SpringSimulation(
      AppSprings.pressSettle,
      _controller.value,
      target,
      0,
    );
    _controller.animateWith(simulation);
  }

  void _fireHaptic() {
    switch (widget.haptic) {
      case null:
        return;
      case HapticIntensity.tick:
        Haptics.tick();
      case HapticIntensity.reward:
        Haptics.reward();
      case HapticIntensity.milestone:
        Haptics.milestone();
    }
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    _fireHaptic();
    _animateTo(widget.pressedScale);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    _animateTo(1.0);
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    _animateTo(1.0);
  }

  void _handleTap() {
    if (!widget.enabled) return;
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _controller.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd flutter_app && flutter test test/widgets/press_scale_test.dart`
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd flutter_app
git add lib/widgets/press_scale.dart test/widgets/press_scale_test.dart
git commit -m "Add PressScale widget with spring-driven press feedback"
```

---

## Task 4: Create RewardGlow widget

**Files:**
- Create: `flutter_app/lib/widgets/reward_glow.dart`

- [ ] **Step 1: Write the file**

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Controller for [RewardGlow]. Call [play] to trigger the celebration
/// flourish. Safe to call multiple times — re-plays the animation from the
/// start.
class RewardGlowController extends ChangeNotifier {
  int _playCount = 0;
  int get playCount => _playCount;

  void play() {
    _playCount++;
    notifyListeners();
  }

  /// Test-only: reset the play counter without notifying listeners.
  void debugReset() {
    _playCount = 0;
  }
}

/// A celebration pulse for multi-stage reward moments. Wraps a [child] and,
/// when the [controller] fires `play()`, plays a three-beat flourish:
///
/// 1. 0–300ms: child scales 1.0 → 1.06 (`AppCurves.pop`)
/// 2. 100–700ms: radial glow behind child fades 0 → 0.5 → 0 alpha,
///    expanding from 0.8× to 1.4× of child bounds
/// 3. 300–900ms: child scales 1.06 → 1.0 (`AppCurves.warmOut`)
///
/// Total duration: `AppDurations.hero` (900ms).
///
/// The glow is rendered behind the child via `Stack`, so it does not affect
/// layout.
class RewardGlow extends StatefulWidget {
  final Widget child;
  final RewardGlowController controller;
  final Color glowColor;

  const RewardGlow({
    super.key,
    required this.child,
    required this.controller,
    this.glowColor = AppColors.accent,
  });

  @override
  State<RewardGlow> createState() => _RewardGlowState();
}

class _RewardGlowState extends State<RewardGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _lastPlayCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.hero,
    );
    widget.controller.addListener(_onPlay);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlay);
    _controller.dispose();
    super.dispose();
  }

  void _onPlay() {
    if (widget.controller.playCount == _lastPlayCount) return;
    _lastPlayCount = widget.controller.playCount;
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disable) return;
    _controller.forward(from: 0);
  }

  // 0–300ms: 1.0 → 1.06 with pop
  // 300–900ms: 1.06 → 1.0 with warmOut
  double _scaleAt(double t) {
    if (t < 0.333) {
      final localT = AppCurves.pop.transform(t / 0.333);
      return 1.0 + 0.06 * localT;
    }
    final localT = AppCurves.warmOut.transform((t - 0.333) / 0.667);
    return 1.06 - 0.06 * localT;
  }

  // 100–700ms: alpha 0 → 0.5 → 0
  double _glowAlphaAt(double t) {
    if (t < 0.111 || t > 0.778) return 0;
    final localT = (t - 0.111) / 0.667;
    final triangle =
        localT < 0.5 ? localT * 2 : (1 - localT) * 2;
    return 0.5 * triangle;
  }

  // 100–700ms: scale 0.8 → 1.4
  double _glowScaleAt(double t) {
    if (t < 0.111 || t > 0.778) return 0.8;
    final localT = (t - 0.111) / 0.667;
    return 0.8 + 0.6 * localT;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Glow layer (behind)
            IgnorePointer(
              child: Opacity(
                opacity: _glowAlphaAt(t),
                child: Transform.scale(
                  scale: _glowScaleAt(t),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.glowColor.withValues(alpha: 0.6),
                          widget.glowColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 200,
                      minHeight: 200,
                    ),
                  ),
                ),
              ),
            ),
            // Child layer (front)
            Transform.scale(
              scale: _scaleAt(t),
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/widgets/reward_glow.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd flutter_app
git add lib/widgets/reward_glow.dart
git commit -m "Add RewardGlow widget with three-beat celebration flourish"
```

---

## Task 5: Create Breathing widget

**Files:**
- Create: `flutter_app/lib/widgets/breathing.dart`

- [ ] **Step 1: Write the file**

```dart
import 'dart:math';
import 'package:flutter/material.dart';

/// A very quiet idle scale oscillation for elements that should feel alive
/// when nothing is happening. Sine-driven, no opacity, no position.
///
/// Auto-starts on mount, auto-disposes. Disables on
/// `MediaQuery.disableAnimations`.
class Breathing extends StatefulWidget {
  final Widget child;
  final Duration period;

  /// Maximum scale delta. The widget oscillates between `1.0` and
  /// `1.0 + amplitude`. Default is `0.015` (subtle).
  final double amplitude;

  const Breathing({
    super.key,
    required this.child,
    this.period = const Duration(seconds: 5),
    this.amplitude = 0.015,
  });

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _disabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disable && !_disabled) {
      _disabled = true;
      _controller.stop();
      _controller.value = 0;
    } else if (!disable && !_controller.isAnimating) {
      _disabled = false;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sine wave: 0 → 1 → 0 over the period. abs() folds the negative
        // half so the scale only oscillates outward (1.0 → 1+amp → 1.0).
        final t = sin(_controller.value * 2 * pi);
        final scale = 1.0 + (t.abs() * widget.amplitude);
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/widgets/breathing.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd flutter_app
git add lib/widgets/breathing.dart
git commit -m "Add Breathing widget for subtle idle oscillation"
```

---

## Task 6: Refactor AppCard to use PressScale

**Files:**
- Modify: `flutter_app/lib/widgets/app_card.dart`

- [ ] **Step 1: Replace the file contents**

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'press_scale.dart';

/// The repeating "choice card" surface used for list items and selectable
/// rows: white background, 18px radius, cream-deep 1.5 border, subtle shadow.
///
/// Supports a `selected` state (primary-pale fill, primary border) for use
/// in multi-select lists like the onboarding preference picker.
///
/// When [onTap] is non-null, the card automatically gets press-scale feedback
/// and the [haptic] (default `tick`) fires on press-in.
///
/// This only covers the *choice card* pattern. Full-width feature cards
/// (task tiles, streak cards, conversational header) intentionally stay
/// inline — they vary too much to force into a single widget.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool selected;
  final BoxConstraints? constraints;
  final HapticIntensity? haptic;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    this.onTap,
    this.selected = false,
    this.constraints,
    this.haptic = HapticIntensity.tick,
  });

  @override
  Widget build(BuildContext context) {
    final decorated = AnimatedContainer(
      duration: AppDurations.short,
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryPale : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.creamDeep,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return decorated;
    return PressScale(
      onTap: onTap,
      haptic: haptic,
      child: decorated,
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/widgets/app_card.dart`
Expected: `No issues found!`

- [ ] **Step 3: Run all existing tests**

Run: `cd flutter_app && flutter test`
Expected: PressScale tests still pass; no new failures.

- [ ] **Step 4: Commit**

```bash
cd flutter_app
git add lib/widgets/app_card.dart
git commit -m "Refactor AppCard to use PressScale internally"
```

---

## Task 7: Migrate fade_route.dart to motion tokens

**Files:**
- Modify: `flutter_app/lib/widgets/fade_route.dart`

- [ ] **Step 1: Replace the file contents**

```dart
import 'package:flutter/material.dart';
import '../theme/motion.dart';

/// Standard fade-through route used across the app.
///
/// Every screen-to-screen transition should go through this helper so the
/// timing curve is identical everywhere. Default duration is
/// `AppDurations.long`.
PageRouteBuilder<T> fadeRoute<T>(
  Widget page, {
  Duration? duration,
}) {
  final d = duration ?? AppDurations.long;
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: d,
    reverseTransitionDuration: d,
  );
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/widgets/fade_route.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
cd flutter_app
git add lib/widgets/fade_route.dart
git commit -m "Migrate fade_route to motion tokens"
```

---

## Task 8: Migrate app_toast.dart to motion tokens

**Files:**
- Modify: `flutter_app/lib/widgets/app_toast.dart:59`

- [ ] **Step 1: Update the import**

In `flutter_app/lib/widgets/app_toast.dart`, after the existing
`import '../theme/app_theme.dart';` line, add:

```dart
import '../theme/motion.dart';
```

- [ ] **Step 2: Replace the `_fadeDuration` constant**

Find the line:
```dart
  static const _fadeDuration = Duration(milliseconds: 400);
```

Replace with:
```dart
  static const _fadeDuration = AppDurations.long;
```

(`AppDurations.long` is itself a `static const`, so `static const _fadeDuration = AppDurations.long` is a valid const expression in Dart 3.)

- [ ] **Step 3: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/widgets/app_toast.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
cd flutter_app
git add lib/widgets/app_toast.dart
git commit -m "Migrate app_toast fade duration to motion tokens"
```

---

## Task 9: Migrate welcome_screen.dart

**Files:**
- Modify: `flutter_app/lib/screens/welcome_screen.dart`

This task migrates four `AnimationController` durations, four `easeOutCubic`
curves, wraps three CTAs with `PressScale(haptic: null)`, and wraps the logo
with `Breathing`.

- [ ] **Step 1: Update imports**

At the top of `flutter_app/lib/screens/welcome_screen.dart`, after the existing
imports, add:

```dart
import '../theme/motion.dart';
import '../widgets/breathing.dart';
import '../widgets/press_scale.dart';
```

- [ ] **Step 2: Migrate AnimationController durations**

Find the four lines (around `welcome_screen.dart:33-41`):
```dart
    _nameController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _taglineController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _proofController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _ratingController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
```

Replace with:
```dart
    _nameController = AnimationController(
        vsync: this, duration: AppDurations.long);
    _taglineController = AnimationController(
        vsync: this, duration: AppDurations.long);
    _proofController = AnimationController(
        vsync: this, duration: AppDurations.long);
    _ratingController = AnimationController(
        vsync: this, duration: AppDurations.long);
```

- [ ] **Step 3: Migrate the easeOutCubic curves**

Find the three `CurvedAnimation` blocks (around `welcome_screen.dart:42-53`):
```dart
    _nameSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _nameController, curve: Curves.easeOutCubic));
    _nameFade = Tween(begin: 0.0, end: 1.0).animate(_nameController);

    _taglineSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _taglineController, curve: Curves.easeOutCubic));
    _taglineFade = Tween(begin: 0.0, end: 1.0).animate(_taglineController);

    _proofSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _proofController, curve: Curves.easeOutCubic));
    _proofFade = Tween(begin: 0.0, end: 1.0).animate(_proofController);
```

Replace each `Curves.easeOutCubic` with `AppCurves.warmOut`:
```dart
    _nameSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _nameController, curve: AppCurves.warmOut));
    _nameFade = Tween(begin: 0.0, end: 1.0).animate(_nameController);

    _taglineSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _taglineController, curve: AppCurves.warmOut));
    _taglineFade = Tween(begin: 0.0, end: 1.0).animate(_taglineController);

    _proofSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _proofController, curve: AppCurves.warmOut));
    _proofFade = Tween(begin: 0.0, end: 1.0).animate(_proofController);
```

- [ ] **Step 4: Wrap the logo container with Breathing**

Find the logo container (around `welcome_screen.dart:94-126`):
```dart
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      // ... etc
                    ),
                    // ... etc
                  ),
                  child: const Center(
                    child: Text(
                      'E',
                      // ... etc
                    ),
                  ),
                ),
```

Wrap it with `Breathing(child: ...)`:
```dart
                Breathing(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        // ... etc unchanged
                      ),
                      // ... etc unchanged
                    ),
                    child: const Center(
                      child: Text(
                        'E',
                        // ... etc unchanged
                      ),
                    ),
                  ),
                ),
```

- [ ] **Step 5: Wrap the Google CTA with PressScale**

Find the Google button (around `welcome_screen.dart:227-250`):
```dart
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigate,
                  icon: const Icon(Icons.g_mobiledata,
                      size: 24, color: Colors.white),
                  label: Text(
                    'Continue with Google',
                    // ...
                  ),
                  style: ElevatedButton.styleFrom(
                    // ...
                  ),
                ),
              ),
```

Wrap the `SizedBox` with `PressScale`:
```dart
              PressScale(
                onTap: _navigate,
                haptic: null,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigate,
                    icon: const Icon(Icons.g_mobiledata,
                        size: 24, color: Colors.white),
                    label: Text(
                      'Continue with Google',
                      // ... unchanged
                    ),
                    style: ElevatedButton.styleFrom(
                      // ... unchanged
                    ),
                  ),
                ),
              ),
```

The `ElevatedButton.icon`'s `onPressed: _navigate` stays — `PressScale` only
adds the scale animation. The button still handles its own ink ripple and
calls `_navigate` on tap. (Both `PressScale.onTap` and `ElevatedButton.onPressed`
will fire — but they call the same callback, and `_navigate` is idempotent
because it just pushes a route. No double-navigation.)

Actually, this could cause double-navigation if the user is fast. Better
approach: pass `null` to the inner button's `onPressed` and let `PressScale`
handle the tap exclusively. But then the button loses its ink ripple. And
making `onPressed: null` gives the button its disabled visual state.

Cleanest fix: keep the button's `onPressed: _navigate` and remove the
`PressScale.onTap` callback (set it to `() {}`), so PressScale only does the
scale animation and the button does the navigation.

Actually no — `PressScale` requires `onTap` and uses it to gate the press
animation. Setting it to a no-op `() {}` works.

Use this pattern instead:
```dart
              PressScale(
                onTap: () {}, // navigation handled by ElevatedButton below
                haptic: null,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigate,
                    // ... rest unchanged
                  ),
                ),
              ),
```

- [ ] **Step 6: Wrap the Apple CTA with PressScale**

Same pattern. Find the Apple button (around `welcome_screen.dart:254-278`)
and wrap its `SizedBox` with `PressScale(onTap: () {}, haptic: null, ...)`.

- [ ] **Step 7: Wrap the Email CTA with PressScale**

Find the email `GestureDetector` (around `welcome_screen.dart:303-322`):
```dart
              GestureDetector(
                onTap: _navigate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    // ...
                  ),
                  child: Text(
                    'Email address',
                    // ...
                  ),
                ),
              ),
```

Replace `GestureDetector` with `PressScale` (since this one doesn't have an
inner button to conflict):
```dart
              PressScale(
                onTap: _navigate,
                haptic: null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    // ... unchanged
                  ),
                  child: Text(
                    'Email address',
                    // ... unchanged
                  ),
                ),
              ),
```

- [ ] **Step 8: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/screens/welcome_screen.dart`
Expected: `No issues found!`

- [ ] **Step 9: Run the app and smoke-test**

Run: `cd flutter_app && flutter run -d <device>` (let user pick device)
Expected: Welcome screen loads. Logo "E" breathes faintly. Name / tagline /
proof still stagger in. All three CTAs give visible press-scale feedback on
press. No haptic. Tapping any CTA navigates to the trust carousel.

- [ ] **Step 10: Commit**

```bash
cd flutter_app
git add lib/screens/welcome_screen.dart
git commit -m "Migrate welcome screen to motion system (tokens + PressScale + Breathing)"
```

---

## Task 10: Migrate trust_carousel_screen.dart

**Files:**
- Modify: `flutter_app/lib/screens/trust_carousel_screen.dart`

The 3000ms `_progressController` and `_autoTimer` are content pacing
(carousel auto-advance) and stay as-is — they will be whitelisted in the
final grep gate. The 450ms `AnimatedSwitcher` and the `easeOutCubic` curve
are migrated. The "Let's get started" CTA and the tap-to-advance gesture
get `PressScale`.

- [ ] **Step 1: Update imports**

Add to the imports at the top:
```dart
import '../theme/motion.dart';
import '../widgets/press_scale.dart';
```

- [ ] **Step 2: Migrate the AnimatedSwitcher duration and curve**

Find (around `trust_carousel_screen.dart:97-113`):
```dart
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _buildSlide(_slides[_currentSlide]),
                ),
```

Replace with:
```dart
                child: AnimatedSwitcher(
                  duration: AppDurations.long,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: AppCurves.warmOut,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _buildSlide(_slides[_currentSlide]),
                ),
```

- [ ] **Step 3: Wrap the tap-to-advance GestureDetector with PressScale**

Find (around `trust_carousel_screen.dart:93-118`):
```dart
          Expanded(
            child: GestureDetector(
              onTap: _advanceSlide,
              child: Center(
                child: AnimatedSwitcher(
                  // ...
                ),
              ),
            ),
          ),
```

Replace with:
```dart
          Expanded(
            child: PressScale(
              onTap: _advanceSlide,
              haptic: HapticIntensity.tick,
              child: Center(
                child: AnimatedSwitcher(
                  // ... unchanged
                ),
              ),
            ),
          ),
```

(Tap-to-advance is an in-place state change, not navigation, so it gets `tick`.)

- [ ] **Step 4: Wrap the "Let's get started" CTA with PressScale**

Find (around `trust_carousel_screen.dart:124-132`):
```dart
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigate,
              style: AppButtonStyles.primary,
              child: Text("Let's get started", style: AppText.ctaLabel),
            ),
          ),
```

Replace with:
```dart
          PressScale(
            onTap: () {},
            haptic: null,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigate,
                style: AppButtonStyles.primary,
                child: Text("Let's get started", style: AppText.ctaLabel),
              ),
            ),
          ),
```

(Same pattern as welcome — `ElevatedButton` keeps its `onPressed`, `PressScale.onTap` is a no-op, no haptic because this navigates.)

- [ ] **Step 5: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/screens/trust_carousel_screen.dart`
Expected: `No issues found!`

- [ ] **Step 6: Smoke-test**

Run: `cd flutter_app && flutter run -d <device>`
Expected: Carousel advances every 3 seconds. Tap-to-advance still works,
gives a tick haptic and press-scale feedback. CTA gives press-scale feedback,
no haptic, navigates to onboarding.

- [ ] **Step 7: Commit**

```bash
cd flutter_app
git add lib/screens/trust_carousel_screen.dart
git commit -m "Migrate trust carousel to motion system"
```

---

## Task 11: Migrate onboarding_screen.dart

**Files:**
- Modify: `flutter_app/lib/screens/onboarding_screen.dart`

Migrates 5 inline durations and 1 curve, wraps the back button with
`PressScale`, wraps both CTAs with `PressScale(haptic: null)`. Preference
rows (`AppCard`) inherit press feedback automatically.

- [ ] **Step 1: Update imports**

Add to the top:
```dart
import '../theme/motion.dart';
import '../widgets/press_scale.dart';
```

- [ ] **Step 2: Migrate the stepper AnimatedContainer**

Find (around `onboarding_screen.dart:96-108`):
```dart
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 24 : 7,
                  height: 7,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    // ...
                  ),
                );
```

Replace with:
```dart
                return AnimatedContainer(
                  duration: AppDurations.medium,
                  curve: AppCurves.warmOut,
                  width: isActive ? 24 : 7,
                  height: 7,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    // ... unchanged
                  ),
                );
```

- [ ] **Step 3: Migrate the step AnimatedSwitcher**

Find (around `onboarding_screen.dart:116`):
```dart
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _buildStep(),
            ),
```

Replace with:
```dart
            child: AnimatedSwitcher(
              duration: AppDurations.medium,
              child: _buildStep(),
            ),
```

- [ ] **Step 4: Migrate the choices fade-in**

Find (around `onboarding_screen.dart:152-162`):
```dart
            AnimatedOpacity(
              opacity: _choicesVisible ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: Text(
                'Pick as many as you like',
                // ...
              ),
            ),
```

Replace `Duration(milliseconds: 400)` with `AppDurations.long`:
```dart
            AnimatedOpacity(
              opacity: _choicesVisible ? 1 : 0,
              duration: AppDurations.long,
              child: Text(
                'Pick as many as you like',
                // ... unchanged
              ),
            ),
```

- [ ] **Step 5: Migrate the choices column animations**

Find (around `onboarding_screen.dart:164-173`):
```dart
            AnimatedOpacity(
              opacity: _choicesVisible ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: AnimatedSlide(
                offset: _choicesVisible ? Offset.zero : const Offset(0, 0.05),
                duration: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    // ...
```

Replace both `Duration(milliseconds: 400)` with `AppDurations.long`:
```dart
            AnimatedOpacity(
              opacity: _choicesVisible ? 1 : 0,
              duration: AppDurations.long,
              child: AnimatedSlide(
                offset: _choicesVisible ? Offset.zero : const Offset(0, 0.05),
                duration: AppDurations.long,
                child: Column(
                  children: [
                    // ... unchanged
```

- [ ] **Step 6: Wrap the back button GestureDetector with PressScale**

Find (around `onboarding_screen.dart:66-85`):
```dart
            child: GestureDetector(
              onTap: () {
                if (_currentStep > 1) {
                  _goToStep(_currentStep - 1);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creamDeep,
                ),
                child: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    size: 20, color: AppColors.ink),
              ),
            ),
```

Replace `GestureDetector` with `PressScale`:
```dart
            child: PressScale(
              onTap: () {
                if (_currentStep > 1) {
                  _goToStep(_currentStep - 1);
                } else {
                  Navigator.of(context).pop();
                }
              },
              haptic: null,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creamDeep,
                ),
                child: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                    size: 20, color: AppColors.ink),
              ),
            ),
```

- [ ] **Step 7: Wrap the Step 1 Continue CTA with PressScale**

Find (around `onboarding_screen.dart:208-216`):
```dart
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: prefs.isNotEmpty
                    ? () => _goToStep(2)
                    : null,
                style: AppButtonStyles.primary,
                child: Text('Continue', style: AppText.ctaLabel),
              ),
            ),
```

Replace with:
```dart
            PressScale(
              onTap: () {},
              haptic: null,
              enabled: prefs.isNotEmpty,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: prefs.isNotEmpty
                      ? () => _goToStep(2)
                      : null,
                  style: AppButtonStyles.primary,
                  child: Text('Continue', style: AppText.ctaLabel),
                ),
              ),
            ),
```

(`enabled: prefs.isNotEmpty` ensures the press-scale is also disabled when
the button is disabled, matching the visual state.)

- [ ] **Step 8: Wrap the Step 2 "That's me" CTA with PressScale**

Find (around `onboarding_screen.dart:295-302`):
```dart
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _finishOnboarding,
            style: AppButtonStyles.primary,
            child: Text("That's me", style: AppText.ctaLabel),
          ),
        ),
```

Replace with:
```dart
        PressScale(
          onTap: () {},
          haptic: null,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finishOnboarding,
              style: AppButtonStyles.primary,
              child: Text("That's me", style: AppText.ctaLabel),
            ),
          ),
        ),
```

- [ ] **Step 9: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/screens/onboarding_screen.dart`
Expected: `No issues found!`

- [ ] **Step 10: Smoke-test**

Run: `cd flutter_app && flutter run -d <device>`
Expected: Stepper dot transition feels slightly softer (warmOut vs easeOutCubic).
Back button gives press-scale, no haptic. Preference rows give press-scale +
`tick` (via AppCard refactor). Continue CTA visually press-scales when enabled,
doesn't when disabled. Both step transitions and the final fade-route work.

- [ ] **Step 11: Commit**

```bash
cd flutter_app
git add lib/screens/onboarding_screen.dart
git commit -m "Migrate onboarding screen to motion system"
```

---

## Task 12: Migrate journey_screen.dart

**Files:**
- Modify: `flutter_app/lib/screens/journey_screen.dart`

The only motion concern is the close button `GestureDetector`. No durations
or curves to migrate.

- [ ] **Step 1: Update imports**

Add:
```dart
import '../widgets/press_scale.dart';
```

- [ ] **Step 2: Wrap the close button GestureDetector with PressScale**

Find (around `journey_screen.dart:31-43`):
```dart
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
```

Replace `GestureDetector` with `PressScale`:
```dart
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
```

- [ ] **Step 3: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/screens/journey_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
cd flutter_app
git add lib/screens/journey_screen.dart
git commit -m "Wrap journey close button with PressScale"
```

---

## Task 13: Migrate home_screen.dart — phase 1 (durations + curves)

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`

This is the heaviest file. Phase 1 only swaps inline durations and curves
for tokens. No structural changes. Phase 2 handles `PressScale`. Phase 3
handles `RewardGlow` on the gift. Phase 4 handles `RewardGlow` on the ring +
`Haptics.*` calls + legend wiring.

Reference for the durations being migrated (line numbers approximate, may
shift after Phase 1 edits accumulate):

| Line | Current | Target |
|---|---|---|
| 39 | `Duration(milliseconds: 600)` (`_giftIconController`) | `AppDurations.hero` (deleted in Phase 3, but migrated here for Phase 1 cleanliness) |
| 41 | `Duration(milliseconds: 800)` (`_giftAmountController`) | `AppDurations.hero` |
| 43 | `Duration(milliseconds: 500)` (`_giftLabelController`) | `AppDurations.long` |
| 373 | `Duration(milliseconds: 600)` (gift overlay AnimatedOpacity) | `AppDurations.long` |
| 609 | `Duration(milliseconds: 500)` (balance row AnimatedContainer) | `AppDurations.long` |
| 630 | `Duration(milliseconds: 1200)` (ring TweenAnimationBuilder) | `AppDurations.hero` |
| 807 | `Duration(milliseconds: 300)` (task card AnimatedOpacity) | `AppDurations.medium` |
| 901 | `Duration(milliseconds: 500)` (earn-more AnimatedOpacity) | `AppDurations.long` |
| 1006 | `Duration(milliseconds: 300)` (nav item AnimatedContainer) | `AppDurations.medium` |

Curves to migrate:
- `Curves.easeOutCubic` (multiple sites in `AnimatedContainer`, `TweenAnimationBuilder`) → `AppCurves.warmOut`
- `Curves.elasticOut` (gift icon `ScaleTransition`) — leave for now, will be deleted in Phase 3.

`Future.delayed` calls in `_playGiftAnimation` and `_completeTask` are NOT
migrated. They are scheduler delays, out of gate scope.

- [ ] **Step 1: Update imports**

Add to the imports at the top of `flutter_app/lib/screens/home_screen.dart`:
```dart
import '../theme/motion.dart';
```

- [ ] **Step 2: Migrate the three gift controller durations**

Find (around `home_screen.dart:36-43`):
```dart
    _giftIconController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _giftAmountController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _giftLabelController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
```

Replace with:
```dart
    _giftIconController = AnimationController(
        vsync: this, duration: AppDurations.hero);
    _giftAmountController = AnimationController(
        vsync: this, duration: AppDurations.hero);
    _giftLabelController = AnimationController(
        vsync: this, duration: AppDurations.long);
```

- [ ] **Step 3: Migrate the gift overlay fade duration**

Find (around `home_screen.dart:373`):
```dart
    return AnimatedOpacity(
      opacity: _giftFading ? 0 : 1,
      duration: const Duration(milliseconds: 600),
      child: Container(
```

Replace with:
```dart
    return AnimatedOpacity(
      opacity: _giftFading ? 0 : 1,
      duration: AppDurations.long,
      child: Container(
```

Also update the corresponding `Future.delayed` in `_playGiftAnimation` to
match the new duration so the swap happens after the fade completes:

Find (around `home_screen.dart:67`):
```dart
    setState(() => _giftFading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
```

Replace with:
```dart
    setState(() => _giftFading = true);
    await Future.delayed(AppDurations.long);
    setState(() {
```

(This `Future.delayed` is allowed to reference `AppDurations.long` because
it's meant to coincide with the fade animation. Future.delayed CAN reference
motion tokens; it just isn't required to.)

- [ ] **Step 4: Migrate the balance row AnimatedContainer**

Find (around `home_screen.dart:609`):
```dart
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          width: 170,
          height: 170,
```

Replace with:
```dart
        AnimatedContainer(
          duration: AppDurations.long,
          curve: AppCurves.warmOut,
          width: 170,
          height: 170,
```

- [ ] **Step 5: Migrate the ring TweenAnimationBuilder**

Find (around `home_screen.dart:629`):
```dart
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: state.goalProgress),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
```

Replace with:
```dart
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: state.goalProgress),
                duration: AppDurations.hero,
                curve: AppCurves.warmOut,
                builder: (context, value, _) {
```

- [ ] **Step 6: Migrate the task card AnimatedOpacity**

Find (around `home_screen.dart:807`):
```dart
      child: AnimatedOpacity(
        opacity: completed ? 0.55 : 1,
        duration: const Duration(milliseconds: 300),
        child: Container(
```

Replace with:
```dart
      child: AnimatedOpacity(
        opacity: completed ? 0.55 : 1,
        duration: AppDurations.medium,
        child: Container(
```

- [ ] **Step 7: Migrate the earn-more AnimatedOpacity**

Find (around `home_screen.dart:901`):
```dart
        AnimatedOpacity(
          opacity: unlocked ? 1 : 0.4,
          duration: const Duration(milliseconds: 500),
          child: Row(
```

Replace with:
```dart
        AnimatedOpacity(
          opacity: unlocked ? 1 : 0.4,
          duration: AppDurations.long,
          child: Row(
```

- [ ] **Step 8: Migrate the nav item AnimatedContainer**

Find (around `home_screen.dart:1006`):
```dart
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
```

Replace with:
```dart
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: AppCurves.warmOut,
        padding: EdgeInsets.symmetric(
```

- [ ] **Step 9: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/screens/home_screen.dart`
Expected: `No issues found!`

- [ ] **Step 10: Smoke-test**

Run: `cd flutter_app && flutter run -d <device>`
Expected: Home loads identically to before (including gift reveal). The ring
fill, task completion fade, and nav item transition feel slightly softer
because of `warmOut` vs `easeOutCubic`. No regressions.

- [ ] **Step 11: Commit**

```bash
cd flutter_app
git add lib/screens/home_screen.dart
git commit -m "Migrate home screen durations and curves to motion tokens"
```

---

## Task 14: Migrate home_screen.dart — phase 2 (PressScale wrapping)

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`

Wraps every tappable in home (except `_gameOption`, which inherits press
feedback via the `AppCard` refactor in Task 6).

Tappables to wrap:
- Currency pill (`GestureDetector` around the toggle pill)
- Conv card (`GestureDetector` around the conversational card → JourneyScreen)
- Task cards (`GestureDetector` in `_taskCard`, with `enabled: !completed`)
- Nav items (`GestureDetector` in `_navItem`)
- Earn-more tiles — currently NOT tappable, skip

- [ ] **Step 1: Update imports**

Add:
```dart
import '../widgets/press_scale.dart';
```

- [ ] **Step 2: Wrap the currency pill with PressScale**

Find (around `home_screen.dart:341-385`):
```dart
                  return GestureDetector(
                    onTap: () => state.toggleCurrency(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        // ...
                      ),
                      child: Row(
                        // ...
                      ),
                    ),
                  );
```

Replace `GestureDetector` with `PressScale`:
```dart
                  return PressScale(
                    onTap: () => state.toggleCurrency(),
                    haptic: HapticIntensity.tick,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        // ... unchanged
                      ),
                      child: Row(
                        // ... unchanged
                      ),
                    ),
                  );
```

- [ ] **Step 3: Wrap the conv card with PressScale**

Find (around `home_screen.dart:497-562`) — the `_buildConvCard` method's
return. The current top-level widget is `GestureDetector`:
```dart
  Widget _buildConvCard(AppState state) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(fadeRoute(const JourneyScreen()));
      },
      child: Container(
        // ...
      ),
    );
  }
```

Replace `GestureDetector` with `PressScale`:
```dart
  Widget _buildConvCard(AppState state) {
    return PressScale(
      onTap: () {
        Navigator.of(context).push(fadeRoute(const JourneyScreen()));
      },
      haptic: HapticIntensity.tick,
      child: Container(
        // ... unchanged
      ),
    );
  }
```

(Conv card opens the journey screen — that's navigation, but it's also a
discoverable in-content tap, not a primary CTA. `tick` is appropriate.)

- [ ] **Step 4: Wrap task cards with PressScale**

Find (around `home_screen.dart:823-826`) — the `_taskCard` method, the
existing GestureDetector + AnimatedOpacity:
```dart
  Widget _taskCard(String title, String meta, IconData icon, Color color,
      String taskKey, AppState state,
      {VoidCallback? onTap}) {
    final completed = state.completedTasks.contains(taskKey);
    return GestureDetector(
      onTap: completed ? null : (onTap ?? () => _completeTask(taskKey)),
      child: AnimatedOpacity(
        opacity: completed ? 0.55 : 1,
        duration: AppDurations.medium,
        child: Container(
          // ...
```

Replace `GestureDetector` with `PressScale`:
```dart
  Widget _taskCard(String title, String meta, IconData icon, Color color,
      String taskKey, AppState state,
      {VoidCallback? onTap}) {
    final completed = state.completedTasks.contains(taskKey);
    return PressScale(
      onTap: completed ? null : (onTap ?? () => _completeTask(taskKey)),
      haptic: HapticIntensity.tick,
      enabled: !completed,
      child: AnimatedOpacity(
        opacity: completed ? 0.55 : 1,
        duration: AppDurations.medium,
        child: Container(
          // ... unchanged
```

(Press-in `tick` fires when the user taps a not-yet-completed task. The
`reward` haptic for completion fires from inside `_completeTask` in Phase 4.
This is the intentional double-beat pattern.)

- [ ] **Step 5: Wrap nav items with PressScale**

Find (around `home_screen.dart:1003-1071`) — the `_navItem` method:
```dart
  Widget _navItem(int index, IconData icon, String? label) {
    final isActive = _navIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _navIndex = index),
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: AppCurves.warmOut,
        // ...
```

Replace `GestureDetector` with `PressScale`:
```dart
  Widget _navItem(int index, IconData icon, String? label) {
    final isActive = _navIndex == index;
    return PressScale(
      onTap: () => setState(() => _navIndex = index),
      haptic: HapticIntensity.tick,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: AppCurves.warmOut,
        // ... unchanged
```

- [ ] **Step 6: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/screens/home_screen.dart`
Expected: `No issues found!`

- [ ] **Step 7: Smoke-test**

Run: `cd flutter_app && flutter run -d <device>`
Expected: Currency pill, conv card, task cards, nav items all give
press-scale + tick haptic. Completed task cards do NOT respond to taps and
do NOT give press feedback. Game-picker bottom sheet (which uses AppCard via
`_gameOption`) gives press feedback automatically.

- [ ] **Step 8: Commit**

```bash
cd flutter_app
git add lib/screens/home_screen.dart
git commit -m "Wrap home screen tappables with PressScale"
```

---

## Task 15: Migrate home_screen.dart — phase 3 (RewardGlow on gift)

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`

Replaces the existing `_giftIconController` + `ScaleTransition` + `elasticOut`
on the gift icon with a `RewardGlow`. Also fires `Haptics.celebrate(welcomeGift)`
at the moment the glow plays.

The `_giftAmountController` and `_giftLabelController` stay — they handle
staged content reveal, not celebration.

- [ ] **Step 1: Update imports**

Add:
```dart
import '../services/haptics.dart';
import '../widgets/reward_glow.dart';
```

- [ ] **Step 2: Add the RewardGlow controller as a state field**

Find (around `home_screen.dart:29-31`):
```dart
  late AnimationController _giftIconController;
  late AnimationController _giftAmountController;
  late AnimationController _giftLabelController;
```

Add a new line below:
```dart
  late AnimationController _giftIconController;
  late AnimationController _giftAmountController;
  late AnimationController _giftLabelController;
  final RewardGlowController _giftGlow = RewardGlowController();
```

- [ ] **Step 3: Dispose the controller**

Find (around `home_screen.dart:293-298`):
```dart
  @override
  void dispose() {
    _giftIconController.dispose();
    _giftAmountController.dispose();
    _giftLabelController.dispose();
    super.dispose();
  }
```

Add `_giftGlow.dispose()`:
```dart
  @override
  void dispose() {
    _giftIconController.dispose();
    _giftAmountController.dispose();
    _giftLabelController.dispose();
    _giftGlow.dispose();
    super.dispose();
  }
```

- [ ] **Step 4: Trigger glow + haptic in `_playGiftAnimation`**

Find (around `home_screen.dart:55-62`):
```dart
    await Future.delayed(const Duration(milliseconds: 200));
    _giftIconController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _giftAmountController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _giftLabelController.forward();
```

Replace with:
```dart
    await Future.delayed(const Duration(milliseconds: 200));
    _giftIconController.forward();
    _giftGlow.play();
    Haptics.celebrate(CelebrateMoments.welcomeGift);
    await Future.delayed(const Duration(milliseconds: 300));
    _giftAmountController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _giftLabelController.forward();
```

- [ ] **Step 5: Wrap the gift icon container with RewardGlow**

Find (around `home_screen.dart:402-426`):
```dart
              ScaleTransition(
                scale: CurvedAnimation(
                    parent: _giftIconController, curve: Curves.elasticOut),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      // ...
                    ),
                    // ...
                  ),
                  child: Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                      size: 48, color: Colors.white),
                ),
              ),
```

Replace the entire `ScaleTransition` block with `RewardGlow` wrapping the
container directly (the `_giftIconController` and its `ScaleTransition` are
no longer needed for the icon — `RewardGlow` provides the scale flourish):

```dart
              RewardGlow(
                controller: _giftGlow,
                glowColor: AppColors.primary,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      // ... unchanged
                    ),
                    // ... unchanged
                  ),
                  child: Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                      size: 48, color: Colors.white),
                ),
              ),
```

- [ ] **Step 6: Delete the now-unused `_giftIconController`**

Find (around `home_screen.dart:29`):
```dart
  late AnimationController _giftIconController;
```
Delete this line.

Find the initialization (around `home_screen.dart:36-37`):
```dart
    _giftIconController = AnimationController(
        vsync: this, duration: AppDurations.hero);
```
Delete these two lines.

Find the disposal (around `home_screen.dart:295`):
```dart
    _giftIconController.dispose();
```
Delete this line.

- [ ] **Step 7: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/screens/home_screen.dart`
Expected: `No issues found!`

- [ ] **Step 8: Smoke-test**

Run: `cd flutter_app && flutter run -d <device>`
Expected: First-launch home shows the gift reveal. The gift icon now plays
the `RewardGlow` flourish (subtle scale-up + radial glow + settle) instead of
the elastic bounce. A heavy haptic fires once. Restart the app — the gift
reveal still plays normally (the screen5Played guard skips it on subsequent
home visits, not on app restarts; the `Haptics.celebrate` guard is session-
scoped so it fires fresh each launch).

- [ ] **Step 9: Commit**

```bash
cd flutter_app
git add lib/screens/home_screen.dart
git commit -m "Replace gift icon ScaleTransition with RewardGlow + celebrate haptic"
```

---

## Task 16: Migrate home_screen.dart — phase 4 (RewardGlow on ring + haptics in _completeTask + legend wiring)

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`

Final phase. Adds `RewardGlow` to the goal ring, fires it on the rising-edge
crossing of `goalProgress >= 100`. Adds `Haptics.reward()` / `milestone()` /
`celebrate(legendReached)` calls in `_completeTask`.

- [ ] **Step 1: Add the ring glow controller as a state field**

Find (around `home_screen.dart:30`):
```dart
  late AnimationController _giftAmountController;
  late AnimationController _giftLabelController;
  final RewardGlowController _giftGlow = RewardGlowController();
```

Add a new line below:
```dart
  late AnimationController _giftAmountController;
  late AnimationController _giftLabelController;
  final RewardGlowController _giftGlow = RewardGlowController();
  final RewardGlowController _ringGlow = RewardGlowController();
  double _lastGoalProgress = 0;
```

- [ ] **Step 2: Dispose the new controller**

Find the dispose method and add `_ringGlow.dispose()`:
```dart
  @override
  void dispose() {
    _giftAmountController.dispose();
    _giftLabelController.dispose();
    _giftGlow.dispose();
    _ringGlow.dispose();
    super.dispose();
  }
```

- [ ] **Step 3: Wrap the ring AnimatedContainer with RewardGlow**

Find the balance row's ring `AnimatedContainer` (around `home_screen.dart:609`):
```dart
        AnimatedContainer(
          duration: AppDurations.long,
          curve: AppCurves.warmOut,
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // ...
          ),
          child: Stack(
            // ...
          ),
        ),
```

Wrap it with `RewardGlow`:
```dart
        RewardGlow(
          controller: _ringGlow,
          glowColor: ringColor,
          child: AnimatedContainer(
            duration: AppDurations.long,
            curve: AppCurves.warmOut,
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // ... unchanged
            ),
            child: Stack(
              // ... unchanged
            ),
          ),
        ),
```

- [ ] **Step 4: Add rising-edge detection in `_buildBalanceRow`**

Find the start of `_buildBalanceRow` (around `home_screen.dart:585-595`):
```dart
  Widget _buildBalanceRow(AppState state) {
    final isSolidFill = state.goalProgress >= 100 || state.isLegend;
    final ringColor = state.ringColor;
    // ...
```

Add a rising-edge check immediately after these lines, BEFORE the `return Row(...)`:
```dart
  Widget _buildBalanceRow(AppState state) {
    final isSolidFill = state.goalProgress >= 100 || state.isLegend;
    final ringColor = state.ringColor;
    final centerTextColor = isSolidFill ? Colors.white : AppColors.ink;
    final centerSubColor = isSolidFill
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.inkTertiary;

    // Rising-edge detector: trigger ring glow when goalProgress crosses 100.
    final currentProgress = state.goalProgress;
    if (_lastGoalProgress < 100 && currentProgress >= 100) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ringGlow.play();
      });
    }
    _lastGoalProgress = currentProgress;

    return Row(
      // ... unchanged
```

(The post-frame callback ensures `_ringGlow.play()` runs after the build
completes — calling it during build would be a Flutter no-no.)

- [ ] **Step 5: Add Haptics.reward() at the top of `_completeTask`**

Find (around `home_screen.dart:91-95`):
```dart
  void _completeTask(String task) {
    final state = context.read<AppState>();
    if (state.completedTasks.contains(task)) return;

    final goalCompleted = state.completeTask(task);
```

Add `Haptics.reward()` after the early return:
```dart
  void _completeTask(String task) {
    final state = context.read<AppState>();
    if (state.completedTasks.contains(task)) return;

    Haptics.reward();
    final goalCompleted = state.completeTask(task);
```

- [ ] **Step 6: Add Haptics.milestone() and legend wiring in the goalCompleted branch**

Find (around `home_screen.dart:149-165`):
```dart
    // Goal completed — hold the solid fill, then advance
    if (goalCompleted) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        final s = context.read<AppState>();
        s.advanceGoal();
        s.addJourneyEntry(
          'Goal ${s.goalIndex} complete!',
          s.isLegend
              ? "You've earned it all."
              : 'Next goal: ${AppState.formatNumber(s.currentGoal.goalStars)} Stars',
          PhosphorIcons.trophy(PhosphorIconsStyle.fill),
          s.ringColor,
          s.ringColor.withValues(alpha: 0.1),
        );
      });
    }
```

Replace with:
```dart
    // Goal completed — hold the solid fill, then advance
    if (goalCompleted) {
      Haptics.milestone();
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        final s = context.read<AppState>();
        s.advanceGoal();
        if (s.isLegend) {
          Haptics.celebrate(CelebrateMoments.legendReached);
        }
        s.addJourneyEntry(
          'Goal ${s.goalIndex} complete!',
          s.isLegend
              ? "You've earned it all."
              : 'Next goal: ${AppState.formatNumber(s.currentGoal.goalStars)} Stars',
          PhosphorIcons.trophy(PhosphorIconsStyle.fill),
          s.ringColor,
          s.ringColor.withValues(alpha: 0.1),
        );
      });
    }
```

(Note: `Haptics.milestone()` fires immediately when the goal is reached.
`Haptics.celebrate(legendReached)` fires 2.5 seconds later, after `advanceGoal()`,
only if the legend state was reached. Both are correct — milestone for the
goal completion event, celebrate for the legend transition.)

- [ ] **Step 7: Add Haptics.milestone() in the allTasksCompleted branch**

Find (around `home_screen.dart:167-176`):
```dart
    if (state.allTasksCompleted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        state.addJourneyEntry(
          'All starter tasks done — Earn More unlocked!',
          // ...
        );
      });
    }
```

Add `Haptics.milestone()` immediately, before the delayed journey entry:
```dart
    if (state.allTasksCompleted) {
      Haptics.milestone();
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        state.addJourneyEntry(
          'All starter tasks done — Earn More unlocked!',
          // ... unchanged
        );
      });
    }
```

- [ ] **Step 8: Verify it compiles**

Run: `cd flutter_app && flutter analyze lib/screens/home_screen.dart`
Expected: `No issues found!`

- [ ] **Step 9: Smoke-test**

Run: `cd flutter_app && flutter run -d <device>`

Expected behavior on a fresh launch:
1. Welcome → trust → onboarding → home, gift reveal → glow + heavy haptic.
2. Tap a task card → `tick` haptic on press-in, `reward` haptic on release
   (the double-beat). Card transitions to completed state.
3. Complete all three onboarding tasks. After the third:
   - `milestone` haptic on goal completion (immediate).
   - `milestone` haptic on all-tasks-unlocked (also immediate).
   - Ring fills to 100%, `RewardGlow` plays on the ring.
   - 2.5s later, journey entry appears, goal advances.
4. Continue advancing through goals. On the final goal completion:
   - `milestone` haptic.
   - 2.5s later, `celebrate(legendReached)` fires (heavy haptic) — but only
     once per app session.

- [ ] **Step 10: Commit**

```bash
cd flutter_app
git add lib/screens/home_screen.dart
git commit -m "Add RewardGlow on ring and haptic calls in _completeTask"
```

---

## Task 17: Final grep gate verification

**Files:**
- No code changes. Verification step only.

- [ ] **Step 1: Run the three grep checks**

Run from `flutter_app/`:
```bash
cd flutter_app

# Check 1: Animation duration parameters
echo "=== Check 1: Inline duration: const Duration ==="
rg 'duration:\s*const Duration' lib/screens/ lib/widgets/ \
  --glob '!motion.dart' \
  --glob '!animated_gradient_bg.dart' \
  --glob '!trust_carousel_screen.dart' || echo "PASS — no matches"

# Check 2: Inline curves
echo "=== Check 2: Inline Curves. ==="
rg 'Curves\.' lib/screens/ lib/widgets/ \
  --glob '!motion.dart' || echo "PASS — no matches"

# Check 3: Raw HapticFeedback
echo "=== Check 3: Raw HapticFeedback ==="
rg 'HapticFeedback\.' lib/screens/ lib/widgets/ \
  --glob '!haptics.dart' || echo "PASS — no matches"
```

- [ ] **Step 2: Verify each check**

Expected:
- Check 1: PASS — no matches (after whitelisting motion.dart, animated_gradient_bg.dart, trust_carousel_screen.dart for its content-pacing duration).
- Check 2: PASS — no matches.
- Check 3: PASS — no matches.

If any check fails, identify the file and either migrate it or — if the
match is justifiable — add it to the whitelist in
`docs/superpowers/specs/2026-04-08-flutter-motion-system-design.md` Section 5
step 6 with a justification.

- [ ] **Step 3: Verify trust_carousel still has its 3000ms pacing intact**

Run:
```bash
cd flutter_app
rg 'Duration\(milliseconds: 3000\)' lib/screens/trust_carousel_screen.dart
```
Expected: 2 matches (the `_progressController` duration and the `Timer.periodic`
interval). These are content pacing — they should NOT be migrated.

- [ ] **Step 4: Verify animated_gradient_bg still has its 8s pacing intact**

Run:
```bash
cd flutter_app
rg 'Duration\(seconds: 8\)' lib/widgets/animated_gradient_bg.dart
```
Expected: 1 match (the `AnimationController` duration). Whitelisted.

- [ ] **Step 5: Run all tests**

Run: `cd flutter_app && flutter test`
Expected: All 3 PressScale tests PASS.

- [ ] **Step 6: Run flutter analyze on the whole project**

Run: `cd flutter_app && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Final smoke test — the full manual checklist from the spec**

From `docs/superpowers/specs/2026-04-08-flutter-motion-system-design.md`
Section 6, run through items 1-10 manually:

1. Welcome screen: logo breathes, CTAs press-scale, no haptic.
2. Trust + onboarding: entrance motion works, CTAs press-scale.
3. Home → gift reveal: RewardGlow + celebrate haptic, fires once per session.
4. Home → task completion: reward haptic per task, double-beat on press-in.
5. Home → goal completion: ring RewardGlow + milestone haptic.
6. Home → legend reached: celebrate haptic, fires once.
7. Home → all tasks done: milestone haptic + earn-more unlock.
8. Home → currency, nav, conv card: tick haptic + press-scale.
9. AppCard surfaces (game picker, onboarding preferences): press feedback.
10. Reduced motion: enable in device settings, verify scales don't animate
    but haptics still fire and taps still work.

- [ ] **Step 8: Commit a marker tag (optional)**

```bash
cd flutter_app
git tag -a motion-system-v1 -m "Motion system migration complete"
```

(Optional — only if the user wants a tag. Skip if they prefer not to tag.)

---

## Summary of files touched

**Created (6):**
- `flutter_app/lib/theme/motion.dart`
- `flutter_app/lib/services/haptics.dart`
- `flutter_app/lib/widgets/press_scale.dart`
- `flutter_app/lib/widgets/reward_glow.dart`
- `flutter_app/lib/widgets/breathing.dart`
- `flutter_app/test/widgets/press_scale_test.dart`

**Modified (8):**
- `flutter_app/lib/widgets/fade_route.dart`
- `flutter_app/lib/widgets/app_toast.dart`
- `flutter_app/lib/widgets/app_card.dart`
- `flutter_app/lib/screens/welcome_screen.dart`
- `flutter_app/lib/screens/trust_carousel_screen.dart`
- `flutter_app/lib/screens/onboarding_screen.dart`
- `flutter_app/lib/screens/journey_screen.dart`
- `flutter_app/lib/screens/home_screen.dart`

**Untouched (whitelisted or out of scope):**
- `flutter_app/lib/widgets/animated_gradient_bg.dart` (whitelisted)
- `flutter_app/lib/widgets/typewriter_text.dart` (whitelisted)
- `flutter_app/lib/widgets/progress_ring.dart` (no motion code)
- `flutter_app/lib/widgets/screen_scaffold.dart` (no motion code)
- `flutter_app/lib/widgets/bottom_sheet_shell.dart` (no motion code)
- `flutter_app/lib/playground/ring_playground.dart` (playground)
- `flutter_app/lib/state/app_state.dart` (state logic)
