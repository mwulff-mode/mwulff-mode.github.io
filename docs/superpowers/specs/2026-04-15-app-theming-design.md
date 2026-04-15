# App Theming + Settings Screen

**Date:** 2026-04-15
**Status:** Design approved, ready for implementation planning
**Ships value:** Yes, introduces the theme system the design-system foundation flagged as "next" and adds the first user-facing settings surface.

## Context

EarnWise's Flutter prototype today renders in a single visual identity ("Cream"): warm cream surface, teal brand, soft drop shadows, rounded-rect buttons. The design system foundation (`docs/superpowers/specs/2026-04-14-design-system-foundation-design.md`) explicitly anticipated theming as a follow-up: `AppColors` was scoped to migrate to `ThemeExtension<AppColorPalette>` while `AppSpacing`, `AppRadius`, `AppElevation`, and `AppText` were planned to stay static because they were assumed brightness-invariant.

This sub-project lands the theming layer, but with a wider variation surface than the foundation anticipated. The user supplied three reference apps (Plum, Bumble, Clue) and asked for themes inspired by them. Those references force more knobs than just color: each theme has its own card radius, button shape, elevation profile, and (for Bumble) a brand-vs-CTA color split. Color alone is not enough to make Plum read as Plum.

This sub-project also introduces the first real Settings screen: a screen-level surface reachable from the gear icon that already exists on `ProfileScreen` (line 52, currently an empty `onTap`).

### What this sub-project does

- Promotes `AppColors`/`AppRadius`/`AppElevation`/CTA tokens from a flat static layer into a single `ThemeExtension<EarnWiseTheme>` with four nested value objects.
- Defines four named themes: `cream` (the existing identity, pixel-identical to today), `plum`, `bumble`, `clue`.
- Wires the theme into `MaterialApp` via `AppState.currentTheme` so the swap is instant and session-scoped.
- Adds a `SettingsScreen` reachable from the Profile gear icon, with a four-row theme picker.
- Migrates the **shared design system widgets** and the **home / profile / settings** surfaces to read tokens from the theme. Other screens keep their direct `AppColors.*` references and look correct only in Cream until they get migrated in follow-up sub-projects.
- Extracts a new shared `PrimaryButton` widget from the seven inline pill-button definitions across the codebase, because the button-shape knob has nowhere else to live.

### What this sub-project explicitly does NOT do

- Does **not** swap typography. All four themes use the existing Outfit type stack and the existing `AppText.*` styles. Adding font-family swap would push the project out of "skinned variants" territory and is left for a follow-up.
- Does **not** persist the theme selection. `AppState.currentTheme` is session-only, matching every other field in `AppState` today. No `shared_preferences` dependency, no async load step at boot. Persistence can be added in a small follow-up that does not change the theme model itself.
- Does **not** swap category tints (`categoryGame`, `categorySurvey`, etc.). These are semantic to the *category*, not to the theme, and stay static.
- Does **not** theme the destructive Sign Out red. Destructive UI must not change color across themes; `_kSignOutRed` on `ProfileScreen` stays hardcoded, and the new `PrimaryButton` exposes a `destructive: true` variant that always renders red regardless of theme.
- Does **not** add a Plum-style hero block to the home screen. Plum's defining full-bleed violet card is out of scope; Plum just gets its violet brand color in the existing layout. If the violet-without-hero feels muted in practice, a `BalanceHeroCard` widget can be designed in a follow-up sub-project.
- Does **not** migrate `splash_screen`, `welcome_screen`, `onboarding_screen`, `trust_carousel_screen`, `journey_screen`, `wallet_screen`, `game_detail_screen`, `placeholder_list_screen`, or `conv_card_content` to read theme tokens. These keep their direct `AppColors.*` references and look correct only in the Cream theme. Each can be migrated in a follow-up sub-project; the migration is mechanical because the `EarnWiseTheme` extension exists.
- Does **not** add lint enforcement against direct `AppColors.*` use in unmigrated screens.
- Does **not** animate the theme swap. `EarnWiseTheme.lerp` returns `this`. The swap is instant. Animated transitions can be added later by interpolating fields inside `lerp` without changing any consumer.
- Does **not** add a second entry point to Settings. The Profile gear icon is the only way in.

## Design

### 1. Token model

A single `ThemeExtension<EarnWiseTheme>` holds four nested immutable value objects. Each value object groups a knob.

```dart
@immutable
class EarnWiseTheme extends ThemeExtension<EarnWiseTheme> {
  final AppColorPalette palette;
  final AppRadiusScale  radii;
  final AppElevationProfile elevation;
  final AppCtaTokens    cta;

  const EarnWiseTheme({
    required this.palette,
    required this.radii,
    required this.elevation,
    required this.cta,
  });

  @override
  EarnWiseTheme copyWith({
    AppColorPalette? palette,
    AppRadiusScale? radii,
    AppElevationProfile? elevation,
    AppCtaTokens? cta,
  }) => EarnWiseTheme(
    palette: palette ?? this.palette,
    radii: radii ?? this.radii,
    elevation: elevation ?? this.elevation,
    cta: cta ?? this.cta,
  );

  @override
  EarnWiseTheme lerp(ThemeExtension<EarnWiseTheme>? other, double t) => this;
}
```

`lerp` returning `this` is deliberate: the swap is instant in v1. Adding interpolation later (color tweens, radius tweens) is a localized change to `lerp` and does not touch any consumer.

#### 1.1 `AppColorPalette`

Every color that varies between themes. Field-by-field:

| Field | Purpose |
|---|---|
| `surface` | page background (the most visible color in the app) |
| `surfaceRaised` | default card background |
| `surfaceSubtle` | secondary surfaces, dividers |
| `surfaceSelected` | selected-state fill on `AppCard` |
| `ink` | primary text and icon color |
| `inkSecondary` | secondary text |
| `inkTertiary` | tertiary text and muted captions |
| `brand` | primary accent (`StatBubble` accent, ring color, link color) |
| `brandStrong` | hover/pressed brand |
| `brandSubtle` | brand-pale background fill |
| `heroBackground` | reserved field for full-bleed hero blocks (unused by v1 widgets, populated for completeness so the catalog is forward-compatible) |
| `heroForeground` | text/icon color on a hero block |
| `hairline` | thin border color, used by themes whose elevation profile is flat (Plum's bordered cards) |

**Not in `AppColorPalette`** (deliberately):

- All `categoryGame*`, `categorySurvey*`, `categoryOffers*`, `categoryReceipts*`, `categoryVideo*`, `categoryCheckin*` colors. Category tints are semantic to the category and stay in static `AppColors`.
- `success`, `flame`, `flameBg`, `gold`. Feedback colors are semantic to feedback, not theme. Stay static.
- The destructive Sign Out red (`_kSignOutRed` on `ProfileScreen`). Stays in place.

#### 1.2 `AppRadiusScale`

```dart
@immutable
class AppRadiusScale {
  final double chip;
  final double card;
  final double feature;
  final double modal;
  final double button;  // NEW: button-shape knob
  // pill stays 9999 across all themes by definition
}
```

`button` is the new field that did not exist in the static `AppRadius`. It is the radius applied by the new `PrimaryButton` widget. `pill` stays a constant `9999.0` because every theme's full-pill elements are full-pill.

#### 1.3 `AppElevationProfile`

```dart
@immutable
class AppElevationProfile {
  final List<BoxShadow> none;   // always const []
  final List<BoxShadow> card;
  final List<BoxShadow> raised;
  final List<BoxShadow> modal;
}
```

Cream's profile holds the existing soft drop shadows from `AppElevation`. Plum/Bumble/Clue's profiles set `card`, `raised`, and `modal` to `const []` — flat. Themes that want bordered cards (Plum) lean on `palette.hairline` to add visual separation, applied at the `Surface` level.

#### 1.4 `AppCtaTokens`

```dart
@immutable
class AppCtaTokens {
  final Color background;
  final Color foreground;
}
```

The brand-vs-CTA split that Bumble forces. For Cream/Plum/Clue, `cta.background == palette.brand` and `cta.foreground == Colors.white` (or the palette equivalent). For Bumble, `cta.background == palette.ink` (near-black) and `cta.foreground == Colors.white`, because yellow on white has no contrast for a primary button.

`PrimaryButton` reads `radii.button` directly for its corner shape, so the radius lives in only one place.

### 2. Theme catalog

Four named const themes live in a new file `lib/theme/theme_catalog.dart`. Each theme is a single `EarnWiseTheme(...)` literal.

#### 2.1 Cream (default, the existing identity)

| Token | Value |
|---|---|
| `surface` | `#FAF8F5` |
| `surfaceRaised` | `#FFFFFF` |
| `surfaceSubtle` | `#F2EDE6` |
| `surfaceSelected` | `#F0FDFA` |
| `ink` | `#3B3230` |
| `inkSecondary` | `#6B5E58` |
| `inkTertiary` | `#8A7D76` |
| `brand` | `#0D9488` |
| `brandStrong` | `#0F766E` |
| `brandSubtle` | `#F0FDFA` |
| `hairline` | `#F2EDE6` (= surfaceSubtle, unused in Cream because cards are shadow-elevated) |
| `heroBackground` / `heroForeground` | `#FFFFFF` / `#3B3230` (placeholder, no hero block in v1) |
| `radii.chip` | 8 |
| `radii.card` | 16 |
| `radii.feature` | 20 |
| `radii.modal` | 24 |
| `radii.button` | 16 |
| `elevation` | the existing `AppElevation.card / raised / modal` (soft drop shadows, unchanged) |
| `cta.background / foreground` | `brand / #FFFFFF` |

**Compatibility assertion:** `EarnWiseTheme.cream.palette.brand == AppColors.brand`, `EarnWiseTheme.cream.palette.surface == AppColors.surface`, etc. for every field that has a static counterpart. Enforced by a unit test (Section 6). The intent: when Cream is the active theme, every screen renders pixel-identical to today, including unmigrated screens that still read from `AppColors.*` directly.

#### 2.2 Plum

| Token | Value |
|---|---|
| `surface` | `#FFFFFF` |
| `surfaceRaised` | `#FFFFFF` |
| `surfaceSubtle` | `#F4F2F7` |
| `surfaceSelected` | `#EFE9FE` |
| `ink` | `#0F1B2B` |
| `inkSecondary` | `#5B6470` |
| `inkTertiary` | `#8B92A0` |
| `brand` | `#5F2EE5` |
| `brandStrong` | `#4A1FB8` |
| `brandSubtle` | `#EFE9FE` |
| `hairline` | `#ECE9F2` |
| `heroBackground` / `heroForeground` | `#5F2EE5` / `#FFFFFF` |
| `radii.chip` | 8 |
| `radii.card` | 14 |
| `radii.feature` | 16 |
| `radii.modal` | 22 |
| `radii.button` | 9999 (pill) |
| `elevation.card / raised / modal` | `const []` (flat, leans on hairline border) |
| `cta.background / foreground` | `brand / #FFFFFF` |

#### 2.3 Bumble

| Token | Value |
|---|---|
| `surface` | `#FFFFFF` |
| `surfaceRaised` | `#F7F7F7` |
| `surfaceSubtle` | `#F2F2F2` |
| `surfaceSelected` | `#FFF6C2` |
| `ink` | `#1A1A1A` |
| `inkSecondary` | `#5C5C5C` |
| `inkTertiary` | `#909090` |
| `brand` | `#FEDA01` |
| `brandStrong` | `#E5C300` |
| `brandSubtle` | `#FFF6C2` |
| `hairline` | `#EAEAEA` |
| `heroBackground` / `heroForeground` | `#FEDA01` / `#1A1A1A` |
| `radii.chip` | 12 |
| `radii.card` | 18 |
| `radii.feature` | 20 |
| `radii.modal` | 24 |
| `radii.button` | 9999 (pill) |
| `elevation.card / raised / modal` | `const []` (flat, fill-differentiated) |
| `cta.background / foreground` | `#1A1A1A / #FFFFFF` (**brand ≠ CTA**) |

#### 2.4 Clue

| Token | Value |
|---|---|
| `surface` | `#ECECEC` |
| `surfaceRaised` | `#FFFFFF` |
| `surfaceSubtle` | `#E0E0E0` |
| `surfaceSelected` | `#D6EFFC` |
| `ink` | `#0E1B2A` |
| `inkSecondary` | `#5B6470` |
| `inkTertiary` | `#8B92A0` |
| `brand` | `#0E7889` |
| `brandStrong` | `#075560` |
| `brandSubtle` | `#D6EFFC` |
| `hairline` | `#DDDDDD` |
| `heroBackground` / `heroForeground` | `#FFFFFF` / `#0E1B2A` |
| `radii.chip` | 12 |
| `radii.card` | 22 |
| `radii.feature` | 24 |
| `radii.modal` | 28 |
| `radii.button` | 9999 (pill) |
| `elevation.card / raised / modal` | `const []` (flat, fill-differentiated) |
| `cta.background / foreground` | `brand / #FFFFFF` |

#### 2.5 Catalog ordering

The themes appear in the Settings picker in this order: Cream, Plum, Bumble, Clue. Cream first because it is the default and the identity the user lands in; the rest in the order they were introduced in this conversation. A single top-level constant `kEarnWiseThemes` (a `List<EarnWiseTheme>`) lives in `theme_catalog.dart` so the picker iterates the catalog without hardcoding the four themes individually.

### 3. State wiring & Material integration

#### 3.1 `AppState` change

`AppState` (`lib/state/app_state.dart`) gains one field and one method:

```dart
EarnWiseTheme currentTheme = EarnWiseTheme.cream;

void setTheme(EarnWiseTheme theme) {
  if (currentTheme == theme) return;
  currentTheme = theme;
  notifyListeners();
}
```

`AppState.reset()` (the Sign Out path) resets `currentTheme` back to `EarnWiseTheme.cream`, so a signed-out user always lands in the default. Adding this to `reset()` is a one-line change in the existing reset block.

#### 3.2 `main.dart` change

The current `EarnWiseApp` builds a `MaterialApp` with a static `AppTheme.theme`. The new build wraps it in a `Consumer<AppState>` so the `MaterialApp` rebuilds when `currentTheme` changes:

```dart
class EarnWiseApp extends StatelessWidget {
  const EarnWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) => MaterialApp(
          title: 'EarnWise',
          theme: AppTheme.buildMaterialTheme(state.currentTheme),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
```

`AppTheme.buildMaterialTheme(EarnWiseTheme t)` replaces the existing static `AppTheme.theme` getter:

```dart
class AppTheme {
  static ThemeData buildMaterialTheme(EarnWiseTheme t) {
    final textTheme = GoogleFonts.outfitTextTheme().apply(
      bodyColor: t.palette.ink,
      displayColor: t.palette.ink,
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.palette.surface,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: t.palette.brand,
        surface: t.palette.surface,
      ),
      extensions: [t],
    );
  }
}
```

`extensions: [t]` is the single line that makes `EarnWiseTheme` available throughout the widget tree via `Theme.of(context).extension<EarnWiseTheme>()!`.

#### 3.3 Consumption helper

A small `BuildContext` extension gives widgets a one-call accessor:

```dart
extension EarnWiseThemeContext on BuildContext {
  EarnWiseTheme get theme =>
      Theme.of(this).extension<EarnWiseTheme>()!;
}

// Usage:
final palette = context.theme.palette;
final radii   = context.theme.radii;
```

Lives in `lib/theme/theme_extension.dart` next to `EarnWiseTheme` itself.

#### 3.4 Swap semantics

User taps a row in `SettingsScreen` → `appState.setTheme(theme)` → `notifyListeners()` → `Consumer<AppState>` in `main.dart` rebuilds the `MaterialApp` → all `Theme.of(context)` consumers in the tree pick up the new tokens on next build → instant swap. No animation.

The active `SettingsScreen` is itself a child of the navigator inside the `MaterialApp`, so it also rebuilds and reflects the new theme. The user sees the full app — including the screen they tapped on — repaint into the new theme without any navigation pop.

### 4. Component migration scope

The principle: **migrate the shared design system widgets and the entry-screen surface so the theme swap is visibly correct on Home/Profile/Settings; leave the rest alone in v1.** Total purity (every `AppColors.*` reference in the codebase becomes `context.theme.palette.*`) is a 100+-site refactor and not the goal of this sub-project.

#### 4.1 Shared widgets that get migrated

Each of these reads from `context.theme` instead of static `AppColors`/`AppRadius`/`AppElevation`:

| Widget | Reads from theme |
|---|---|
| `Surface` (`lib/widgets/surface.dart`) | `palette.surfaceRaised`, `radii.card`, `elevation.card`. **New behavior:** if the resolved `elevation.card` is empty *and* the call site does not pass an explicit `border`, `Surface` draws a 1px hairline border using `palette.hairline`. This is what makes Plum's flat cards readable without requiring every `Surface(...)` call site in the codebase to opt into a border. Themes whose `elevation.card` is non-empty (Cream) skip the hairline because the shadow already provides the affordance. |
| `AppCard` (`lib/widgets/app_card.dart`) | inherits `Surface` reads + `palette.surfaceSelected` and `palette.brand` for its selected-state border |
| `ListRow` (`lib/widgets/list_row.dart`) | no direct change; carried by `Surface` migration |
| `VerticalTile` (`lib/widgets/vertical_tile.dart`) | `radii.feature`, `palette.surfaceRaised`, `elevation.card` |
| `StatBubble` (`lib/widgets/stat_bubble.dart`) | default `accentColor` becomes `palette.brand` instead of `AppColors.brand` |
| `BottomSheetShell` (`lib/widgets/bottom_sheet_shell.dart`) | `radii.modal`, `palette.surfaceRaised`, `elevation.modal` |
| `SectionHeader` (`lib/widgets/section_header.dart`) | `palette.ink` for the title, `palette.inkSecondary` for the subtitle if any |
| `ScreenScaffold` (`lib/widgets/screen_scaffold.dart`) | `palette.surface` for the page background |

`CategoryIconSquare` does **not** change. Category tints are not theme-dependent.

#### 4.2 New shared widget: `PrimaryButton`

A new file `lib/widgets/primary_button.dart`. The widget reads `context.theme.cta` for background, foreground, and radius. It accepts:

```dart
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool destructive;  // overrides cta with red, used by Sign Out only
  final IconData? leadingIcon;
  // Visual: full-width by default, 60px tall, AppText.ctaLabel,
  // wrapped in PressScale for the existing physical-press feel.
}
```

Sites that get migrated to use `PrimaryButton`:

- `welcome_screen.dart` — Get started CTA
- `onboarding_screen.dart` — Continue, Pick games CTAs
- `trust_carousel_screen.dart` — Got it CTA
- `game_detail_screen.dart` — Play / Continue CTAs
- `wallet_screen.dart` — Cash out CTA
- `profile_screen.dart` — **Sign Out** (uses `destructive: true`, which forces the red regardless of theme)

These migrations land in this sub-project even for screens that are otherwise not migrated. The reason: a single shared button widget is a small, contained change per screen, and it is the only way to get the button-shape knob to actually take effect across the app. Note that this change makes `welcome_screen`/`onboarding_screen`/`trust_carousel_screen`/`game_detail_screen`/`wallet_screen` partially theme-aware (their button picks up `cta.*`) even though their other surfaces (background, cards, text colors) keep reading from static `AppColors`. This mismatch is acceptable because the button is the most prominent interactive element on each of those screens.

#### 4.3 Screens migrated for v1

These screens get a full pass to read theme tokens (palette, radii, elevation) from `context.theme`:

- `home_screen.dart` — the most important surface
- `home_shell.dart` — bottom nav background and active-tab tint
- `profile_screen.dart` — the entry point to Settings
- `settings_screen.dart` — new (Section 5)

#### 4.4 Screens NOT migrated for v1

These screens keep their direct `AppColors.*`/`AppRadius.*`/`AppElevation.*` references and look correct only in the Cream theme. The compatibility assertion in Section 2.1 guarantees they do not drift in Cream:

`splash_screen`, `welcome_screen`, `onboarding_screen`, `trust_carousel_screen`, `journey_screen`, `wallet_screen`, `game_detail_screen`, `placeholder_list_screen`, `conv_card_content`.

Each is a candidate for a follow-up mechanical migration sub-project. The work is straightforward because the `EarnWiseTheme` extension already exists.

#### 4.5 Static `AppColors` / `AppRadius` / `AppElevation` retention

The static classes stay around as the **Cream defaults**. Every value in the static layer equals the corresponding field on `EarnWiseTheme.cream`. The compatibility assertion in Section 6 enforces this. This is the smallest blast radius for the migration: unmigrated screens keep working, migrated screens read from theme, and the two paths return the same values when Cream is active.

After every screen has been migrated in follow-up sub-projects, the static classes can be removed in a final cleanup. That cleanup is not in scope here.

### 5. Settings screen

#### 5.1 Entry point

`profile_screen.dart` line 52 — the gear icon's `onTap: () {}` becomes:

```dart
onTap: () {
  Navigator.of(context).push(fadeRoute(const SettingsScreen()));
},
```

`fadeRoute` is the existing helper in `lib/widgets/fade_route.dart` and matches how other screens are pushed in the prototype.

#### 5.2 Layout

`SettingsScreen` (`lib/screens/settings_screen.dart`) is a `StatelessWidget` whose body is a `ScreenScaffold` with the page title "Theme" and a back arrow. The body is a vertical column of one `_ThemeRow` per entry in `kEarnWiseThemes`:

```
ScreenScaffold(title: "Theme")
└── Column
    ├── (subtitle, AppText.body, inkSecondary)
    │     "Pick how EarnWise looks. The change happens instantly."
    ├── SizedBox(height: AppSpacing.sectionGap)
    └── for each theme in kEarnWiseThemes:
          _ThemeRow(theme: theme, selected: theme == state.currentTheme)
          SizedBox(height: AppSpacing.rowGap)
```

The screen uses a `Consumer<AppState>` so it rebuilds when the user taps a row and the active theme changes; the radio dot on the new row fills in immediately.

#### 5.3 `_ThemeRow` widget

Private widget inside `settings_screen.dart`. Not promoted to the design system; one-time use.

```
[corner-split swatch] [title]            [radio]
                      [subtitle]
```

- Wraps `AppCard(selected: selected, onTap: ...)`. When `selected` is true, the card picks up `palette.surfaceSelected` fill and `palette.brand` border for free, and that styling itself comes from the **active** theme, so the row looks right in every theme.
- The corner-split swatch is a 28x28 box with the top-left half showing `theme.palette.surface` and the bottom-right half showing `theme.palette.brand`. Renders the theme being represented, not the active theme — so the user sees what each option will look like before tapping.
- Title uses `AppText.listItem`, subtitle uses `AppText.body` colored `palette.inkSecondary`.
- Right-side radio dot: 18x18 circle, outlined `palette.inkTertiary` when not selected, filled `palette.brand` with a white inner dot when selected.
- `onTap` calls `context.read<AppState>().setTheme(theme)` and triggers a `Haptics.tap()` for tactile confirmation. No navigation pop — the user stays on Settings and watches the swap propagate.

#### 5.4 Row content

| Theme | Title | Subtitle |
|---|---|---|
| Cream | Cream | Warm and soft. The original. |
| Plum | Plum | Bold violet, white surface. |
| Bumble | Bumble | Honey yellow with black accents. |
| Clue | Clue | Calm gray with deep teal. |

The subtitles deliberately read like sentences a person would say (per the "human voice" rule in `CLAUDE.md`). No telegraphic fragments.

### 6. Test plan

Proportionate to a prototype. No goldens.

**Unit tests** (`test/theme/earnwise_theme_test.dart`):
- All four named themes (`cream`, `plum`, `bumble`, `clue`) are constructable with all required fields populated.
- `kEarnWiseThemes` contains exactly four entries in the expected order.
- **Compatibility assertion:** for every field on `EarnWiseTheme.cream.palette` that has a static counterpart in `AppColors`, the values are equal. Same for `radii` vs `AppRadius` (excluding the new `button` field) and `elevation` vs `AppElevation`.

**Widget tests** (`test/widgets/`):
- `Surface` renders with the radius / elevation / color of the active `EarnWiseTheme`. One test per theme by wrapping the widget in a `MaterialApp(theme: AppTheme.buildMaterialTheme(theme))`.
- `PrimaryButton`:
  - In Cream/Plum/Clue, the rendered background equals `palette.brand`.
  - In Bumble, the rendered background equals `palette.ink` (proves the brand-vs-CTA split).
  - With `destructive: true`, the rendered background is `_kSignOutRed` regardless of theme.

**Widget test** (`test/screens/settings_screen_test.dart`):
- Renders four `_ThemeRow` entries in the order `Cream, Plum, Bumble, Clue`.
- Tapping the second row calls `setTheme(EarnWiseTheme.plum)` on the provided `AppState`.
- After the tap, the second row reports `selected: true` and the first row reports `selected: false`.
- The screen's `Scaffold.backgroundColor` reflects the new theme on the next build (proves the rebuild-on-notify path).

**Widget test** (`test/screens/profile_screen_test.dart`):
- Tapping the gear icon at the top of `ProfileScreen` pushes a `SettingsScreen` onto the navigator.

**Manual visual check** (not automated):
- Open the app, tap each theme in turn, eyeball the home screen, profile, settings. Confirm: surfaces, ink, brand, button shape, card radius, and elevation all visibly change. Confirm: unmigrated screens still look correct in Cream after a round trip.

### 7. Open questions resolved during brainstorm

| Question | Answer |
|---|---|
| Light + dark, multiple brand themes, or both? | Multiple brand themes, light only |
| Color only, color + style, or full design language swap? | Color + style (skinned variants) |
| 1–2 style knobs, or more? | 4 knobs: color, radius, elevation, button shape |
| Persistence? | Session-only, no `shared_preferences` |
| Settings entry point? | Profile gear icon (existing empty `onTap`) |
| Settings scope? | Theme-only screen (no other settings) |
| Picker layout? | List rows with corner-split swatch (Layout A from brainstorm) |
| How many themes in v1? | Four: Cream, Plum, Bumble, Clue |
| Architecture? | Single `ThemeExtension<EarnWiseTheme>` wrapping four nested value objects |
| Default theme on boot? | Cream |
| Plum hero block? | Out of scope. Plum gets its violet brand color in the existing layout only. |
| Sign Out red themed? | No. Destructive UI does not change color across themes. |

### 8. Risks and mitigations

**Unmigrated screens look wrong in non-Cream themes.** Mitigated by being explicit in this spec and in the Settings screen itself — the screen does not advertise "the whole app is themed", and the user piloting this prototype already knows the migration is incremental. The compatibility assertion guarantees Cream stays pixel-correct.

**`PrimaryButton` migration touches seven screens, some of which are otherwise unmigrated.** Mitigated by keeping the change in each screen tightly scoped (one button replacement, no other edits) and by the `destructive: true` variant for Sign Out so red stays red.

**A consumer reads `Theme.of(context).extension<EarnWiseTheme>()` before the extension is registered** (e.g., during a test that wraps a widget in a bare `MaterialApp` with no theme). Mitigated by the bang on the `BuildContext.theme` extension — failure is loud and immediate. Tests that need a theme are required to wrap with `AppTheme.buildMaterialTheme(...)`.

**Bumble's `cta.background == ink` could surprise a future contributor** who expects `cta.background == brand`. Mitigated by an inline comment in `theme_catalog.dart` next to Bumble's `cta` literal explaining the brand-vs-CTA split, and by the dedicated Bumble assertion in `PrimaryButton`'s widget test.

### 9. Out of scope / future work

- **Persistence** of the theme selection across app restarts (`shared_preferences` + an async load step on boot).
- **Animated theme swap** by interpolating fields inside `EarnWiseTheme.lerp`.
- **Per-theme typography** (font family swap, bolder display weights for Plum).
- **Per-theme category tints**, if Clue's round colored circles ever feel wrong with the static category palette.
- **`BalanceHeroCard`** widget, if Plum's violet without a hero block feels muted on Home.
- **Migrating the remaining nine screens** to read theme tokens. Each screen is a small follow-up sub-project.
- **A second Settings entry point** (e.g., a long-press on the brand mark, a debug menu, a developer drawer) if discoverability becomes a friction point.
- **Removing the static `AppColors`/`AppRadius`/`AppElevation` classes** after every screen has migrated.
