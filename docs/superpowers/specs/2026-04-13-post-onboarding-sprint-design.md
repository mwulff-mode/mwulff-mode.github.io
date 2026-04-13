# Post-Onboarding Sprint

**Date:** 2026-04-13
**Deadline:** Thursday 2026-04-16 (3 working days)
**Status:** Decomposition approved, individual sub-project specs pending

## Goal

Ship seven EarnWise features at rough fidelity by Thursday so the full post-onboarding loop is demonstrable end to end. Breadth over depth. Nothing has to feel finished, but every item has to be reachable and render real state.

## Approach

**Screens first, systems last.** All visible screens get built against the current light theme on Days 1 and 2. The cross-cutting systems (Dark Mode, unified Celebrations) land on Day 3.

This is the riskiest of the three approaches we considered, because Day 3 could turn into a retrofit scramble. We are explicitly choosing it anyway because it produces visible progress fastest and makes each screen feel real before the systems get layered on top.

## Survival rule

**No new hardcoded hex codes.** Every color in new code this week goes through `AppColors` tokens in `flutter_app/lib/theme/app_theme.dart`, even though the dark variants have not been defined yet. This rule is what makes Day 3 a token-expansion job instead of a grep-and-replace death march across seven files.

This is already the project convention (see commit `8cd5385 refactor(theme): promote repeated raw Color literals to AppColors tokens`), so it is enforcement of an existing rule rather than a new one.

## Scope

### In scope (7 items)

1. **Post-Onboarding Home hub** — replace `_buildDailyTasks` in `home_screen.dart:858-911` with a hub-shaped layout: daily goal card with within-day extension to $3, a conditional "Continue earning" section (up to 3 in-progress games), and three section cards routing to Surveys, Offers, and Tasks list screens. Medium. See [Post-Onboarding Home design](./2026-04-13-post-onboarding-home-design.md). Grew from "small polish" during brainstorming because the post-onboarding experience is more than a tightening pass.
2. **Post-Onboarding Wallet polish** — verify all three Wallet states (locked, unlocked, redeemed) in `wallet_screen.dart`. Tighten copy and spacing. Small. No new architecture.
3. **Earnable list component plus three list screens (Surveys, Offers, Tasks)** — one reusable list component with three data-driven screen wrappers. The Tasks screen is the destination formerly known as Game Catalog; the old `_showGamePicker` bottom sheet gets retired. Surveys and Offers are net-new screens using the same list primitive. Medium. Merges the original Game Catalog sub-project.
4. **Transaction History screen** — net-new. Reached from Wallet or Profile. Shows earning events chronologically. Data source to be decided during its brainstorm (likely derived from `journeyLog` or a new ledger). Medium.
5. **Streaks View screen** — net-new, Duolingo-inspired. Reached from the streak pill on Home. Streak definition is "complete any one task that day," not "hit the daily goal." Shows current streak, past streaks, and what keeps a streak alive. Medium.
6. **Celebrations primitive** — unify `_PayoutCelebrationModal`, the goal-complete modal, and the `HapticsService` into one reusable primitive that Home, Wallet, and Streaks can call. Refactor, no new visuals. Big celebration moments to brainstorm: cash out, daily goal hit, daily goal extended and hit, first payout, tier-ups.
7. **Dark Mode** — add dark variants to existing tokens in `app_theme.dart`, wire `ThemeMode` into `main.dart`, add a toggle in Profile. Medium.

### Cut from original list

- **Refinements.** No concrete list, no scope. Cut entirely rather than treated as a drain bucket.
- **Game Details Screen.** Already built in both Flutter (`game_detail_screen.dart`) and the Figma extraction. Not on the list.

## Day-by-day sequence

Updated after the Home brainstorm expanded sub-project 1 and merged Game Catalog into sub-project 3.

### Day 1 (Mon 2026-04-13) — Home and Wallet

- Post-Onboarding Home hub
- Post-Onboarding Wallet polish

### Day 2 (Tue 2026-04-14) — the browse system

- Earnable list component plus three list screens (Surveys, Offers, Tasks)

### Day 3 (Wed 2026-04-15) — remaining screens and start of Celebrations

- Transaction History screen
- Streaks View screen
- Start Celebrations primitive (afternoon)

### Day 4 (Thu 2026-04-16 AM) — ship

- Finish Celebrations primitive and wire it into Home, Wallet, Streaks
- Dark Mode tokens, toggle in Profile, retrofit sweep for any hardcoded colors
- Final bug pass, ship

## How we run this

Each of the seven items gets its own spec, plan, and implementation cycle:

1. Short brainstorm (most will be quick because the questions are "which pattern" not "what are we building")
2. Design doc in `docs/superpowers/specs/2026-04-13-<name>-design.md`
3. Plan in `docs/superpowers/plans/2026-04-13-<name>.md` via `writing-plans`
4. Implementation

Starting with sub-project #1: Post-Onboarding Home hub. Design doc: [2026-04-13-post-onboarding-home-design.md](./2026-04-13-post-onboarding-home-design.md).

## Risks and mitigations

- **Day 3 retrofit panic.** Mitigated by the survival rule above. Every screen built in Days 1 and 2 is already using tokens, so Dark Mode becomes "add values to existing tokens" rather than "find every hex code."
- **Data source for Transaction History and Streaks View.** Both new screens depend on state that may not exist yet. This gets resolved during each screen's brainstorm, not here. If a new data source is required, it is in scope for that sub-project.
- **Home is now a medium item, not a polish item.** The post-onboarding Home brainstorm revealed a daily goal mechanic, a continue-where-you-left-off section, and three new browse destinations. Day 1 is now fully committed to Home plus Wallet polish. If Home takes longer than a day, the browse system on Day 2 compresses or a screen in Day 3 gets cut (Transaction History is the likeliest candidate since it has no upstream dependencies).
- **Scope creep on Wallet polish.** Wallet is still explicitly "verify and tighten" not "redesign." If the Wallet brainstorm turns up a redesign-scale question, we timebox or cut.
- **Per-game state model.** Post-Onboarding Home's "Continue earning" section needs per-game progress, which the current code tracks at the task-type level. The Home plan will either propose a minimal per-game model or fake it with hardcoded installed-game state for v1.
- **Celebrations primitive refactor.** Touching three existing pieces (payout modal, goal modal, haptics) risks breaking the Wallet payout flow. The primitive is built and tested in isolation before any existing caller is migrated.
