# Profile Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a new Profile screen that opens as a tab inside a new `HomeShell` tab-based architecture, with an avatar, fictional profile fields, an account card, and a red-outlined Sign Out button that resets `AppState` and navigates back to welcome.

**Architecture:** A new `HomeShell` `StatefulWidget` wraps an `IndexedStack` of three children (`HomeScreen`, a `_WalletTabStub`, and a new `ProfileScreen`), plus a floating glass nav pill overlay with a cream-to-transparent gradient fade (lifted from the current `HomeScreen` nav chrome). `HomeScreen` keeps its class name but drops its nav state and nav overlay. `ProfileScreen` is a new stateless widget composed of private helper widgets (hero, personal-info card, account card, sign-out button). `AppState` gains four fictional profile fields and a `reset()` method.

**Tech Stack:** Flutter (Material), `provider` for state, `phosphor_flutter` icons, existing EarnWise design system primitives (`AppText`, `AppColors`, `AppSpacing`, `AppLayout`, `AppCard` recipe, `PressScale`, `fadeRoute`, `AnimatedGradientBg`), `flutter_test` for widget tests.

**Spec:** [`docs/superpowers/specs/2026-04-10-profile-screen-design.md`](../specs/2026-04-10-profile-screen-design.md)

**Prerequisites (user-owned, not part of any task):**
One image asset dropped at `flutter_app/assets/images/google_logo.png`. The `_GoogleLogo` helper inside `profile_screen.dart` includes an `Image.asset` `errorBuilder` fallback that renders a white circle with a black "G" letter when the asset is missing, so the build does not crash. The asset directory is already registered in `pubspec.yaml`.

**Codebase notes for the implementing engineer:**

- Project root for the Flutter app is `flutter_app/`. All `flutter` and `dart` commands run from there. Prefix with `cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app && ...` when in doubt.
- Package name is `earnwise_mvp`. Imports use `package:earnwise_mvp/...`.
- Run a single test file: `flutter test test/path/file.dart`. Run the full suite: `flutter test`.
- After every code change, run `dart analyze` and confirm zero issues before committing.
- Project memory rule, applies to every string in this plan and every commit message: **no em-dashes**. Use periods, commas, colons, or parentheses instead.
- Stage files explicitly by name with `git add path/to/file`. Do NOT use `git add -A`.
- Commit messages use HEREDOC for multi-line bodies and always end with `Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>`.
- NEVER amend an existing commit. Always create a new commit, even for review-fix commits.
- `Provider` is the state management library. Screens that read `AppState` use `Consumer<AppState>` or `context.read<AppState>()` / `context.watch<AppState>()`. Widget tests that pump these screens must wrap them in `ChangeNotifierProvider<AppState>(create: (_) => AppState(), child: ...)`.

---

## File Structure

**Files created:**

| Path | Purpose | Approx size |
|---|---|---|
| `lib/screens/home_shell.dart` | `HomeShell` tab-shell widget, its private `_buildBottomNav` / `_navItem` helpers, and the `_WalletTabStub` widget | ~250 lines |
| `lib/screens/profile_screen.dart` | `ProfileScreen` public widget and all its private helpers (`_ProfileHero`, `_AvatarCircle`, `_ProviderBadge`, `_GoogleLogo`, `_SectionHeading`, `_InfoCard`, `_InfoRow`, `_RowDivider`, `_AccountCard`, `_AccountRow`, `_SignOutButton`) | ~450 lines |
| `test/state/app_state_test.dart` | Unit tests for `AppState.reset()` | ~80 lines |
| `test/screens/home_shell_test.dart` | Widget tests for tab switching in `HomeShell` | ~80 lines |
| `test/screens/profile_screen_test.dart` | Widget tests for `ProfileScreen` (avatar, sections, sign out behavior) | ~180 lines |

**Files modified:**

| Path | Change |
|---|---|
| `lib/state/app_state.dart` | Add `email`, `authProvider`, `ageRange`, `gender` string fields. Add a `reset()` method that restores every in-session field to its initial value. |
| `lib/screens/home_screen.dart` | Delete `_navIndex`, `_buildBottomNav`, `_navItem`, and the floating-nav `Positioned` block. Drop the top-level `ScreenScaffold` wrapper and replace it with an `AnimatedGradientBg` wrapping the Stack directly. |
| `lib/screens/onboarding_screen.dart` | `pushAndRemoveUntil` target changes from `HomeScreen()` to `HomeShell()`. Import `home_shell.dart`. |

**Files NOT modified:**

- `lib/screens/splash_screen.dart`: does not reference `HomeScreen` (pushes `WelcomeScreen`).
- `lib/main.dart`: does not reference `HomeScreen` directly.
- `lib/theme/*.dart`: no new styles; everything reuses existing `AppText` / `AppColors` / `AppSpacing`.
- `test/widgets/press_scale_test.dart`: unrelated existing test stays unchanged.

---

## Task 1: AppState profile fields and reset() method

**Files:**
- Modify: `flutter_app/lib/state/app_state.dart`
- Create: `flutter_app/test/state/app_state_test.dart`

**Why first:** Every later task either reads or writes these fields. The Sign Out wiring in Task 7 is the most visible consumer, and the widget tests in Task 7 rely on `reset()` being implementable and testable in isolation.

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/state/app_state_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';

void main() {
  group('AppState profile fields', () {
    test('default values match the spec', () {
      final state = AppState();
      expect(state.email, 'lisa@earnwise.demo');
      expect(state.authProvider, 'Google');
      expect(state.ageRange, '26-35');
      expect(state.gender, 'Female');
    });
  });

  group('AppState.reset()', () {
    test('restores every in-session field to its default value', () {
      final state = AppState();

      // Mutate everything a real session might touch.
      state.userName = 'Dirty';
      state.stars = 9999;
      state.earnedToday = 500;
      state.goalIndex = 3;
      state.tasksCompleted = 7;
      state.screen5Played = true;
      state.streakCount = 12;
      state.isLegend = true;
      state.completedTasks.addAll({'profile', 'survey', 'game'});
      state.lastCompletedTask = 'game';
      state.selectedPreferences.addAll(['puzzle', 'word']);
      state.journeyLog
          .add(JourneyEntry(
            title: 'Dirty',
            subtitle: 'Dirty',
            icon: Icons.bug_report,
            iconColor: Colors.red,
            iconBg: Colors.pink,
            time: '12:00 PM',
          ));
      state.convCardMsg = 'Dirty message';
      state.convCardIcon = Icons.bug_report;
      state.convCardIconColor = Colors.red;
      state.convCardIconBg = Colors.pink;
      state.email = 'hacked@example.com';
      state.authProvider = 'Facebook';
      state.ageRange = '99+';
      state.gender = 'Dirty';

      state.reset();

      expect(state.userName, 'Lisa');
      expect(state.stars, 125);
      expect(state.earnedToday, 0);
      expect(state.goalIndex, 0);
      expect(state.tasksCompleted, 0);
      expect(state.screen5Played, isFalse);
      expect(state.streakCount, 0);
      expect(state.isLegend, isFalse);
      expect(state.completedTasks, isEmpty);
      expect(state.lastCompletedTask, isNull);
      expect(state.selectedPreferences, isEmpty);
      expect(state.journeyLog, isEmpty);
      expect(state.convCardMsg, '');
      expect(state.convCardIcon, Icons.waving_hand);
      expect(state.convCardIconColor, AppColors.primary);
      expect(state.convCardIconBg, AppColors.primaryPale);
      expect(state.email, 'lisa@earnwise.demo');
      expect(state.authProvider, 'Google');
      expect(state.ageRange, '26-35');
      expect(state.gender, 'Female');
    });

    test('notifies listeners when called', () {
      final state = AppState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.reset();

      expect(notifyCount, 1);
    });
  });
}
```

Note on the `journeyLog` entry: the test constructs a `JourneyEntry` to prove `reset()` empties the list. If the existing `JourneyEntry` constructor signature in `app_state.dart` differs from the one used above (the field names here are `title`, `subtitle`, `icon`, `iconColor`, `iconBg`, `time`), adjust the test to match the real constructor. The engineer should read the existing `JourneyEntry` class before writing the test.

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/state/app_state_test.dart
```

Expected: failure. The first two tests fail because `state.email` (and the other three new fields) do not exist. The `reset()` test fails because `state.reset()` does not exist.

- [ ] **Step 3: Add the four new fields to AppState**

Open `flutter_app/lib/state/app_state.dart` and locate the field declarations near line 74 (after `class AppState extends ChangeNotifier {`). After the existing `journeyLog` and `convCardIconBg` fields, add four new string fields. Place them in a clearly-labeled group:

```dart
  // Profile fields (fictional demo values, surfaced on ProfileScreen)
  String email = 'lisa@earnwise.demo';
  String authProvider = 'Google'; // 'Google' | 'Apple'
  String ageRange = '26-35';
  String gender = 'Female';
```

- [ ] **Step 4: Add the reset() method**

In the same file, add a `reset()` method inside the `AppState` class. Place it near the bottom of the class, just before the closing brace. The method must restore every listed field to its documented initial value and call `notifyListeners()`.

```dart
  /// Resets every in-session field to the same initial value the field
  /// declaration uses today. Called by the Sign Out button on
  /// [ProfileScreen]. After reset the next onboarding run sees the
  /// welcome gift animation again because [stars] goes back to 125.
  void reset() {
    userName = 'Lisa';
    stars = 125;
    earnedToday = 0;
    goalIndex = 0;
    tasksCompleted = 0;
    screen5Played = false;
    streakCount = 0;
    isLegend = false;
    completedTasks = <String>{};
    lastCompletedTask = null;
    selectedPreferences = <String>[];
    journeyLog = <JourneyEntry>[];
    convCardMsg = '';
    convCardIcon = Icons.waving_hand;
    convCardIconColor = AppColors.primary;
    convCardIconBg = AppColors.primaryPale;
    email = 'lisa@earnwise.demo';
    authProvider = 'Google';
    ageRange = '26-35';
    gender = 'Female';
    notifyListeners();
  }
```

Note: the three collection fields (`completedTasks`, `selectedPreferences`, `journeyLog`) are reassigned to NEW empty collections rather than mutated via `.clear()`. This avoids stale references if any outside code is holding the old collection.

`Icons.waving_hand` comes from `package:flutter/material.dart` which is already imported by `app_state.dart`. `AppColors.primary` and `AppColors.primaryPale` come from `../theme/app_theme.dart`. Verify that `import '../theme/app_theme.dart';` is at the top of `app_state.dart`; if it is not, add it.

- [ ] **Step 5: Run the test to confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/state/app_state_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 6: Run the full analyzer**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 7: Commit**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen
git add flutter_app/lib/state/app_state.dart flutter_app/test/state/app_state_test.dart
git commit -m "$(cat <<'EOF'
feat(state): add profile fields and reset() method

Add email, authProvider, ageRange, and gender as new AppState fields
with fictional demo values so the upcoming ProfileScreen can render a
full personal-info section without inventing real auth. Add a reset()
method that restores every in-session field, including stars, the
onboarding task sets, the conv-card state, and the new profile fields,
back to their default values so Sign Out on the profile screen feels
like a clean slate. Unit test verifies reset() resets all 20 fields
and notifies listeners once.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: ProfileScreen skeleton

**Files:**
- Create: `flutter_app/lib/screens/profile_screen.dart`
- Create: `flutter_app/test/screens/profile_screen_test.dart`

**Why next:** `HomeShell` in Task 3 needs to reference `ProfileScreen` as an `IndexedStack` child. Creating a minimal skeleton now lets Task 3 wire the shell without blocking on full profile content. Subsequent tasks (4-7) fill in the real content.

- [ ] **Step 1: Write the failing smoke test**

Create `flutter_app/test/screens/profile_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/profile_screen.dart';
import 'package:earnwise_mvp/state/app_state.dart';

/// Pumps [ProfileScreen] inside a minimal Provider + MaterialApp harness
/// so widgets that call `context.read<AppState>()` or `context.watch`
/// can resolve their dependency.
Future<void> pumpProfile(WidgetTester tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>(
      create: (_) => AppState(),
      child: const MaterialApp(
        home: Scaffold(body: ProfileScreen()),
      ),
    ),
  );
}

void main() {
  group('ProfileScreen', () {
    testWidgets('renders without throwing', (tester) async {
      await pumpProfile(tester);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/profile_screen_test.dart
```

Expected: failure with `Target of URI doesn't exist: 'package:earnwise_mvp/screens/profile_screen.dart'`.

- [ ] **Step 3: Create the profile screen skeleton**

Create `flutter_app/lib/screens/profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-page profile surface shown as the third tab inside [HomeShell].
/// Displays the user's avatar, email, fictional personal info fields,
/// a connected-account row, and a Sign Out button.
///
/// v1 is intentionally a demo surface: the edit icons are decorative,
/// the auth provider is hardcoded, and Sign Out just calls
/// [AppState.reset] and sends the user back to welcome.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      // Content is added in subsequent tasks.
    );
  }
}
```

- [ ] **Step 4: Run the test to confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/profile_screen_test.dart
```

Expected: 1 test passes.

- [ ] **Step 5: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen
git add flutter_app/lib/screens/profile_screen.dart flutter_app/test/screens/profile_screen_test.dart
git commit -m "$(cat <<'EOF'
feat(screens): add ProfileScreen skeleton

Create the empty ProfileScreen StatelessWidget and a smoke test so the
new HomeShell in the next task has a real class to reference. Content
is added in follow-up tasks that build the hero, personal info card,
account card, and sign out button.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: HomeShell refactor with floating nav pill

**Files:**
- Create: `flutter_app/lib/screens/home_shell.dart`
- Modify: `flutter_app/lib/screens/home_screen.dart`
- Modify: `flutter_app/lib/screens/onboarding_screen.dart`
- Create: `flutter_app/test/screens/home_shell_test.dart`

**Why now:** The shell is the architectural change that every other screen flows through. Refactoring it early means later tasks build on a stable nav structure. The HomeScreen modifications and the entry point update happen atomically in this task because the three pieces depend on each other: HomeShell needs HomeScreen to not own nav state, HomeScreen needs onboarding to push HomeShell instead.

- [ ] **Step 1: Write the failing widget test**

Create `flutter_app/test/screens/home_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/home_shell.dart';
import 'package:earnwise_mvp/state/app_state.dart';

/// Pumps [HomeShell] inside a Provider + MaterialApp harness.
Future<void> pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>(
      create: (_) => AppState(),
      child: const MaterialApp(
        home: HomeShell(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HomeShell', () {
    testWidgets('renders without throwing', (tester) async {
      await pumpShell(tester);
      expect(find.byType(HomeShell), findsOneWidget);
    });

    testWidgets('tapping the Wallet tab shows the Wallet stub',
        (tester) async {
      await pumpShell(tester);
      expect(find.text('Wallet coming soon'), findsNothing);

      await tester.tap(find.byKey(const Key('shell_nav_wallet')));
      await tester.pumpAndSettle();

      expect(find.text('Wallet coming soon'), findsOneWidget);
    });

    testWidgets('tapping the Profile tab shows the profile screen',
        (tester) async {
      await pumpShell(tester);
      expect(find.byKey(const Key('profile_screen_root')), findsNothing);

      await tester.tap(find.byKey(const Key('shell_nav_profile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_screen_root')), findsOneWidget);
    });
  });
}
```

The test uses `Key('shell_nav_wallet')` and `Key('shell_nav_profile')` on the nav items and `Key('profile_screen_root')` on the profile screen's root. Those keys are added in Step 3 below.

Note: the Home tab test is omitted because the current `HomeScreen` has a complex entry animation (the welcome gift overlay) that makes `find.text` assertions brittle. The Wallet and Profile tab tests are sufficient to prove the shell switches children.

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/home_shell_test.dart
```

Expected: failure with `Target of URI doesn't exist: 'package:earnwise_mvp/screens/home_shell.dart'`.

- [ ] **Step 3: Create HomeShell with the floating nav pill**

Create `flutter_app/lib/screens/home_shell.dart`:

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/press_scale.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Top-level tab shell that sits between onboarding and the tab content.
/// Owns the floating glass nav pill that overlays every tab with a
/// cream-to-transparent gradient fade above it. Children are swapped via
/// [IndexedStack] so each tab's state survives tab switches.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _navIndex,
              children: const [
                HomeScreen(),
                _WalletTabStub(),
                ProfileScreen(),
              ],
            ),
          ),
          // Floating glass nav pill with cream-to-transparent gradient fade
          // above it, matching the pattern the home screen used to own.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 40,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.cream.withValues(alpha: 0),
                      AppColors.cream.withValues(alpha: 0.92),
                    ],
                  ),
                ),
                child: Center(child: _buildBottomNav()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navItem(
                0,
                PhosphorIcons.house(PhosphorIconsStyle.fill),
                'Home',
                const Key('shell_nav_home'),
              ),
              _navItem(
                1,
                PhosphorIcons.wallet(PhosphorIconsStyle.fill),
                'Wallet',
                const Key('shell_nav_wallet'),
              ),
              _navItem(
                2,
                PhosphorIcons.user(PhosphorIconsStyle.fill),
                'Profile',
                const Key('shell_nav_profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, Key key) {
    final isActive = _navIndex == index;
    return PressScale(
      key: key,
      onTap: () => setState(() => _navIndex = index),
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: AppCurves.warmOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive ? Colors.white : AppColors.inkSecondary,
            ),
            AnimatedSize(
              duration: AppDurations.medium,
              curve: AppCurves.warmOut,
              child: isActive
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: AppText.bodyStrong.copyWith(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder widget for the Wallet tab. A real Wallet screen is out of
/// scope for this task; the stub keeps the tab tappable and visually
/// consistent with the cream theme.
class _WalletTabStub extends StatelessWidget {
  const _WalletTabStub();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Wallet',
              style: AppText.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Wallet coming soon',
              style: AppText.body.copyWith(color: AppColors.inkTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
```

`dart:ui` provides `ImageFilter.blur` for the glass effect. `phosphor_flutter`, `provider`, the theme imports, and `press_scale` are already used elsewhere in the codebase.

- [ ] **Step 4: Add the root Key to ProfileScreen for the tab-switching test**

Update `flutter_app/lib/screens/profile_screen.dart`. Replace the skeleton `build` method so the returned Container carries a root Key:

```dart
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile_screen_root'),
      color: AppColors.cream,
      // Content is added in subsequent tasks.
    );
  }
```

- [ ] **Step 5: Strip the nav code from HomeScreen**

Open `flutter_app/lib/screens/home_screen.dart` and make four targeted deletions plus one wrapper swap.

**5a.** Delete the `_navIndex` field declaration inside `_HomeScreenState`. The line currently reads roughly `int _navIndex = 0;` near the top of the state class. Remove it.

**5b.** Delete the `_buildBottomNav()` method and the `_navItem(int, IconData, String)` method. Both live near the bottom of `_HomeScreenState`. They are now owned by `HomeShell`.

**5c.** Delete the entire `Positioned(left: 0, right: 0, bottom: 0, ...)` block inside `build()` that wraps `IgnorePointer`, the gradient `Container`, and `Center(child: _buildBottomNav())`. The block starts with a comment like "Floating glass nav bar with a cream-to-transparent gradient fade" and ends with the closing `),` of its `Positioned`. After this deletion, the `Stack` inside `build()` contains only the home content (`_buildHomeContent()`) and the gift overlay (`_buildGiftOverlay()`). Dollars to donuts the `if (_homeRevealed && !_showGift)` guard line goes with this block too; remove it.

**5d.** Replace the top-level `ScreenScaffold(...)` wrapper with an `AnimatedGradientBg` wrapping the `Stack` directly. The current build returns something like:

```dart
return ScreenScaffold(
  safeArea: false,
  padding: EdgeInsets.zero,
  animatedGradient: true,
  child: Stack(
    children: [...],
  ),
);
```

Replace it with:

```dart
return AnimatedGradientBg(
  child: Stack(
    children: [...],
  ),
);
```

Add `import '../widgets/animated_gradient_bg.dart';` at the top of the file if it is not already present. Remove the `import '../widgets/screen_scaffold.dart';` line if `ScreenScaffold` is no longer referenced anywhere else in the file.

**5e.** Audit the imports. After the deletions, `ImageFilter` (from `dart:ui`), `BackdropFilter`, and any phosphor-only icons that were used solely by `_navItem` may no longer be referenced. Let `dart analyze` catch unused imports; remove any it flags.

- [ ] **Step 6: Update onboarding to push HomeShell**

Open `flutter_app/lib/screens/onboarding_screen.dart`. At the top of the imports, add:

```dart
import 'home_shell.dart';
```

Find the line that reads `fadeRoute(const HomeScreen())` inside the `_finishOnboarding` method (around line 54). Replace `HomeScreen` with `HomeShell`:

```dart
Navigator.of(context).pushAndRemoveUntil(
  fadeRoute(const HomeShell()),
  (route) => false,
);
```

Leave the existing `import 'home_screen.dart';` alone. It is no longer strictly needed in this file; remove it only if `dart analyze` flags it as unused. If removing it causes no other breakage, remove it for cleanliness.

- [ ] **Step 7: Run the widget tests**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/home_shell_test.dart
```

Expected: 3 tests pass (renders, Wallet tap, Profile tap).

- [ ] **Step 8: Run the full test suite**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test
```

Expected: all tests pass. The existing game-detail-screen widget tests and press-scale tests continue to pass because the HomeShell refactor does not touch them.

- [ ] **Step 9: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 10: Commit**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen
git add flutter_app/lib/screens/home_shell.dart flutter_app/lib/screens/profile_screen.dart flutter_app/lib/screens/home_screen.dart flutter_app/lib/screens/onboarding_screen.dart flutter_app/test/screens/home_shell_test.dart
git commit -m "$(cat <<'EOF'
feat(screens): extract HomeShell with floating nav pill and wire tabs

Create HomeShell, a new StatefulWidget that owns the tab state and
renders a Stack body with an IndexedStack of three children (the
existing HomeScreen, a private _WalletTabStub, and the new ProfileScreen
skeleton) plus the floating glass nav pill overlay with the
cream-to-transparent gradient fade above it. The nav pill, its
_buildBottomNav helper, and the _navItem helper all move from
HomeScreen into HomeShell verbatim, with Keys added to each nav item
so widget tests can tap them by name.

HomeScreen keeps its class name and every non-nav concern (gift
overlay, reward glow, game picker, all _build helpers). It drops
_navIndex, _buildBottomNav, _navItem, the Positioned nav overlay
block, and the top-level ScreenScaffold wrapper. The screen now
returns an AnimatedGradientBg wrapping its content Stack directly,
since the shell provides the outer Scaffold.

Onboarding pushes HomeShell instead of HomeScreen at the end of the
name step. Widget tests verify the shell renders and tapping the
Wallet or Profile tabs switches the IndexedStack to the right child.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Profile hero (avatar, email, provider badge)

**Files:**
- Modify: `flutter_app/lib/screens/profile_screen.dart`
- Modify: `flutter_app/test/screens/profile_screen_test.dart`

**Why now:** The hero is the most visible part of the profile. After this task the tab shows real content from `AppState`, which makes the remaining tasks easier to verify visually.

- [ ] **Step 1: Add failing tests for the hero**

Open `flutter_app/test/screens/profile_screen_test.dart` and append three new tests inside the existing `group('ProfileScreen', ...)`. Replace the file contents with this expanded version:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/profile_screen.dart';
import 'package:earnwise_mvp/state/app_state.dart';

/// Pumps [ProfileScreen] inside a minimal Provider + MaterialApp harness.
/// Optionally accepts a pre-built [AppState] so tests can set userName
/// or other fields before the screen reads them.
Future<void> pumpProfile(
  WidgetTester tester, {
  AppState? state,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state ?? AppState(),
      child: const MaterialApp(
        home: Scaffold(body: ProfileScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ProfileScreen', () {
    testWidgets('renders without throwing', (tester) async {
      await pumpProfile(tester);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('renders the avatar initial from userName', (tester) async {
      final state = AppState();
      state.userName = 'Lisa';
      await pumpProfile(tester, state: state);
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('renders the email from AppState', (tester) async {
      await pumpProfile(tester);
      expect(find.text('lisa@earnwise.demo'), findsWidgets);
    });

    testWidgets('renders the provider badge "via Google"', (tester) async {
      await pumpProfile(tester);
      expect(find.text('via'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
    });
  });
}
```

The email test uses `findsWidgets` (plural) because the email appears twice once the account section lands in Task 6 (once in the hero, once in the account row). For now it appears once, which still satisfies `findsWidgets`.

- [ ] **Step 2: Run the tests to confirm they fail**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/profile_screen_test.dart
```

Expected: the 3 new tests fail because nothing in the skeleton renders the text.

- [ ] **Step 3: Replace the skeleton with the hero layout**

Open `flutter_app/lib/screens/profile_screen.dart` and replace the entire file contents:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Full-page profile surface shown as the third tab inside [HomeShell].
/// Displays the user's avatar, email, fictional personal info fields,
/// a connected-account row, and a Sign Out button.
///
/// v1 is intentionally a demo surface: the edit icons are decorative,
/// the auth provider is hardcoded, and Sign Out just calls
/// [AppState.reset] and sends the user back to welcome.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile_screen_root'),
      color: AppColors.cream,
      child: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: AppLayout.gutter,
                right: AppLayout.gutter,
                top: AppSpacing.xl,
                // Extra bottom padding so the last element sits above the
                // floating nav pill overlay that HomeShell renders above
                // every tab.
                bottom: 140,
              ),
              child: Column(
                children: [
                  _ProfileHero(state: state),
                  // Personal Info, Account, and Sign Out are added in
                  // subsequent tasks.
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Hero block: avatar circle with initials on top, email and provider
/// badge below.
class _ProfileHero extends StatelessWidget {
  final AppState state;

  const _ProfileHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final initials = state.userName.isEmpty
        ? '?'
        : state.userName[0].toUpperCase();
    return Column(
      children: [
        _AvatarCircle(initials: initials),
        const SizedBox(height: AppSpacing.lg),
        Text(
          state.email,
          style: AppText.body.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        _ProviderBadge(provider: state.authProvider),
      ],
    );
  }
}

/// Teal circle with white initials centered and a soft primary-alpha
/// glow layer behind it.
class _AvatarCircle extends StatelessWidget {
  final String initials;

  const _AvatarCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow layer: slightly larger soft circle behind the avatar.
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          // Avatar face.
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppText.display.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// "via [G] Google" row shown under the email.
class _ProviderBadge extends StatelessWidget {
  final String provider;

  const _ProviderBadge({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'via',
          style: AppText.caption.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(width: 6),
        const _GoogleLogo(size: 20),
        const SizedBox(width: 6),
        Text(
          provider,
          style: AppText.caption.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}

/// Google G logo asset with a letter-fallback for when the asset is
/// missing. Same pattern as the game detail screen's game icon.
class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/google_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Text(
              'G',
              style: AppText.caption.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.62,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests to confirm they pass**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/profile_screen_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 5: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen
git add flutter_app/lib/screens/profile_screen.dart flutter_app/test/screens/profile_screen_test.dart
git commit -m "$(cat <<'EOF'
feat(screens): render profile hero with avatar, email, provider badge

Replace the profile screen skeleton with a hero block that renders the
avatar circle (teal fill, first letter of userName, soft primary-alpha
glow), the email from AppState, and a "via [G] Google" provider badge
row. The Google G logo uses an Image.asset with an errorBuilder
fallback that renders a white circle with a black G letter when the
asset is missing, so the build does not crash until the user drops
assets/images/google_logo.png. The remaining personal-info, account,
and sign-out sections land in follow-up tasks.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Personal Info section

**Files:**
- Modify: `flutter_app/lib/screens/profile_screen.dart`
- Modify: `flutter_app/test/screens/profile_screen_test.dart`

**Why now:** This is the densest visible block on the profile. Adding it after the hero lets the page look close to complete before the account card and sign out button land.

- [ ] **Step 1: Add failing tests for the personal info section**

Add these tests inside the existing `group('ProfileScreen', ...)` in `test/screens/profile_screen_test.dart`:

```dart
testWidgets('renders the PERSONAL INFO section heading', (tester) async {
  await pumpProfile(tester);
  expect(find.text('PERSONAL INFO'), findsOneWidget);
});

testWidgets('renders the Full Name row with label and value',
    (tester) async {
  final state = AppState();
  state.userName = 'Lisa';
  await pumpProfile(tester, state: state);
  expect(find.text('Full Name'), findsOneWidget);
  // The hero shows the initial 'L' and the info row shows the full name 'Lisa'.
  expect(find.text('Lisa'), findsOneWidget);
});

testWidgets('renders the Age Range row with label and value',
    (tester) async {
  await pumpProfile(tester);
  expect(find.text('Age Range'), findsOneWidget);
  expect(find.text('26-35'), findsOneWidget);
});

testWidgets('renders the Gender row with label and value', (tester) async {
  await pumpProfile(tester);
  expect(find.text('Gender'), findsOneWidget);
  expect(find.text('Female'), findsOneWidget);
});
```

- [ ] **Step 2: Run the tests to confirm they fail**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/profile_screen_test.dart
```

Expected: the 4 new tests fail because nothing in the screen renders these strings yet.

- [ ] **Step 3: Add the section heading and the info card widgets**

Open `flutter_app/lib/screens/profile_screen.dart`. Append these private widgets at the bottom of the file (after `_GoogleLogo`):

```dart
/// The eyebrow heading style used by every section on the profile.
/// Uppercase, letter-spaced, ink-tertiary, weight 700. Matches the same
/// recipe used by the game detail screen's _SectionHeading.
class _SectionHeading extends StatelessWidget {
  final String label;

  const _SectionHeading({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.inkTertiary,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Outer card wrapping three _InfoRow children with thin dividers.
/// Replicates the AppCard visual recipe inline (white, 18 radius,
/// cream-deep border, soft shadow) because the profile info card is
/// a fixed three-row layout that does not need the AppCard widget's
/// tap-target behavior.
class _InfoCard extends StatelessWidget {
  final AppState state;

  const _InfoCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          _InfoRow(
            icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
            label: 'Full Name',
            value: state.userName,
          ),
          const _RowDivider(),
          _InfoRow(
            icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular),
            label: 'Age Range',
            value: state.ageRange,
          ),
          const _RowDivider(),
          _InfoRow(
            icon: PhosphorIcons.usersThree(PhosphorIconsStyle.regular),
            label: 'Gender',
            value: state.gender,
          ),
        ],
      ),
    );
  }
}

/// One row inside _InfoCard. Circular icon tile on the left, label
/// above value in the middle, decorative pencil icon on the right.
/// The pencil icon has no tap handler in v1.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      AppText.caption.copyWith(color: AppColors.inkSecondary),
                ),
                const SizedBox(height: 2),
                Text(value, style: AppText.listItem),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            PhosphorIcons.pencilSimpleLine(PhosphorIconsStyle.regular),
            size: 20,
            color: AppColors.inkTertiary,
          ),
        ],
      ),
    );
  }
}

/// 1 px cream-deep divider inset from both sides by AppSpacing.md so it
/// does not touch the card border.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.creamDeep,
      ),
    );
  }
}
```

`PhosphorIcons` comes from `package:phosphor_flutter/phosphor_flutter.dart`. Add this import at the top of the file:

```dart
import 'package:phosphor_flutter/phosphor_flutter.dart';
```

- [ ] **Step 4: Wire the section into the ProfileScreen column**

In `ProfileScreen.build`, add the section heading and the info card to the `Column` after `_ProfileHero`:

```dart
child: Column(
  children: [
    _ProfileHero(state: state),
    const SizedBox(height: AppSpacing.xl),
    const _SectionHeading(label: 'PERSONAL INFO'),
    _InfoCard(state: state),
    // Account and Sign Out are added in subsequent tasks.
  ],
),
```

- [ ] **Step 5: Run the tests to confirm they pass**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/profile_screen_test.dart
```

Expected: 8 tests pass (4 from the earlier tasks plus 4 new).

- [ ] **Step 6: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 7: Commit**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen
git add flutter_app/lib/screens/profile_screen.dart flutter_app/test/screens/profile_screen_test.dart
git commit -m "$(cat <<'EOF'
feat(screens): add profile PERSONAL INFO section with three rows

Append a _SectionHeading helper and _InfoCard / _InfoRow / _RowDivider
private widgets to profile_screen.dart and wire them into the scrolling
Column after the hero. The card renders the AppCard visual recipe
inline (white, 18 radius, cream-deep border, soft shadow) with three
rows separated by thin dividers: Full Name pulls from AppState.userName,
Age Range and Gender pull from the new profile fields. Each row has a
circular teal-alpha icon tile, label above value, and a decorative
pencil icon on the right that does nothing on tap in v1.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Account section

**Files:**
- Modify: `flutter_app/lib/screens/profile_screen.dart`
- Modify: `flutter_app/test/screens/profile_screen_test.dart`

**Why now:** The account card is a single row and depends on the `_GoogleLogo` helper that already exists from Task 4. Adding it here keeps Task 7 focused on the sign-out flow.

- [ ] **Step 1: Add failing tests for the account section**

Add these tests inside the existing `group('ProfileScreen', ...)`:

```dart
testWidgets('renders the ACCOUNT section heading', (tester) async {
  await pumpProfile(tester);
  expect(find.text('ACCOUNT'), findsOneWidget);
});

testWidgets('renders the Connected Account row with the email',
    (tester) async {
  await pumpProfile(tester);
  expect(find.text('Connected Account'), findsOneWidget);
  // Email now appears twice: once in the hero and once in the account row.
  expect(find.text('lisa@earnwise.demo'), findsNWidgets(2));
});
```

- [ ] **Step 2: Run the tests to confirm they fail**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/profile_screen_test.dart
```

Expected: the 2 new tests fail.

- [ ] **Step 3: Add the account card widgets**

Append these private widgets at the bottom of `profile_screen.dart`:

```dart
/// Outer card for the connected account row. Same AppCard visual
/// recipe as _InfoCard (white, 18 radius, cream-deep border, soft
/// shadow) but holds only one row because there is only one connected
/// account in v1.
class _AccountCard extends StatelessWidget {
  final AppState state;

  const _AccountCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.creamDeep, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _AccountRow(state: state),
    );
  }
}

/// Connected Account row: Google logo on the left, label above the
/// email in the middle, lock icon on the right. The lock icon signals
/// that this row is not editable (unlike the decorative pencil icons
/// on _InfoRow).
class _AccountRow extends StatelessWidget {
  final AppState state;

  const _AccountRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const _GoogleLogo(size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Account',
                  style:
                      AppText.caption.copyWith(color: AppColors.inkSecondary),
                ),
                const SizedBox(height: 2),
                Text(state.email, style: AppText.listItem),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            PhosphorIcons.lock(PhosphorIconsStyle.regular),
            size: 20,
            color: AppColors.inkTertiary,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Wire the section into ProfileScreen**

In `ProfileScreen.build`, extend the `Column` children to add the account section after the info card:

```dart
child: Column(
  children: [
    _ProfileHero(state: state),
    const SizedBox(height: AppSpacing.xl),
    const _SectionHeading(label: 'PERSONAL INFO'),
    _InfoCard(state: state),
    const SizedBox(height: AppSpacing.lg),
    const _SectionHeading(label: 'ACCOUNT'),
    _AccountCard(state: state),
    // Sign Out is added in the next task.
  ],
),
```

- [ ] **Step 5: Run the tests**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/profile_screen_test.dart
```

Expected: 10 tests pass (8 prior plus 2 new).

- [ ] **Step 6: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 7: Commit**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen
git add flutter_app/lib/screens/profile_screen.dart flutter_app/test/screens/profile_screen_test.dart
git commit -m "$(cat <<'EOF'
feat(screens): add profile ACCOUNT section with connected account row

Append _AccountCard and _AccountRow private widgets to profile_screen.dart
and wire them into the scrolling Column after the PERSONAL INFO card.
The row uses the existing _GoogleLogo helper at 44 px on the left, a
two-line Connected Account label plus email in the middle, and a lock
icon from phosphor_flutter on the right. The lock visually signals
that this row is not editable, in contrast to the decorative pencil
icons on the info rows.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Sign Out button and reset wiring

**Files:**
- Modify: `flutter_app/lib/screens/profile_screen.dart`
- Modify: `flutter_app/test/screens/profile_screen_test.dart`

**Why last:** The Sign Out flow touches `AppState.reset()` (Task 1) and the navigation back to `WelcomeScreen`. With everything else already on the screen, this final task closes the loop and makes the profile fully interactive.

- [ ] **Step 1: Add failing tests for the Sign Out button**

Add these tests inside the existing `group('ProfileScreen', ...)`:

```dart
testWidgets('renders the Sign Out button', (tester) async {
  await pumpProfile(tester);
  expect(find.byKey(const Key('profile_sign_out')), findsOneWidget);
  expect(find.text('Sign Out'), findsOneWidget);
});

testWidgets('tapping Sign Out calls AppState.reset', (tester) async {
  final state = AppState();
  state.userName = 'Dirty';
  state.stars = 9999;
  state.tasksCompleted = 5;

  await pumpProfile(tester, state: state);
  expect(find.text('Sign Out'), findsOneWidget);

  await tester.tap(find.byKey(const Key('profile_sign_out')));
  await tester.pumpAndSettle();

  // AppState is back to defaults.
  expect(state.userName, 'Lisa');
  expect(state.stars, 125);
  expect(state.tasksCompleted, 0);
});

testWidgets('tapping Sign Out pops the profile screen away',
    (tester) async {
  await pumpProfile(tester);
  expect(find.text('Sign Out'), findsOneWidget);

  await tester.tap(find.byKey(const Key('profile_sign_out')));
  await tester.pumpAndSettle();

  // The Sign Out button is no longer in the tree because the profile
  // screen was popped (and the WelcomeScreen is now on top).
  expect(find.text('Sign Out'), findsNothing);
});
```

The second test verifies the reset call by checking three representative fields, not all 20. That keeps the assertion compact while still proving `reset()` was invoked.

The third test verifies the navigation happened by confirming the profile screen is no longer in the tree. The test does not assert we landed on `WelcomeScreen` specifically because `WelcomeScreen` has entrance animations that make `find` assertions brittle during `pumpAndSettle`.

- [ ] **Step 2: Run the tests to confirm they fail**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/profile_screen_test.dart
```

Expected: the 3 new tests fail because no `profile_sign_out` key is in the tree.

- [ ] **Step 3: Add the Sign Out button widget**

Append this private widget at the bottom of `profile_screen.dart`:

```dart
/// Red-outlined pill button. Full width. Tap calls AppState.reset()
/// and then pushes the welcome screen onto a cleared navigation stack.
class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: const Key('profile_sign_out'),
        onPressed: () {
          context.read<AppState>().reset();
          Navigator.of(context).pushAndRemoveUntil(
            fadeRoute(const WelcomeScreen()),
            (route) => false,
          );
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: _kSignOutRed,
          side: const BorderSide(color: _kSignOutRed, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 18),
          minimumSize: const Size(double.infinity, 60),
        ),
        child: Text(
          'Sign Out',
          style: AppText.ctaLabel.copyWith(color: _kSignOutRed),
        ),
      ),
    );
  }
}

/// Red used by the Sign Out button. Not in AppColors because Sign Out
/// is the only red surface in the app today; if a second red element
/// ever ships, promote this to AppColors.
const Color _kSignOutRed = Color(0xFFDC2626);
```

Add these imports at the top of `profile_screen.dart`:

```dart
import '../widgets/fade_route.dart';
import 'welcome_screen.dart';
```

- [ ] **Step 4: Wire the Sign Out button into the ProfileScreen column**

In `ProfileScreen.build`, extend the `Column` children to add the Sign Out button after the account card:

```dart
child: Column(
  children: [
    _ProfileHero(state: state),
    const SizedBox(height: AppSpacing.xl),
    const _SectionHeading(label: 'PERSONAL INFO'),
    _InfoCard(state: state),
    const SizedBox(height: AppSpacing.lg),
    const _SectionHeading(label: 'ACCOUNT'),
    _AccountCard(state: state),
    const SizedBox(height: AppSpacing.xl),
    const _SignOutButton(),
  ],
),
```

- [ ] **Step 5: Run the tests**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test test/screens/profile_screen_test.dart
```

Expected: 13 tests pass (10 prior plus 3 new).

- [ ] **Step 6: Run the full test suite**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
flutter test
```

Expected: every test in the repository passes. This includes the game-detail-screen widget tests, the press-scale test, the new `app_state_test.dart`, the new `home_shell_test.dart`, and the 13 profile screen tests.

- [ ] **Step 7: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 8: Run the formatter**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen/flutter_app
dart format lib/state/app_state.dart lib/screens/home_shell.dart lib/screens/home_screen.dart lib/screens/onboarding_screen.dart lib/screens/profile_screen.dart test/state/app_state_test.dart test/screens/home_shell_test.dart test/screens/profile_screen_test.dart
```

Expected: the formatter reports which files changed (likely zero if you matched the existing style; otherwise a handful of whitespace tweaks).

- [ ] **Step 9: Commit**

```bash
cd /Users/markus/Dev/earnapp/.worktrees/game-detail-screen
git add flutter_app/lib/screens/profile_screen.dart flutter_app/test/screens/profile_screen_test.dart
git commit -m "$(cat <<'EOF'
feat(screens): wire Sign Out button that resets AppState and pops to welcome

Add a _SignOutButton private widget to profile_screen.dart and wire it
into the bottom of the scrolling Column. The button is a full-width
red-outlined pill (white fill, DC2626 red border and text, stadium
shape, 60 px tall) that, on tap, calls AppState.reset() and then
pushAndRemoveUntil fadeRoute WelcomeScreen so the back stack is cleared
and the user flows through welcome, trust carousel, and onboarding
from scratch. Widget tests verify the button renders with the expected
Key and that tapping it resets three representative AppState fields
and removes the profile screen from the tree.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

### Spec coverage check

| Spec section | Covered by |
|---|---|
| Naming contract (`HomeShell`, `HomeScreen`, `ProfileScreen`, `_WalletTabStub`) | Task 3 creates/modifies all four with the exact names. |
| `HomeShell` Stack body with floating nav pill | Task 3 Step 3 |
| `_buildBottomNav` and `_navItem` lifted into shell | Task 3 Step 3 |
| `_WalletTabStub` inside `home_shell.dart` | Task 3 Step 3 |
| `HomeScreen` deletions (`_navIndex`, `_buildBottomNav`, `_navItem`, `Positioned` nav block, `ScreenScaffold` wrapper) | Task 3 Step 5 |
| Entry point update in `onboarding_screen.dart` | Task 3 Step 6 |
| `ProfileScreen` hero (avatar, email, provider badge) | Task 4 |
| `ProfileScreen` PERSONAL INFO section with three rows | Task 5 |
| `ProfileScreen` ACCOUNT section with connected account row | Task 6 |
| `ProfileScreen` Sign Out button wired to reset + welcome | Task 7 |
| `AppState` fields (`email`, `authProvider`, `ageRange`, `gender`) | Task 1 Step 3 |
| `AppState.reset()` restoring all 20 fields | Task 1 Step 4 |
| Widget tests for `ProfileScreen` covering hero, info, account, sign out | Tasks 2/4/5/6/7 |
| Widget tests for `HomeShell` covering tab switching | Task 3 |
| Unit test for `AppState.reset()` | Task 1 |
| `_GoogleLogo` fallback for missing asset | Task 4 Step 3 |
| Asset prerequisite documented | Plan header |

Every spec section maps to a concrete task.

### Placeholder scan

No `TBD`, `TODO`, `implement later`, or "Add appropriate error handling" markers anywhere in the plan. Every step shows the literal code to write, the exact command to run, and the expected output. One code comment inside the plan says "Content is added in subsequent tasks" and "Sign Out is added in the next task"; these are forward-references to Task 4 through 7, not unfilled steps.

### Type consistency

- `AppState` field names (`email`, `authProvider`, `ageRange`, `gender`) are identical across Task 1 (definition), Task 4 (hero display), Task 5 (info rows), Task 6 (account row), and Task 7 (reset test assertions).
- `ProfileScreen` constructor signature is `const ProfileScreen({super.key})` across Tasks 2, 3, 4, 5, 6, 7.
- `HomeShell` constructor signature is `const HomeShell({super.key})` across Task 3.
- Widget Keys used in tests (`shell_nav_wallet`, `shell_nav_profile`, `profile_screen_root`, `profile_sign_out`) are defined at the exact same spelling at the matching call site.
- `_WalletTabStub` is a private class in `home_shell.dart` per the naming contract; it is never referenced from outside the shell file.

### Em-dash scan

The plan was authored with the project rule in mind. No em-dashes in any prose, code, comment, or commit message. Task 3 Step 6 explicitly replaces `HomeScreen` with `HomeShell` in `onboarding_screen.dart` with no em-dashes introduced.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-10-profile-screen.md`. Two execution options:

**1. Subagent-Driven (recommended)**: I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution**: Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
