# Post-Onboarding Home

**Date:** 2026-04-13
**Sub-project of:** [Post-Onboarding Sprint](./2026-04-13-post-onboarding-sprint-design.md)
**Status:** Design approved, plan pending

## Goal

Replace what `_buildDailyTasks` renders in `home_screen.dart:858-911` with a post-onboarding Home that gives returning users three things: a clear daily earning target, a way to continue any games they have already started, and fast access to browse surveys, offers, and games by category.

## Trigger

Home already branches at `home_screen.dart:185` on `goalIndex == 0` for onboarding versus post-onboarding. This design replaces only the post-onboarding body; the branching and the onboarding path stay as they are.

## Screen shape, top to bottom

### 1. Header strip

Existing layout stays. "Hi {userName}" greeting plus the streak pill. Tapping the streak pill routes to `StreaksScreen` when that screen exists (sub-project 5). Until then, tap is a no-op.

### 2. Daily Goal card

Hero card at the top of the scroll area. Shows today's earnings as a progress bar toward the current daily target.

**Default state:**
- Target: `$2.00`
- Progress: "$X today of $2.00"
- Primary-colored fill bar

**Goal-hit state (fires once when `dailyEarnedDollars` crosses `dailyGoalDollars` for the first time today):**
- Card flips to "Nice, you hit today's $2. Push for $3?" with two actions: "Push to $3" (primary) and "Bank it" (secondary)
- "Push to $3" sets `dailyGoalDollars = 3.00` for today only and fires a celebration
- "Bank it" keeps the card at full progress, no further extension prompts today
- Fires a `CelebrationsService.trigger('daily_goal_hit')` call. The primitive is built in sub-project 6; for v1 we can call a stub.

**Extended state:**
- Same layout as default with target $3.00 and progress "$X today of $3.00"
- No further extension prompts today

**Reset:**
- At local midnight, `dailyEarnedDollars`, `dailyGoalDollars`, and `dailyExtensionOffered` reset. Tomorrow always starts at $2.00 default.

### 3. Continue earning section (conditional)

**Visibility.** Renders only when the user has at least one in-progress game, meaning an installed game with at least one milestone remaining. Hides entirely otherwise. No fallback card, no empty state.

**Layout.** Section header reading "Continue earning" plus up to three vertically-stacked `AppCard`-style rows. Visual treatment matches the existing daily task rows in `_buildDailyTasks` so the reader's eye does not have to learn a new pattern.

**Each row shows:**
- Game icon (left, 48x48)
- Game name as the primary label
- Next milestone text as the secondary label, for example "Level 50"
- Reward for the next milestone on the right, primary color
- Chevron

**Ordering.** Most recently played first.

**Cap.** Three. If the user has more than three in-progress games, show the three most recently played and drop the rest. No "see more" affordance in v1 since the Tasks list screen covers the full browse case.

**Tap target.** Routes to `GameDetailScreen` for that game.

### 4. Earn more section (always visible)

Section header reading "Earn more" plus three vertically-stacked section cards, same `AppCard` visual treatment as the rows above.

**Surveys card.** Icon, title "Surveys", blurb "$0.50 to $2.00 each". Routes to `SurveysScreen`.

**Offers card.** Icon, title "Offers", blurb "Up to $10 each". Routes to `OffersScreen`.

**Tasks card.** Icon, title "Tasks", blurb "Earn by playing". Routes to `TasksScreen`, which is the screen formerly known as Game Catalog.

All three destination screens are built in sub-project 3 ("Earnable list component and three screens"). Home wires the routes; the screens themselves are separate work.

## Empty-Continue state

When the Continue earning section has zero items it disappears entirely. Home renders header, Daily Goal card, then Earn more. No fallback card, no layout flip. This keeps Home with one shape instead of two and trusts the user to tap into a category.

## Data requirements

New or clarified fields in `AppState`:

- `double dailyGoalDollars` starts at 2.00, can be pushed to 3.00 for the day
- `double dailyEarnedDollars` sums today's earnings, resets at midnight
- `bool dailyExtensionOffered` gates the "push for $3" prompt to once per day
- In-progress games list, meaning installed games with at least one milestone remaining, ordered by last played time

Midnight reset logic: when the date rolls over, reset `dailyEarnedDollars`, `dailyGoalDollars`, and `dailyExtensionOffered`.

**Open data question for the plan:** the current code tracks `completedTasks` at the task-type level (`game_install`, `game_milestone`) rather than per-game. The plan needs to either propose a minimal per-game model or fake it for v1 with hardcoded installed-game state so Home can render realistic Continue rows without blocking on a full state refactor.

## Celebrations hooks (noted for Day 3 Celebrations brainstorm)

This screen produces two celebration moments the Celebrations primitive will need to handle:

1. "You hit today's $2 goal." Fires the extension prompt plus a small celebration.
2. "You pushed to $3 and made it." Fires a bigger celebration.

Both are `CelebrationsService.trigger(...)` calls from the Daily Goal card's state transitions. The primitive itself is built in sub-project 6. For this sub-project, a stub is acceptable and the real primitive replaces it on Day 3.

## Out of scope for this sub-project

- Dark Mode. Daily Goal card and section cards use `AppColors` tokens so Dark Mode is an additive change on Day 3.
- The three destination screens (Surveys, Offers, Tasks). Built in sub-project 3.
- Streaks screen. Built in sub-project 5. Streak pill tap is a no-op until it exists.
- Transaction History. Built in sub-project 4. No entry point from Home in v1.
- Surveys and offers as Continue items. Games only in v1. The Continue primitive can extend to other types later when their data supports "in progress".
- A "see more" affordance on Continue. Capped at 3.

## Risks

- **Per-game state model does not exist yet.** Highest risk. If the plan decides to build a real per-game model, that eats most of the Home day. Mitigation: fake it for v1 with a hardcoded list of installed games and treat the model as a follow-up.
- **Goal-hit state is the first celebration moment in the app.** If the Celebrations primitive is not ready on Day 1, the stub has to feel good enough that the extension flow is testable. Minimum acceptable: a haptic plus a simple modal.
- **Three destination routes that do not exist yet.** Home will reference `SurveysScreen`, `OffersScreen`, and `TasksScreen`, all of which get built in sub-project 3. Either stub the routes (push a placeholder) or build sub-project 3 in the same Day 1 slot. Resolve during the plan step.
