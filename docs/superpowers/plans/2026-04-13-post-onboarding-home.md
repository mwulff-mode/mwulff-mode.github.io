# Post-Onboarding Home Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `_buildDailyTasks` in `home_screen.dart` with a post-onboarding Home body that shows a Daily Goal card (with within-day extension to $3), a conditional "Continue earning" section of up to three in-progress games, and three section cards routing to placeholder Surveys/Offers/Tasks list screens.

**Architecture:** New `DailyGoalCard` widget lives in `flutter_app/lib/widgets/`. `AppState` gains daily goal fields (`dailyGoalStars`, `dailyExtensionOffered`, `_dailyResetDate`) and an `InstalledGame` model with a seeded list plus an `inProgressGames` getter. A new `_buildPostOnboardingBody` method in `HomeScreen` branches off `goalIndex > 0` and composes the Daily Goal card, the Continue section, and three `AppCard`-style Earn More rows. Routes go to a shared `PlaceholderListScreen` that will be replaced by sub-project 3. Celebrations are a direct `Haptics.celebrate(...)` call with a `// TODO sub-project 6: route through CelebrationsService` marker.

**Tech Stack:** Flutter 3, Provider, `phosphor_flutter` icons, existing `AppCard` / `PressScale` / `Haptics` helpers, `flutter_test`.

**Spec:** [docs/superpowers/specs/2026-04-13-post-onboarding-home-design.md](../specs/2026-04-13-post-onboarding-home-design.md)

---

## File Structure

**Create:**
- `flutter_app/lib/widgets/daily_goal_card.dart` — stateless Daily Goal hero card with default / goal-hit / extended states
- `flutter_app/lib/models/installed_game.dart` — `InstalledGame` data class
- `flutter_app/lib/screens/placeholder_list_screen.dart` — temporary destination for Surveys / Offers / Tasks routes until sub-project 3 replaces it
- `flutter_app/test/widgets/daily_goal_card_test.dart` — widget tests for the card states
- `flutter_app/test/screens/post_onboarding_home_test.dart` — widget tests for the full post-onboarding body

**Modify:**
- `flutter_app/lib/state/app_state.dart` — add daily goal fields, daily reset logic, `InstalledGame` seed list, `inProgressGames` getter, update `reset()`
- `flutter_app/lib/screens/home_screen.dart` — branch at line 476, add `_buildPostOnboardingBody`, inline Continue and Earn More sections
- `flutter_app/test/state/app_state_test.dart` — new test groups for daily goal and in-progress games

---

## Task 1: Add daily goal fields and reset logic to AppState

**Files:**
- Modify: `flutter_app/lib/state/app_state.dart`
- Test: `flutter_app/test/state/app_state_test.dart`

- [ ] **Step 1: Write the failing tests**

Append this group at the end of `flutter_app/test/state/app_state_test.dart`, inside `void main() { ... }`, just before the final closing brace:

```dart
  // ---------------------------------------------------------------------------
  // Daily goal
  // ---------------------------------------------------------------------------

  group('daily goal', () {
    test('dailyGoalStars defaults to 1500 (\$2.00)', () {
      final state = AppState();
      expect(state.dailyGoalStars, 1500);
    });

    test('dailyExtensionOffered defaults to false', () {
      final state = AppState();
      expect(state.dailyExtensionOffered, isFalse);
    });

    test('dailyGoalHit is false when earnedToday is below target', () {
      final state = AppState();
      state.earnedToday = 1499;
      expect(state.dailyGoalHit, isFalse);
    });

    test('dailyGoalHit is true when earnedToday reaches target', () {
      final state = AppState();
      state.earnedToday = 1500;
      expect(state.dailyGoalHit, isTrue);
    });

    test('pushDailyGoalToThree raises target to 2250 and marks offered', () {
      final state = AppState();
      state.earnedToday = 1500;
      state.pushDailyGoalToThree();
      expect(state.dailyGoalStars, 2250);
      expect(state.dailyExtensionOffered, isTrue);
    });

    test('pushDailyGoalToThree is a no-op if already offered', () {
      final state = AppState();
      state.dailyExtensionOffered = true;
      state.dailyGoalStars = 1500; // banked scenario
      state.pushDailyGoalToThree();
      expect(state.dailyGoalStars, 1500, reason: 'must not re-push');
    });

    test('bankDailyGoal marks offered but leaves target at 1500', () {
      final state = AppState();
      state.earnedToday = 1500;
      state.bankDailyGoal();
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyExtensionOffered, isTrue);
    });

    test('pushDailyGoalToThree notifies listeners', () {
      final state = AppState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);
      state.pushDailyGoalToThree();
      expect(notifyCount, 1);
    });

    test('bankDailyGoal notifies listeners', () {
      final state = AppState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);
      state.bankDailyGoal();
      expect(notifyCount, 1);
    });

    test('checkDailyReset resets earnedToday, target, and extension flag when date changes', () {
      final state = AppState();
      state.earnedToday = 2000;
      state.dailyGoalStars = 2250;
      state.dailyExtensionOffered = true;
      // Force last reset date to yesterday.
      state.debugSetDailyResetDate('2000-01-01');
      state.checkDailyReset();
      expect(state.earnedToday, 0);
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyExtensionOffered, isFalse);
    });

    test('checkDailyReset is a no-op when date has not changed', () {
      final state = AppState();
      state.checkDailyReset(); // sets last reset date to today
      state.earnedToday = 500;
      state.checkDailyReset();
      expect(state.earnedToday, 500, reason: 'same-day call must not reset');
    });

    test('first checkDailyReset on a fresh state preserves same-session progress', () {
      // Onboarding just ran, so earnedToday already has value. The very
      // first time Home mounts and checkDailyReset() is called, it must
      // only anchor today's date — never wipe counters that were built
      // earlier in the same day.
      final state = AppState();
      state.earnedToday = 900;
      state.checkDailyReset();
      expect(state.earnedToday, 900);
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyExtensionOffered, isFalse);
    });

    test('reset() restores daily goal fields to defaults', () {
      final state = AppState();
      state.dailyGoalStars = 2250;
      state.dailyExtensionOffered = true;
      state.reset();
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyExtensionOffered, isFalse);
    });

    test('completeTask does not crash when haptic fires on goal crossing', () {
      // The celebration lives inside completeTask. We exercise the exact
      // rising edge (crossing dailyGoalStars for the first time) to make
      // sure the Haptics call compiles and does not throw under flutter
      // test. Haptics.celebrate is per-run guarded, so repeats are safe.
      Haptics.debugResetCelebrateGuard();
      final state = AppState();
      // Load earnedToday right up against the threshold so the next
      // task crosses it.
      state.earnedToday = state.dailyGoalStars - 100;
      // Pick a task whose reward is large enough to cross 1500.
      state.completeTask('game_milestone'); // +600 stars
      expect(state.dailyGoalHit, isTrue);
    });

    test('second goal crossing in the same day does not re-celebrate', () {
      // Manually flip the guard to prove the second cross is a no-op on
      // the internal flag. We can not observe the haptic directly, but
      // we can observe that a second crossing does not throw and the
      // state stays consistent.
      Haptics.debugResetCelebrateGuard();
      final state = AppState();
      state.earnedToday = state.dailyGoalStars - 100;
      state.completeTask('game_milestone');
      // Synthetically drop earnedToday back under the goal to simulate a
      // second crossing path, then cross again. The second call must not
      // throw and must leave dailyGoalHit true.
      state.earnedToday = state.dailyGoalStars - 10;
      state.completeTask('daily_offer');
      expect(state.dailyGoalHit, isTrue);
    });
  });
```

The Haptics test imports need to be present at the top of `flutter_app/test/state/app_state_test.dart`. Add this import near the existing imports if missing:

```dart
import 'package:earnwise_mvp/services/haptics.dart';
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd flutter_app && flutter test test/state/app_state_test.dart
```

Expected: failures complaining about `dailyGoalStars`, `dailyExtensionOffered`, `dailyGoalHit`, `pushDailyGoalToThree`, `bankDailyGoal`, `checkDailyReset`, and `debugSetDailyResetDate` being undefined.

- [ ] **Step 3: Add fields, getters, and methods to AppState**

In `flutter_app/lib/state/app_state.dart`, add the following fields to the `AppState` class, right after the existing `List<JourneyEntry> journeyLog = [];` line (around line 88):

```dart
  // Daily goal (post-onboarding). earnedToday is reused as the progress
  // counter; it resets at local midnight via checkDailyReset.
  int dailyGoalStars = 1500; // $2.00
  bool dailyExtensionOffered = false;
  String _dailyResetDate = ''; // yyyy-MM-dd of last reset, empty until first check
  bool _dailyGoalCelebrated = false; // rising-edge guard for the goal-hit celebration
```

Then add these methods to `AppState`, placed logically near `completeTask` (after the `completeTask` method, before `redeemPayout`):

```dart
  bool get dailyGoalHit => earnedToday >= dailyGoalStars;

  /// Extend today's goal from $2 to $3. No-op if the user has already
  /// banked or pushed today.
  void pushDailyGoalToThree() {
    if (dailyExtensionOffered) return;
    dailyGoalStars = 2250; // $3.00
    dailyExtensionOffered = true;
    notifyListeners();
  }

  /// Keep today's $2 goal and stop prompting for an extension.
  void bankDailyGoal() {
    if (dailyExtensionOffered) return;
    dailyExtensionOffered = true;
    notifyListeners();
  }

  /// Call once on Home mount and again when the app resumes. Resets the
  /// daily counters when the local date has actually rolled over.
  ///
  /// The first call on a fresh AppState must be a no-op on the counters —
  /// it only records today's date as the reset anchor. Otherwise same-day
  /// progress that was just built up (e.g. from onboarding tasks earlier
  /// in the same session) would be wiped the first time Home mounts.
  void checkDailyReset() {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_dailyResetDate == today) return;
    final isFirstInit = _dailyResetDate.isEmpty;
    _dailyResetDate = today;
    if (isFirstInit) return;
    earnedToday = 0;
    dailyGoalStars = 1500;
    dailyExtensionOffered = false;
    _dailyGoalCelebrated = false;
    notifyListeners();
  }

  /// Test-only helper so unit tests can force a date-rollover scenario
  /// without mocking DateTime.now.
  @visibleForTesting
  void debugSetDailyResetDate(String isoDate) {
    _dailyResetDate = isoDate;
  }
```

Add these imports at the top of the file if not already present:

```dart
import 'package:flutter/foundation.dart';
import '../services/haptics.dart';
```

Then update `reset()` (currently ending around line 289) so the new persistent fields get restored. Find these existing lines inside `reset()`:

```dart
    hasRedeemed = false;
    selectedPreferences = <String>[];
```

And insert the new resets immediately after `hasRedeemed = false;`:

```dart
    dailyGoalStars = 1500;
    dailyExtensionOffered = false;
    _dailyResetDate = '';
    _dailyGoalCelebrated = false;
```

Finally, patch `completeTask` so the daily goal celebration fires on the rising edge (when `earnedToday` crosses `dailyGoalStars` for the first time today), not on the user's response to the extension prompt. The existing method body (around lines 221-239) is:

```dart
  bool completeTask(String task) {
    if (completedTasks.contains(task)) return false;
    completedTasks.add(task);
    lastCompletedTask = task;
    final prevStars = stars;
    final earned = taskStars[task] ?? 0;
    stars += earned;
    earnedToday += earned;
    tasksCompleted++;
    notifyListeners();

    // Check if we crossed a goal threshold
    if (!isLegend &&
        stars >= currentGoal.goalStars &&
        prevStars < currentGoal.goalStars) {
      return true;
    }
    return false;
  }
```

Replace with:

```dart
  bool completeTask(String task) {
    if (completedTasks.contains(task)) return false;
    completedTasks.add(task);
    lastCompletedTask = task;
    final prevStars = stars;
    final prevEarnedToday = earnedToday;
    final earned = taskStars[task] ?? 0;
    stars += earned;
    earnedToday += earned;
    tasksCompleted++;

    // Rising-edge celebration: fires once the first time the user crosses
    // today's daily goal, regardless of which Home button they tap next.
    // This matches the Home spec: the celebration belongs to the goal-hit
    // transition, not to the extension prompt's Push/Bank actions.
    // TODO sub-project 6: route through CelebrationsService instead of
    // calling Haptics directly from state.
    if (!_dailyGoalCelebrated &&
        earnedToday >= dailyGoalStars &&
        prevEarnedToday < dailyGoalStars) {
      _dailyGoalCelebrated = true;
      Haptics.celebrate(CelebrateMoments.goalReached);
    }

    notifyListeners();

    // Check if we crossed a lifetime goal threshold
    if (!isLegend &&
        stars >= currentGoal.goalStars &&
        prevStars < currentGoal.goalStars) {
      return true;
    }
    return false;
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
cd flutter_app && flutter test test/state/app_state_test.dart
```

Expected: all new `daily goal` group tests pass. Existing tests still pass.

- [ ] **Step 5: Commit**

```bash
cd flutter_app && cd .. && git add flutter_app/lib/state/app_state.dart flutter_app/test/state/app_state_test.dart
git commit -m "feat(state): add daily goal fields and midnight reset to AppState"
```

---

## Task 2: Add InstalledGame model and in-progress games seed

**Files:**
- Create: `flutter_app/lib/models/installed_game.dart`
- Modify: `flutter_app/lib/state/app_state.dart`
- Test: `flutter_app/test/state/app_state_test.dart`

- [ ] **Step 1: Write the failing tests**

Append this group inside `void main() { ... }` in `flutter_app/test/state/app_state_test.dart`, right after the `daily goal` group:

```dart
  // ---------------------------------------------------------------------------
  // In-progress games
  // ---------------------------------------------------------------------------

  group('in-progress games', () {
    test('installedGames seed contains at least two games', () {
      final state = AppState();
      expect(state.installedGames.length, greaterThanOrEqualTo(2));
    });

    test('inProgressGames returns only games with remaining milestones', () {
      final state = AppState();
      final filtered = state.inProgressGames;
      expect(filtered.every((g) => g.nextMilestoneReward > 0), isTrue);
    });

    test('inProgressGames is ordered by lastPlayedAt, most recent first', () {
      final state = AppState();
      final list = state.inProgressGames;
      for (int i = 1; i < list.length; i++) {
        expect(
          list[i - 1].lastPlayedAt.isAfter(list[i].lastPlayedAt) ||
              list[i - 1].lastPlayedAt.isAtSameMomentAs(list[i].lastPlayedAt),
          isTrue,
          reason: 'index $i should be at or after index ${i - 1}',
        );
      }
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd flutter_app && flutter test test/state/app_state_test.dart
```

Expected: failures complaining about `installedGames`, `inProgressGames`, or `InstalledGame` being undefined.

- [ ] **Step 3: Create the InstalledGame model**

Create `flutter_app/lib/models/installed_game.dart`:

```dart
/// A minimal per-game state record used by the Post-Onboarding Home
/// "Continue earning" section. This is a v1 placeholder — sub-project 3
/// (Tasks list screen) may replace this with a richer model.
class InstalledGame {
  final String id;
  final String name;
  final String iconPath;
  final String nextMilestoneLabel;
  final double nextMilestoneReward;
  final DateTime lastPlayedAt;

  const InstalledGame({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.nextMilestoneLabel,
    required this.nextMilestoneReward,
    required this.lastPlayedAt,
  });

  /// True when the user still has at least one milestone to complete.
  /// v1 assumes any seeded game with a positive reward is in progress.
  bool get hasRemainingMilestones => nextMilestoneReward > 0;
}
```

- [ ] **Step 4: Add the seed list and getter to AppState**

At the top of `flutter_app/lib/state/app_state.dart`, add the import:

```dart
import '../models/installed_game.dart';
```

Inside the `AppState` class, add these fields right after the `bool dailyExtensionOffered = false;` line from Task 1:

```dart
  // In-progress games for the Post-Onboarding Home "Continue earning"
  // section. Seeded for v1 — names and icon paths match the real catalog
  // in `data/games.dart` so `gamesByName[game.name]` resolves and
  // `Image.asset(game.iconPath)` does not fall back to placeholder art.
  // Replaced by a real per-game progress model when sub-project 3
  // (Tasks list screen) lands.
  List<InstalledGame> installedGames = [
    InstalledGame(
      id: 'candy_crush',
      name: 'Candy Crush',
      iconPath: 'assets/app_icons/Candy_Crush_Saga.png',
      nextMilestoneLabel: 'Reach Level 50',
      nextMilestoneReward: 2.00,
      lastPlayedAt: DateTime(2026, 4, 13, 9, 15),
    ),
    InstalledGame(
      id: 'solitaire',
      name: 'Solitaire',
      iconPath: 'assets/app_icons/Solitaire_Classic.png',
      nextMilestoneLabel: 'Win 75 games',
      nextMilestoneReward: 2.50,
      lastPlayedAt: DateTime(2026, 4, 12, 20, 40),
    ),
  ];

  List<InstalledGame> get inProgressGames {
    final filtered =
        installedGames.where((g) => g.hasRemainingMilestones).toList();
    filtered.sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    return filtered;
  }
```

Then update `reset()` to restore the seed. Find the line from Task 1:

```dart
    dailyGoalStars = 1500;
    dailyExtensionOffered = false;
    _dailyResetDate = '';
```

And append:

```dart
    installedGames = [
      InstalledGame(
        id: 'candy_crush',
        name: 'Candy Crush',
        iconPath: 'assets/app_icons/Candy_Crush_Saga.png',
        nextMilestoneLabel: 'Reach Level 50',
        nextMilestoneReward: 2.00,
        lastPlayedAt: DateTime(2026, 4, 13, 9, 15),
      ),
      InstalledGame(
        id: 'solitaire',
        name: 'Solitaire',
        iconPath: 'assets/app_icons/Solitaire_Classic.png',
        nextMilestoneLabel: 'Win 75 games',
        nextMilestoneReward: 2.50,
        lastPlayedAt: DateTime(2026, 4, 12, 20, 40),
      ),
    ];
```

- [ ] **Step 5: Run the tests**

```bash
cd flutter_app && flutter test test/state/app_state_test.dart
```

Expected: all new `in-progress games` tests pass. Existing tests still pass.

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/models/installed_game.dart flutter_app/lib/state/app_state.dart flutter_app/test/state/app_state_test.dart
git commit -m "feat(state): add InstalledGame model and seeded in-progress games list"
```

---

## Task 3: Create the DailyGoalCard widget

**Files:**
- Create: `flutter_app/lib/widgets/daily_goal_card.dart`
- Test: `flutter_app/test/widgets/daily_goal_card_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Create `flutter_app/test/widgets/daily_goal_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/widgets/daily_goal_card.dart';

Future<void> pumpCard(WidgetTester tester, AppState state) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(
        home: Scaffold(body: DailyGoalCard()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('DailyGoalCard', () {
    testWidgets('default state shows "\$X of \$2.00"', (tester) async {
      final state = AppState()..earnedToday = 750; // $1.00
      await pumpCard(tester, state);
      expect(find.textContaining('\$1.00'), findsOneWidget);
      expect(find.textContaining('\$2.00'), findsOneWidget);
      expect(find.text('Push to \$3'), findsNothing);
    });

    testWidgets('goal-hit state shows the extension prompt', (tester) async {
      final state = AppState()..earnedToday = 1500;
      await pumpCard(tester, state);
      expect(find.textContaining("you hit today's \$2"), findsOneWidget);
      expect(find.text('Push to \$3'), findsOneWidget);
      expect(find.text('Bank it'), findsOneWidget);
    });

    testWidgets('tapping "Push to \$3" raises target and hides the prompt',
        (tester) async {
      final state = AppState()..earnedToday = 1500;
      await pumpCard(tester, state);
      await tester.tap(find.text('Push to \$3'));
      await tester.pump();
      expect(state.dailyGoalStars, 2250);
      expect(state.dailyExtensionOffered, isTrue);
      expect(find.text('Push to \$3'), findsNothing);
      // Progress bar should now show target \$3.00.
      expect(find.textContaining('\$3.00'), findsOneWidget);
    });

    testWidgets('tapping "Bank it" keeps \$2 target and hides the prompt',
        (tester) async {
      final state = AppState()..earnedToday = 1500;
      await pumpCard(tester, state);
      await tester.tap(find.text('Bank it'));
      await tester.pump();
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyExtensionOffered, isTrue);
      expect(find.text('Push to \$3'), findsNothing);
      // In banked state, card shows "Goal complete" or target still \$2.00.
      expect(find.textContaining('\$2.00'), findsOneWidget);
    });

    testWidgets('extended state after push shows "\$X of \$3.00"',
        (tester) async {
      final state = AppState()
        ..earnedToday = 1800
        ..dailyGoalStars = 2250
        ..dailyExtensionOffered = true;
      await pumpCard(tester, state);
      expect(find.textContaining('\$2.40'), findsOneWidget); // 1800/750
      expect(find.textContaining('\$3.00'), findsOneWidget);
      expect(find.text('Push to \$3'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd flutter_app && flutter test test/widgets/daily_goal_card_test.dart
```

Expected: failure complaining about `daily_goal_card.dart` not found.

- [ ] **Step 3: Create the DailyGoalCard widget**

Create `flutter_app/lib/widgets/daily_goal_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/haptics.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Hero card at the top of the Post-Onboarding Home body. Renders three
/// states derived from AppState: default (progress toward target),
/// goal-hit (extension prompt with Push / Bank actions), and extended
/// (progress toward \$3 after a push, or banked full bar at \$2).
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
    final earnedDollars = state.earnedToday / AppState.starsPerDollar;
    final targetDollars = state.dailyGoalStars / AppState.starsPerDollar;
    final fillFraction =
        (state.earnedToday / state.dailyGoalStars).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.creamDeep, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${earnedDollars.toStringAsFixed(2)}',
                style: AppText.display.copyWith(color: AppColors.ink),
              ),
              const SizedBox(width: 6),
              Text(
                'of \$${targetDollars.toStringAsFixed(2)}',
                style: AppText.body.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
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
          const SizedBox(height: 16),
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
```

The card only fires `Haptics.confirm()` for CTA taps. The louder goal-hit celebration (`Haptics.celebrate(CelebrateMoments.goalReached)`) is wired into `AppState.completeTask` in Task 1 so it fires on the rising edge of the goal-hit transition, not on the user's response to the extension prompt.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
cd flutter_app && flutter test test/widgets/daily_goal_card_test.dart
```

Expected: all 5 DailyGoalCard tests pass.

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/widgets/daily_goal_card.dart flutter_app/test/widgets/daily_goal_card_test.dart
git commit -m "feat(home): add DailyGoalCard widget with default, prompt, and extended states"
```

---

## Task 4: Create PlaceholderListScreen for Surveys / Offers / Tasks routes

**Files:**
- Create: `flutter_app/lib/screens/placeholder_list_screen.dart`

- [ ] **Step 1: Create the placeholder screen**

Create `flutter_app/lib/screens/placeholder_list_screen.dart`:

```dart
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
```

Before committing, verify `ScreenScaffold` and its `animatedGradient` parameter exist. They are used in `journey_screen.dart` and `onboarding_screen.dart`, so they should be present.

- [ ] **Step 2: Run the full test suite to confirm nothing broke**

```bash
cd flutter_app && flutter test
```

Expected: same test count as before Task 4, all passing.

- [ ] **Step 3: Commit**

```bash
git add flutter_app/lib/screens/placeholder_list_screen.dart
git commit -m "feat(home): add PlaceholderListScreen as temporary target for Earn More routes"
```

---

## Task 5: Branch HomeScreen build to render a post-onboarding body

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`
- Test: `flutter_app/test/screens/post_onboarding_home_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `flutter_app/test/screens/post_onboarding_home_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/home_shell.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/widgets/daily_goal_card.dart';

Future<void> pumpPostOnboardingHome(
  WidgetTester tester, {
  void Function(AppState)? setup,
}) async {
  final state = AppState()
    ..screen5Played = true
    ..welcomeModalShown = true
    ..goalIndex = 1 // Post-onboarding: past first goal.
    ..userName = 'Sarah';
  if (setup != null) setup(state);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: HomeShell()),
    ),
  );
  await tester.pump();
}

void main() {
  group('Post-Onboarding Home', () {
    testWidgets('renders the DailyGoalCard instead of Today\'s Tasks',
        (tester) async {
      await pumpPostOnboardingHome(tester);
      expect(find.byType(DailyGoalCard), findsOneWidget);
      expect(find.text("Today's Tasks"), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd flutter_app && flutter test test/screens/post_onboarding_home_test.dart
```

Expected: failure because `DailyGoalCard` is not yet rendered by `HomeShell` when `goalIndex == 1`.

- [ ] **Step 3: Add the post-onboarding branch in home_screen.dart**

Open `flutter_app/lib/screens/home_screen.dart` and add the `DailyGoalCard` import at the top with the other widget imports:

```dart
import '../widgets/daily_goal_card.dart';
```

The daily reset check must NOT run from inside `build()` because `checkDailyReset` may call `notifyListeners()`, and mutating a `ChangeNotifier` during build throws a framework assertion. Hook it in `initState` via a post-frame callback instead. Find the existing `initState` at the top of `_HomeScreenState` (around line 44):

```dart
  @override
  void initState() {
    super.initState();
```

Insert the post-frame callback right after `super.initState();`:

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().checkDailyReset();
    });
```

This runs exactly once per Home mount, after the first frame is built, outside any build scope. It is enough for v1 — if a user keeps the app open past midnight, the reset fires on the next Home remount. A lifecycle-aware resume hook is a follow-up.

Then find the build section around line 465-486 that renders the main Home body. The existing code is:

```dart
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingRow(state),
                    const SizedBox(height: AppSpacing.xl),

                    // Balance + Ring row
                    _buildBalanceRow(state),
                    const SizedBox(height: AppSpacing.xl),

                    // Starter tasks
                    _buildStarterTasks(state),
                    const SizedBox(height: AppSpacing.lg),

                    // Earn more section
                    _buildEarnMore(state),
                    // Extra bottom space so content clears the floating glass nav
                    const SizedBox(height: 120),
                  ],
                ),
```

Replace it with a branch on `goalIndex > 0`:

```dart
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingRow(state),
                    const SizedBox(height: AppSpacing.xl),
                    if (state.goalIndex > 0)
                      ..._buildPostOnboardingBody(state)
                    else ...[
                      _buildBalanceRow(state),
                      const SizedBox(height: AppSpacing.xl),
                      _buildStarterTasks(state),
                      const SizedBox(height: AppSpacing.lg),
                      _buildEarnMore(state),
                    ],
                    // Extra bottom space so content clears the floating glass nav
                    const SizedBox(height: 120),
                  ],
                ),
```

Then add a new method just above `_buildStarterTasks` (around line 716):

```dart
  List<Widget> _buildPostOnboardingBody(AppState state) {
    return const [
      DailyGoalCard(),
      SizedBox(height: AppSpacing.lg),
      // Continue earning section added in Task 6.
      // Earn more section added in Task 7.
    ];
  }
```

Note: the daily reset call lives in `initState`, not in this method. Never call `checkDailyReset()` from inside `build()` — it calls `notifyListeners()` on the rollover path and will trip Flutter's "setState during build" assertion.

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd flutter_app && flutter test test/screens/post_onboarding_home_test.dart
```

Expected: the `renders the DailyGoalCard` test passes. Existing `home_shell_test.dart` still passes.

- [ ] **Step 5: Run the full test suite**

```bash
cd flutter_app && flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/screens/home_screen.dart flutter_app/test/screens/post_onboarding_home_test.dart
git commit -m "feat(home): branch HomeScreen body for post-onboarding state with DailyGoalCard"
```

---

## Task 6: Render the "Continue earning" section

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`
- Modify: `flutter_app/test/screens/post_onboarding_home_test.dart`

- [ ] **Step 1: Write the failing tests**

Append the following `testWidgets` blocks inside the existing `Post-Onboarding Home` group in `flutter_app/test/screens/post_onboarding_home_test.dart`:

```dart
    testWidgets('shows Continue earning cards for in-progress games',
        (tester) async {
      await pumpPostOnboardingHome(tester);
      expect(find.text('Continue earning'), findsOneWidget);
      expect(find.text('Candy Crush'), findsOneWidget);
      expect(find.text('Solitaire'), findsOneWidget);
    });

    testWidgets('hides the Continue earning section when no in-progress games',
        (tester) async {
      await pumpPostOnboardingHome(tester, setup: (s) {
        s.installedGames = [];
      });
      expect(find.text('Continue earning'), findsNothing);
    });

    testWidgets('caps Continue earning at 3 cards', (tester) async {
      await pumpPostOnboardingHome(tester, setup: (s) {
        s.installedGames = List.generate(
          5,
          (i) => InstalledGame(
            id: 'game_$i',
            name: 'Game $i',
            iconPath: 'assets/logos/unknown.png',
            nextMilestoneLabel: 'Level ${i + 1}',
            nextMilestoneReward: 1.0,
            lastPlayedAt: DateTime(2026, 4, 13, 10, i),
          ),
        );
      });
      expect(find.text('Game 4'), findsOneWidget); // most recent
      expect(find.text('Game 3'), findsOneWidget);
      expect(find.text('Game 2'), findsOneWidget);
      expect(find.text('Game 1'), findsNothing); // dropped
      expect(find.text('Game 0'), findsNothing); // dropped
    });
```

At the top of the test file, add the import so `InstalledGame` is available:

```dart
import 'package:earnwise_mvp/models/installed_game.dart';
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd flutter_app && flutter test test/screens/post_onboarding_home_test.dart
```

Expected: three new failures because `Continue earning` is not yet rendered.

- [ ] **Step 3: Implement the Continue earning section**

Open `flutter_app/lib/screens/home_screen.dart`. Replace the `_buildPostOnboardingBody` method stub from Task 5:

```dart
  List<Widget> _buildPostOnboardingBody(AppState state) {
    return const [
      DailyGoalCard(),
      SizedBox(height: AppSpacing.lg),
      // Continue earning section added in Task 6.
      // Earn more section added in Task 7.
    ];
  }
```

with the following implementation that conditionally appends the Continue section:

```dart
  List<Widget> _buildPostOnboardingBody(AppState state) {
    final inProgress = state.inProgressGames.take(3).toList();
    return [
      const DailyGoalCard(),
      const SizedBox(height: AppSpacing.lg),
      if (inProgress.isNotEmpty) ...[
        Text(
          'Continue earning',
          style: AppText.listItem.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < inProgress.length; i++) ...[
          _buildContinueCard(inProgress[i]),
          if (i < inProgress.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
      // Earn more section added in Task 7.
    ];
  }

  Widget _buildContinueCard(InstalledGame game) {
    return PressScale(
      onTap: () => _openGameDetail(game),
      haptic: null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                game.iconPath,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.creamDeep,
                  alignment: Alignment.center,
                  child: Text(
                    game.name.isEmpty ? '?' : game.name[0].toUpperCase(),
                    style: AppText.bodyStrong.copyWith(color: AppColors.ink),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: AppText.bodyStrong
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game.nextMilestoneLabel,
                    style: AppText.caption
                        .copyWith(color: AppColors.inkSecondary),
                  ),
                ],
              ),
            ),
            Text(
              '\$${game.nextMilestoneReward.toStringAsFixed(2)}',
              style: AppText.bodyStrong.copyWith(color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              size: 18,
              color: AppColors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _openGameDetail(InstalledGame game) {
    // v1: look the installed game up in the real catalog by display name.
    // `gamesByName` is a `Map<String, Game>` exported from data/games.dart
    // keyed by the same strings we use for `InstalledGame.name` in the
    // seed list (Candy Crush, Solitaire, Word Search). `slideUpRoute`
    // matches the existing `_showGamePicker` route pattern used elsewhere
    // in this file.
    final match = gamesByName[game.name];
    if (match == null) return;
    Navigator.of(context).push(
      slideUpRoute(
        GameDetailScreen(
          game: match,
          onInstall: () {},
        ),
      ),
    );
  }
```

Add the import for `InstalledGame` at the top of `home_screen.dart` if not already present:

```dart
import '../models/installed_game.dart';
```

`gamesByName`, `slideUpRoute`, and `GameDetailScreen` are already imported from the existing `_showGamePicker` implementation, so no additional imports are required.

- [ ] **Step 4: Run the tests**

```bash
cd flutter_app && flutter test test/screens/post_onboarding_home_test.dart
```

Expected: all four `Post-Onboarding Home` tests pass.

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/screens/home_screen.dart flutter_app/test/screens/post_onboarding_home_test.dart
git commit -m "feat(home): render Continue earning section with up to 3 in-progress games"
```

---

## Task 7: Render the "Earn more" section with three routing section cards

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`
- Modify: `flutter_app/test/screens/post_onboarding_home_test.dart`

- [ ] **Step 1: Write the failing tests**

Append to the `Post-Onboarding Home` group in `flutter_app/test/screens/post_onboarding_home_test.dart`:

```dart
    testWidgets('shows three Earn more section cards', (tester) async {
      await pumpPostOnboardingHome(tester);
      expect(find.text('Earn more'), findsOneWidget);
      expect(find.text('Surveys'), findsOneWidget);
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
    });

    testWidgets('tapping the Surveys card pushes PlaceholderListScreen',
        (tester) async {
      await pumpPostOnboardingHome(tester);
      await tester.tap(find.text('Surveys'));
      await tester.pumpAndSettle();
      // PlaceholderListScreen shows the title we passed in and the
      // "coming soon" subtitle fragment.
      expect(find.byType(PlaceholderListScreen), findsOneWidget);
      expect(find.text('Surveys'), findsWidgets); // appears on the new screen
      expect(find.textContaining('coming soon'), findsOneWidget);
    });
```

Add this import to the top of the test file:

```dart
import 'package:earnwise_mvp/screens/placeholder_list_screen.dart';
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd flutter_app && flutter test test/screens/post_onboarding_home_test.dart
```

Expected: two new failures because Earn more section is not yet rendered.

- [ ] **Step 3: Add the Earn more section to _buildPostOnboardingBody**

In `flutter_app/lib/screens/home_screen.dart`, update `_buildPostOnboardingBody` to append the Earn more section after the Continue section. Replace the existing method body:

```dart
  List<Widget> _buildPostOnboardingBody(AppState state) {
    final inProgress = state.inProgressGames.take(3).toList();
    return [
      const DailyGoalCard(),
      const SizedBox(height: AppSpacing.lg),
      if (inProgress.isNotEmpty) ...[
        Text(
          'Continue earning',
          style: AppText.listItem.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < inProgress.length; i++) ...[
          _buildContinueCard(inProgress[i]),
          if (i < inProgress.length - 1) const SizedBox(height: 10),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
      Text(
        'Earn more',
        style: AppText.listItem.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      _buildSectionCard(
        title: 'Surveys',
        blurb: '\$0.50 to \$2.00 each',
        icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
        iconColor: AppColors.taskSurvey,
        onTap: () => _openPlaceholderList('Surveys',
            'Survey catalog coming soon.\nBuilt in sub-project 3.'),
      ),
      const SizedBox(height: 10),
      _buildSectionCard(
        title: 'Offers',
        blurb: 'Up to \$10 each',
        icon: PhosphorIcons.tag(PhosphorIconsStyle.duotone),
        iconColor: AppColors.taskOffers,
        onTap: () => _openPlaceholderList(
            'Offers', 'Offer catalog coming soon.\nBuilt in sub-project 3.'),
      ),
      const SizedBox(height: 10),
      _buildSectionCard(
        title: 'Tasks',
        blurb: 'Earn by playing',
        icon: PhosphorIcons.gameController(PhosphorIconsStyle.duotone),
        iconColor: AppColors.taskGame,
        onTap: () => _openPlaceholderList(
            'Tasks', 'Game catalog coming soon.\nBuilt in sub-project 3.'),
      ),
    ];
  }

  Widget _buildSectionCard({
    required String title,
    required String blurb,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return PressScale(
      onTap: onTap,
      haptic: null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.bodyStrong
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    blurb,
                    style: AppText.caption
                        .copyWith(color: AppColors.inkSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
              size: 18,
              color: AppColors.inkTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _openPlaceholderList(String title, String subtitle) {
    Navigator.of(context).push(
      fadeRoute(
        PlaceholderListScreen(title: title, subtitle: subtitle),
      ),
    );
  }
```

Add the import at the top of `home_screen.dart`:

```dart
import 'placeholder_list_screen.dart';
```

Verify that `AppColors.taskSurvey` exists in `flutter_app/lib/theme/app_theme.dart`. The existing onboarding task cards already use `AppColors.taskSurvey`, so it should be present. If it is not, use `AppColors.primary` for the Surveys card and leave a `// TODO add AppColors.taskSurvey token` comment.

- [ ] **Step 4: Run the tests**

```bash
cd flutter_app && flutter test test/screens/post_onboarding_home_test.dart
```

Expected: all six `Post-Onboarding Home` tests pass.

- [ ] **Step 5: Run the full test suite**

```bash
cd flutter_app && flutter test
```

Expected: every test passes. No regressions in `home_shell_test.dart`, `app_state_test.dart`, or `daily_goal_card_test.dart`.

- [ ] **Step 6: Commit**

```bash
git add flutter_app/lib/screens/home_screen.dart flutter_app/test/screens/post_onboarding_home_test.dart
git commit -m "feat(home): add Earn more section with Surveys/Offers/Tasks routing cards"
```

---

## Task 8: Smoke test the full post-onboarding layout and confirm manual flow

**Files:**
- Modify: `flutter_app/test/screens/post_onboarding_home_test.dart`

- [ ] **Step 1: Write the integration smoke test**

Append this final block to the `Post-Onboarding Home` group:

```dart
    testWidgets('end-to-end: progress increment to goal-hit flows through UI',
        (tester) async {
      await pumpPostOnboardingHome(tester, setup: (s) {
        s.earnedToday = 1450; // just under $2 target
      });
      expect(find.text('Push to \$3'), findsNothing);

      // Simulate earning the remaining 50 stars.
      final state =
          Provider.of<AppState>(tester.element(find.byType(DailyGoalCard)),
              listen: false);
      state.earnedToday = 1500;
      state.notifyListeners();
      await tester.pump();

      expect(find.text('Push to \$3'), findsOneWidget);

      // Tap Push to \$3.
      await tester.tap(find.text('Push to \$3'));
      await tester.pump();
      expect(state.dailyGoalStars, 2250);
      expect(state.dailyExtensionOffered, isTrue);
      expect(find.text('Push to \$3'), findsNothing);
      // Progress card should now target \$3.00.
      expect(find.textContaining('\$3.00'), findsOneWidget);
    });
```

- [ ] **Step 2: Run the test**

```bash
cd flutter_app && flutter test test/screens/post_onboarding_home_test.dart
```

Expected: all seven `Post-Onboarding Home` tests pass, including the new end-to-end smoke test.

- [ ] **Step 3: Run the full test suite one more time**

```bash
cd flutter_app && flutter test
```

Expected: everything green.

- [ ] **Step 4: Manual sanity check in the running app**

Launch the app on a device or simulator:

```bash
cd flutter_app && flutter run
```

Walk through:
1. Complete onboarding. Use the existing Home debug path to advance `goalIndex` past 0 (or temporarily change the initial value in `AppState` to 1 and revert before commit).
2. Post-onboarding Home should show: greeting, DailyGoalCard, Continue earning (Candy Crush + Solitaire), Earn more (Surveys, Offers, Tasks).
3. Tap Surveys: PlaceholderListScreen opens with "Coming soon" copy. X button pops.
4. Tap Candy Crush card: GameDetailScreen opens. X pops back.
5. Manually set `state.earnedToday = 1500` via a debug path or by completing onboarding tasks that push the counter. Verify the prompt state shows. Tap Push to $3 and verify the card flips to a $3 target.

Revert any debug-only state changes.

- [ ] **Step 5: Commit the smoke test**

```bash
git add flutter_app/test/screens/post_onboarding_home_test.dart
git commit -m "test(home): add end-to-end smoke test for post-onboarding goal-hit flow"
```

---

## Self-Review

Spec coverage, section by section:

| Spec section | Covered by |
|---|---|
| Header strip (existing) | Task 5 (preserves `_buildGreetingRow` in the branch) |
| Daily Goal card (default) | Task 3 `_ProgressCard`, tested in Task 3 step 1 |
| Daily Goal card (goal-hit) | Task 3 `_PromptCard`, tested in Task 3 step 1 |
| Daily Goal card (extended) | Task 3 `_ProgressCard` with pushed target, tested in Task 3 step 1 |
| Midnight reset | Task 1 `checkDailyReset`, called from `_buildPostOnboardingBody` in Task 5 |
| Continue earning section (up to 3) | Task 6, tested for 0/2/5 cases |
| Continue earning ordering (most recent first) | Task 2 `inProgressGames` getter, tested in Task 2 |
| Empty Continue state (section hides) | Task 6 test `hides the Continue earning section when no in-progress games` |
| Earn more section (3 cards) | Task 7, tested in Task 7 step 1 |
| Surveys / Offers / Tasks routes | Task 4 placeholder + Task 7 routing, tested for Surveys in Task 7 |
| Celebrations hook (stubbed) | Task 1 fires `Haptics.celebrate(CelebrateMoments.goalReached)` from `completeTask` on the rising-edge crossing of `dailyGoalStars`, guarded by `_dailyGoalCelebrated` so it fires once per day. TODO marker in `completeTask` flags the sub-project 6 migration. |
| Out of scope: three destination screens | Task 4 creates placeholder only |
| Out of scope: Dark Mode | All new code uses `AppColors` tokens; no hardcoded hex codes |
| Risk: per-game state model not built | Addressed by v1 `InstalledGame` seed list in Task 2 |

Placeholder scan: the only "TODO" in the plan is the `// TODO sub-project 6: route through CelebrationsService` marker in Task 3, which is deliberately left as a seam for sub-project 6 to wire the real service. Every other step has concrete code.

Type consistency check:
- `dailyGoalStars` (int) used in Task 1, Task 3, Task 8 — consistent
- `dailyExtensionOffered` (bool) used in Task 1, Task 3, Task 8 — consistent
- `pushDailyGoalToThree()` / `bankDailyGoal()` used in Task 1 and Task 3 — consistent
- `InstalledGame.nextMilestoneReward` (double) used in Task 2 and Task 6 — consistent
- `_buildPostOnboardingBody` returns `List<Widget>` throughout Tasks 5-7 — consistent
- `PlaceholderListScreen(title, subtitle)` constructor used identically in Task 4 and Task 7

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-13-post-onboarding-home.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
