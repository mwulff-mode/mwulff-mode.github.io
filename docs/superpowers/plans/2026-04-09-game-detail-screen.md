# Game Detail Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a new full-page game detail screen that opens when a user picks a game from the picker sheet, showing a 2-step ladder summing to $1.00, a sticky Install CTA, an X close button, and a re-pickable flow.

**Architecture:** A `StatelessWidget` (`GameDetailScreen`) that takes a `Game` data object plus a `VoidCallback onInstall`. Game data lives in a new `lib/data/games.dart` file with three hardcoded entries. The home screen picker is updated to push the detail screen via `fadeRoute` after the sheet pops, capturing the picked game name into `_selectedGame` so the existing reward animation copy stays correct.

**Tech Stack:** Flutter (Material), `provider` for state, `phosphor_flutter` icons, existing EarnWise design system primitives (`AppText`, `AppColors`, `AppSpacing`, `AppLayout`, `PhysicalPress`, `PressScale`, `fadeRoute`, `ScreenScaffold`), `flutter_test` for widget tests.

**Spec:** [`docs/superpowers/specs/2026-04-09-game-detail-screen-design.md`](../specs/2026-04-09-game-detail-screen-design.md)

**Prerequisites (user-owned, not part of any task):**
Three game icon PNG files dropped at `assets/images/games/{candy_crush,solitaire,word_search}.png`. The `_GameIcon` widget includes an `errorBuilder` fallback so the build does not crash if these are missing. The screen will render a colored letter square in their place until the real assets arrive.

**Codebase notes for the implementing engineer:**

- Project root for the Flutter app is `flutter_app/`. All `flutter` and `dart` commands run from there. When in doubt, prefix with `cd /Users/markus/Dev/earnapp/flutter_app && ...`.
- Package name is `earnwise_mvp`. Imports use `package:earnwise_mvp/...`.
- Existing test pattern lives at `test/widgets/press_scale_test.dart`. Follow it: `MaterialApp` + `Scaffold` wrapper, `find.text` / `find.byKey` / `find.byType`, `tester.pumpAndSettle()` after taps.
- Run a single test file with `flutter test test/path/file.dart`. Run a single test with `flutter test test/path/file.dart --plain-name 'test name'`.
- After every code change, before committing, run `dart analyze` and confirm zero issues. Run `dart format lib/ test/` to keep formatting consistent.
- Project memory rule, applies to every string in this plan and every commit message: **no em-dashes**. Use periods, commas, colons, or parentheses instead.

---

## File Structure

**Files created:**

| Path | Purpose | Approx size |
|---|---|---|
| `lib/data/games.dart` | `Game` and `GameStep` data classes plus three const game instances and a `gamesByName` lookup map. Pure data, no widgets. | ~120 lines |
| `lib/screens/game_detail_screen.dart` | `GameDetailScreen` (stateless) plus all of its private widgets (`_HeroBand`, `_GameIcon`, `_TitleRow`, `_EarningBadge`, `_TopProgressBar`, `_SectionHeading`, `_StepCard`, `_AboutSection`, `_DisclaimerSection`). | ~400 lines |
| `test/data/games_test.dart` | Pure data tests for the game definitions. | ~50 lines |
| `test/screens/game_detail_screen_test.dart` | Widget tests for the detail screen. Builds up through the tasks. | ~250 lines |

**Files modified:**

| Path | Change |
|---|---|
| `lib/screens/home_screen.dart` | Update the picker sheet description copy. Update the `_showGamePicker` `.then` callback to push `GameDetailScreen` via `fadeRoute` instead of calling `_completeTask` directly. Add two imports. |

**Files NOT modified:**

`lib/state/app_state.dart` is not touched. The reward engine still pays $1.00 for `'game'` exactly as today. The detail screen ladder is intentionally aligned to that number.

---

## Task 1: Game data layer

**Files:**
- Create: `lib/data/games.dart`
- Create: `test/data/games_test.dart`

**Why first:** Every later task uses this data to render and to test. Locking it in first means later tasks can use real `Game` instances instead of fakes.

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/data/games_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/data/games.dart';

void main() {
  group('gamesByName', () {
    test('contains exactly 3 entries keyed by display name', () {
      expect(gamesByName.keys.toSet(),
          {'Candy Crush', 'Solitaire', 'Word Search'});
    });

    test('every game has 2 regular steps totaling \$1.00', () {
      for (final game in gamesByName.values) {
        expect(game.regularSteps.length, 2,
            reason: '${game.name} should have exactly 2 steps');
        final total = game.regularSteps
            .fold<double>(0.0, (sum, step) => sum + step.reward);
        expect(total, closeTo(1.00, 0.001),
            reason: '${game.name} steps should sum to \$1.00');
      }
    });

    test('every game has non-empty howItWorks, about, disclaimer', () {
      for (final game in gamesByName.values) {
        expect(game.howItWorks, isNotEmpty);
        expect(game.about, isNotEmpty);
        expect(game.disclaimer, isNotEmpty);
      }
    });

    test('every game has a non-empty iconPath under assets/images/games/', () {
      for (final game in gamesByName.values) {
        expect(game.iconPath, startsWith('assets/images/games/'));
        expect(game.iconPath, endsWith('.png'));
      }
    });

    test('every game has a 2-stop hero gradient', () {
      for (final game in gamesByName.values) {
        expect(game.heroGradient.length, 2,
            reason: '${game.name} should have 2 gradient stops');
      }
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/data/games_test.dart
```

Expected: failure with `Target of URI doesn't exist: 'package:earnwise_mvp/data/games.dart'`.

- [ ] **Step 3: Write the data file**

Create `flutter_app/lib/data/games.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One step in a game's reward ladder.
class GameStep {
  final String label;
  final double reward;

  const GameStep({required this.label, required this.reward});
}

/// All the data needed to render a game detail page. Hardcoded in
/// [gamesByName] for v1. Three games total.
class Game {
  /// Stable internal id, lowercase snake_case. Matches the filename of the
  /// icon asset.
  final String key;

  /// Display name. Used as the lookup key in [gamesByName] and as the title
  /// shown on the detail screen.
  final String name;

  /// Short category label like 'Puzzle' or 'Card'.
  final String category;

  /// 0.0 to 5.0 star rating. Hardcoded per game.
  final double rating;

  /// Asset path under `assets/images/games/`. The detail screen uses an
  /// `errorBuilder` fallback so a missing file does not crash the build.
  final String iconPath;

  /// Two color stops used by the hero band gradient.
  final List<Color> heroGradient;

  /// Ordered list of regular steps. v1 always has exactly 2.
  final List<GameStep> regularSteps;

  /// Short paragraph for the HOW IT WORKS section.
  final String howItWorks;

  /// 2 to 3 sentence game blurb for the ABOUT section.
  final String about;

  /// Fine print for the DISCLAIMER section.
  final String disclaimer;

  const Game({
    required this.key,
    required this.name,
    required this.category,
    required this.rating,
    required this.iconPath,
    required this.heroGradient,
    required this.regularSteps,
    required this.howItWorks,
    required this.about,
    required this.disclaimer,
  });
}

/// All games shown in the picker, keyed by display name. The picker sheet
/// pops with the display name as its result, so the home screen can look
/// the matching `Game` up directly with `gamesByName[picked]`.
const Map<String, Game> gamesByName = {
  'Candy Crush': Game(
    key: 'candy_crush',
    name: 'Candy Crush',
    category: 'Puzzle',
    rating: 4.7,
    iconPath: 'assets/images/games/candy_crush.png',
    heroGradient: [AppColors.taskVideo, AppColors.accent],
    regularSteps: [
      GameStep(label: 'Install the app', reward: 0.10),
      GameStep(label: 'Reach Level 15', reward: 0.90),
    ],
    howItWorks:
        'Download the app for free, swap candies to clear the puzzles, and earn dollars when you hit each milestone.',
    about:
        'A bright, casual matching game where you swap and chain colored candies to clear the board. Great for short sessions while you wait for the bus.',
    disclaimer:
        'Rewards credit to your EarnWise balance after each milestone is verified. Some milestones can take a few hours to confirm.',
  ),
  'Solitaire': Game(
    key: 'solitaire',
    name: 'Solitaire',
    category: 'Card',
    rating: 4.6,
    iconPath: 'assets/images/games/solitaire.png',
    heroGradient: [AppColors.primary, AppColors.creamDeep],
    regularSteps: [
      GameStep(label: 'Install the app', reward: 0.10),
      GameStep(label: 'Win 25 games', reward: 0.90),
    ],
    howItWorks:
        'Download the app for free, sort cards into the four foundation piles, and earn dollars when you hit each milestone.',
    about:
        'The classic single-player card game. Stack cards in descending order, build the foundations, and finish a hand in a few quiet minutes.',
    disclaimer:
        'Rewards credit to your EarnWise balance after each milestone is verified. Some milestones can take a few hours to confirm.',
  ),
  'Word Search': Game(
    key: 'word_search',
    name: 'Word Search',
    category: 'Word',
    rating: 4.5,
    iconPath: 'assets/images/games/word_search.png',
    heroGradient: [AppColors.taskCheckin, AppColors.creamWarm],
    regularSteps: [
      GameStep(label: 'Install the app', reward: 0.10),
      GameStep(label: 'Complete 20 puzzles', reward: 0.90),
    ],
    howItWorks:
        'Download the app for free, find every word hidden in the grid, and earn dollars when you hit each milestone.',
    about:
        'A relaxing puzzle game where you trace hidden words in a grid of letters. New themes and word lists are added every week.',
    disclaimer:
        'Rewards credit to your EarnWise balance after each milestone is verified. Some milestones can take a few hours to confirm.',
  ),
};
```

- [ ] **Step 4: Run the test to confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/data/games_test.dart
```

Expected: 5 tests pass.

- [ ] **Step 5: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
cd /Users/markus/Dev/earnapp
git add flutter_app/lib/data/games.dart flutter_app/test/data/games_test.dart
git commit -m "feat(data): add Game model and three game definitions"
```

---

## Task 2: GameDetailScreen scaffold with X close button

**Files:**
- Create: `lib/screens/game_detail_screen.dart`
- Create: `test/screens/game_detail_screen_test.dart`

**Why next:** Establishes the page shell and proves the close interaction works before any layout content is added. Later tasks fill in sections without touching the X behavior.

- [ ] **Step 1: Write the failing widget test**

Create `flutter_app/test/screens/game_detail_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/data/games.dart';
import 'package:earnwise_mvp/screens/game_detail_screen.dart';

void main() {
  /// Helper that pushes [GameDetailScreen] onto a real Navigator so the
  /// X button can pop it like in the real app.
  Future<void> pumpDetail(
    WidgetTester tester, {
    required Game game,
    VoidCallback? onInstall,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GameDetailScreen(
                      game: game,
                      onInstall: onInstall ?? () {},
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('GameDetailScreen', () {
    testWidgets('renders the game name in the title', (tester) async {
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('Candy Crush'), findsWidgets);
    });

    testWidgets('X button pops the screen', (tester) async {
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('Candy Crush'), findsWidgets);

      await tester.tap(find.byKey(const Key('game_detail_close')));
      await tester.pumpAndSettle();

      expect(find.text('Candy Crush'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: failure with `Target of URI doesn't exist: 'package:earnwise_mvp/screens/game_detail_screen.dart'`.

- [ ] **Step 3: Create the minimal screen**

Create `flutter_app/lib/screens/game_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../data/games.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/press_scale.dart';

/// Full-page detail view for a single game. Opens after the user picks a
/// game from the home screen game picker. The X button in the hero band
/// pops the screen without committing. The sticky Install CTA at the
/// bottom (added in Task 7) commits via [onInstall] and then pops.
class GameDetailScreen extends StatelessWidget {
  final Game game;
  final VoidCallback onInstall;

  const GameDetailScreen({
    super.key,
    required this.game,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Hero band, partial in this task: gradient + close button only.
          // Title, icon, and the rest of the page are added in later tasks.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220 + MediaQuery.of(context).padding.top,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: game.heroGradient,
                ),
              ),
            ),
          ),
          // X close button, top right, inside safe area.
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: PressScale(
              onTap: () => Navigator.of(context).pop(),
              haptic: null,
              child: Container(
                key: const Key('game_detail_close'),
                width: 40,
                height: 40,
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
          ),
          // Below the hero, an Offstage Text holds the game name so the
          // first widget test can find it. Real title row is added in
          // Task 4 and replaces this stub.
          Positioned(
            top: 220 + MediaQuery.of(context).padding.top + 24,
            left: 24,
            child: Text(game.name, style: AppText.sectionTitle),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 5: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
cd /Users/markus/Dev/earnapp
git add flutter_app/lib/screens/game_detail_screen.dart flutter_app/test/screens/game_detail_screen_test.dart
git commit -m "feat(screens): add GameDetailScreen scaffold with X close"
```

---

## Task 3: Game icon with missing-asset fallback

**Files:**
- Modify: `lib/screens/game_detail_screen.dart`
- Modify: `test/screens/game_detail_screen_test.dart`

**Why now:** Before adding visible content, prove the icon renders when the asset exists and falls back gracefully when it does not. Every later task assumes the page does not crash without art.

- [ ] **Step 1: Add a failing test for the fallback**

Add this `testWidgets` block inside the existing `group('GameDetailScreen', ...)` in `test/screens/game_detail_screen_test.dart`:

```dart
testWidgets(
  'falls back to a colored letter square when the icon asset is missing',
  (tester) async {
    const fakeGame = Game(
      key: 'fake',
      name: 'Fake Game',
      category: 'Puzzle',
      rating: 4.0,
      iconPath: 'assets/images/games/does_not_exist.png',
      heroGradient: [AppColors.primary, AppColors.creamDeep],
      regularSteps: [
        GameStep(label: 'Install the app', reward: 0.10),
        GameStep(label: 'Reach Level 1', reward: 0.90),
      ],
      howItWorks: 'How it works copy.',
      about: 'About copy.',
      disclaimer: 'Disclaimer copy.',
    );
    await pumpDetail(tester, game: fakeGame);
    // Wait long enough for Image.asset to fail and call the errorBuilder.
    await tester.pump(const Duration(milliseconds: 200));
    // Fallback shows the first letter of the game name.
    expect(find.text('F'), findsOneWidget);
  },
);
```

You will need to add these imports at the top of the test file (alongside the existing ones):

```dart
import 'package:earnwise_mvp/theme/app_theme.dart';
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: the new test fails because no `_GameIcon` exists yet and nothing is rendering an `'F'` letter.

- [ ] **Step 3: Add `_GameIcon` and place it inside the hero band**

In `lib/screens/game_detail_screen.dart`, add this private widget at the bottom of the file (after the `GameDetailScreen` class):

```dart
/// Displays the square game icon at the requested size, with a colored
/// letter-square fallback when the asset cannot be loaded. Used inside
/// the hero band so the screen never crashes when art is missing.
class _GameIcon extends StatelessWidget {
  final Game game;
  final double size;

  const _GameIcon({required this.game, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        game.iconPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: game.heroGradient.isNotEmpty
                ? game.heroGradient.first
                : AppColors.creamDeep,
            alignment: Alignment.center,
            child: Text(
              game.name.isEmpty ? '?' : game.name[0].toUpperCase(),
              style: AppText.display.copyWith(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
```

Now place the icon inside the hero band. Update the hero `Positioned` in `GameDetailScreen.build` to add a centered icon child:

```dart
Positioned(
  top: 0,
  left: 0,
  right: 0,
  height: 220 + MediaQuery.of(context).padding.top,
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: game.heroGradient,
      ),
    ),
    child: Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      child: Center(
        child: _GameIcon(game: game),
      ),
    ),
  ),
),
```

- [ ] **Step 4: Run the tests to confirm everything passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: all 3 tests pass.

- [ ] **Step 5: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
cd /Users/markus/Dev/earnapp
git add flutter_app/lib/screens/game_detail_screen.dart flutter_app/test/screens/game_detail_screen_test.dart
git commit -m "feat(screens): render game icon with missing-asset fallback"
```

---

## Task 4: Title row, earning badge, top progress bar

**Files:**
- Modify: `lib/screens/game_detail_screen.dart`
- Modify: `test/screens/game_detail_screen_test.dart`

**Why now:** This is the metadata block right under the hero. After this task the page already shows everything a user needs to recognize the game and its earning ceiling. Later tasks add explanatory content.

- [ ] **Step 1: Add failing tests for the title block**

Add these tests inside the existing `group('GameDetailScreen', ...)` in `test/screens/game_detail_screen_test.dart`:

```dart
testWidgets('renders the game category and rating', (tester) async {
  await pumpDetail(tester, game: gamesByName['Candy Crush']!);
  expect(find.text('Puzzle'), findsOneWidget);
  expect(find.text('4.7'), findsOneWidget);
});

testWidgets('renders the max earning badge as \$1.00', (tester) async {
  await pumpDetail(tester, game: gamesByName['Candy Crush']!);
  expect(find.text('\$1.00'), findsWidgets);
});

testWidgets('renders the progress label "0.00 earned of \$1.00"',
    (tester) async {
  await pumpDetail(tester, game: gamesByName['Candy Crush']!);
  expect(find.text('\$0.00 earned of \$1.00'), findsOneWidget);
});
```

- [ ] **Step 2: Run the tests to confirm they fail**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: the 3 new tests fail with "expected one matching node, found zero".

- [ ] **Step 3: Replace the body of `GameDetailScreen.build` with a scrolling layout**

In `lib/screens/game_detail_screen.dart`, replace the entire `build` method body with the scrolling structure below. The hero band, X button, and stub title from Task 2 / 3 stay, but the stub `Positioned` Text for the game name is removed because the new `_TitleRow` renders it. The page becomes a `Stack` with the hero on top and a `SingleChildScrollView` underneath that starts below the hero.

```dart
@override
Widget build(BuildContext context) {
  final topInset = MediaQuery.of(context).padding.top;
  final heroHeight = 220 + topInset;

  return Scaffold(
    backgroundColor: AppColors.cream,
    body: Stack(
      children: [
        // Hero band, full width, gradient + centered icon.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: heroHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: game.heroGradient,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: topInset),
              child: Center(
                child: _GameIcon(game: game),
              ),
            ),
          ),
        ),
        // Scrolling content begins under the hero.
        Positioned.fill(
          top: heroHeight,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppLayout.gutter,
              right: AppLayout.gutter,
              top: AppSpacing.lg,
              bottom: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TitleRow(game: game),
                const SizedBox(height: AppSpacing.lg),
                const _TopProgressBar(),
              ],
            ),
          ),
        ),
        // X close button, top right, inside safe area.
        Positioned(
          top: topInset + 12,
          right: 20,
          child: PressScale(
            onTap: () => Navigator.of(context).pop(),
            haptic: null,
            child: Container(
              key: const Key('game_detail_close'),
              width: 40,
              height: 40,
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
        ),
      ],
    ),
  );
}
```

Add the three new private widgets at the bottom of the same file (after `_GameIcon`):

```dart
/// Game name on the left, max-earning badge on the right. A second line
/// shows the rating (Phosphor star + number) and the category, separated
/// by a centered dot.
class _TitleRow extends StatelessWidget {
  final Game game;

  const _TitleRow({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                game.name,
                style: AppText.brandMark.copyWith(fontSize: 28),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const _EarningBadge(amount: 1.00),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              PhosphorIcons.star(PhosphorIconsStyle.fill),
              size: 16,
              color: AppColors.gold,
            ),
            const SizedBox(width: 4),
            Text(
              game.rating.toStringAsFixed(1),
              style: AppText.caption.copyWith(color: AppColors.inkSecondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '·',
              style: AppText.caption.copyWith(color: AppColors.inkTertiary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              game.category,
              style: AppText.caption.copyWith(color: AppColors.inkSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pill-shaped earning badge. Primary-pale background, primary text,
/// shows a dollar amount.
class _EarningBadge extends StatelessWidget {
  final double amount;

  const _EarningBadge({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Text(
        '\$${amount.toStringAsFixed(2)}',
        style: AppText.bodyStrong.copyWith(color: AppColors.primary),
      ),
    );
  }
}

/// Top progress bar. Cream-deep track, primary fill, label row above.
/// Progress is always 0 in v1 because no steps complete in-session.
class _TopProgressBar extends StatelessWidget {
  const _TopProgressBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\$0.00 earned of \$1.00',
          style: AppText.caption.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.creamDeep,
            borderRadius: BorderRadius.circular(4),
          ),
          // Foreground fill rendered as a 0-width container for v1.
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
```

The new file imports `AppLayout` and `AppSpacing`. Both come from `app_theme.dart`, which is already imported, so no new imports are needed.

- [ ] **Step 4: Run the tests to confirm everything passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: all tests pass (the original 3 plus the 3 new ones).

- [ ] **Step 5: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
cd /Users/markus/Dev/earnapp
git add flutter_app/lib/screens/game_detail_screen.dart flutter_app/test/screens/game_detail_screen_test.dart
git commit -m "feat(screens): add title row, earning badge, and top progress bar"
```

---

## Task 5: Section heading helper plus HOW IT WORKS, ABOUT, DISCLAIMER

**Files:**
- Modify: `lib/screens/game_detail_screen.dart`
- Modify: `test/screens/game_detail_screen_test.dart`

**Why now:** Three text sections share the same heading style. Build the helper once, then use it in three places.

- [ ] **Step 1: Add failing tests for the three sections**

Add these tests inside the existing `group('GameDetailScreen', ...)`:

```dart
testWidgets('renders the HOW IT WORKS section', (tester) async {
  await pumpDetail(tester, game: gamesByName['Candy Crush']!);
  expect(find.text('HOW IT WORKS'), findsOneWidget);
  expect(
    find.text(gamesByName['Candy Crush']!.howItWorks),
    findsOneWidget,
  );
});

testWidgets('renders the ABOUT section with the game name in the heading',
    (tester) async {
  await pumpDetail(tester, game: gamesByName['Candy Crush']!);
  expect(find.text('ABOUT CANDY CRUSH'), findsOneWidget);
  expect(find.text(gamesByName['Candy Crush']!.about), findsOneWidget);
});

testWidgets('renders the DISCLAIMER section', (tester) async {
  await pumpDetail(tester, game: gamesByName['Candy Crush']!);
  expect(find.text('DISCLAIMER'), findsOneWidget);
  expect(
    find.text(gamesByName['Candy Crush']!.disclaimer),
    findsOneWidget,
  );
});
```

- [ ] **Step 2: Run the tests to confirm they fail**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: the 3 new tests fail because nothing renders the headings yet.

- [ ] **Step 3: Add the section helper widgets**

In `lib/screens/game_detail_screen.dart`, append these four widgets at the bottom (after `_TopProgressBar`):

```dart
/// The eyebrow heading style used by every section. Optional trailing
/// widget slot for a counter or icon.
class _SectionHeading extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionHeading({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.caption.copyWith(
                color: AppColors.inkTertiary,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// HOW IT WORKS section: heading plus a short paragraph.
class _HowItWorksSection extends StatelessWidget {
  final Game game;

  const _HowItWorksSection({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(label: 'HOW IT WORKS'),
        Text(
          game.howItWorks,
          style: AppText.body.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

/// ABOUT [GAME NAME] section: heading plus a short blurb.
class _AboutSection extends StatelessWidget {
  final Game game;

  const _AboutSection({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(label: 'ABOUT ${game.name.toUpperCase()}'),
        Text(
          game.about,
          style: AppText.body.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

/// DISCLAIMER section: heading plus fine print.
class _DisclaimerSection extends StatelessWidget {
  final Game game;

  const _DisclaimerSection({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(label: 'DISCLAIMER'),
        Text(
          game.disclaimer,
          style: AppText.caption.copyWith(
            color: AppColors.inkTertiary,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
```

Now wire the three sections into the scrolling `Column` inside `build`. Replace the existing `Column` children with:

```dart
children: [
  _TitleRow(game: game),
  const SizedBox(height: AppSpacing.lg),
  const _TopProgressBar(),
  const SizedBox(height: AppSpacing.xl),
  _HowItWorksSection(game: game),
  const SizedBox(height: AppSpacing.xl),
  _AboutSection(game: game),
  const SizedBox(height: AppSpacing.xl),
  _DisclaimerSection(game: game),
],
```

- [ ] **Step 4: Run the tests to confirm they pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
cd /Users/markus/Dev/earnapp
git add flutter_app/lib/screens/game_detail_screen.dart flutter_app/test/screens/game_detail_screen_test.dart
git commit -m "feat(screens): add HOW IT WORKS, ABOUT, and DISCLAIMER sections"
```

---

## Task 6: Regular steps section with `_StepCard`

**Files:**
- Modify: `lib/screens/game_detail_screen.dart`
- Modify: `test/screens/game_detail_screen_test.dart`

**Why now:** This is the most visually distinctive part of the page. After this task the body is feature-complete; only the sticky CTA and home wiring remain.

- [ ] **Step 1: Add failing tests for the steps section**

Add these tests inside the existing `group('GameDetailScreen', ...)`:

```dart
testWidgets('renders the REGULAR STEPS heading with a 0/2 counter',
    (tester) async {
  await pumpDetail(tester, game: gamesByName['Candy Crush']!);
  expect(find.text('REGULAR STEPS'), findsOneWidget);
  expect(find.text('0 / 2'), findsOneWidget);
});

testWidgets('renders both step labels and rewards', (tester) async {
  await pumpDetail(tester, game: gamesByName['Candy Crush']!);
  expect(find.text('Install the app'), findsOneWidget);
  expect(find.text('Reach Level 15'), findsOneWidget);
  expect(find.text('\$0.10'), findsOneWidget);
  expect(find.text('\$0.90'), findsOneWidget);
});

testWidgets('first step shows UP NEXT, second step shows NOT STARTED',
    (tester) async {
  await pumpDetail(tester, game: gamesByName['Candy Crush']!);
  expect(find.text('UP NEXT'), findsOneWidget);
  expect(find.text('NOT STARTED'), findsOneWidget);
});
```

- [ ] **Step 2: Run the tests to confirm they fail**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: the 3 new tests fail.

- [ ] **Step 3: Add `_StepCard` and the section wrapper**

In `lib/screens/game_detail_screen.dart`, append these widgets at the bottom (after `_DisclaimerSection`):

```dart
/// Visual state of a regular step. v1 only ever uses [notStarted] and
/// [upNext]; [completed] is included so the same widget can render the
/// future "in progress" state without a follow-up refactor.
enum _StepState { notStarted, upNext, completed }

/// REGULAR STEPS section: heading with a counter trailing widget plus
/// a horizontal scroll list of [_StepCard]s.
class _RegularStepsSection extends StatelessWidget {
  final Game game;

  const _RegularStepsSection({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          label: 'REGULAR STEPS',
          trailing: Text(
            '0 / ${game.regularSteps.length}',
            style: AppText.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: game.regularSteps.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final step = game.regularSteps[index];
              final state =
                  index == 0 ? _StepState.upNext : _StepState.notStarted;
              return _StepCard(step: step, state: state);
            },
          ),
        ),
      ],
    );
  }
}

/// One step card. Replicates the AppCard visual recipe inline because
/// AppCard does not support a fixed width. White background, 18 radius,
/// cream-deep border, soft shadow. State pill at the top, label in the
/// middle, reward at the bottom.
class _StepCard extends StatelessWidget {
  final GameStep step;
  final _StepState state;

  const _StepCard({required this.step, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.md),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatePill(state: state),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              step.label,
              style: AppText.listItem,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${step.reward.toStringAsFixed(2)}',
            style: AppText.bodyStrong.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// The state pill shown at the top of each step card. Three states map
/// to three color treatments. The pill text is taken from the enum.
class _StatePill extends StatelessWidget {
  final _StepState state;

  const _StatePill({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (state) {
      _StepState.notStarted => (
          'NOT STARTED',
          AppColors.creamDeep,
          AppColors.inkTertiary
        ),
      _StepState.upNext => (
          'UP NEXT',
          AppColors.primaryPale,
          AppColors.primary
        ),
      _StepState.completed => (
          'COMPLETED',
          AppColors.primaryLight,
          AppColors.primaryDark
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: fg,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
```

Now wire `_RegularStepsSection` into the scrolling `Column` between `_TopProgressBar` and `_HowItWorksSection`:

```dart
children: [
  _TitleRow(game: game),
  const SizedBox(height: AppSpacing.lg),
  const _TopProgressBar(),
  const SizedBox(height: AppSpacing.xl),
  _HowItWorksSection(game: game),
  const SizedBox(height: AppSpacing.xl),
  _RegularStepsSection(game: game),
  const SizedBox(height: AppSpacing.xl),
  _AboutSection(game: game),
  const SizedBox(height: AppSpacing.xl),
  _DisclaimerSection(game: game),
],
```

`_RegularStepsSection` uses a horizontal `ListView`, which needs unconstrained horizontal space. The wrapping `SingleChildScrollView` already gives that, but the inner `ListView` must overflow the gutter padding to feel correct. For v1, the gutter padding on the parent is fine. If you want the cards to bleed past the gutter on the right, follow up in a later iteration.

- [ ] **Step 4: Run the tests to confirm everything passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
cd /Users/markus/Dev/earnapp
git add flutter_app/lib/screens/game_detail_screen.dart flutter_app/test/screens/game_detail_screen_test.dart
git commit -m "feat(screens): add REGULAR STEPS section with step cards and state pills"
```

---

## Task 7: Sticky Install CTA wired to onInstall

**Files:**
- Modify: `lib/screens/game_detail_screen.dart`
- Modify: `test/screens/game_detail_screen_test.dart`

**Why now:** With the body content done, wire the action that commits the user to the game. Use `Scaffold.bottomNavigationBar` so the rest of the page scrolls underneath.

- [ ] **Step 1: Add a failing test for the Install button**

Add this test inside the existing `group('GameDetailScreen', ...)`:

```dart
testWidgets('Install Game button calls onInstall and pops the screen',
    (tester) async {
  int installCount = 0;
  await pumpDetail(
    tester,
    game: gamesByName['Candy Crush']!,
    onInstall: () => installCount++,
  );
  expect(find.text('Candy Crush'), findsWidgets);

  await tester.tap(find.byKey(const Key('game_detail_install')));
  await tester.pumpAndSettle();

  expect(installCount, 1);
  expect(find.text('Candy Crush'), findsNothing);
  expect(find.text('open'), findsOneWidget);
});
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: the new test fails because no widget has the `game_detail_install` key.

- [ ] **Step 3: Add the sticky Install button to the Scaffold**

In `lib/screens/game_detail_screen.dart`, add these imports at the top:

```dart
import '../widgets/physical_press.dart';
```

Then wrap the existing `Scaffold` body in a Scaffold that also sets `bottomNavigationBar`. The simplest path is to add a `bottomNavigationBar` argument to the existing `Scaffold`. Replace `return Scaffold(...)` with:

```dart
return Scaffold(
  backgroundColor: AppColors.cream,
  body: Stack(
    /* unchanged children */
  ),
  bottomNavigationBar: SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.gutter,
        AppSpacing.md,
        AppLayout.gutter,
        AppSpacing.md,
      ),
      child: PhysicalPress(
        onTap: () {
          onInstall();
          Navigator.of(context).pop();
        },
        backgroundColor: AppColors.primary,
        shadowColor: AppColors.primaryDark,
        depth: 6,
        height: 68,
        haptic: HapticIntensity.confirm,
        child: Container(
          key: const Key('game_detail_install'),
          alignment: Alignment.center,
          child: Text('Install Game', style: AppText.ctaLabel),
        ),
      ),
    ),
  ),
);
```

`HapticIntensity` is exported from `physical_press.dart` (it re-exports from `press_scale.dart`). The import you added covers it.

- [ ] **Step 4: Run the tests to confirm everything passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test test/screens/game_detail_screen_test.dart
```

Expected: all tests pass.

- [ ] **Step 5: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Run the formatter**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
dart format lib/screens/game_detail_screen.dart test/screens/game_detail_screen_test.dart
```

Expected: file is reformatted with no semantic changes.

- [ ] **Step 7: Commit**

```bash
cd /Users/markus/Dev/earnapp
git add flutter_app/lib/screens/game_detail_screen.dart flutter_app/test/screens/game_detail_screen_test.dart
git commit -m "feat(screens): wire sticky Install Game CTA via PhysicalPress"
```

---

## Task 8: Wire the home screen picker to the new detail screen

**Files:**
- Modify: `lib/screens/home_screen.dart`

**Why last:** Once the detail screen is feature-complete and tested, swap the picker callback to push it. Changing the picker description copy at the same time keeps the user-facing change atomic.

- [ ] **Step 1: Read the current state of `_showGamePicker`**

Open `flutter_app/lib/screens/home_screen.dart` and locate the `_showGamePicker` method. The current state has:

- A description Text at roughly line 224 that reads `'You\'ll earn $1.00 once you reach 1 hour of play time. Pick the one you'll enjoy most — you can't switch later.'` (note the em-dash, which violates the project rule).
- A `.then((picked) { ... _selectedGame = picked; _completeTask('game'); })` callback at the end.

Both need to change.

- [ ] **Step 2: Add the new imports**

At the top of `lib/screens/home_screen.dart`, add these two imports next to the existing `screens/` and `widgets/` imports:

```dart
import '../data/games.dart';
import 'game_detail_screen.dart';
```

The list of imports is already alphabetized. Insert each new line in the correct alphabetical slot.

- [ ] **Step 3: Replace the picker description copy**

Replace the existing description Text inside `_showGamePicker` with the approved copy. Find:

```dart
'You\'ll earn \$1.00 once you reach 1 hour of play time. Pick the one you\'ll enjoy most — you can\'t switch later.',
```

Replace it with:

```dart
'Tap a game to see the details. You can come back and pick a different one anytime.',
```

This removes the em-dash and matches the new re-pickable flow.

- [ ] **Step 4: Replace the `.then` callback to push the detail screen**

Find the existing `.then` block at the end of `_showGamePicker`:

```dart
.then((picked) {
  if (picked == null || !mounted) return;
  _selectedGame = picked;
  _completeTask('game');
});
```

Replace it with:

```dart
.then((picked) {
  if (picked == null || !mounted) return;
  final game = gamesByName[picked];
  if (game == null) return;
  _selectedGame = picked;
  Navigator.of(context).push(
    fadeRoute(GameDetailScreen(
      game: game,
      onInstall: () => _completeTask('game'),
    )),
  );
});
```

The assignment to `_selectedGame` happens before the push so the existing copy in `_completeTask` (which reads `_selectedGame ?? 'Game played'` for the journey log entry at home_screen.dart line 109) still has the right value when Install fires later.

`fadeRoute` is already imported in `home_screen.dart` from `../widgets/fade_route.dart`.

- [ ] **Step 5: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
dart analyze
```

Expected: `No issues found!`.

- [ ] **Step 6: Run all tests**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
flutter test
```

Expected: all tests pass. The widget tests for the detail screen still pass; the data tests still pass; the existing `press_scale_test.dart` still passes; there are no new tests for `home_screen.dart` because the change is a wiring update with no isolated logic to test independently.

- [ ] **Step 7: Run the formatter**

```bash
cd /Users/markus/Dev/earnapp/flutter_app
dart format lib/screens/home_screen.dart
```

Expected: file is reformatted with no semantic changes.

- [ ] **Step 8: Manually smoke-test the flow**

If a Flutter target is available (`flutter run -d chrome` or any device), open the app and walk through:

1. Start onboarding, finish it, land on home.
2. Tap a daily task that opens the game picker.
3. Tap one of the three game cards.
4. Verify the picker sheet pops, then the new detail screen slides in from the right.
5. Verify the hero band shows the gradient and either the icon (if you have dropped the PNG files) or the colored letter fallback.
6. Verify the title row, progress bar, HOW IT WORKS, REGULAR STEPS, ABOUT, and DISCLAIMER sections all render.
7. Tap the X button. Confirm you go back to home with no reward animation.
8. Re-open the picker, tap a game, this time tap Install Game. Confirm the haptic fires, the screen pops, and the existing reward animation runs on home.

If anything looks visually off, file a follow-up rather than expanding this task.

- [ ] **Step 9: Commit**

```bash
cd /Users/markus/Dev/earnapp
git add flutter_app/lib/screens/home_screen.dart
git commit -m "feat(home): push GameDetailScreen from picker and refresh sheet copy"
```

---

## Self-Review

### Spec coverage check

| Spec section | Covered by |
|---|---|
| Reward contract (v1) | Task 1 (data totals $1.00), Task 8 (wires Install to existing `_completeTask`) |
| User flow steps 1 to 6 | Task 2 (X close), Task 7 (Install commit), Task 8 (push from picker) |
| Layout: hero band | Tasks 2 and 3 |
| Layout: title row + earning badge + progress bar | Task 4 |
| Layout: HOW IT WORKS | Task 5 |
| Layout: REGULAR STEPS (0 / 2) | Task 6 |
| Layout: ABOUT [GAME NAME] | Task 5 |
| Layout: DISCLAIMER | Task 5 |
| Layout: sticky Install CTA | Task 7 |
| Data model (`Game`, `GameStep`, `gamesByName`) | Task 1 |
| Components: `_HeroBand`, `_GameIcon`, `_TitleRow`, `_EarningBadge`, `_TopProgressBar`, `_SectionHeading`, `_StepCard`, `_AboutSection`, `_DisclaimerSection` | Tasks 2 to 7 |
| State and navigation: `StatelessWidget` constructor, X pop, Install pop | Tasks 2 and 7 |
| Visual / motion / haptic: `AppText`, `AppColors`, `AppSpacing`, `PhysicalPress` confirm haptic, `PressScale` chrome X | Tasks 2 to 7 |
| Prerequisites: missing-asset fallback via `_GameIcon` | Task 3 |
| Files modified: home_screen picker copy + push | Task 8 |

No spec section without a task.

### Placeholder scan

No `TBD`, `TODO`, `placeholder`, or "implement later" markers anywhere in this plan. Every step shows the literal code or command to run.

### Type consistency

- `Game` and `GameStep` are defined in Task 1 with the exact field names used in every later task: `key`, `name`, `category`, `rating`, `iconPath`, `heroGradient`, `regularSteps`, `howItWorks`, `about`, `disclaimer`, and `label`, `reward`.
- `GameDetailScreen` constructor signature is consistent across Tasks 2, 7, and 8: `Game game`, `VoidCallback onInstall`.
- `_StepState` enum values (`notStarted`, `upNext`, `completed`) match the labels rendered by `_StatePill`.
- Test keys (`game_detail_close`, `game_detail_install`) match between widget definition and test lookup.

### Em-dash scan

The plan was authored with the project rule in mind. Every prose section uses periods, commas, colons, or parentheses instead of em-dashes. The picker copy replacement in Task 8 explicitly removes the existing em-dash from `home_screen.dart`.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-09-game-detail-screen.md`. Two execution options:

**1. Subagent-Driven (recommended)**: I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution**: Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
