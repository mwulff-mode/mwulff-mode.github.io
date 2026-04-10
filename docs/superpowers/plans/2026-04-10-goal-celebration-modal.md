# Goal Celebration Modal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show a centered floating card modal when the user reaches their first payout threshold ($2.00), guiding them to cash out or keep earning.

**Architecture:** The modal is a stateful widget shown via `showGeneralDialog` from the existing `_completeTask` handler in HomeScreen. HomeShell passes an `onNavigateToWallet` callback (same pattern as `onNavigateHome` in WalletScreen). Goal 2 threshold drops from $6.67 to $5.00.

**Tech Stack:** Flutter, Provider, Phosphor Icons, existing AppText/AppColors/AppDurations/AppCurves tokens

---

### Task 1: Update Goal 2 star threshold

**Files:**
- Modify: `flutter_app/lib/state/app_state.dart:44-48`
- Modify: `flutter_app/test/state/app_state_test.dart:348-353`

- [ ] **Step 1: Update the goal 2 threshold**

In `flutter_app/lib/state/app_state.dart`, change the Goal 2 entry in the `goals` array:

```dart
  Goal(
      level: 2,
      goalStars: 3750,
      ringColor: Color(0xFF0D9488),
      trackColor: Color(0xFFE2E8F0)),
```

- [ ] **Step 2: Update the test expectation**

In `flutter_app/test/state/app_state_test.dart`, update the test at line 348:

```dart
    test('formatGoal returns correct dollar for goal 1 threshold', () {
      final state = AppState();
      state.goalIndex = 1;
      // Goal 1 goalStars == 3750; 3750 / 750 == $5.00
      expect(state.formatGoal(), '\$5.00');
    });
```

- [ ] **Step 3: Run the tests**

Run: `cd flutter_app && flutter test test/state/app_state_test.dart`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/state/app_state.dart flutter_app/test/state/app_state_test.dart
git commit -m "feat: change goal 2 threshold from \$6.67 to \$5.00"
```

---

### Task 2: Wire onNavigateToWallet through HomeShell

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart:22-23`
- Modify: `flutter_app/lib/screens/home_shell.dart:47-48`

- [ ] **Step 1: Add onNavigateToWallet parameter to HomeScreen**

In `flutter_app/lib/screens/home_screen.dart`, update the HomeScreen widget to accept a callback:

```dart
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToWallet;

  const HomeScreen({super.key, this.onNavigateToWallet});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
```

- [ ] **Step 2: Pass the callback from HomeShell**

In `flutter_app/lib/screens/home_shell.dart`, update the HomeScreen instantiation in the IndexedStack (line 48):

```dart
                HomeScreen(
                  onNavigateToWallet: () => setState(() => _navIndex = 1),
                ),
```

- [ ] **Step 3: Run the existing tests to verify nothing breaks**

Run: `cd flutter_app && flutter test test/screens/home_shell_test.dart`
Expected: All tests pass. The `const` on HomeScreen will need to be dropped since we added a parameter, but `pumpShell` creates HomeShell which creates HomeScreen internally, so the test doesn't need changes.

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/screens/home_screen.dart flutter_app/lib/screens/home_shell.dart
git commit -m "feat: pass onNavigateToWallet callback from HomeShell to HomeScreen"
```

---

### Task 3: Build the goal celebration modal

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart` (add modal widget + show function at bottom of file, before `_GoalRingPainter`)

- [ ] **Step 1: Add the celebrate haptic moment constant**

In `flutter_app/lib/services/haptics.dart`, add a new constant to `CelebrateMoments`:

```dart
  /// Onboarding goal reached -- first $2 payout threshold crossed.
  static const goalReached = 'goal_reached';
```

- [ ] **Step 2: Add the showGoalCelebration function and _GoalCelebrationModal widget**

In `flutter_app/lib/screens/home_screen.dart`, add this code just before the `_GoalRingPainter` class (before line 1033):

```dart
/// Shows the goal celebration modal as a general dialog overlay.
/// Returns `true` if the user tapped "Cash out now", `false` if dismissed
/// via close X or "Keep earning".
Future<bool> _showGoalCelebration(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const _GoalCelebrationModal(),
  ).then((v) => v ?? false);
}

class _GoalCelebrationModal extends StatefulWidget {
  const _GoalCelebrationModal();

  @override
  State<_GoalCelebrationModal> createState() => _GoalCelebrationModalState();
}

class _GoalCelebrationModalState extends State<_GoalCelebrationModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _barrierOpacity;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _barrierOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );
    _cardScale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppCurves.warmOut),
    );
    _cardOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    Haptics.celebrate(CelebrateMoments.goalReached);
    _ctrl.forward();
  }

  Future<void> _dismiss(bool cashOut) async {
    // Reverse animation
    await _ctrl.reverse();
    if (mounted) Navigator.of(context).pop(cashOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          children: [
            // Barrier scrim
            Positioned.fill(
              child: Opacity(
                opacity: _barrierOpacity.value,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            // Card
            Center(
              child: Opacity(
                opacity: _cardOpacity.value,
                child: Transform.scale(
                  scale: _cardScale.value,
                  child: _buildCard(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard() {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close X - top right
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => _dismiss(false),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.creamDeep,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.x(PhosphorIconsStyle.bold),
                    size: 14,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.tealSecondary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                PhosphorIcons.star(PhosphorIconsStyle.fill),
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Amount
            Text(
              '\$2.00',
              style: AppText.prompt.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              'GOAL REACHED',
              style: AppText.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Body
            Text(
              'You did it! Your first payout is ready to cash out.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Primary CTA
            PressScale(
              onTap: () => _dismiss(true),
              haptic: HapticIntensity.confirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Cash out now',
                  textAlign: TextAlign.center,
                  style: AppText.bodyStrong.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Secondary
            PressScale(
              onTap: () => _dismiss(false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Keep earning',
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify the app builds**

Run: `cd flutter_app && flutter build apk --debug 2>&1 | tail -5`
Expected: Build succeeds. (The modal is not wired up yet, just compiling.)

Note: `AnimatedBuilder` should be `AnimatedBuilder` -- verify the correct class name is `AnimatedBuilder` from Flutter. If the build shows an error about `AnimatedBuilder`, it is actually `AnimatedBuilder` in Flutter. Double-check: the correct Flutter widget is `AnimatedBuilder`.

- [ ] **Step 4: Commit**

```bash
git add flutter_app/lib/screens/home_screen.dart flutter_app/lib/services/haptics.dart
git commit -m "feat: add goal celebration modal widget and show function"
```

---

### Task 4: Wire the modal into the goal completion flow

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart:171-205` (replace goal-completed block + remove allTasksCompleted block)

- [ ] **Step 1: Replace the goal-completed and allTasksCompleted blocks**

In `flutter_app/lib/screens/home_screen.dart`, replace lines 171-205 (from `// Goal completed: hold the solid fill, then advance` through the closing brace of the `allTasksCompleted` block):

Old code (to be replaced):
```dart
    // Goal completed: hold the solid fill, then advance
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
              : 'Next goal: \$${(s.currentGoal.goalStars / AppState.starsPerDollar).toStringAsFixed(2)}',
          PhosphorIcons.trophy(PhosphorIconsStyle.fill),
          s.ringColor,
          s.ringColor.withValues(alpha: 0.1),
        );
      });
    }

    if (state.allTasksCompleted) {
      Haptics.milestone();
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        state.addJourneyEntry(
          'All starter tasks done. Earn More unlocked!',
          'Offers, Receipts & Games are now available',
          PhosphorIcons.lockSimpleOpen(PhosphorIconsStyle.duotone),
          AppColors.primary,
          AppColors.primaryPale,
        );
      });
    }
```

New code:
```dart
    // Goal completed: hold the solid fill so the user sees it, then celebrate
    if (goalCompleted) {
      Haptics.milestone();
      // First onboarding goal: show celebration modal
      if (state.goalIndex == 0) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          _showGoalCelebration(context).then((cashOut) {
            if (!mounted) return;
            final s = context.read<AppState>();
            // Shared dismiss logic: advance goal + journal entry
            s.advanceGoal();
            s.addJourneyEntry(
              'Goal complete! Your first \$2 payout is ready.',
              'Earn More is now unlocked',
              PhosphorIcons.trophy(PhosphorIconsStyle.fill),
              s.ringColor,
              s.ringColor.withValues(alpha: 0.1),
            );
            // Branch on path
            if (cashOut) {
              widget.onNavigateToWallet?.call();
            } else {
              showAppToast(
                context,
                title: 'Earn More is unlocked!',
                subtitle: 'Offers, Receipts and Games are now available',
                icon: PhosphorIcons.lockSimpleOpen(PhosphorIconsStyle.duotone),
                iconColor: AppColors.primary,
                iconBackground: AppColors.primaryPale,
              );
            }
          });
        });
      } else {
        // Later goals: keep the existing silent advance behavior
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
                : 'Next goal: \$${(s.currentGoal.goalStars / AppState.starsPerDollar).toStringAsFixed(2)}',
            PhosphorIcons.trophy(PhosphorIconsStyle.fill),
            s.ringColor,
            s.ringColor.withValues(alpha: 0.1),
          );
        });
      }
    }
```

- [ ] **Step 2: Verify the app builds**

Run: `cd flutter_app && flutter build apk --debug 2>&1 | tail -5`
Expected: Build succeeds.

- [ ] **Step 3: Run all tests**

Run: `cd flutter_app && flutter test`
Expected: All tests pass.

- [ ] **Step 4: Manual smoke test**

Run: `cd flutter_app && flutter run`

Test the flow:
1. Complete onboarding (create a name, go through screens)
2. On the home screen, complete all 4 starter tasks (profile, survey, install game, reach milestone)
3. Watch the ring fill to 100%
4. After ~1.5s, the celebration modal should appear with "$2.00 / GOAL REACHED"
5. Test "Keep earning": modal dismisses, ring shows new $5.00 goal, toast appears "Earn More is unlocked!", Earn More section is active
6. Sign out (profile > sign out), re-run onboarding, test "Cash out now": modal dismisses, switches to Wallet tab

- [ ] **Step 5: Commit**

```bash
git add flutter_app/lib/screens/home_screen.dart
git commit -m "feat: wire goal celebration modal into completion flow

Show celebration modal on first goal completion instead of
silently advancing. Consolidate Earn More unlock feedback
into the modal dismiss path to prevent duplicate messaging."
```
