# Flutter Motion System — Design

**Date:** 2026-04-08
**Scope:** `flutter_app/` (EarnWise MVP prototype)
**Goal:** Make the app feel more sophisticated by replacing ad-hoc, hand-rolled
animations with a small shared motion vocabulary, reusable interaction widgets,
and a single-source-of-truth haptic policy.

## Background

The current Flutter prototype has working but uncrafted motion:

- Inline durations scattered across files (200/300/400/500/600/800/1200ms).
- Mixed curves (`easeOutCubic`, `elasticOut`) chosen per call site.
- Hand-rolled `Future.delayed` chains for staggered entrances.
- No press / touch feedback on tappable surfaces.
- No haptics anywhere.
- The existing motion helpers (`fade_route`, `animated_gradient_bg`,
  `progress_ring`, `typewriter_text`, `app_toast`) are fine in isolation but
  share no vocabulary.

The aesthetic target is **playful warmth** — the Duolingo / Headspace
register: bouncy springs on rewards, gentle motion on idle elements, tasteful
but warm. Matches the existing cream / teal / Stars surface design.

## Approach

**Option A — Tokens + small set of reusable widgets.** Five new files give the
app a shared vocabulary and three reusable widgets, then a migration pass
through existing screens swaps inline motion for the new system.

Rejected alternatives:

- *Tokens file only* — no central place for press feedback or haptic policy;
  both would drift across call sites.
- *Full motion layer with custom AnimationController orchestration* — overkill
  for a five-screen prototype; pulls into refactoring screens that already
  work.

## Section 1 — Motion tokens (`lib/theme/motion.dart`)

A new file with three groups of constants. Foundation for everything else.

### Durations

| Token | Value | Use for |
|---|---|---|
| `instant` | 120ms | Press-scale snap-back, micro feedback |
| `short` | 220ms | Toggles, tiny state flips (currency pill, nav tab) |
| `medium` | 320ms | Default for state changes (task card → completed, earn-more unlock) |
| `long` | 480ms | Page transitions, entrance reveals |
| `hero` | 900ms | Multi-beat moments (ring fill, gift reveal stages) |

### Curves

| Token | Definition | Use for |
|---|---|---|
| `warmOut` | `Cubic(0.2, 0.9, 0.1, 1)` | Primary deceleration. Softer than `easeOutCubic`. Default for entrances and reveals. |
| `warmInOut` | `Cubic(0.45, 0, 0.15, 1)` | Symmetric; reversible transitions (toggles, expand/collapse) |
| `pop` | `Cubic(0.3, 1.4, 0.6, 1)` | Slight overshoot. Reward flourishes, badge bumps. Replaces `Curves.elasticOut` (too bouncy for the warm register). |
| `gentle` | `Curves.easeInOut` | Idle / breathing motion only |

### Spring

One preset, used by `PressScale`:

```dart
SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 0.85)
```

### Migration rule

After this file lands, no raw `Duration(milliseconds: …)` or `Curves.*`
remains in screen code. Enforced at PR review (no static lint).

## Section 2 — Haptics service (`lib/services/haptics.dart`)

Single source of truth for the haptic policy. Four methods. Every call site
in the app uses only these — no raw `HapticFeedback.*` anywhere else in `lib/`.

```dart
class Haptics {
  /// Ordinary state changes: nav switch, toggle, task tap initiation.
  /// Uses HapticFeedback.selectionClick — quiet, non-intrusive.
  static void tick();

  /// Completing a single task (profile done, survey done).
  /// Uses HapticFeedback.lightImpact.
  static void reward();

  /// Milestone: goal completed, streak advanced, day closed.
  /// Uses HapticFeedback.mediumImpact.
  static void milestone();

  /// Rare hero moments: welcome gift reveal, legend reached.
  /// Uses HapticFeedback.heavyImpact.
  /// Guarded: each [momentId] fires at most once per session. Different
  /// momentIds are independent — firing 'welcome_gift' does not block
  /// 'legend_reached'. Internal `Set<String> _firedMoments` tracks state.
  static void celebrate(String momentId);
}

/// Canonical momentId constants. Call sites must use these to avoid typos.
class CelebrateMoments {
  CelebrateMoments._();
  static const welcomeGift = 'welcome_gift';
  static const legendReached = 'legend_reached';
}
```

### Call site map

| Method | Fires on |
|---|---|
| `tick` | Nav tab switch · currency pill toggle · bottom-sheet option tap · `AppCard`-based rows (game picker, onboarding preferences) |
| `reward` | Task card → completed state (profile/survey/game/daily_survey/daily_play/daily_offer). The streak-first-bump moment piggybacks on this — the streak advances inside the same `_completeTask` flow, so no second haptic. |
| `milestone` | Goal completion · all-tasks-unlocked moment · day close |
| `celebrate(welcomeGift)` | Welcome gift reveal (125 Stars). Fires once per session. |
| `celebrate(legendReached)` | `state.isLegend` becomes true after `advanceGoal()` on the last goal. Fires once per session. |

### Policy notes

1. No haptic on ordinary buttons (email input tap, sign-in tap). These map to
   navigation, which already feels confirmed by the transition.
2. No haptic on the ambient gradient, toast appearance, or entrance reveals.
3. `celebrate` uses a session-scoped guard keyed by `momentId`. Each unique
   moment fires at most once per app run; different moments do not block each
   other. Matches the spirit of the existing `screen5Played` pattern in
   `app_state.dart` but lives in the haptics service so widget code doesn't
   own the bookkeeping.
4. Accessibility: if `MediaQueryData.disableAnimations` is true, the service
   still fires haptics (haptics help accessibility, motion hurts it). Platform
   haptic settings are respected by default.

## Section 3 — `PressScale` widget (`lib/widgets/press_scale.dart`)

Wraps any tappable surface and gives it physical press feedback.

### API

```dart
PressScale({
  required Widget child,
  required VoidCallback? onTap,
  double pressedScale = 0.97,
  HapticIntensity? haptic,   // null = no haptic
  bool enabled = true,
})

enum HapticIntensity { tick, reward, milestone }
// celebrate is intentionally NOT in this enum — it requires a momentId for
// the per-session guard, which an enum cannot carry. Celebrate haptics fire
// manually from screen code via Haptics.celebrate(momentId).
```

### Behavior

1. On press-in: animate `child` to `pressedScale` via `SpringSimulation` with
   the `pressSettle` spring from Section 1.
2. On press-out (release or cancel): animate back to `1.0` with the same spring.
3. If `haptic` is non-null, fire it **on press-in, before the spring** — touch
   feedback feels simultaneous with finger contact.
4. `onTap` fires on release, like a normal `GestureDetector`.
5. When `enabled: false` (e.g. completed task card), tapping is a no-op and no
   scale/haptic fires — but the widget still renders its child normally.
6. `MediaQuery.disableAnimations: true` → skip the spring, keep the haptic.

### Call site map

| Site | File | Haptic |
|---|---|---|
| Task cards (onboarding + daily) | `home_screen.dart` | `reward` on complete, `tick` on press-in |
| Earn-more tiles | `home_screen.dart` | `tick` |
| Conversational card | `home_screen.dart` | `tick` |
| Currency pill | `home_screen.dart` | `tick` |
| Nav items | `home_screen.dart` | `tick` |
| Bottom-sheet game options | `home_screen.dart` (via `AppCard`) | `tick` |
| Onboarding preference picker rows | `onboarding_screen.dart` (via `AppCard`) | `tick` |
| Primary CTAs (Google / Apple / Email) | `welcome_screen.dart` | none — see below |

### Why press-in haptic, not release

Releasing a press is when `onTap` fires and the screen typically transitions.
Adding a haptic there fights the transition. Firing on press-in makes the touch
feel acknowledged without competing with the result.

### Integration with `AppCard`

`AppCard` (`lib/widgets/app_card.dart`) already owns its tap gesture via
`GestureDetector` and is used by `_gameOption` in `home_screen.dart` and the
preference picker in `onboarding_screen.dart`. Wrapping `AppCard` call sites in
`PressScale` from the outside would either duplicate gesture handling or get
shadowed by the inner gesture.

**Fix:** refactor `AppCard` internally to use `PressScale` whenever
`onTap != null`. Add an optional `haptic` parameter that defaults to
`HapticIntensity.tick`. The existing API for callers stays the same (they keep
passing `onTap` and `selected`); they get press-scale + haptic for free. The
existing `AnimatedContainer(duration: 200ms)` for the `selected` color/border
transition stays, but the duration migrates to `AppDurations.short`.

```dart
// Before:
class AppCard extends StatelessWidget {
  // ...
  Widget build(BuildContext context) {
    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // ...
    );
    if (onTap == null) return decorated;
    return GestureDetector(onTap: onTap, child: decorated);
  }
}

// After:
class AppCard extends StatelessWidget {
  // ... + final HapticIntensity haptic;
  Widget build(BuildContext context) {
    final decorated = AnimatedContainer(
      duration: AppDurations.short,
      // ...
    );
    if (onTap == null) return decorated;
    return PressScale(onTap: onTap, haptic: haptic, child: decorated);
  }
}
```

This means the bottom-sheet game options and onboarding preference rows
inherit press feedback automatically when `AppCard` is migrated — they do not
need separate `PressScale` wrapping at the call site.

### Why no haptic on welcome CTAs

The Google / Apple / Email rows on `welcome_screen.dart` map directly to a
fade-route navigation. The transition itself is the confirmation; adding a
press-in `tick` would compete with it. These get press-scale only — visual
feedback without haptic noise. (This resolves a contradiction between earlier
draft sections of this spec.)

## Section 4 — `RewardGlow` and `Breathing` widgets

Two small wrappers handling the warmth side of the system.

### `RewardGlow` (`lib/widgets/reward_glow.dart`)

A celebration pulse for multi-stage reward moments.

```dart
RewardGlow({
  required Widget child,
  required RewardGlowController controller,
  Color glowColor = AppColors.accent,
})
```

**Three beats, total ~900ms (`hero` duration):**

1. 0–300ms: child scales `1.0` → `1.06` using `pop` curve.
2. 100–700ms: radial glow behind child fades 0 → 0.5 alpha → 0, expanding 0.8×
   to 1.4× of child bounds.
3. 300–900ms: child scales `1.06` → `1.0` using `warmOut`.

Renders as `Stack(children: [_glowLayer, child])` so the glow sits behind the
child without affecting layout.

**Applied to two sites:**

1. Gift icon (`home_screen.dart` gift overlay) — `play()` fires 200ms into the
   existing reveal sequence.
2. Goal ring (`home_screen.dart` balance row) — `play()` fires on the
   *transition* from < 100 to ≥ 100. Implementation: a `didChangeDependencies`
   /`Consumer` listener compares the current `goalProgress` against the
   previously rendered value; on the rising-edge crossing of 100, call
   `controller.play()` once.

The existing `_giftIconController` + `ScaleTransition` + `elasticOut` on the
gift icon gets deleted and replaced with `RewardGlow` around the gift container.
The other two controllers in the gift overlay (`_giftAmountController`,
`_giftLabelController`) stay; their job is staged content reveal, not
celebration.

### `Breathing` (`lib/widgets/breathing.dart`)

A very quiet idle oscillation for elements that should feel alive when nothing
is happening.

```dart
Breathing({
  required Widget child,
  Duration period = const Duration(seconds: 5),
  double amplitude = 0.015,   // max scale delta — 1.015 at peak
})
```

Sine-driven scale oscillation, no opacity, no position. `gentle` curve.
Auto-starts, auto-disposes. Disables on `MediaQuery.disableAnimations`.

**Applied to exactly one place:** the welcome screen logo (the "E" gradient
circle). Restraint is intentional — breathing everywhere becomes noise.

## Section 5 — Migration plan

### New files (no behavior change to existing code on land)

- `lib/theme/motion.dart`
- `lib/services/haptics.dart`
- `lib/widgets/press_scale.dart`
- `lib/widgets/reward_glow.dart`
- `lib/widgets/breathing.dart`

### Existing files

| File | Changes |
|---|---|
| `lib/widgets/fade_route.dart` | Default duration → `AppDurations.long`. No behavior change. |
| `lib/widgets/app_toast.dart` | Internal `_fadeDuration` → `AppDurations.long`. `showFor` content duration unchanged. |
| `lib/widgets/app_card.dart` | Refactor to use `PressScale` internally when `onTap != null`. Existing 200ms `AnimatedContainer` migrates to `AppDurations.short`. New optional `haptic` param defaults to `HapticIntensity.tick`. See Section 3 "Integration with `AppCard`" for the diff. |
| `lib/widgets/animated_gradient_bg.dart` | No change. Ambient, period intentional. |
| `lib/widgets/typewriter_text.dart` | No change. Specialty component — its 28ms `charDelay` is content pacing (per-character reveal), not a motion token. **Whitelisted from the grep gate** (see below). |
| `lib/widgets/progress_ring.dart` | No change. Static painter. |
| `lib/widgets/screen_scaffold.dart` | No change. Pure layout. |
| `lib/widgets/bottom_sheet_shell.dart` | No change. Pure layout. |
| `lib/screens/welcome_screen.dart` | Replace inline durations / curves with tokens. Wrap Google / Apple / Email CTAs with `PressScale(haptic: null)` — press-scale only, no haptic (see Section 3 "Why no haptic on welcome CTAs"). Wrap logo "E" container with `Breathing`. |
| `lib/screens/trust_carousel_screen.dart` | Inline durations / curves → tokens. Wrap any tappables with `PressScale`. (File not yet read; surprises flagged during implementation.) |
| `lib/screens/onboarding_screen.dart` | Same treatment. (File not yet read.) |
| `lib/screens/journey_screen.dart` | Same treatment. (File not yet read.) |
| `lib/screens/home_screen.dart` | Largest file. See detailed list below. |
| `lib/state/app_state.dart` | No edits. Haptics fire from the widget layer. |
| `lib/playground/ring_playground.dart` | No edits. Not user-facing. |

### `home_screen.dart` detail

1. Replace inline durations (200, 300, 400, 500, 600, 800, 1200ms) with tokens.
2. Replace `Curves.easeOutCubic` and `Curves.elasticOut` with tokens.
3. Delete `_giftIconController` and its `ScaleTransition` on the gift icon.
   Replace with `RewardGlow` around the gift container. `_glow.play()` fires
   from `_playGiftAnimation` at the moment the original elastic bounce would
   have started. Also fires `Haptics.celebrate()` there.
4. `_giftAmountController` and `_giftLabelController` stay; their curves and
   durations migrate to tokens.
5. Wrap task cards, earn tiles, conv card, currency pill, and nav items with
   `PressScale` using the haptic mapping from Section 3. Game-picker options
   inherit press feedback automatically via the `AppCard` refactor — no
   call-site change needed.
6. Inside `_completeTask`: add `Haptics.reward()` at the top. Add
   `Haptics.milestone()` inside the `goalCompleted` branch (after
   `s.advanceGoal()`) and inside the `allTasksCompleted` branch.
7. **Legend wiring.** Inside the `goalCompleted` branch in `_completeTask`,
   after the `s.advanceGoal()` call, check `s.isLegend`. If true, fire
   `Haptics.celebrate(CelebrateMoments.legendReached)`. This is the only place
   the legend transition is observable from the home screen, so it's the
   correct hook point.
8. Wrap the goal ring in a `RewardGlow` that fires when `state.goalProgress`
   transitions to 100. Also fires on the legend transition (the rising-edge
   detector covers both — legend implies `goalProgress == 100`).
9. `TweenAnimationBuilder` duration on the ring migrates from `1200ms` inline
   to `AppDurations.hero`.

### Order of implementation

1. Land the five new files. App still compiles.
2. Migrate `fade_route.dart` and `app_toast.dart` to use tokens. Smoke-test.
3. Migrate `welcome_screen.dart` fully. Smoke-test entrance + press feedback +
   logo breathing.
4. Migrate `home_screen.dart` — first the duration / curve pass, then
   `PressScale` wrapping, then `RewardGlow` on gift, then `RewardGlow` on ring,
   then `Haptics.*` calls.
5. Migrate `trust_carousel_screen.dart`, `onboarding_screen.dart`,
   `journey_screen.dart` — duration tokens + `PressScale` wrapping.
6. Final review pass — grep gate. The gate flags **animation timings**, not
   scheduler delays. Three searches must each return zero matches outside the
   whitelist:

   ```
   # Animation duration parameters (AnimatedContainer, AnimatedOpacity,
   # AnimatedSwitcher, AnimatedSlide, AnimationController, CurvedAnimation,
   # TweenAnimationBuilder all use the same `duration:` keyword arg).
   rg 'duration:\s*const Duration' lib/screens/ lib/widgets/

   # Inline curve references.
   rg 'Curves\.' lib/screens/ lib/widgets/

   # Raw HapticFeedback usage outside the haptics service.
   rg 'HapticFeedback\.' lib/screens/ lib/widgets/
   ```

   **Out of gate scope:** `Future.delayed(Duration(milliseconds: …))` and
   `Timer.periodic(Duration(milliseconds: …))`. These are scheduler /
   content-pacing concerns, not motion. They may reference `AppDurations.*`
   when meant to coincide with an animation (e.g. waiting for a fade to
   complete) but are not required to.

   **Whitelist** (justified exceptions to the gate):

   - `lib/widgets/typewriter_text.dart` — `charDelay` is content pacing, not
     a motion token. Forcing it through `AppDurations` would either degrade
     the typewriter feel or pollute the token namespace with a one-off. Note:
     this file uses `Timer.periodic`, which is already out of gate scope, so
     no whitelist entry is technically needed unless future edits add an
     animation widget.
   - `lib/widgets/animated_gradient_bg.dart` — the 8-second period on the
     `AnimationController` is ambient loop pacing, not a motion token.
     This file IS in gate scope (it uses `duration:` on a controller) and
     needs an explicit whitelist exception.
   - `lib/screens/trust_carousel_screen.dart` — the 3000ms `_progressController`
     duration is carousel content pacing (how long each slide shows), not
     motion. Whitelisted. The 450ms `AnimatedSwitcher` in the same file IS
     migrated to `AppDurations.long`.
   - `lib/theme/motion.dart`, `lib/services/haptics.dart`, and the new
     `lib/widgets/press_scale.dart` / `reward_glow.dart` / `breathing.dart` —
     these are the motion system itself; they define the tokens and use raw
     `HapticFeedback.*` underneath.

   Any new whitelist entry requires a justification in this spec.

## Section 6 — Testing

Deliberately light. `flutter_app/` is a prototype.

### Widget tests (`test/press_scale_test.dart`)

1. `PressScale` calls `onTap` on release.
2. `PressScale` with `enabled: false` does not call `onTap`.
3. `PressScale` does not crash when `MediaQuery.disableAnimations` is true.

### Not tested

- Motion tokens — they're constants.
- Haptics service — thin pass-through to `HapticFeedback.*`. Mocking platform
  channels for a prototype is bad ROI.
- `RewardGlow` / `Breathing` — visual behavior; assertions tautologically
  match implementation. Manual verification is more honest.

### Manual smoke test checklist

1. Welcome screen: logo breathes faintly; name / tagline / proof still stagger
   in; all three CTAs give press-scale feedback on press-in. **No haptic** —
   confirm by holding a press without releasing (no tick) and by releasing
   into the navigation transition.
2. Trust carousel + onboarding: entrance motion still works; any buttons
   wrapped in `PressScale` feel right.
3. Home → gift reveal: `RewardGlow` fires; `Haptics.celebrate()` fires once;
   replaying the screen (via `screen5Played` guard) does NOT re-fire.
4. Home → task completion: `reward` haptic fires on each of profile / survey /
   game; card transitions from active-teal to completed-cream.
5. Home → goal completion: `RewardGlow` fires on ring; `milestone` haptic
   fires.
6. Home → legend reached: complete the last goal; `celebrate(legendReached)`
   haptic fires once. Repeat the flow without restarting the app — should NOT
   re-fire (per-momentId guard).
7. Home → all tasks done: `milestone` haptic fires; earn-more unlocks.
8. Home → currency pill, nav items, conv card: `tick` haptic fires on tap;
   press-scale visible.
9. Bottom-sheet game options + onboarding preference picker: press-scale +
   `tick` haptic via the refactored `AppCard`.
10. Reduced motion: set `MediaQuery.disableAnimations: true`; verify scales
    don't animate but haptics still fire and taps still work.

### Out of scope

Perf profiling, frame-rate targets, golden tests. Investigated only if jank
appears during manual testing.

## Decisions accepted during brainstorming

- Five duration tiers (vs. coarser or finer).
- `pop` replaces `elasticOut` on the gift icon (no exception kept for the
  original bounce).
- `celebrate` guard is session-scoped (per `momentId`), not persisted across
  runs.
- Task cards get a double-beat haptic (`tick` on press-in + `reward` on
  completion).
- `trust_carousel`, `onboarding`, `journey` screens are read during
  implementation, not before writing this spec. (`onboarding` was partially
  read during code review to verify the AppCard usage; the rest is still
  deferred.)
- Step 6 grep enforcement is manual; no lint rule added.

## Decisions made during code review

- `Haptics.celebrate` takes a `momentId: String` parameter; the guard is a
  per-id `Set<String>`. Required to allow both `welcomeGift` and
  `legendReached` to fire without blocking each other.
- Welcome CTAs (Google / Apple / Email) get press-scale only, **no haptic**.
  Resolves a contradiction between the original Section 2 policy ("no haptic
  on sign-in") and the original Section 3 call-site map ("CTAs → tick"). The
  navigation transition is the confirmation.
- `AppCard` is refactored to use `PressScale` internally, rather than wrapping
  call sites externally. Avoids gesture-detector duplication on the
  bottom-sheet game options and onboarding preference picker.
- Legend hero haptic is wired inside `_completeTask` after `s.advanceGoal()`.
  Without this, the original migration plan never fired
  `celebrate(legendReached)` even though the call-site map promised it.
- Grep gate has an explicit, justified whitelist (`typewriter_text.dart`,
  `animated_gradient_bg.dart`, the motion system files themselves). Any new
  whitelist entry requires updating this spec.
