# Game Detail Screen Design

**Date:** 2026-04-09
**Status:** Approved for implementation (revised after first review)
**Owner:** EarnWise MVP

## Overview

A new full-page screen that opens after a user picks a game from the existing
game picker bottom sheet. The page shows what the game pays out, what the user
has to do to earn it, and a sticky Install button at the bottom that commits
to the choice and returns the user to home with the existing reward animation.

The page is the first surface in the prototype where the user sees a per-game
step ladder instead of a single flat reward.

## Reward contract (v1)

The existing reward engine credits exactly 750 Stars (which displays as $1.00)
for the `'game'` task. See `app_state.dart` `taskStars['game'] = 750` and
`starsPerDollar = 750`. The detail screen v1 must not promise more than the
engine delivers. The ladder on the page therefore totals exactly $1.00:

- Step 1: Install the app. $0.10. Auto-completes when Install is tapped.
- Step 2: Reach the in-game milestone (Level 15 / Win 25 games / Complete 20
  puzzles). $0.90. Represents the rest of the play time the user is committing
  to.

Tapping Install fires the existing `_completeTask('game')` flow, which credits
the full $1.00 in one shot. From the user's perspective, both steps are
completed at the same moment as part of "I'm in, give me the game".

**Bonus goals are deferred to v2.** The JustPlay reference shows time-bound
bonus rewards (for example "reach the milestone within 3 days for an extra
$0.50"), but the prototype's reward engine cannot pay variable amounts per
game and does not track real time. We will add bonus goals in a follow-up
when those two pieces exist. The detail page layout leaves no bonus section
in v1.

## Goals

- Show the user a clear breakdown of what they earn from a single game and
  the steps required to earn it.
- Match the visual richness of the JustPlay and Raid Shadow Legends references
  while staying inside the EarnWise design system and the existing reward
  economy.
- Reuse existing primitives: `PhysicalPress`, `AppCard`, `AppText`,
  `AppColors`, `AppSpacing`, `AppLayout`, `fadeRoute`, `ScreenScaffold`,
  `Phosphor` icons.
- Add the smallest possible amount of new state to support the new flow.

## Non-goals

- No real time tracking. The prototype does not measure actual play time.
- No real app store deep link. The Install button stays inside the prototype
  and triggers the existing `_completeTask('game')` reward sequence.
- No per-step state changes during a session. Both regular steps render as
  "Not started" until Install is tapped, then the page pops back to home and
  the reward animation runs.
- No editing of game data from inside the app. Game definitions live in code.
- No bonus goals in v1. See "Future work".

## User flow

1. User opens the game picker from the home screen daily tasks list.
2. User taps a game card. The picker sheet pops back to home with the picked
   game name as the result.
3. The home screen captures the picked name into `_selectedGame` (so the
   existing journey-log copy still has the right game name when
   `_completeTask` runs later), looks up the matching `Game` definition, and
   pushes a new `GameDetailScreen(game: ...)` via `fadeRoute` (Cupertino
   slide-from-right).
4. User scrolls the detail page, reads the about section, inspects the
   regular steps.
5. User taps the X button in the top-right of the hero band. The page pops
   back to home, the game task stays incomplete, and the user can re-open the
   game picker if they want.
6. Or, user taps the sticky Install Game button. The page calls
   `onInstall()` (which fires the home screen's `_completeTask('game')`) and
   then pops back to home. The existing conv-card update and reward animation
   runs and credits the full $1.00.

## Layout

Top to bottom inside a scrolling page with a sticky bottom CTA:

1. **Hero band**, ~220 px tall. Full-bleed gradient using the game's branded
   colors. The 120 px game icon sits centered with a soft drop shadow. A
   circular X close button sits in the top-right, overlaid on the gradient,
   using the same chrome circle style as the journey screen close icon.
2. **Title row**, `AppLayout.gutter` horizontal padding, `AppSpacing.lg`
   below the hero. Game name on the left, max-earning badge ($1.00) on the
   right. A second line below shows the rating (Phosphor star icon plus
   "4.7") and the category, separated by a centered dot.
3. **Top progress bar**, full width inside the gutter. CreamDeep track,
   primary fill, with "$0.00 earned of $1.00" label above. Progress is always
   0 in v1 since no steps complete in-session.
4. **HOW IT WORKS** section. Eyebrow heading using the caption styling
   (uppercase, letter-spaced, ink-tertiary), then a 2 to 3 sentence paragraph
   using `AppText.body`.
5. **REGULAR STEPS (0 / 2)** section. Eyebrow heading with the completion
   counter on the right. A horizontal `ListView` of two `_StepCard`s with
   gutter padding on both sides and a 12 px gap between cards. Each card is
   ~180 px wide and ~140 px tall, with a state pill at the top (NOT STARTED
   / UP NEXT / COMPLETED), the step name in `AppText.listItem` below, and
   the reward in `AppText.bodyStrong` at the bottom. The first card shows
   "UP NEXT", the second shows "NOT STARTED".
6. **ABOUT [GAME NAME]** section. Eyebrow heading and a 2 to 3 sentence
   game blurb in `AppText.body`. Original copy, written from scratch per
   game.
7. **DISCLAIMER** section. Eyebrow heading and small fine print in
   `AppText.caption` with ink-tertiary color.
8. **Sticky bottom CTA**: a `PhysicalPress` Install Game button. Lives inside
   `ScreenScaffold`'s `bottomNavigationBar` slot so the rest of the page
   scrolls underneath without resizing on keyboard show.

## Data model

A new `lib/data/games.dart` file with:

```dart
class Game {
  final String key;          // 'candy_crush' | 'solitaire' | 'word_search'
  final String name;
  final String category;     // 'Puzzle', 'Card', 'Word'
  final double rating;       // 4.5 .. 4.7
  final String iconPath;     // assets/images/games/<key>.png
  final List<Color> heroGradient;  // 2 color stops
  final List<GameStep> regularSteps;
  final String howItWorks;
  final String about;
  final String disclaimer;
}

class GameStep {
  final String label;
  final double reward;       // dollars
}

const Map<String, Game> gamesByName = { /* keyed by display name */ };
```

`GameStep` has no `deadlineDays` field in v1 because there are no bonus goals.

The three Game instances are hard-coded in `lib/data/games.dart`:

| Game        | Category | Rating | Step 2 label         | Hero gradient            |
|-------------|----------|--------|----------------------|--------------------------|
| Candy Crush | Puzzle   | 4.7    | Reach Level 15       | warm pink to gold        |
| Solitaire   | Card     | 4.6    | Win 25 games         | teal to cream-deep       |
| Word Search | Word     | 4.5    | Complete 20 puzzles  | violet to soft cream     |

All three games share the same step value layout: $0.10 install plus $0.90
main milestone, $1.00 total. This matches `taskStars['game'] = 750` exactly.

## Components

All inside `lib/screens/game_detail_screen.dart` as private widgets unless
they end up reused elsewhere:

- `_HeroBand`: Stack with the gradient container, centered icon, and X
  button positioned top-right. Uses `MediaQuery.padding.top` for the
  safe-area inset. Wraps the icon in a `_GameIcon` that handles the
  fallback for missing asset files (see Prerequisites).
- `_GameIcon`: small helper that loads `Image.asset(iconPath)` and falls
  back to a colored square with the game's first letter if the asset is
  missing. Used in the hero band so the build never crashes when art is
  not yet provided.
- `_TitleRow`: Row with the title (left-expanded) and the earning badge
  (right). Below the row, a secondary line shows rating and category.
- `_EarningBadge`: Pill-shaped chip, primary-pale background, primary text,
  displays the max-earning amount.
- `_TopProgressBar`: CreamDeep track, primary fill, label row above.
- `_SectionHeading`: The eyebrow heading style used by every section
  (uppercase, letter-spaced, ink-tertiary). Optional trailing widget slot
  for the `(0 / 2)` counter.
- `_StepCard`: Rounded card matching the `AppCard` visual recipe (white,
  18 radius, cream-deep border, soft shadow), fixed width and height. State
  pill at the top, label in the middle, reward at the bottom. The card
  replicates the `AppCard` recipe inline rather than wrapping `AppCard`
  because it needs a fixed width that `AppCard` does not natively support.
- `_AboutSection`, `_DisclaimerSection`: simple wrappers for heading plus
  paragraph.

## State and navigation

`GameDetailScreen` is a `StatelessWidget`. Constructor:

```dart
class GameDetailScreen extends StatelessWidget {
  final Game game;
  final VoidCallback onInstall;

  const GameDetailScreen({
    super.key,
    required this.game,
    required this.onInstall,
  });
}
```

Inside the screen, the X button calls `Navigator.of(context).pop()`. The
Install button calls `onInstall()` followed by `Navigator.of(context).pop()`.
Both calls are made directly on the constructor field; there is no `widget.`
prefix because this is not a `State` class.

The home screen's existing `_showGamePicker` method needs three updates:

1. Replace the description copy in the picker sheet with the already-approved
   line: `"Tap a game to see the details. You can come back and pick a
   different one anytime."` Today the sheet says
   `"You'll earn $1.00 once you reach 1 hour of play time. Pick the one
   you'll enjoy most, you can't switch later."`, which contradicts the new
   re-pickable flow.
2. After `showAppBottomSheet` returns the picked name, capture it into
   `_selectedGame` so the existing copy in `_completeTask('game')` (which
   reads `_selectedGame` for the journey log entry) still has the right
   value when Install fires later.
3. Look up the matching `Game` and push the detail screen instead of
   completing the task immediately.

```dart
showAppBottomSheet<String>(
  context: context,
  builder: (ctx) => /* picker content */,
).then((picked) {
  if (picked == null || !mounted) return;
  final game = gamesByName[picked];
  if (game == null) return;
  setState(() => _selectedGame = picked);
  Navigator.of(context).push(
    fadeRoute(GameDetailScreen(
      game: game,
      onInstall: () => _completeTask('game'),
    )),
  );
});
```

## Visual, motion, haptic

- Background: `AppColors.cream` for the page body. The hero band uses its
  own gradient.
- Type: every text widget uses an `AppText` style. CTA label uses
  `AppText.ctaLabel`. Eyebrow headings use `AppText.caption` with letter
  spacing 0.18 to 0.22 and `AppColors.inkTertiary`.
- Spacing: all padding uses `AppSpacing.xs / sm / md / lg / xl` and
  `AppLayout.gutter`.
- Icons: Phosphor only. Star, X, and any other in-page icons use the
  `phosphor_flutter` weights already in use elsewhere.
- Page transition: `fadeRoute`, which now wraps `CupertinoPageRoute`. The
  X button gets the swipe-back-to-pop gesture for free.
- Sticky CTA: `PhysicalPress` with `HapticIntensity.confirm`,
  `backgroundColor: AppColors.primary`, `shadowColor: AppColors.primaryDark`,
  `depth: 6`, `height: 68`. Label "Install Game" via `AppText.ctaLabel`.
- X button: `PressScale` wrapper around the existing chrome circle, no
  haptic (chrome rule).
- No hero band entrance animation in v1. Add later if it improves the feel.

## Prerequisites

The detail screen depends on three game icon PNG files that do not yet
exist in the repo. The `assets/images/games/` directory is already declared
in `pubspec.yaml`. The user is expected to drop these three files before
the page renders correctly:

- `assets/images/games/candy_crush.png`
- `assets/images/games/solitaire.png`
- `assets/images/games/word_search.png`

Recommended source size: square, 256 px or larger. Use the flat App Store
artwork; the screen clips to a 12 px squircle automatically.

The `_GameIcon` helper renders a colored fallback square with the game's
first letter when an asset fails to load. This means the build does not
crash if a file is missing; it just looks visibly degraded until the real
asset is provided. Keeping the fallback also makes the screen testable
without art.

## Future work

- **Bonus goals.** Add the JustPlay-style time-bound bonus card once the
  reward engine supports per-game variable payouts. Requires extending
  `app_state.dart` so `_completeTask('game')` can credit a per-game amount,
  and adding a `bonusGoal: GameStep?` field to `Game`.
- **Real time tracking.** When we have actual play tracking, the regular
  step cards can flip to "Completed" between sessions, and the page can
  show real progress instead of always 0.
- **Per-game brand color.** Pull the dominant color from the icon image to
  drive the hero gradient, so each game feels visually distinct without
  hard-coding colors.
- **Tier integration.** Surface "this game contributes to your Explorer
  tier" somewhere on the page.
- **External app store deep link.** Replace the in-prototype Install action
  with a real app store URL once the prototype graduates.

## Files added

- `lib/data/games.dart`
- `lib/screens/game_detail_screen.dart`

## Files modified

- `lib/screens/home_screen.dart`
  - Update the picker sheet description copy to the new re-pickable line.
  - In the `_showGamePicker` `.then` callback, set `_selectedGame = picked`
    via `setState` and push `GameDetailScreen` via `fadeRoute` instead of
    calling `_completeTask` directly.

## Files needed from the user (not created by implementation)

- `assets/images/games/candy_crush.png`
- `assets/images/games/solitaire.png`
- `assets/images/games/word_search.png`
