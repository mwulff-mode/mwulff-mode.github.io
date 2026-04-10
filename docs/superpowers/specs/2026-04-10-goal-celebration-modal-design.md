# Goal Celebration Modal

## Summary

When the user completes all four onboarding tasks and crosses the first payout threshold ($2.00 / 1500 stars), show a centered floating card modal over the home screen instead of silently advancing to the next goal. The modal celebrates the onboarding milestone and guides the user toward cashing out or continuing to earn.

## Trigger & Flow

1. User completes their 4th onboarding task, crossing the 1500-star goal threshold
2. Ring fills to 100%, milestone haptic fires (unchanged)
3. After ~1.5s hold (so the user sees the filled ring), the celebration modal appears as a `showGeneralDialog` overlay
4. On dismissal (any path), immediately: (1) `advanceGoal()` to goal 2 ($5.00), (2) add journey log entry
5. Two exit paths after shared dismissal logic:
   - **"Cash out now"** -- switch to Wallet tab (user sees their ready balance and can redeem)
   - **Close X / "Keep earning"** -- stay on home screen, show "Earn More unlocked" toast (user sees the unlocked section when they scroll)

## Celebration Modal Widget

Shown via `showGeneralDialog` for full control over barrier and animation.

### Visual spec

- **Barrier**: semi-transparent black (0.45 alpha), no blur (keeps it lightweight)
- **Card**: white background, 24px border-radius, centered vertically, 24px horizontal margin
- **Close X**: top-right corner of card, circular `creamDeep` background, 28x28px
- **Icon**: 56x56px rounded-square (16px radius), teal gradient (`AppColors.primary` to `AppColors.tealSecondary`), star icon centered, subtle box shadow
- **Amount**: "$2.00" in `heroAmount`-scale text (28-32px, weight 800)
- **Label**: "GOAL REACHED" uppercase, teal, 11px, letter-spacing 1.5
- **Body**: single sentence, human voice, ~13px
- **Primary CTA**: full-width teal button "Cash out now", 14px rounded 12px
- **Secondary**: "Keep earning" text link below, muted color

### Animation

- Entry: barrier fades in (300ms) + card scales from 0.85 to 1.0 with `AppCurves.warmOut` (400ms)
- Exit: card + barrier fade out together (250ms)
- Respects `prefers-reduced-motion`: skip scale, just show/hide

## State & Navigation Changes

### HomeShell
- Pass `onNavigateToWallet` callback down to HomeScreen (same pattern as `onNavigateHome` already passed to WalletScreen)

### HomeScreen
- Constructor accepts `VoidCallback onNavigateToWallet`
- Goal-completed block in `_completeTask` (lines 172-190) replaced: instead of delayed `advanceGoal()` + journey entry, shows the celebration modal after 1.5s
- `allTasksCompleted` block (lines 193-205) removed: unlock feedback consolidated into modal dismiss
- Modal dismiss callback handles shared logic (`advanceGoal()`, journey entry) then branches on path

### AppState goals array
- Goal 2 changes from `goalStars: 5000` ($6.67) to `goalStars: 3750` ($5.00)

### Earn More unlock
- Gate remains `allTasksCompleted` (4 tasks) -- no change needed since completing 4 tasks = reaching goal 1
- **Remove** the existing `allTasksCompleted` block in `_completeTask` (lines 193-205) that schedules a 2s-delayed journey entry. This fires on the same task completion that triggers the modal, causing duplicate/mistimed unlock messaging. All unlock feedback is now consolidated into the modal dismiss flow:
  - Journey entry logged on any dismissal path (step 4 above)
  - Toast shown only on "Keep earning" path (user is on home screen to see it)

## Files Modified

- `flutter_app/lib/screens/home_screen.dart` -- new modal widget, updated goal completion handler
- `flutter_app/lib/screens/home_shell.dart` -- pass `onNavigateToWallet` to HomeScreen
- `flutter_app/lib/state/app_state.dart` -- update Goal 2 star threshold
