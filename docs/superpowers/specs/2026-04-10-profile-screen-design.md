# Profile Screen Design

**Date:** 2026-04-10
**Status:** Approved for implementation
**Owner:** EarnWise MVP

## Overview

A new Profile surface that sits alongside Home as a tab inside a shared
`HomeShell`. The profile shows the user's avatar, a fictional email and
auth-provider badge, a personal-info card with three rows (full name, age
range, gender), a locked connected-account card, and a red-outlined Sign
Out button that resets app state and sends the user back to welcome.

This task also refactors the existing `HomeScreen` to live inside a new
`HomeShell` as one of three `IndexedStack` children, so the app has a
real tab-based architecture instead of the current "nav exists but does
nothing" setup. `HomeScreen` keeps its class name and file name; only
the nav state and the floating-pill overlay move up to the shell.

## Goals

- Give the prototype a real Profile surface so the bottom-nav Profile tab
  actually navigates somewhere.
- Match the visual structure of the reference screenshot the user provided:
  centered avatar, email plus provider badge, two sections of cards, red
  Sign Out button.
- Replace the stubbed bottom-nav in `HomeScreen` with a real tab shell
  (`HomeShell`) so the Profile tab switches content in place.
- Reuse existing EarnWise primitives (`AppText`, `AppColors`, `AppSpacing`,
  `AppLayout`, `AppCard` recipe, `PhysicalPress`, `PressScale`, Phosphor
  icons) instead of inventing new styles.

## Non-goals

- No real auth. The auth provider is a fictional label. There is no OAuth
  flow, no token, no real email verification.
- No functional edit flows. The pencil icons next to Full Name, Age Range,
  and Gender are decorative in v1 (they render the affordance so the page
  matches the reference visually but tapping them does nothing).
- No real provider logos beyond Google. The Apple, email, and other
  provider variants are out of scope for v1; the data model supports a
  different provider name but the visual only ships with a Google asset.
- No confirmation dialog on Sign Out. Tapping the button immediately resets
  state and sends the user back to welcome. A "really sign out?" dialog is
  a real-product concern.
- No profile-specific tests for the decorative edit icons. v1 tests cover
  that the icons render; they do not assert tap behavior because there is
  no tap behavior.

## Architecture

### Naming contract

To avoid churn:

- The shell class is `HomeShell`, in `lib/screens/home_shell.dart`.
- The existing `HomeScreen` class in `lib/screens/home_screen.dart` keeps
  its class name and file name. It is NOT renamed to `HomeTab`. The word
  "tab" in this spec refers to its architectural role as a child of the
  shell's `IndexedStack`, not to the class name.
- The new profile class is `ProfileScreen`, in `lib/screens/profile_screen.dart`.
- The Wallet stub is a private widget `_WalletTabStub` inside
  `home_shell.dart`. It has no public name because it is single-use.

Test files and imports use these concrete names consistently.

### `HomeShell` (new)

A `StatefulWidget` in `lib/screens/home_shell.dart`. Owns the `_navIndex`
state that currently lives inside `HomeScreen`. The shell does NOT use
`Scaffold.bottomNavigationBar` because the current home bottom nav is a
floating glass pill overlay with a cream-to-transparent gradient fade
above it, not a fixed Material nav bar. Preserving that visual requires
a Stack-based body with a positioned nav overlay.

Structure:

```dart
Scaffold(
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
      // above it, exactly as the home screen renders today.
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
)
```

`IndexedStack` keeps all tab children alive so their state, animations, and
scroll positions survive tab switches.

The shell also owns the previously-private `_buildBottomNav()` and
`_navItem(...)` helpers, which move here verbatim from `home_screen.dart`:

- `_buildBottomNav()` returns the glass pill: `ClipRRect` with 40 radius
  wrapping a `BackdropFilter(ImageFilter.blur(sigmaX: 24, sigmaY: 24))`
  wrapping a `Container` with a 55% white fill, a 70% white border, and
  an inner `Row` of `_navItem` widgets.
- `_navItem(index, icon, label)` returns a `PressScale` wrapping an
  `AnimatedContainer` that highlights the active tab (primary fill,
  label visible via `AnimatedSize`) and dims the others.
- The nav items are, in order: `PhosphorIcons.house` "Home",
  `PhosphorIcons.wallet` "Wallet", `PhosphorIcons.user` "Profile".
- Tapping a nav item calls `setState(() => _navIndex = index)`. Since
  the nav now lives in the shell, the `setState` updates the shell's
  own state and the `IndexedStack` switches children.

### What the shell owns vs what each tab owns

Because the nav is a floating overlay that sits on top of whatever tab is
visible, each tab's scrollable content must include its own bottom
padding so the last element does not sit hidden under the nav pill. The
existing `HomeScreen` already accounts for this via its scroll view
padding. `ProfileScreen` must add the same style of bottom padding
(roughly 120 px plus the bottom safe-area inset) to the last element of
its scroll view.

The shell does NOT apply a `SafeArea` around the tab content; each tab
is responsible for its own safe-area handling, matching how the current
`HomeScreen` handles it today.

### Tab list

The shell has the same three tabs the current home nav shows, in the same
order (Home, Wallet, Profile), because the current bottom nav already
renders these three labels and icons.

- Tab 0: `HomeScreen` (the existing home content, modified in place to
  drop its own nav state and floating-pill overlay)
- Tab 1: `_WalletTabStub`, a tiny private widget that renders a cream
  background and a single centered "Wallet coming soon" message using
  `AppText.sectionTitle` and an ink-tertiary body line. No controls, no
  state. This keeps the Wallet tab tappable without inventing a full Wallet
  feature. A real Wallet screen is out of scope.
- Tab 2: `ProfileScreen` (new, the main work of this task)

### `HomeScreen` (existing, modified in place)

`HomeScreen` stays where it is, with its current class name, as one of
the three children of `HomeShell`'s `IndexedStack`. The changes are
targeted deletions, not a rewrite.

Deletions:

- Remove the `_navIndex` field from `_HomeScreenState`.
- Remove the `_buildBottomNav()` method. It moves to `HomeShell` verbatim.
- Remove the `_navItem(...)` method. It moves to `HomeShell` verbatim.
- Remove the entire `Positioned(left: 0, right: 0, bottom: 0, ...)` block
  from the Stack in `_HomeScreenState.build()` that currently renders
  `IgnorePointer` wrapping the gradient-fade Container wrapping
  `Center(child: _buildBottomNav())`. This whole floating-pill overlay
  moves to `HomeShell`. After this deletion, the `Stack` in `HomeScreen`
  contains only the home content and the gift overlay.
- Remove the top-level `ScreenScaffold` wrapper around the Stack because
  the shell already provides the outer `Scaffold`. Nested `Scaffold`s
  are legal in Flutter, but the cleaner move here is to drop the
  `ScreenScaffold` and let the Stack (wrapped in whatever background
  the tab needs) sit directly as the shell child. Keep the
  `AnimatedGradientBg` behavior: the cleanest way is to wrap the Stack in
  `AnimatedGradientBg` directly, since that is the only visual service
  `ScreenScaffold` was providing on this screen.

Keeps:

- All gift-overlay state (`_showGift`, `_giftFading`, `_giftAmountController`,
  `_giftLabelController`, `_giftGlow`, `_ringGlow`, `_lastGoalProgress`).
- `_selectedGame` and the game picker flow (`_showGamePicker`,
  `_gameOption`) as modified by the game detail screen task.
- `_completeTask(String task)` and every private `_build...` helper.
- The scroll view content and its existing bottom padding, which already
  reserves space for the floating nav pill.

### `ProfileScreen` (new)

A `StatelessWidget` in `lib/screens/profile_screen.dart`. Consumes
`AppState` via `Consumer<AppState>` so it rebuilds when the name changes
or when Sign Out triggers a reset. Renders a `SafeArea` wrapping a
vertical scroll view with the profile content. The scroll view's
`padding` must reserve ~120 px plus the bottom safe-area inset at the
bottom so the Sign Out button does not sit under the floating nav pill
the shell overlays above every tab.

The file exports `ProfileScreen` as the public class name. Internally it
composes the private widgets described below.

### Entry point updates

- `lib/screens/onboarding_screen.dart`: the "That's me" button currently
  pushes `HomeScreen`. Change it to push `HomeShell`.
- `lib/screens/splash_screen.dart`: if it references `HomeScreen`, update to
  `HomeShell`.
- `lib/main.dart`: if it references `HomeScreen` as a home route, update to
  `HomeShell`.
- `lib/screens/welcome_screen.dart` and `lib/screens/trust_carousel_screen.dart`:
  these do not navigate directly to the home screen, so they are not
  touched.

## Data model (`AppState` additions)

Add four new hardcoded demo fields. All four are plain `String` because
the edit flows are decorative, so the type never gets constrained by UI
input validation.

```dart
String email = 'lisa@earnwise.demo';
String authProvider = 'Google'; // 'Google' | 'Apple'
String ageRange = '26-35';
String gender = 'Female';
```

The `email` is a fixed demo value. It intentionally does not derive from
`userName` because `userName` can change (via onboarding or a future edit
flow) and a self-rewriting email would confuse the demo.

Add a new method `AppState.reset()` that restores every in-session field
to the same initial value the field declaration uses today. This is a
complete, implementable spec, not a "audit the file yourself" pointer.

The current `AppState` has the following initialized fields (as of the
start of this task). The `reset()` method must set each one back to the
exact value shown on the right-hand side, which matches the current
field initializers in `lib/state/app_state.dart`.

| Field | Reset value |
|---|---|
| `userName` | `'Lisa'` |
| `stars` | `125` (the welcome-gift starting balance) |
| `earnedToday` | `0` |
| `goalIndex` | `0` |
| `tasksCompleted` | `0` |
| `screen5Played` | `false` |
| `streakCount` | `0` |
| `isLegend` | `false` |
| `completedTasks` | `<String>{}` (new empty set, not `.clear()`) |
| `lastCompletedTask` | `null` |
| `selectedPreferences` | `<String>[]` (new empty list) |
| `journeyLog` | `<JourneyEntry>[]` (new empty list) |
| `convCardMsg` | `''` |
| `convCardIcon` | `Icons.waving_hand` |
| `convCardIconColor` | `AppColors.primary` (matches the current literal `Color(0xFF0D9488)`) |
| `convCardIconBg` | `AppColors.primaryPale` (matches the current literal `Color(0xFFF0FDFA)`) |
| `email` (new) | `'lisa@earnwise.demo'` |
| `authProvider` (new) | `'Google'` |
| `ageRange` (new) | `'26-35'` |
| `gender` (new) | `'Female'` |

Concrete implementation:

```dart
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

Notes:

- `completedTasks`, `selectedPreferences`, and `journeyLog` are reassigned
  to new empty collections rather than mutated in place. This matches the
  pattern the existing code uses for initialization and avoids subtle
  bugs if any outside code is holding a stale reference to the old
  collection.
- `Icons.waving_hand` comes from `package:flutter/material.dart`, which
  is already imported by `app_state.dart`.
- `AppColors.primary` and `AppColors.primaryPale` are the same concrete
  colors the current field declarations use as literals. Using the named
  constants keeps the reset in sync with the design system if those
  values ever change.
- After a reset the next run through welcome and onboarding will see
  `stars = 125`, which triggers the welcome-gift animation again. This
  is correct: the welcome gift is part of the first-run experience, and
  Sign Out should make the app feel first-run again.

If any field is added to `AppState` after this spec is written, the
implementer must extend `reset()` to cover the new field. The spec
documents the current shape; future additions are a normal part of
ongoing maintenance.

## Layout (Profile tab, top to bottom)

1. **Top padding**, `AppSpacing.xl` from the top safe area, so the avatar
   does not crowd the status bar.
2. **Avatar**, centered, 120 px circular container. Background is
   `AppColors.primary`. A soft glow layer sits behind it: a slightly larger
   circle with a primary-alpha radial gradient, ~140 px, opacity 0.3. The
   initials (uppercase first letter of `userName`) render in the center
   with `AppText.display.copyWith(color: Colors.white)`.
3. **Email line**, `AppSpacing.lg` below the avatar, centered,
   `AppText.body.copyWith(color: AppColors.inkSecondary)`.
4. **Provider badge row**, `AppSpacing.xs` below the email, centered. Says
   "via" in caption style, then a 20 px Google logo image, then the
   provider name (`'Google'`) in `AppText.caption.copyWith(color: AppColors.ink)`.
   The Google logo uses `Image.asset('assets/images/google_logo.png')` with
   an `errorBuilder` fallback that renders a "G" letter in a circle when
   the asset is missing, same pattern as `_GameIcon` in the game detail
   screen.
5. **`AppSpacing.xl` gap.**
6. **`PERSONAL INFO` section heading.** Same eyebrow caption styling as the
   game detail screen: uppercase, letter-spacing 1.6, weight 700,
   `AppColors.inkTertiary`.
7. **Personal info card.** One outer `AppCard`-style container with three
   inner rows separated by thin dividers. Each row has:
   - A 44 px circular icon tile on the left with a teal-alpha background
     (`AppColors.primary.withValues(alpha: 0.12)`) and a Phosphor icon
     centered in `AppColors.primary`.
   - A two-line label + value block in the middle: label in
     `AppText.caption.copyWith(color: AppColors.inkSecondary)`, value in
     `AppText.listItem`.
   - A decorative pencil icon on the right (`PhosphorIcons.pencilSimpleLine(...)`,
     size 20, color `AppColors.inkTertiary`). The icon has no tap handler.
   Rows: Full Name (user icon), Age Range (calendar icon), Gender
   (users-three icon or similar).
8. **`AppSpacing.lg` gap.**
9. **`ACCOUNT` section heading.**
10. **Account card.** One outer `AppCard`-style container with one row:
    - A 44 px Google logo on the left (same asset as the provider badge,
      scaled up).
    - Label "Connected Account" in caption, value is the email in
      `AppText.listItem`.
    - A lock icon on the right (`PhosphorIcons.lock(...)`, size 20, color
      `AppColors.inkTertiary`). The lock signals that this row is not
      editable. No tap handler.
11. **`AppSpacing.xl` gap.**
12. **Sign Out button.** Full-width pill button. White background, red-600
    border (1.5 px), red-600 text in `AppText.ctaLabel`. Height 60 px,
    pill-radius via `StadiumBorder`. Wrapped in `PressScale` with
    `HapticIntensity.warning` so the haptic feels different from a normal
    CTA confirm. Tap calls `AppState.reset()` and then
    `Navigator.of(context).pushAndRemoveUntil(fadeRoute(const WelcomeScreen()), (_) => false)`.
13. **Bottom padding** so the last element does not sit flush against the
    bottom nav bar.

The whole content is wrapped in a `SingleChildScrollView` with
`AppLayout.gutter` horizontal padding. The shell's bottom nav bar is
always visible beneath it.

## Components (inside `lib/screens/profile_screen.dart`)

All private widgets except for the public `ProfileScreen`:

- `ProfileScreen` (public `StatelessWidget`): top-level scroll view that
  composes everything.
- `_ProfileHero`: avatar + email + provider badge block.
- `_AvatarCircle`: the 120 px teal circle with initials and the behind-glow
  layer. Takes a `String initials` and renders the glow as a `Container`
  with a radial gradient behind the main circle.
- `_ProviderBadge`: the "via [logo] Google" row. Takes the provider name
  and the logo asset path.
- `_GoogleLogo`: image helper with `errorBuilder` fallback, same pattern
  as `_GameIcon` in the game detail screen. Takes a `double size`
  parameter.
- `_SectionHeading`: local duplicate of the eyebrow caption style from
  game_detail_screen.dart. Follow-up work extracts this to a shared
  `lib/widgets/app_section_heading.dart`; v1 duplicates rather than
  touching game_detail_screen.dart.
- `_InfoCard`: the outer card holding three `_InfoRow` children with thin
  dividers between them. Uses the AppCard visual recipe inline (white
  background, 18 radius, cream-deep border 1.5, soft shadow).
- `_InfoRow`: one row with the circular icon tile, label + value, and
  the decorative pencil icon. Takes `label`, `value`, `icon` (Phosphor
  IconData).
- `_RowDivider`: a 1 px cream-deep horizontal line inset from both sides
  by `AppSpacing.md` so it does not touch the card border.
- `_AccountCard`: the outer card for the connected account row. Visual
  recipe matches `_InfoCard` (white, 18 radius, cream-deep border, soft
  shadow) but holds only one row.
- `_AccountRow`: one row with the Google logo, label + value, and the
  lock icon on the right.
- `_SignOutButton`: the red-outlined pill button. Wraps
  `OutlinedButton` or a custom `PressScale` + `Container` pair; the
  implementer picks whichever keeps the styling cleanest.

## Widget tests

In `test/screens/profile_screen_test.dart`:

1. `'renders the avatar initial from userName'`: pump with a test AppState
   where `userName = 'Lisa'`, assert `find.text('L')` is found once inside
   the avatar area.
2. `'renders the email and provider badge'`: assert
   `find.text('lisa@earnwise.demo')` is found (appears twice: once in the
   hero and once in the account card), and `find.text('Google')` is found.
3. `'renders the three personal info rows'`: assert `find.text('Full Name')`,
   `find.text('Age Range')`, `find.text('Gender')`, and their values
   (`'Lisa'`, `'26-35'`, `'Female'`) all render.
4. `'renders the account section with a lock icon'`: assert
   `find.text('Connected Account')` and `find.byIcon(PhosphorIcons.lock(...))`
   are present.
5. `'tapping Sign Out calls reset and pops to welcome'`: pump inside a real
   `Navigator`, tap the Sign Out button, confirm the welcome screen appears
   and the back stack was cleared (use a key on Sign Out for the tap target).
   Use a mock or spy to verify `AppState.reset()` was called if that is
   feasible without over-engineering.
6. `'edit icons are decorative and do not crash on tap'`: tap each of the
   three pencil icons and confirm no exception is thrown and the screen
   remains in place.

In `test/screens/home_shell_test.dart`:

1. `'starts on the Home tab'`: pump `HomeShell`, assert the home content is
   visible.
2. `'tapping the Profile tab switches to the profile screen'`: pump
   `HomeShell`, tap the Profile nav button, assert the profile content is
   now visible (look for `find.text('PERSONAL INFO')` or similar).

## Visual, motion, haptic

- Background: `AppColors.cream` for the profile tab body. No gradient.
- Type: every text widget uses an `AppText` style. Eyebrow headings use
  the same `AppText.caption.copyWith(letterSpacing: ..., fontWeight: w700)`
  recipe as the game detail screen's `_SectionHeading` (this is the
  duplication called out in Future work).
- Spacing: `AppSpacing` and `AppLayout.gutter` only. No raw pixel values.
- Icons: Phosphor only. Pencil, lock, user, calendar, users-three, etc.
- Tab switching: `IndexedStack` has no transition animation by default.
  v1 accepts this; a later pass can add a crossfade if the hard swap feels
  jarring.
- Sign Out haptic: `HapticIntensity.warning` (the heavy impact), not
  `confirm`. Signing out is a destructive action and the haptic should feel
  slightly different from a normal CTA.

## Prerequisites

Add the Google G logo as an asset:

- `assets/images/google_logo.png` (user-provided, square, 256 px or larger)

The `_GoogleLogo` helper includes an `errorBuilder` fallback that renders a
"G" letter inside a white circle when the asset is missing, so the build
does not crash if the file is not yet dropped. The app still looks visibly
degraded until the real asset arrives.

The `assets/images/` directory is already registered in `pubspec.yaml`,
so no pubspec change is needed.

## Future work

- **Extract `_SectionHeading`** into a shared `lib/widgets/app_section_heading.dart`
  and migrate both `game_detail_screen.dart` and `profile_screen.dart` to
  use it. Not done in v1 to keep this task from touching the game detail
  screen.
- **Real edit flows** for Full Name, Age Range, and Gender. v1's pencil
  icons are decorative. Each field would open a bottom sheet with an
  appropriate input (text field, single-select list).
- **Sign Out confirmation dialog** once there is real auth to protect.
- **Per-provider logos** (Apple, email) if the auth provider ever varies.
  Today only Google ships.
- **Tab crossfade animation** if `IndexedStack`'s instant swap feels jarring
  during live demos.
- **More tabs** once the tab shell exists. Adding a new tab is now a
  matter of creating a widget and adding it to `HomeShell`'s list.

## Files added

- `lib/screens/home_shell.dart`
- `lib/screens/profile_screen.dart`
- `test/screens/profile_screen_test.dart`
- `test/screens/home_shell_test.dart`

## Files modified

- `lib/screens/home_screen.dart`: keep the `HomeScreen` class name but
  delete the nav state and the floating-pill overlay. Specifically:
  remove the `_navIndex` field, the `_buildBottomNav()` method, the
  `_navItem(...)` method, and the entire `Positioned(left: 0, right: 0,
  bottom: 0, ...)` block that wraps `IgnorePointer` + gradient Container
  + Center + nav pill. Also drop the top-level `ScreenScaffold` wrapper
  and replace it with an `AnimatedGradientBg` wrapping the Stack
  directly. Keep all other state, controllers, and private widgets
  intact.
- `lib/state/app_state.dart`: add `email`, `authProvider`, `ageRange`,
  `gender` string fields with the demo defaults, and add a `reset()`
  method that wipes in-session state.
- `lib/screens/onboarding_screen.dart`: update the "That's me" button to
  push `HomeShell` instead of `HomeScreen`.
- `lib/screens/splash_screen.dart`: if it references `HomeScreen`, update
  to `HomeShell`.
- `lib/main.dart`: if it references `HomeScreen` as a route, update to
  `HomeShell`.

## Files needed from the user (not created by implementation)

- `assets/images/google_logo.png`
