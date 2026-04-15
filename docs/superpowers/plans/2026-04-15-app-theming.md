# App Theming + Settings Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Promote the flat `AppColors`/`AppRadius`/`AppElevation` layer into a `ThemeExtension<EarnWiseTheme>` with four named themes (Cream, Plum, Bumble, Clue), wire the active theme through `AppState` into `MaterialApp`, migrate the shared widgets and home/profile/settings surfaces to read tokens from the theme, extract a `PrimaryButton` widget, and land a new `SettingsScreen` that swaps themes live from a four-row picker.

**Architecture:** A single `ThemeExtension<EarnWiseTheme>` wraps four nested value objects — `AppColorPalette`, `AppRadiusScale`, `AppElevationProfile`, `AppCtaTokens` — that hold the four "knobs" (color, radius, elevation, button shape + brand-vs-CTA split). The themes are registered via `ThemeData.extensions: [t]` so every widget gets them through `Theme.of(context).extension<EarnWiseTheme>()!`, surfaced ergonomically by a `context.theme` `BuildContext` extension. The existing static `AppColors`/`AppRadius`/`AppElevation` classes stay around as the Cream defaults so unmigrated screens still render correctly in the default theme. The spec this plan is built from is at `docs/superpowers/specs/2026-04-15-app-theming-design.md`.

**Tech Stack:** Flutter 3.x, Dart, Material 3, `provider` (already in `pubspec.yaml`), `google_fonts`, `phosphor_flutter`, `flutter_test`. The package name is `earnwise_mvp`; imports use `package:earnwise_mvp/…`.

---

## File Structure

**Created:**
- `flutter_app/lib/theme/app_color_palette.dart` — `AppColorPalette` value object (13 fields).
- `flutter_app/lib/theme/app_radius_scale.dart` — `AppRadiusScale` value object (chip/card/feature/modal/button).
- `flutter_app/lib/theme/app_elevation_profile.dart` — `AppElevationProfile` value object (none/card/raised/modal).
- `flutter_app/lib/theme/app_cta_tokens.dart` — `AppCtaTokens` value object (background/foreground).
- `flutter_app/lib/theme/earnwise_theme.dart` — `ThemeExtension<EarnWiseTheme>` wrapping the four value objects above, plus the `context.theme` `BuildContext` extension.
- `flutter_app/lib/theme/theme_catalog.dart` — four named const themes (`cream`, `plum`, `bumble`, `clue`) plus `kEarnWiseThemes`.
- `flutter_app/lib/widgets/primary_button.dart` — shared pill/rect CTA, reads `cta` + `radii.button` from theme, supports `destructive: true`.
- `flutter_app/lib/screens/settings_screen.dart` — new Theme picker screen with private `_ThemeRow`.
- `flutter_app/test/theme/earnwise_theme_test.dart` — token value-object tests + Cream compatibility assertion + catalog ordering.
- `flutter_app/test/widgets/primary_button_test.dart` — CTA color per theme + destructive override.
- `flutter_app/test/widgets/theme_test_harness.dart` — tiny helper that wraps a child in a `MaterialApp` built with a given `EarnWiseTheme`, used by several widget tests.
- `flutter_app/test/screens/settings_screen_test.dart` — theme picker row count, order, selection, live swap.

**Modified:**
- `flutter_app/lib/theme/app_theme.dart` — `AppTheme.theme` getter replaced by `AppTheme.buildMaterialTheme(EarnWiseTheme t)`. The static `AppColors` / `AppRadius` / `AppElevation` classes stay as the Cream defaults.
- `flutter_app/lib/main.dart` — `MaterialApp` wrapped in `Consumer<AppState>`, calls `AppTheme.buildMaterialTheme(state.currentTheme)`.
- `flutter_app/lib/state/app_state.dart` — adds `currentTheme` + `setTheme()`; `reset()` also resets `currentTheme` to `EarnWiseTheme.cream`.
- `flutter_app/lib/widgets/surface.dart` — reads `surfaceRaised`/`radii.card`/`elevation.card` from theme; auto-hairline when `elevation.card` is empty and no explicit `border` was passed.
- `flutter_app/lib/widgets/app_card.dart` — reads `surfaceRaised`/`surfaceSelected`/`brand`/`hairline`/`radii.card`/`elevation.card` from theme.
- `flutter_app/lib/widgets/screen_scaffold.dart` — default background reads `palette.surface` from theme.
- `flutter_app/lib/widgets/vertical_tile.dart` — reads `radii.feature` / ink colors from theme.
- `flutter_app/lib/widgets/stat_bubble.dart` — default `accentColor` resolves from `palette.brand` at build time.
- `flutter_app/lib/widgets/bottom_sheet_shell.dart` — reads `palette.surfaceRaised` / `radii.modal` / `palette.surfaceSubtle` (grab-handle) from theme.
- `flutter_app/lib/widgets/section_header.dart` — title/subtitle ink colors read from theme.
- `flutter_app/lib/widgets/list_row.dart` — ink colors read from theme.
- `flutter_app/lib/screens/welcome_screen.dart`, `onboarding_screen.dart`, `trust_carousel_screen.dart`, `game_detail_screen.dart`, `wallet_screen.dart` — inline pill-button sites replaced by `PrimaryButton(...)` instances. These screens stay otherwise unmigrated.
- `flutter_app/lib/screens/home_screen.dart` — ink/brand/surface reads migrated to `context.theme.palette.*`.
- `flutter_app/lib/screens/home_shell.dart` — bottom nav pill reads ink/brand/surface from theme.
- `flutter_app/lib/screens/profile_screen.dart` — migrated to theme + Sign Out becomes `PrimaryButton(destructive: true)` + gear icon pushes `SettingsScreen` via `fadeRoute`.
- `flutter_app/test/screens/profile_screen_test.dart` — adds test that tapping the gear icon navigates to `SettingsScreen`.

**Untouched:** `splash_screen.dart`, `journey_screen.dart`, `placeholder_list_screen.dart`, `conv_card_content.dart`, `lib/theme/app_text.dart`, `lib/theme/motion.dart`, `category_icon_square.dart`, and every asset/model file. Non-migrated screens keep their direct `AppColors.*` references and look correct only in the Cream theme; the compatibility assertion in Task 3 guarantees Cream stays pixel-correct.

---

## Task 0: Baseline verification

**Purpose:** confirm the suite is green before any changes so subsequent failures are attributable to this work.

**Files:** none modified.

- [ ] **Step 1: Run the full test suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all tests pass.

- [ ] **Step 2: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze
```

Expected: "No issues found!" (or the same pre-existing info messages as before; no warnings or errors).

- [ ] **Step 3: Note the green count**

Record the test count from Step 1. Task 21 must match this number plus the new tests added by this plan.

No commit. If either step fails, stop and debug before touching any other file.

---

## Task 1: Token value objects

**Purpose:** create the four immutable value objects that `EarnWiseTheme` wraps. No theme literals yet — just the types.

**Files:**
- Create: `flutter_app/lib/theme/app_color_palette.dart`
- Create: `flutter_app/lib/theme/app_radius_scale.dart`
- Create: `flutter_app/lib/theme/app_elevation_profile.dart`
- Create: `flutter_app/lib/theme/app_cta_tokens.dart`
- Create: `flutter_app/test/theme/earnwise_theme_test.dart` (starts with value-object tests; grows in later tasks)

- [ ] **Step 1: Write the failing test for `AppColorPalette`**

Create `flutter_app/test/theme/earnwise_theme_test.dart` with this exact content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/app_color_palette.dart';
import 'package:earnwise_mvp/theme/app_radius_scale.dart';
import 'package:earnwise_mvp/theme/app_elevation_profile.dart';
import 'package:earnwise_mvp/theme/app_cta_tokens.dart';

void main() {
  group('AppColorPalette', () {
    test('exposes every required semantic slot', () {
      const p = AppColorPalette(
        surface: Color(0xFF000001),
        surfaceRaised: Color(0xFF000002),
        surfaceSubtle: Color(0xFF000003),
        surfaceSelected: Color(0xFF000004),
        ink: Color(0xFF000005),
        inkSecondary: Color(0xFF000006),
        inkTertiary: Color(0xFF000007),
        brand: Color(0xFF000008),
        brandStrong: Color(0xFF000009),
        brandSubtle: Color(0xFF00000A),
        heroBackground: Color(0xFF00000B),
        heroForeground: Color(0xFF00000C),
        hairline: Color(0xFF00000D),
      );
      expect(p.surface, const Color(0xFF000001));
      expect(p.hairline, const Color(0xFF00000D));
    });
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: FAIL with "Target of URI doesn't exist" or similar — `app_color_palette.dart` does not exist yet.

- [ ] **Step 3: Create `AppColorPalette`**

Create `flutter_app/lib/theme/app_color_palette.dart`:

```dart
import 'package:flutter/material.dart';

/// Every color that varies between EarnWise themes. Category tints,
/// feedback colors (success/flame/gold), and the destructive Sign Out red
/// are deliberately NOT in this palette — they stay static in `AppColors`.
///
/// See `docs/superpowers/specs/2026-04-15-app-theming-design.md` §1.1.
@immutable
class AppColorPalette {
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSubtle;
  final Color surfaceSelected;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color brand;
  final Color brandStrong;
  final Color brandSubtle;
  final Color heroBackground;
  final Color heroForeground;
  final Color hairline;

  const AppColorPalette({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSubtle,
    required this.surfaceSelected,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.brand,
    required this.brandStrong,
    required this.brandSubtle,
    required this.heroBackground,
    required this.heroForeground,
    required this.hairline,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppColorPalette &&
          other.surface == surface &&
          other.surfaceRaised == surfaceRaised &&
          other.surfaceSubtle == surfaceSubtle &&
          other.surfaceSelected == surfaceSelected &&
          other.ink == ink &&
          other.inkSecondary == inkSecondary &&
          other.inkTertiary == inkTertiary &&
          other.brand == brand &&
          other.brandStrong == brandStrong &&
          other.brandSubtle == brandSubtle &&
          other.heroBackground == heroBackground &&
          other.heroForeground == heroForeground &&
          other.hairline == hairline);

  @override
  int get hashCode => Object.hash(
        surface,
        surfaceRaised,
        surfaceSubtle,
        surfaceSelected,
        ink,
        inkSecondary,
        inkTertiary,
        brand,
        brandStrong,
        brandSubtle,
        heroBackground,
        heroForeground,
        hairline,
      );
}
```

- [ ] **Step 4: Run the palette test to confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: 1 test passes.

- [ ] **Step 5: Append the failing test for `AppRadiusScale`**

Append to the `void main() { ... }` body in `test/theme/earnwise_theme_test.dart`:

```dart
  group('AppRadiusScale', () {
    test('stores every radius knob and `pill` is 9999 by convention', () {
      const r = AppRadiusScale(
        chip: 8,
        card: 16,
        feature: 20,
        modal: 24,
        button: 16,
      );
      expect(r.chip, 8);
      expect(r.card, 16);
      expect(r.feature, 20);
      expect(r.modal, 24);
      expect(r.button, 16);
      expect(AppRadiusScale.pill, 9999.0);
    });
  });
```

- [ ] **Step 6: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: FAIL — `app_radius_scale.dart` does not exist.

- [ ] **Step 7: Create `AppRadiusScale`**

Create `flutter_app/lib/theme/app_radius_scale.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Radius knob for a theme. The `button` field is new in this sub-project
/// — static `AppRadius` does not define one. Pill (9999) is a constant
/// and lives on the class, not on instances, because every theme's
/// full-pill elements are full-pill.
@immutable
class AppRadiusScale {
  final double chip;
  final double card;
  final double feature;
  final double modal;
  final double button;

  const AppRadiusScale({
    required this.chip,
    required this.card,
    required this.feature,
    required this.modal,
    required this.button,
  });

  /// 9999 — theme-invariant full-pill radius.
  static const double pill = 9999;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppRadiusScale &&
          other.chip == chip &&
          other.card == card &&
          other.feature == feature &&
          other.modal == modal &&
          other.button == button);

  @override
  int get hashCode => Object.hash(chip, card, feature, modal, button);
}
```

- [ ] **Step 8: Run and confirm pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 9: Append the failing test for `AppElevationProfile`**

Append to `void main() { ... }`:

```dart
  group('AppElevationProfile', () {
    test('allows all-flat profiles and rich drop-shadow profiles', () {
      const flat = AppElevationProfile(
        none: [],
        card: [],
        raised: [],
        modal: [],
      );
      final rich = AppElevationProfile(
        none: const [],
        card: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
        raised: const [],
        modal: const [],
      );
      expect(flat.card, isEmpty);
      expect(rich.card.single.blurRadius, 8);
    });
  });
```

- [ ] **Step 10: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: FAIL — `app_elevation_profile.dart` does not exist.

- [ ] **Step 11: Create `AppElevationProfile`**

Create `flutter_app/lib/theme/app_elevation_profile.dart`:

```dart
import 'package:flutter/material.dart';

/// Elevation knob for a theme. Each list is assignable directly to
/// `BoxDecoration.boxShadow`. Flat themes (Plum/Bumble/Clue) set every
/// layer except `none` to `const []` and lean on `AppColorPalette.hairline`
/// for visual card separation.
@immutable
class AppElevationProfile {
  final List<BoxShadow> none;
  final List<BoxShadow> card;
  final List<BoxShadow> raised;
  final List<BoxShadow> modal;

  const AppElevationProfile({
    required this.none,
    required this.card,
    required this.raised,
    required this.modal,
  });
}
```

- [ ] **Step 12: Run and confirm pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 13: Append the failing test for `AppCtaTokens`**

Append to `void main() { ... }`:

```dart
  group('AppCtaTokens', () {
    test('stores background and foreground', () {
      const cta = AppCtaTokens(
        background: Color(0xFF111111),
        foreground: Color(0xFFFFFFFF),
      );
      expect(cta.background, const Color(0xFF111111));
      expect(cta.foreground, const Color(0xFFFFFFFF));
    });
  });
```

- [ ] **Step 14: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: FAIL — `app_cta_tokens.dart` does not exist.

- [ ] **Step 15: Create `AppCtaTokens`**

Create `flutter_app/lib/theme/app_cta_tokens.dart`:

```dart
import 'package:flutter/material.dart';

/// Primary-button color pair. Deliberately a separate object (not part of
/// `AppColorPalette`) because Bumble forces `background = ink` instead of
/// `background = brand` — yellow on white has no contrast for a CTA.
/// `PrimaryButton` reads `radii.button` for its radius directly, so the
/// button-shape knob lives in one place only.
@immutable
class AppCtaTokens {
  final Color background;
  final Color foreground;

  const AppCtaTokens({
    required this.background,
    required this.foreground,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppCtaTokens &&
          other.background == background &&
          other.foreground == foreground);

  @override
  int get hashCode => Object.hash(background, foreground);
}
```

- [ ] **Step 16: Run and confirm pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 17: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/theme/app_color_palette.dart flutter_app/lib/theme/app_radius_scale.dart flutter_app/lib/theme/app_elevation_profile.dart flutter_app/lib/theme/app_cta_tokens.dart flutter_app/test/theme/earnwise_theme_test.dart
git commit -m "feat(theme): add AppColorPalette/AppRadiusScale/AppElevationProfile/AppCtaTokens value objects"
```

---

## Task 2: `EarnWiseTheme` extension + `context.theme` helper

**Purpose:** land the `ThemeExtension<EarnWiseTheme>` wrapper and the `BuildContext` ergonomics helper. No themes yet — just the plumbing.

**Files:**
- Create: `flutter_app/lib/theme/earnwise_theme.dart`

- [ ] **Step 1: Append the failing test**

Append to the `void main() { ... }` body in `test/theme/earnwise_theme_test.dart` (and add an import for `earnwise_theme.dart` at the top of the file):

```dart
  group('EarnWiseTheme', () {
    AppColorPalette palette() => const AppColorPalette(
          surface: Color(0xFFFFFFFF),
          surfaceRaised: Color(0xFFFFFFFF),
          surfaceSubtle: Color(0xFFEEEEEE),
          surfaceSelected: Color(0xFFDDDDDD),
          ink: Color(0xFF000000),
          inkSecondary: Color(0xFF444444),
          inkTertiary: Color(0xFF888888),
          brand: Color(0xFF00AAAA),
          brandStrong: Color(0xFF007777),
          brandSubtle: Color(0xFFCCFFFF),
          heroBackground: Color(0xFFFFFFFF),
          heroForeground: Color(0xFF000000),
          hairline: Color(0xFFDDDDDD),
        );

    EarnWiseTheme make() => EarnWiseTheme(
          palette: palette(),
          radii: const AppRadiusScale(
            chip: 8,
            card: 16,
            feature: 20,
            modal: 24,
            button: 16,
          ),
          elevation: const AppElevationProfile(
            none: [],
            card: [],
            raised: [],
            modal: [],
          ),
          cta: const AppCtaTokens(
            background: Color(0xFF00AAAA),
            foreground: Color(0xFFFFFFFF),
          ),
        );

    test('is a ThemeExtension<EarnWiseTheme>', () {
      expect(make(), isA<ThemeExtension<EarnWiseTheme>>());
    });

    test('copyWith swaps only the provided slot', () {
      final base = make();
      final swapped = base.copyWith(
        cta: const AppCtaTokens(
          background: Color(0xFF111111),
          foreground: Color(0xFFFFFFFF),
        ),
      );
      expect(swapped.palette, base.palette);
      expect(swapped.radii, base.radii);
      expect(swapped.elevation, base.elevation);
      expect(swapped.cta.background, const Color(0xFF111111));
    });

    test('lerp is instant (returns `this`) in v1', () {
      final base = make();
      final other = base.copyWith(
        cta: const AppCtaTokens(
          background: Color(0xFF222222),
          foreground: Color(0xFFFFFFFF),
        ),
      );
      // Instant swap is deliberate; animated lerp is deferred.
      expect(identical(base.lerp(other, 0.5), base), isTrue);
    });
  });
```

Add imports at the top:

```dart
import 'package:earnwise_mvp/theme/earnwise_theme.dart';
```

- [ ] **Step 2: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: FAIL — `earnwise_theme.dart` does not exist.

- [ ] **Step 3: Create `EarnWiseTheme`**

Create `flutter_app/lib/theme/earnwise_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'app_color_palette.dart';
import 'app_cta_tokens.dart';
import 'app_elevation_profile.dart';
import 'app_radius_scale.dart';

/// Single `ThemeExtension` that wraps the four "knobs" EarnWise themes vary
/// across: color palette, radius scale, elevation profile, CTA colors.
///
/// Registered on `ThemeData.extensions` so any widget can read it via
/// `Theme.of(context).extension<EarnWiseTheme>()!` — or, more ergonomically,
/// via the `context.theme` extension below.
///
/// `lerp` returns `this` in v1: theme swaps are instant. Animated
/// interpolation can be added later by tweening each field inside `lerp`
/// without touching any consumer.
@immutable
class EarnWiseTheme extends ThemeExtension<EarnWiseTheme> {
  final AppColorPalette palette;
  final AppRadiusScale radii;
  final AppElevationProfile elevation;
  final AppCtaTokens cta;

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
  }) =>
      EarnWiseTheme(
        palette: palette ?? this.palette,
        radii: radii ?? this.radii,
        elevation: elevation ?? this.elevation,
        cta: cta ?? this.cta,
      );

  @override
  EarnWiseTheme lerp(covariant ThemeExtension<EarnWiseTheme>? other, double t) =>
      this;
}

/// Ergonomic `Theme.of(context).extension<EarnWiseTheme>()!` shortcut.
///
/// Use `context.theme.palette.ink` instead of
/// `Theme.of(context).extension<EarnWiseTheme>()!.palette.ink`.
///
/// The bang is intentional: if a test wraps a widget in a `MaterialApp`
/// without `AppTheme.buildMaterialTheme(...)`, failure should be loud and
/// immediate so the test harness is fixed, not papered over.
extension EarnWiseThemeContext on BuildContext {
  EarnWiseTheme get theme => Theme.of(this).extension<EarnWiseTheme>()!;
}
```

- [ ] **Step 4: Run and confirm pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: 7 tests pass (4 from Task 1 + 3 new).

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/theme/earnwise_theme.dart flutter_app/test/theme/earnwise_theme_test.dart
git commit -m "feat(theme): add EarnWiseTheme ThemeExtension + context.theme helper"
```

---

## Task 3: Cream theme + compatibility assertion

**Purpose:** introduce the Cream theme and prove, by test, that its field values are byte-identical to the existing static `AppColors`/`AppRadius`/`AppElevation` values. This is what keeps unmigrated screens pixel-correct in Cream.

**Files:**
- Create: `flutter_app/lib/theme/theme_catalog.dart`
- Modify: `flutter_app/test/theme/earnwise_theme_test.dart`

- [ ] **Step 1: Append the failing compatibility test**

Append to `void main() { ... }` in `test/theme/earnwise_theme_test.dart`:

```dart
  group('kCreamTheme compatibility with static AppColors/AppRadius/AppElevation',
      () {
    test('palette equals the static AppColors semantic fields', () {
      final p = kCreamTheme.palette;
      expect(p.surface, AppColors.surface);
      expect(p.surfaceRaised, AppColors.surfaceRaised);
      expect(p.surfaceSubtle, AppColors.surfaceSubtle);
      expect(p.surfaceSelected, AppColors.surfaceSelected);
      expect(p.ink, AppColors.ink);
      expect(p.inkSecondary, AppColors.inkSecondary);
      expect(p.inkTertiary, AppColors.inkTertiary);
      expect(p.brand, AppColors.brand);
      expect(p.brandStrong, AppColors.brandStrong);
      expect(p.brandSubtle, AppColors.brandSubtle);
    });

    test('radii equal the static AppRadius fields (excluding new `button`)',
        () {
      final r = kCreamTheme.radii;
      expect(r.chip, AppRadius.chip);
      expect(r.card, AppRadius.card);
      expect(r.feature, AppRadius.feature);
      expect(r.modal, AppRadius.modal);
      // `button` is new; it matches the existing card radius for Cream.
      expect(r.button, AppRadius.card);
    });

    test('elevation equals the static AppElevation lists', () {
      final e = kCreamTheme.elevation;
      expect(e.none, AppElevation.none);
      expect(e.card, AppElevation.card);
      expect(e.raised, AppElevation.raised);
      expect(e.modal, AppElevation.modal);
    });

    test('cta uses brand background and white foreground', () {
      expect(kCreamTheme.cta.background, AppColors.brand);
      expect(kCreamTheme.cta.foreground, Colors.white);
    });
  });
```

Add imports at the top of the test file:

```dart
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';
```

- [ ] **Step 2: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: FAIL — `theme_catalog.dart` does not exist.

- [ ] **Step 3: Create the catalog with Cream only**

Create `flutter_app/lib/theme/theme_catalog.dart`:

```dart
import 'package:flutter/material.dart';
import 'app_color_palette.dart';
import 'app_cta_tokens.dart';
import 'app_elevation_profile.dart';
import 'app_radius_scale.dart';
import 'app_theme.dart';
import 'earnwise_theme.dart';

/// The four named EarnWise themes plus the `kEarnWiseThemes` catalog list.
/// See `docs/superpowers/specs/2026-04-15-app-theming-design.md` §2.

/// Cream — the existing EarnWise identity. Every palette/radii/elevation
/// field equals its static `AppColors`/`AppRadius`/`AppElevation`
/// counterpart so unmigrated screens stay pixel-correct when Cream is
/// active. Enforced by a unit test in `earnwise_theme_test.dart`.
final EarnWiseTheme kCreamTheme = EarnWiseTheme(
  palette: const AppColorPalette(
    surface: Color(0xFFFAF8F5),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF2EDE6),
    surfaceSelected: Color(0xFFF0FDFA),
    ink: Color(0xFF3B3230),
    inkSecondary: Color(0xFF6B5E58),
    inkTertiary: Color(0xFF8A7D76),
    brand: Color(0xFF0D9488),
    brandStrong: Color(0xFF0F766E),
    brandSubtle: Color(0xFFF0FDFA),
    heroBackground: Color(0xFFFFFFFF),
    heroForeground: Color(0xFF3B3230),
    // Unused in Cream — cards are shadow-elevated — but populated for
    // forward-compat with the `AppColorPalette` contract.
    hairline: Color(0xFFF2EDE6),
  ),
  radii: const AppRadiusScale(
    chip: 8,
    card: 16,
    feature: 20,
    modal: 24,
    button: 16,
  ),
  elevation: AppElevationProfile(
    none: AppElevation.none,
    card: AppElevation.card,
    raised: AppElevation.raised,
    modal: AppElevation.modal,
  ),
  cta: const AppCtaTokens(
    background: Color(0xFF0D9488),
    foreground: Colors.white,
  ),
);
```

- [ ] **Step 4: Run and confirm pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: 11 tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/theme/theme_catalog.dart flutter_app/test/theme/earnwise_theme_test.dart
git commit -m "feat(theme): add Cream theme with static-AppColors compatibility assertion"
```

---

## Task 4: Plum, Bumble, Clue themes + catalog list

**Purpose:** add the three non-Cream themes and the `kEarnWiseThemes` list in catalog order (Cream, Plum, Bumble, Clue).

**Files:**
- Modify: `flutter_app/lib/theme/theme_catalog.dart`
- Modify: `flutter_app/test/theme/earnwise_theme_test.dart`

- [ ] **Step 1: Append the failing catalog tests**

Append to `void main() { ... }` in `test/theme/earnwise_theme_test.dart`:

```dart
  group('non-Cream themes', () {
    test('Plum palette uses violet brand and white surface', () {
      expect(kPlumTheme.palette.brand, const Color(0xFF5F2EE5));
      expect(kPlumTheme.palette.surface, const Color(0xFFFFFFFF));
      expect(kPlumTheme.radii.button, AppRadiusScale.pill);
      expect(kPlumTheme.elevation.card, isEmpty);
    });

    test('Bumble forces brand ≠ CTA (yellow brand, black CTA)', () {
      expect(kBumbleTheme.palette.brand, const Color(0xFFFEDA01));
      expect(kBumbleTheme.cta.background, kBumbleTheme.palette.ink);
      expect(kBumbleTheme.cta.foreground, const Color(0xFFFFFFFF));
      expect(kBumbleTheme.radii.button, AppRadiusScale.pill);
      expect(kBumbleTheme.elevation.card, isEmpty);
    });

    test('Clue uses cool gray surface with deep teal brand', () {
      expect(kClueTheme.palette.surface, const Color(0xFFECECEC));
      expect(kClueTheme.palette.brand, const Color(0xFF0E7889));
      expect(kClueTheme.radii.card, 22);
      expect(kClueTheme.elevation.card, isEmpty);
    });
  });

  group('kEarnWiseThemes catalog', () {
    test('contains four themes in the order Cream, Plum, Bumble, Clue', () {
      expect(kEarnWiseThemes, hasLength(4));
      expect(kEarnWiseThemes[0], kCreamTheme);
      expect(kEarnWiseThemes[1], kPlumTheme);
      expect(kEarnWiseThemes[2], kBumbleTheme);
      expect(kEarnWiseThemes[3], kClueTheme);
    });
  });
```

- [ ] **Step 2: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: FAIL — `kPlumTheme` / `kBumbleTheme` / `kClueTheme` / `kEarnWiseThemes` not defined.

- [ ] **Step 3: Append the three themes and the catalog list**

Append to `flutter_app/lib/theme/theme_catalog.dart`:

```dart

/// Plum — bold violet brand on white surface, flat cards with hairline
/// borders, full-pill buttons.
const EarnWiseTheme kPlumTheme = EarnWiseTheme(
  palette: AppColorPalette(
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF4F2F7),
    surfaceSelected: Color(0xFFEFE9FE),
    ink: Color(0xFF0F1B2B),
    inkSecondary: Color(0xFF5B6470),
    inkTertiary: Color(0xFF8B92A0),
    brand: Color(0xFF5F2EE5),
    brandStrong: Color(0xFF4A1FB8),
    brandSubtle: Color(0xFFEFE9FE),
    heroBackground: Color(0xFF5F2EE5),
    heroForeground: Color(0xFFFFFFFF),
    hairline: Color(0xFFECE9F2),
  ),
  radii: AppRadiusScale(
    chip: 8,
    card: 14,
    feature: 16,
    modal: 22,
    button: AppRadiusScale.pill,
  ),
  elevation: AppElevationProfile(
    none: [],
    card: [],
    raised: [],
    modal: [],
  ),
  cta: AppCtaTokens(
    background: Color(0xFF5F2EE5),
    foreground: Color(0xFFFFFFFF),
  ),
);

/// Bumble — honey yellow brand, BLACK CTA background. This theme is the
/// reason `AppCtaTokens` is a separate object: yellow on white has no
/// contrast for a primary button, so `cta.background == ink`, not
/// `cta.background == brand`. Future contributors, please leave this
/// asymmetry in place.
const EarnWiseTheme kBumbleTheme = EarnWiseTheme(
  palette: AppColorPalette(
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF7F7F7),
    surfaceSubtle: Color(0xFFF2F2F2),
    surfaceSelected: Color(0xFFFFF6C2),
    ink: Color(0xFF1A1A1A),
    inkSecondary: Color(0xFF5C5C5C),
    inkTertiary: Color(0xFF909090),
    brand: Color(0xFFFEDA01),
    brandStrong: Color(0xFFE5C300),
    brandSubtle: Color(0xFFFFF6C2),
    heroBackground: Color(0xFFFEDA01),
    heroForeground: Color(0xFF1A1A1A),
    hairline: Color(0xFFEAEAEA),
  ),
  radii: AppRadiusScale(
    chip: 12,
    card: 18,
    feature: 20,
    modal: 24,
    button: AppRadiusScale.pill,
  ),
  elevation: AppElevationProfile(
    none: [],
    card: [],
    raised: [],
    modal: [],
  ),
  // INTENTIONAL: cta.background == palette.ink (not brand) so the CTA
  // reads as black-on-white. Yellow-on-white would be invisible.
  cta: AppCtaTokens(
    background: Color(0xFF1A1A1A),
    foreground: Color(0xFFFFFFFF),
  ),
);

/// Clue — cool gray surface with deep teal brand. Largest card radius of
/// the four themes (22); full-pill buttons.
const EarnWiseTheme kClueTheme = EarnWiseTheme(
  palette: AppColorPalette(
    surface: Color(0xFFECECEC),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFE0E0E0),
    surfaceSelected: Color(0xFFD6EFFC),
    ink: Color(0xFF0E1B2A),
    inkSecondary: Color(0xFF5B6470),
    inkTertiary: Color(0xFF8B92A0),
    brand: Color(0xFF0E7889),
    brandStrong: Color(0xFF075560),
    brandSubtle: Color(0xFFD6EFFC),
    heroBackground: Color(0xFFFFFFFF),
    heroForeground: Color(0xFF0E1B2A),
    hairline: Color(0xFFDDDDDD),
  ),
  radii: AppRadiusScale(
    chip: 12,
    card: 22,
    feature: 24,
    modal: 28,
    button: AppRadiusScale.pill,
  ),
  elevation: AppElevationProfile(
    none: [],
    card: [],
    raised: [],
    modal: [],
  ),
  cta: AppCtaTokens(
    background: Color(0xFF0E7889),
    foreground: Color(0xFFFFFFFF),
  ),
);

/// Catalog list in the order the Settings picker displays:
/// Cream (default) first, then the three in conversation order.
final List<EarnWiseTheme> kEarnWiseThemes = [
  kCreamTheme,
  kPlumTheme,
  kBumbleTheme,
  kClueTheme,
];
```

- [ ] **Step 4: Run and confirm pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/earnwise_theme_test.dart
```

Expected: 15 tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/theme/theme_catalog.dart flutter_app/test/theme/earnwise_theme_test.dart
git commit -m "feat(theme): add Plum, Bumble, Clue themes and kEarnWiseThemes catalog"
```

---

## Task 5: `AppTheme.buildMaterialTheme` + `main.dart` integration

**Purpose:** replace the static `AppTheme.theme` getter with a factory that takes an `EarnWiseTheme` and registers it on `ThemeData.extensions`. Wrap `MaterialApp` in `Consumer<AppState>` so theme swaps rebuild the app. `AppState.currentTheme` lands in Task 6 — this task temporarily passes `kCreamTheme` directly so the app boots.

**Files:**
- Modify: `flutter_app/lib/theme/app_theme.dart`
- Modify: `flutter_app/lib/main.dart`

- [ ] **Step 1: Replace the static `AppTheme.theme` getter**

In `flutter_app/lib/theme/app_theme.dart`, replace the existing `AppTheme` class (lines ~330–345) with:

```dart
class AppTheme {
  AppTheme._();

  /// Builds the live Material `ThemeData` for a given EarnWise theme.
  /// Every theme-aware widget in the tree reads `EarnWiseTheme` via
  /// `context.theme` — the rebuild path is:
  ///   AppState.setTheme → notifyListeners → Consumer<AppState> in
  ///   main.dart → MaterialApp rebuilds with a fresh ThemeData → every
  ///   `Theme.of(context)` consumer picks up the new extension.
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

Add the import at the top of `app_theme.dart`:

```dart
import 'earnwise_theme.dart';
```

- [ ] **Step 2: Update `main.dart` to build the theme from `kCreamTheme`**

Replace the body of `EarnWiseApp.build` in `flutter_app/lib/main.dart`:

```dart
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'EarnWise',
        theme: AppTheme.buildMaterialTheme(kCreamTheme),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
```

Add the import:

```dart
import 'theme/theme_catalog.dart';
```

- [ ] **Step 3: Run analyzer and tests**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze && flutter test
```

Expected: analyzer clean, all tests still pass. `AppTheme.theme` is gone but nothing referenced it — the old call site in `main.dart` just got rewritten.

- [ ] **Step 4: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/theme/app_theme.dart flutter_app/lib/main.dart
git commit -m "feat(theme): replace AppTheme.theme with buildMaterialTheme(EarnWiseTheme)"
```

---

## Task 6: `AppState.currentTheme` + live swap wiring

**Purpose:** add the theme-selection state, swap `main.dart` to read it through a `Consumer`, and prove (via test) that `setTheme` notifies listeners.

**Files:**
- Modify: `flutter_app/lib/state/app_state.dart`
- Modify: `flutter_app/lib/main.dart`
- Create: `flutter_app/test/state/app_state_theme_test.dart`

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/state/app_state_theme_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';

void main() {
  group('AppState.currentTheme', () {
    test('defaults to Cream', () {
      final state = AppState();
      expect(state.currentTheme, kCreamTheme);
    });

    test('setTheme updates the field and notifies listeners', () {
      final state = AppState();
      var notified = 0;
      state.addListener(() => notified++);

      state.setTheme(kPlumTheme);

      expect(state.currentTheme, kPlumTheme);
      expect(notified, 1);
    });

    test('setTheme is a no-op when the theme does not change', () {
      final state = AppState();
      state.setTheme(kPlumTheme); // move off the default first
      var notified = 0;
      state.addListener(() => notified++);

      state.setTheme(kPlumTheme);

      expect(notified, 0);
    });

    test('reset returns currentTheme to Cream', () {
      final state = AppState();
      state.setTheme(kBumbleTheme);

      state.reset();

      expect(state.currentTheme, kCreamTheme);
    });
  });
}
```

- [ ] **Step 2: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/state/app_state_theme_test.dart
```

Expected: FAIL — `currentTheme` / `setTheme` not defined on `AppState`.

- [ ] **Step 3: Add `currentTheme` + `setTheme` to `AppState`**

In `flutter_app/lib/state/app_state.dart`, add this import near the top:

```dart
import 'theme/theme_catalog.dart';
import 'theme/earnwise_theme.dart';
```

Wait — `app_state.dart` is at `lib/state/`, so the import paths are relative to that file. Use:

```dart
import '../theme/earnwise_theme.dart';
import '../theme/theme_catalog.dart';
```

Add these additions inside the `AppState` class body, right after `List<JourneyEntry> journeyLog = [];` (the existing last field in the opening block around line 92):

```dart
  /// Active theme. Session-only; reset by [reset]. Default is Cream so a
  /// fresh install / sign-out always lands in the original identity.
  EarnWiseTheme currentTheme = kCreamTheme;

  /// Swaps the active theme and rebuilds the app through the `Consumer`
  /// in `main.dart`. No-op when the requested theme is already active, to
  /// avoid a needless `notifyListeners()` traversal.
  void setTheme(EarnWiseTheme theme) {
    if (currentTheme == theme) return;
    currentTheme = theme;
    notifyListeners();
  }
```

- [ ] **Step 4: Extend `AppState.reset()` to reset `currentTheme`**

In the existing `reset()` method in `app_state.dart`, add this line alongside the other field resets (e.g. right after `gender = 'Female';`):

```dart
    currentTheme = kCreamTheme;
```

- [ ] **Step 5: Run the app_state test and confirm pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/state/app_state_theme_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 6: Wire `main.dart` through the Consumer**

Replace `EarnWiseApp.build` in `flutter_app/lib/main.dart` with:

```dart
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
```

The existing `import 'theme/theme_catalog.dart';` line from Task 5 can now be removed because `state.currentTheme` flows from `AppState` instead of a direct catalog reference. If removing it causes an "unused import" warning, delete it; otherwise leave it.

- [ ] **Step 7: Run the full suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze && flutter test
```

Expected: analyzer clean, all tests still pass.

- [ ] **Step 8: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/state/app_state.dart flutter_app/lib/main.dart flutter_app/test/state/app_state_theme_test.dart
git commit -m "feat(theme): wire AppState.currentTheme through Consumer in main.dart"
```

---

## Task 7: Theme test harness + migrate `Surface` (with auto-hairline)

**Purpose:** build a small test helper so subsequent widget tests can wrap a child in a `MaterialApp` with a chosen `EarnWiseTheme`. Then migrate `Surface` to resolve `color`/`radius`/`elevation` from the active theme and auto-draw a 1px `palette.hairline` border when `elevation.card` is empty AND no explicit `border` was passed. This is the load-bearing change that makes Plum's flat cards readable without editing every `Surface(...)` call site in the codebase.

**Files:**
- Create: `flutter_app/test/widgets/theme_test_harness.dart`
- Modify: `flutter_app/lib/widgets/surface.dart`
- Create: `flutter_app/test/widgets/surface_theme_test.dart`

- [ ] **Step 1: Create the theme test harness**

Create `flutter_app/test/widgets/theme_test_harness.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/theme/earnwise_theme.dart';

/// Wraps [child] in a minimal `MaterialApp` built with
/// `AppTheme.buildMaterialTheme(theme)` so widget tests can assert how a
/// widget reads from a specific `EarnWiseTheme`.
Widget wrapWithTheme(EarnWiseTheme theme, Widget child) {
  return MaterialApp(
    theme: AppTheme.buildMaterialTheme(theme),
    home: Scaffold(body: Center(child: child)),
  );
}
```

- [ ] **Step 2: Write the failing `Surface` theme test**

Create `flutter_app/test/widgets/surface_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';
import 'package:earnwise_mvp/widgets/surface.dart';
import 'theme_test_harness.dart';

BoxDecoration _decorationOf(WidgetTester tester, Key key) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byKey(key), matching: find.byType(Container)),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  const k = Key('surface-under-test');

  testWidgets('Cream Surface uses raised surface color + elevation.card',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kCreamTheme,
        Surface(key: k, child: const SizedBox(width: 80, height: 40)),
      ),
    );

    final d = _decorationOf(tester, k);
    expect(d.color, kCreamTheme.palette.surfaceRaised);
    expect(d.boxShadow, isNotEmpty);
    expect(d.border, isNull); // Cream has shadows, no auto-hairline
  });

  testWidgets('Plum Surface is flat and auto-draws the hairline border',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kPlumTheme,
        Surface(key: k, child: const SizedBox(width: 80, height: 40)),
      ),
    );

    final d = _decorationOf(tester, k);
    expect(d.color, kPlumTheme.palette.surfaceRaised);
    expect(d.boxShadow, isEmpty);
    // Auto-hairline fired because elevation.card is empty and no
    // explicit border was passed.
    final border = d.border as Border;
    expect(border.top.color, kPlumTheme.palette.hairline);
    expect(border.top.width, 1);
  });

  testWidgets('An explicit border suppresses the auto-hairline', (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kPlumTheme,
        Surface(
          key: k,
          border: Border.all(color: const Color(0xFF123456), width: 2),
          child: const SizedBox(width: 80, height: 40),
        ),
      ),
    );

    final d = _decorationOf(tester, k);
    final border = d.border as Border;
    expect(border.top.color, const Color(0xFF123456));
    expect(border.top.width, 2);
  });
}
```

- [ ] **Step 3: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/surface_theme_test.dart
```

Expected: FAIL — Cream test probably passes (default still resolves via static `AppColors`), but Plum's color/hairline assertions fail because `Surface` currently hard-codes `AppColors.surfaceRaised` / `AppElevation.card` / no border.

- [ ] **Step 4: Migrate `Surface` to read from theme + auto-hairline**

Replace the body of `flutter_app/lib/widgets/surface.dart` with:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';
import 'press_scale.dart';

/// Raised-card primitive. Defaults resolve from the active `EarnWiseTheme`
/// at build time: `palette.surfaceRaised` for color, `radii.card` for
/// radius, `elevation.card` for shadows. Any non-null constructor arg
/// overrides the theme-resolved default for that site only.
///
/// **Auto-hairline:** when the resolved `elevation.card` is empty AND the
/// caller did not pass an explicit `border`, Surface draws a 1px
/// `palette.hairline` border. This is what gives Plum's flat cards visual
/// separation without every call site having to opt in. Themes that ship
/// non-empty `elevation.card` (Cream) skip the hairline because the shadow
/// already provides the affordance.
///
/// This is **not** a selectable choice card. For the "choice card" pattern
/// (brand-subtle fill when selected, brand border), use `AppCard`.
class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? radius;
  final List<BoxShadow>? elevation;
  final Color? color;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final HapticIntensity? haptic;

  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPad),
    this.radius,
    this.elevation,
    this.color,
    this.border,
    this.onTap,
    this.haptic,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    final resolvedRadius = radius ?? t.radii.card;
    final resolvedElevation = elevation ?? t.elevation.card;
    final resolvedColor = color ?? t.palette.surfaceRaised;
    final resolvedBorder = border ??
        (resolvedElevation.isEmpty
            ? Border.all(color: t.palette.hairline, width: 1)
            : null);

    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(resolvedRadius),
        boxShadow: resolvedElevation,
        border: resolvedBorder,
      ),
      child: child,
    );
    if (onTap == null) return decorated;
    return PressScale(
      onTap: onTap,
      haptic: haptic,
      child: decorated,
    );
  }
}
```

- [ ] **Step 5: Run the Surface theme test and confirm pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/surface_theme_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 6: Run the full suite — existing `surface_test.dart` must still pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all tests pass. The existing `test/widgets/surface_test.dart` wraps `Surface` in a `MaterialApp` built by the app's `AppTheme`, which now always includes the `EarnWiseTheme` extension, so the existing assertions still hold because Cream is byte-identical to the static `AppColors`/`AppElevation` values. If the existing test instead wraps in a bare `MaterialApp` (no theme), it must be updated to use `wrapWithTheme(kCreamTheme, ...)` from the harness.

- [ ] **Step 7: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/surface.dart flutter_app/test/widgets/surface_theme_test.dart flutter_app/test/widgets/theme_test_harness.dart
git commit -m "feat(theme): Surface reads from theme + auto-hairline for flat themes"
```

---

## Task 8: Migrate `AppCard`

**Purpose:** the choice card resolves fill / border / radius / elevation from the active theme. Selected state uses `palette.surfaceSelected` + `palette.brand` border; unselected uses `palette.surfaceRaised` + `palette.hairline` border.

**Files:**
- Modify: `flutter_app/lib/widgets/app_card.dart`
- Create: `flutter_app/test/widgets/app_card_theme_test.dart`

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/widgets/app_card_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';
import 'package:earnwise_mvp/widgets/app_card.dart';
import 'theme_test_harness.dart';

BoxDecoration _decorationOf(WidgetTester tester, Key key) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byKey(key),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  const k = Key('card-under-test');

  testWidgets('Plum AppCard unselected uses surfaceRaised + hairline border',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kPlumTheme,
        AppCard(key: k, child: const SizedBox(width: 80, height: 40)),
      ),
    );

    final d = _decorationOf(tester, k);
    expect(d.color, kPlumTheme.palette.surfaceRaised);
    final border = d.border as Border;
    expect(border.top.color, kPlumTheme.palette.hairline);
  });

  testWidgets('Plum AppCard selected uses surfaceSelected + brand border',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kPlumTheme,
        AppCard(
          key: k,
          selected: true,
          child: const SizedBox(width: 80, height: 40),
        ),
      ),
    );

    final d = _decorationOf(tester, k);
    expect(d.color, kPlumTheme.palette.surfaceSelected);
    final border = d.border as Border;
    expect(border.top.color, kPlumTheme.palette.brand);
  });
}
```

- [ ] **Step 2: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/app_card_theme_test.dart
```

Expected: FAIL — current `AppCard` hardcodes `AppColors.primaryPale`/`AppColors.white`/`AppColors.primary`/`AppColors.creamDeep`.

- [ ] **Step 3: Migrate `AppCard`**

Replace the `build` method in `flutter_app/lib/widgets/app_card.dart` with:

```dart
  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    final fill = selected ? t.palette.surfaceSelected : t.palette.surfaceRaised;
    final borderColor = selected ? t.palette.brand : t.palette.hairline;
    final boxShadow = t.elevation.card;

    final decorated = AnimatedContainer(
      duration: AppDurations.short,
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(t.radii.card),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap == null) return decorated;
    return PressScale(
      onTap: onTap,
      haptic: haptic,
      child: decorated,
    );
  }
```

Add the import:

```dart
import '../theme/earnwise_theme.dart';
```

- [ ] **Step 4: Run the new and existing card tests**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/app_card_theme_test.dart test/widgets/app_card_test.dart
```

Expected: all pass. The existing `app_card_test.dart` wraps `AppCard` in the app's `MaterialApp` which now ships the Cream theme by default; Cream's hairline equals `#F2EDE6` which is exactly the former `creamDeep`, so the selected/unselected border assertions hold.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/app_card.dart flutter_app/test/widgets/app_card_theme_test.dart
git commit -m "feat(theme): AppCard resolves fill/border/radius from active theme"
```

---

## Task 9: Migrate `ScreenScaffold`

**Purpose:** the default page background becomes `context.theme.palette.surface`.

**Files:**
- Modify: `flutter_app/lib/widgets/screen_scaffold.dart`

- [ ] **Step 1: Edit `build` in `screen_scaffold.dart`**

Replace the `return Scaffold(...)` block at the end of `build` with:

```dart
    return Scaffold(
      backgroundColor: backgroundColor ?? context.theme.palette.surface,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
    );
```

Add the import:

```dart
import '../theme/earnwise_theme.dart';
```

- [ ] **Step 2: Run the full suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all tests pass. Cream's `surface` equals `AppColors.cream` exactly, so nothing shifts for existing tests.

- [ ] **Step 3: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/screen_scaffold.dart
git commit -m "feat(theme): ScreenScaffold default background reads palette.surface"
```

---

## Task 10: Migrate `VerticalTile`, `StatBubble`, `BottomSheetShell`, `SectionHeader`, `ListRow`

**Purpose:** the remaining shared widgets resolve their colors/radii from the active theme. Each one is small, so they're grouped into a single task with one commit per widget.

**Files:**
- Modify: `flutter_app/lib/widgets/vertical_tile.dart`
- Modify: `flutter_app/lib/widgets/stat_bubble.dart`
- Modify: `flutter_app/lib/widgets/bottom_sheet_shell.dart`
- Modify: `flutter_app/lib/widgets/section_header.dart`
- Modify: `flutter_app/lib/widgets/list_row.dart`

- [ ] **Step 1: Migrate `VerticalTile`**

In `flutter_app/lib/widgets/vertical_tile.dart`, replace the `content` and `surface` initialization in `build` with:

```dart
    final t = context.theme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(height: AppSpacing.inner),
        Text(
          title,
          style: AppText.bodyStrong.copyWith(color: t.palette.ink),
        ),
        const SizedBox(height: AppSpacing.tight),
        Text(
          subtitle,
          style: AppText.caption.copyWith(
            fontWeight: FontWeight.w400,
            color: t.palette.inkSecondary,
          ),
        ),
      ],
    );

    final surface = Surface(
      radius: t.radii.feature,
      onTap: disabled ? null : onTap,
      child: content,
    );
```

Add the import:

```dart
import '../theme/earnwise_theme.dart';
```

- [ ] **Step 2: Run the full suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all pass.

- [ ] **Step 3: Migrate `StatBubble`**

In `flutter_app/lib/widgets/stat_bubble.dart`, change the field default from a const `AppColors.brand` to a nullable-resolved pattern:

```dart
class StatBubble extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? accentColor;

  const StatBubble({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? context.theme.palette.brand;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: AppSpacing.tight),
        Text(value, style: AppText.statNumber),
        Text(label, style: AppText.caption),
      ],
    );
  }
}
```

Add the import:

```dart
import '../theme/earnwise_theme.dart';
```

- [ ] **Step 4: Run the full suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all pass.

- [ ] **Step 5: Migrate `BottomSheetShell`**

In `flutter_app/lib/widgets/bottom_sheet_shell.dart`, replace the `build` method with:

```dart
  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayout.gutter,
        AppSpacing.sm,
        AppLayout.gutter,
        MediaQuery.of(context).padding.bottom + AppLayout.gutter,
      ),
      decoration: BoxDecoration(
        color: t.palette.surfaceRaised,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(t.radii.modal),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: t.palette.surfaceSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
```

Add the import:

```dart
import '../theme/earnwise_theme.dart';
```

- [ ] **Step 6: Run the full suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all pass. Cream's `surfaceRaised` is white (was `AppColors.cream` before, a visible 3-byte shift), so if any existing test asserts a specific sheet background color, update it to the Cream value. Spec note: this is a deliberate correction — the old sheet used `cream` as its background, which was inconsistent with every other raised surface. Cream's new sheet background matches the rest of the cream theme. If an existing golden / test breaks, fix the test to assert `kCreamTheme.palette.surfaceRaised`, not the old `AppColors.cream`.

- [ ] **Step 7: Migrate `SectionHeader`**

In `flutter_app/lib/widgets/section_header.dart`, replace the `build` method with:

```dart
  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppText.title.copyWith(color: t.palette.ink),
              ),
            ),
            if (action != null) action!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.tight),
          Text(
            subtitle!,
            style: AppText.caption.copyWith(color: t.palette.inkSecondary),
          ),
        ],
      ],
    );
  }
```

Add the import:

```dart
import '../theme/earnwise_theme.dart';
```

- [ ] **Step 8: Migrate `ListRow`**

In `flutter_app/lib/widgets/list_row.dart`, replace the `build` method with:

```dart
  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    final effectiveTrailing = trailing ??
        Icon(
          PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
          size: 16,
          color: t.palette.inkTertiary,
        );

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        leading,
        const SizedBox(width: AppSpacing.cardPad),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppText.bodyStrong.copyWith(
                  fontWeight: FontWeight.w700,
                  color: t.palette.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.tight),
                Text(
                  subtitle!,
                  style: AppText.caption.copyWith(
                    color: t.palette.inkSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        effectiveTrailing,
      ],
    );

    final surface = Surface(
      onTap: disabled ? null : onTap,
      child: content,
    );

    if (!disabled) return surface;
    return Opacity(opacity: 0.45, child: IgnorePointer(child: surface));
  }
```

Add the import:

```dart
import '../theme/earnwise_theme.dart';
```

- [ ] **Step 9: Run the full suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze && flutter test
```

Expected: all tests pass.

- [ ] **Step 10: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/vertical_tile.dart flutter_app/lib/widgets/stat_bubble.dart flutter_app/lib/widgets/bottom_sheet_shell.dart flutter_app/lib/widgets/section_header.dart flutter_app/lib/widgets/list_row.dart
git commit -m "feat(theme): migrate VerticalTile/StatBubble/BottomSheetShell/SectionHeader/ListRow"
```

---

## Task 11: `PrimaryButton` shared widget

**Purpose:** extract the seven inline pill-button sites into a single widget that reads `cta.background`, `cta.foreground`, and `radii.button` from the active theme. Supports a `destructive: true` variant that always renders the Sign Out red regardless of theme.

**Files:**
- Create: `flutter_app/lib/widgets/primary_button.dart`
- Create: `flutter_app/test/widgets/primary_button_test.dart`

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/widgets/primary_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';
import 'package:earnwise_mvp/widgets/primary_button.dart';
import 'theme_test_harness.dart';

BoxDecoration _decorationOf(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(PrimaryButton),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('Cream CTA renders brand background with full card radius',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kCreamTheme,
        PrimaryButton(label: 'Continue', onTap: () {}),
      ),
    );
    final d = _decorationOf(tester);
    expect(d.color, kCreamTheme.palette.brand);
    expect(
      (d.borderRadius as BorderRadius).topLeft.x,
      kCreamTheme.radii.button,
    );
  });

  testWidgets('Plum CTA renders violet background with full pill radius',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kPlumTheme,
        PrimaryButton(label: 'Continue', onTap: () {}),
      ),
    );
    final d = _decorationOf(tester);
    expect(d.color, kPlumTheme.palette.brand);
    expect(
      (d.borderRadius as BorderRadius).topLeft.x,
      kPlumTheme.radii.button,
    );
  });

  testWidgets('Bumble CTA uses ink background, NOT brand', (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kBumbleTheme,
        PrimaryButton(label: 'Continue', onTap: () {}),
      ),
    );
    final d = _decorationOf(tester);
    // The brand-vs-CTA split: yellow brand but black CTA.
    expect(d.color, kBumbleTheme.palette.ink);
    expect(d.color, isNot(kBumbleTheme.palette.brand));
  });

  testWidgets('destructive=true overrides theme with Sign Out red',
      (tester) async {
    const signOutRed = Color(0xFFDC2626);
    await tester.pumpWidget(
      wrapWithTheme(
        kBumbleTheme,
        PrimaryButton(
          label: 'Sign Out',
          onTap: () {},
          destructive: true,
        ),
      ),
    );
    final d = _decorationOf(tester);
    expect(d.color, signOutRed);
  });

  testWidgets('onTap fires when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrapWithTheme(
        kCreamTheme,
        PrimaryButton(label: 'Continue', onTap: () => taps++),
      ),
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/primary_button_test.dart
```

Expected: FAIL — `primary_button.dart` does not exist.

- [ ] **Step 3: Create `PrimaryButton`**

Create `flutter_app/lib/widgets/primary_button.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';
import 'press_scale.dart';

/// Destructive red used by Sign Out and every other `destructive: true`
/// usage. Deliberately hardcoded — destructive UI does not change color
/// across themes. Mirrors the `_kSignOutRed` that used to live inline on
/// `profile_screen.dart`.
const Color kDestructiveRed = Color(0xFFDC2626);

/// Shared primary CTA. Full-width by default, 60 px tall, reads colors
/// and radius from the active `EarnWiseTheme.cta` + `radii.button`.
///
/// Pass `destructive: true` for the Sign Out button and any future
/// destructive confirm — this overrides the theme-resolved background
/// with `kDestructiveRed` regardless of which theme is active.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool destructive;
  final IconData? leadingIcon;
  final HapticIntensity haptic;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.leadingIcon,
    this.haptic = HapticIntensity.confirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    final background = destructive ? kDestructiveRed : t.cta.background;
    final foreground = destructive ? Colors.white : t.cta.foreground;
    final radius = t.radii.button;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 22, color: foreground),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          label,
          style: AppText.ctaLabel.copyWith(color: foreground),
        ),
      ],
    );

    return PressScale(
      onTap: onTap,
      haptic: haptic,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}
```

- [ ] **Step 4: Run and confirm pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/primary_button_test.dart
```

Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/primary_button.dart flutter_app/test/widgets/primary_button_test.dart
git commit -m "feat(theme): add PrimaryButton (theme-aware CTA with destructive variant)"
```

---

## Task 12: Migrate inline pill buttons to `PrimaryButton`

**Purpose:** replace the seven inline `PressScale + Container(height: 60, decoration: BoxDecoration(...))` sites with `PrimaryButton(...)`. Each step is a single-file replacement.

**Files:**
- Modify: `flutter_app/lib/screens/welcome_screen.dart`
- Modify: `flutter_app/lib/screens/onboarding_screen.dart`
- Modify: `flutter_app/lib/screens/trust_carousel_screen.dart`
- Modify: `flutter_app/lib/screens/game_detail_screen.dart`
- Modify: `flutter_app/lib/screens/wallet_screen.dart`
- Modify: `flutter_app/lib/screens/profile_screen.dart`

Each of these sub-steps follows the same pattern: find the inline button, replace with `PrimaryButton(label: ..., onTap: ...)`. The layout dimensions (60 height, full width) match today's inline buttons exactly, so no surrounding code needs to change. Add `import '../widgets/primary_button.dart';` to each modified file.

- [ ] **Step 1: Welcome screen**

Open `flutter_app/lib/screens/welcome_screen.dart`. Find the `PressScale(...)` wrapping a `Container(height: 60, ...)` (the "Get started" CTA) and replace it with:

```dart
PrimaryButton(
  label: 'Get started',
  onTap: () => Navigator.of(context).push(
    fadeRoute(const OnboardingScreen()),
  ),
),
```

(Preserve whatever existing navigation target the welcome CTA has — the line above is the most common shape. If the existing handler differs, keep that logic in the closure.)

Add the import `import '../widgets/primary_button.dart';` at the top.

- [ ] **Step 2: Run the suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all pass.

- [ ] **Step 3: Onboarding screen**

Open `flutter_app/lib/screens/onboarding_screen.dart`. Each inline pill CTA inside this screen (Continue / Pick games / whatever other primary confirms it uses) becomes:

```dart
PrimaryButton(
  label: 'Continue',
  onTap: onContinuePressed,
),
```

Replace the `String` label and `onTap` handler to match what the existing inline `Container` was wrapping. Keep the existing onTap closures verbatim — copy them out, build the `PrimaryButton`, and delete the old inline `PressScale`/`Container` block.

Add the import.

- [ ] **Step 4: Run the suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all pass.

- [ ] **Step 5: Trust carousel screen**

Open `flutter_app/lib/screens/trust_carousel_screen.dart`. Replace the inline "Got it" pill button with:

```dart
PrimaryButton(
  label: 'Got it',
  onTap: onGotItPressed,
),
```

Preserve the existing handler. Add the import.

- [ ] **Step 6: Run the suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all pass.

- [ ] **Step 7: Game detail screen**

Open `flutter_app/lib/screens/game_detail_screen.dart`. The inline CTA that currently reads "Play" / "Continue playing" becomes:

```dart
PrimaryButton(
  label: ctaLabel,       // whatever the existing label computation produces
  onTap: onPlayPressed,
),
```

Preserve the existing `ctaLabel` / `onPlayPressed` computation — copy them verbatim. Add the import.

- [ ] **Step 8: Run the suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all pass. Watch for `test/screens/game_detail_screen_test.dart` — if it asserts a specific child `Container` for the CTA, update it to `find.byType(PrimaryButton)`.

- [ ] **Step 9: Wallet screen**

Open `flutter_app/lib/screens/wallet_screen.dart`. Find the inline `PressScale` wrapping the "Cash out" / "Finish your starter tasks" CTA (the match I scouted at lines ~280–290). Replace with:

```dart
PrimaryButton(
  label: 'Cash out',
  onTap: widget.onNavigateHome,
),
```

Preserve the exact label string and handler that the existing inline button uses. Add the import.

- [ ] **Step 10: Run the suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all pass.

- [ ] **Step 11: Profile screen Sign Out (destructive variant)**

Open `flutter_app/lib/screens/profile_screen.dart`. Replace the entire `_SignOutButton` widget's `build` method with:

```dart
  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      key: const Key('profile_sign_out'),
      label: 'Sign Out',
      destructive: true,
      haptic: HapticIntensity.warning,
      onTap: () {
        context.read<AppState>().reset();
        Navigator.of(context).pushAndRemoveUntil(
          fadeRoute(const WelcomeScreen()),
          (route) => false,
        );
      },
    );
  }
```

Delete the now-unused `_kSignOutRed` constant at the bottom of the file — its responsibility has moved into `PrimaryButton.kDestructiveRed`.

Add the import `import '../widgets/primary_button.dart';` at the top.

- [ ] **Step 12: Run the suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze && flutter test
```

Expected: analyzer clean, all tests pass. If `test/screens/profile_screen_test.dart` asserts on the inline `Container` of the old sign-out button, update it to `find.byKey(const Key('profile_sign_out'))` + `find.byType(PrimaryButton)`.

- [ ] **Step 13: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/screens/welcome_screen.dart flutter_app/lib/screens/onboarding_screen.dart flutter_app/lib/screens/trust_carousel_screen.dart flutter_app/lib/screens/game_detail_screen.dart flutter_app/lib/screens/wallet_screen.dart flutter_app/lib/screens/profile_screen.dart
git commit -m "refactor(theme): migrate seven inline pill buttons to PrimaryButton"
```

---

## Task 13: Migrate `home_screen.dart` to theme

**Purpose:** every direct `AppColors.*` / `AppRadius.*` / `AppElevation.*` reference in `home_screen.dart` is replaced with a `context.theme.*` read. This is the largest file in the migration; walk through it section by section.

**Files:**
- Modify: `flutter_app/lib/screens/home_screen.dart`

- [ ] **Step 1: Cache `final t = context.theme;` at the top of each relevant `build` method**

Open `flutter_app/lib/screens/home_screen.dart`. For every `Widget build(BuildContext context)` that references an `AppColors`/`AppRadius`/`AppElevation` value, add a `final t = context.theme;` line as the first statement in the method body. Add `import '../theme/earnwise_theme.dart';` if it is not already present.

- [ ] **Step 2: Replace `AppColors.ink` / `AppColors.primary` / `AppColors.surface`-family references**

Sweep the file and replace:

| Old | New |
|---|---|
| `AppColors.ink` | `t.palette.ink` |
| `AppColors.inkSecondary` | `t.palette.inkSecondary` |
| `AppColors.inkTertiary` | `t.palette.inkTertiary` |
| `AppColors.brand` (and `AppColors.primary`) | `t.palette.brand` |
| `AppColors.brandStrong` (and `AppColors.primaryDark`) | `t.palette.brandStrong` |
| `AppColors.brandSubtle` (and `AppColors.primaryPale`) | `t.palette.brandSubtle` |
| `AppColors.surface` (and `AppColors.cream`) | `t.palette.surface` |
| `AppColors.surfaceRaised` (and `AppColors.white`) | `t.palette.surfaceRaised` |
| `AppColors.surfaceSubtle` (and `AppColors.creamDeep`) | `t.palette.surfaceSubtle` |
| `AppColors.surfaceSelected` | `t.palette.surfaceSelected` |
| `AppRadius.card` | `t.radii.card` |
| `AppRadius.feature` | `t.radii.feature` |
| `AppRadius.modal` | `t.radii.modal` |
| `AppElevation.card` | `t.elevation.card` |
| `AppElevation.raised` | `t.elevation.raised` |
| `AppElevation.modal` | `t.elevation.modal` |

**Do NOT replace** any `AppColors.category*`, `AppColors.success`, `AppColors.flame*`, `AppColors.gold`, `AppColors.accent`, `AppColors.tealRing`, `AppColors.violetRing`, `AppColors.ringTrack`, `AppSpacing.*`, `AppText.*`, `AppLayout.*`, or the ring-related constants in `AppState.goals`. Those are theme-invariant or explicitly not in scope.

If a given `build` method is a `const` constructor path and cannot reach `context` (e.g. a sub-widget that takes no `BuildContext`), restructure it to a non-const `StatelessWidget` build — or pass the needed color/radius as constructor arguments — rather than leaving a direct `AppColors.*` reference.

- [ ] **Step 3: Run the suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze && flutter test
```

Expected: analyzer clean, all tests pass. If `test/screens/post_onboarding_home_test.dart` asserts on a specific color, it either continues to pass (Cream matches static) or needs a `kCreamTheme.palette.*` update.

- [ ] **Step 4: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/screens/home_screen.dart
git commit -m "refactor(theme): home_screen reads palette/radii/elevation from context.theme"
```

---

## Task 14: Migrate `home_shell.dart` to theme

**Purpose:** the bottom-nav pill and its active-tab tint read from the active theme.

**Files:**
- Modify: `flutter_app/lib/screens/home_shell.dart`

- [ ] **Step 1: Edit the file**

Open `flutter_app/lib/screens/home_shell.dart`. Apply the same replacement table as Task 13, Step 2 to every `AppColors.*` / `AppRadius.*` / `AppElevation.*` reference in the file (~5 sites per the Grep count). Add `import '../theme/earnwise_theme.dart';` and cache `final t = context.theme;` at the top of every relevant `build`.

- [ ] **Step 2: Run the suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze && flutter test
```

Expected: all pass.

- [ ] **Step 3: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/screens/home_shell.dart
git commit -m "refactor(theme): home_shell reads palette/radii from context.theme"
```

---

## Task 15: Migrate `profile_screen.dart` to theme

**Purpose:** migrate every non-Sign-Out `AppColors.*` reference on the profile screen (avatar glow, info card chrome, account card chrome, section headings, row dividers). The Sign Out red is already handled by `PrimaryButton(destructive: true)` from Task 12.

**Files:**
- Modify: `flutter_app/lib/screens/profile_screen.dart`

- [ ] **Step 1: Edit the file**

Apply the same replacement table as Task 13, Step 2 to every `AppColors.*` / `AppRadius.*` / `AppElevation.*` reference in `profile_screen.dart`. Specific spots to watch:

- `_AvatarCircle` uses `AppColors.primary` for both the glow radial gradient and the solid avatar face — replace with `t.palette.brand` via a `context.theme` read in that widget's `build`.
- `_InfoCard` and `_AccountCard` use inline `Container` with `AppColors.white` / `AppColors.creamDeep` — replace with `t.palette.surfaceRaised` / `t.palette.hairline`. The hardcoded `18` radius and inline shadow stay as-is in this pass unless you want to also drop them onto `t.radii.card` / `t.elevation.card` (recommended — replace `BorderRadius.circular(18)` with `BorderRadius.circular(t.radii.card)` and the inline shadow with `boxShadow: t.elevation.card`).
- `_InfoRow` uses `AppColors.primary.withValues(alpha: 0.12)` for the icon tile background and `AppColors.primary` for the icon color — replace with `t.palette.brand`.
- `_InfoRow` trailing pencil and `_AccountRow` trailing lock use `AppColors.inkTertiary` — replace.
- `_RowDivider` uses `AppColors.creamDeep` — replace with `t.palette.hairline`. Note: this requires `_RowDivider.build` to read `context`, so remove `const` from the constructor if needed.

Add `import '../theme/earnwise_theme.dart';` if not already present.

- [ ] **Step 2: Run the suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze && flutter test
```

Expected: all pass.

- [ ] **Step 3: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/screens/profile_screen.dart
git commit -m "refactor(theme): profile_screen reads palette/radii/elevation from context.theme"
```

---

## Task 16: `SettingsScreen` + `_ThemeRow`

**Purpose:** the new Theme picker. `SettingsScreen` renders a subtitle + one `_ThemeRow` per entry in `kEarnWiseThemes`. Each row has a corner-split swatch (representing the theme being chosen, not the active theme), a title, a subtitle, and a radio dot. Tapping a row calls `context.read<AppState>().setTheme(...)`, which lives-swaps the whole app via the `Consumer` in `main.dart`.

**Files:**
- Create: `flutter_app/lib/screens/settings_screen.dart`
- Create: `flutter_app/test/screens/settings_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/screens/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/settings_screen.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';

Widget _boot(AppState state) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: Consumer<AppState>(
      builder: (context, s, _) => MaterialApp(
        theme: AppTheme.buildMaterialTheme(s.currentTheme),
        home: const SettingsScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders four rows in Cream, Plum, Bumble, Clue order',
      (tester) async {
    final state = AppState();
    await tester.pumpWidget(_boot(state));

    expect(find.text('Cream'), findsOneWidget);
    expect(find.text('Plum'), findsOneWidget);
    expect(find.text('Bumble'), findsOneWidget);
    expect(find.text('Clue'), findsOneWidget);

    // Row order: find the ListView / Column children by their titles in order
    final titles = tester
        .widgetList<Text>(find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Text),
        ))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    final creamIdx = titles.indexOf('Cream');
    final plumIdx = titles.indexOf('Plum');
    final bumbleIdx = titles.indexOf('Bumble');
    final clueIdx = titles.indexOf('Clue');
    expect(creamIdx, lessThan(plumIdx));
    expect(plumIdx, lessThan(bumbleIdx));
    expect(bumbleIdx, lessThan(clueIdx));
  });

  testWidgets('tapping Plum row calls setTheme(kPlumTheme)', (tester) async {
    final state = AppState();
    await tester.pumpWidget(_boot(state));

    expect(state.currentTheme, kCreamTheme);

    await tester.tap(find.text('Plum'));
    await tester.pumpAndSettle();

    expect(state.currentTheme, kPlumTheme);
  });

  testWidgets('after tap, Scaffold.backgroundColor reflects the new theme',
      (tester) async {
    final state = AppState();
    await tester.pumpWidget(_boot(state));

    await tester.tap(find.text('Plum'));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, kPlumTheme.palette.surface);
  });
}
```

- [ ] **Step 2: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/screens/settings_screen_test.dart
```

Expected: FAIL — `settings_screen.dart` does not exist.

- [ ] **Step 3: Create `SettingsScreen`**

Create `flutter_app/lib/screens/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';
import '../theme/theme_catalog.dart';
import '../widgets/press_scale.dart';
import '../widgets/screen_scaffold.dart';

/// Theme picker. Reachable from the gear icon on `ProfileScreen`. Lists
/// every theme in `kEarnWiseThemes`; tapping a row calls
/// `AppState.setTheme` which rebuilds the whole app through the
/// `Consumer<AppState>` in `main.dart`.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _rowSubtitles = {
    'Cream': 'Warm and soft. The original.',
    'Plum': 'Bold violet, white surface.',
    'Bumble': 'Honey yellow with black accents.',
    'Clue': 'Calm gray with deep teal.',
  };

  static const _rowNames = {
    0: 'Cream',
    1: 'Plum',
    2: 'Bumble',
    3: 'Clue',
  };

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      child: Consumer<AppState>(
        builder: (context, state, _) {
          final t = context.theme;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.pageTop),
                _Header(onBack: () => Navigator.of(context).maybePop()),
                const SizedBox(height: AppSpacing.sectionGap),
                Text(
                  'Theme',
                  style: AppText.title.copyWith(color: t.palette.ink),
                ),
                const SizedBox(height: AppSpacing.tight),
                Text(
                  "Pick how EarnWise looks. The change happens instantly.",
                  style: AppText.body.copyWith(color: t.palette.inkSecondary),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                for (var i = 0; i < kEarnWiseThemes.length; i++) ...[
                  _ThemeRow(
                    name: _rowNames[i]!,
                    subtitle: _rowSubtitles[_rowNames[i]!]!,
                    theme: kEarnWiseThemes[i],
                    selected: state.currentTheme == kEarnWiseThemes[i],
                  ),
                  if (i < kEarnWiseThemes.length - 1)
                    const SizedBox(height: AppSpacing.rowGap),
                ],
                const SizedBox(height: AppSpacing.blockGap),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Row(
      children: [
        PressScale(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: t.palette.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(color: t.palette.hairline),
            ),
            child: Icon(
              PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
              size: 18,
              color: t.palette.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final EarnWiseTheme theme;
  final bool selected;

  const _ThemeRow({
    required this.name,
    required this.subtitle,
    required this.theme,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final active = context.theme;
    final radius = active.radii.card;
    final fill =
        selected ? active.palette.surfaceSelected : active.palette.surfaceRaised;
    final borderColor =
        selected ? active.palette.brand : active.palette.hairline;

    return PressScale(
      haptic: HapticIntensity.tick,
      onTap: () => context.read<AppState>().setTheme(theme),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPad,
          vertical: AppSpacing.cardPad,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: active.elevation.card,
        ),
        child: Row(
          children: [
            _CornerSplitSwatch(
              topLeft: theme.palette.surface,
              bottomRight: theme.palette.brand,
            ),
            const SizedBox(width: AppSpacing.cardPad),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppText.listItem.copyWith(color: active.palette.ink),
                  ),
                  const SizedBox(height: AppSpacing.tight),
                  Text(
                    subtitle,
                    style: AppText.body
                        .copyWith(color: active.palette.inkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _CornerSplitSwatch extends StatelessWidget {
  final Color topLeft;
  final Color bottomRight;

  const _CornerSplitSwatch({
    required this.topLeft,
    required this.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CustomPaint(
          painter: _SplitPainter(topLeft: topLeft, bottomRight: bottomRight),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SplitPainter extends CustomPainter {
  final Color topLeft;
  final Color bottomRight;

  _SplitPainter({required this.topLeft, required this.bottomRight});

  @override
  void paint(Canvas canvas, Size size) {
    final tlPaint = Paint()..color = topLeft;
    final brPaint = Paint()..color = bottomRight;
    canvas.drawRect(Offset.zero & size, tlPaint);
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, brPaint);
  }

  @override
  bool shouldRepaint(covariant _SplitPainter oldDelegate) =>
      oldDelegate.topLeft != topLeft || oldDelegate.bottomRight != bottomRight;
}

class _RadioDot extends StatelessWidget {
  final bool selected;

  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? t.palette.brand : Colors.transparent,
        border: Border.all(
          color: selected ? t.palette.brand : t.palette.inkTertiary,
          width: 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}
```

- [ ] **Step 4: Run the new test and confirm pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/screens/settings_screen_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/screens/settings_screen.dart flutter_app/test/screens/settings_screen_test.dart
git commit -m "feat(settings): add SettingsScreen with four-row theme picker"
```

---

## Task 17: Wire the gear icon → `SettingsScreen`

**Purpose:** the profile gear icon (currently `onTap: () {}`) pushes `SettingsScreen` via `fadeRoute`.

**Files:**
- Modify: `flutter_app/lib/screens/profile_screen.dart`
- Modify: `flutter_app/test/screens/profile_screen_test.dart` (or create if it does not already exist)

- [ ] **Step 1: Write the failing test**

Append to `flutter_app/test/screens/profile_screen_test.dart` (create the file if it does not exist — in that case, make the `main()` wrap everything):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/profile_screen.dart';
import 'package:earnwise_mvp/screens/settings_screen.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';

void main() {
  testWidgets('tapping the gear icon pushes SettingsScreen', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: Consumer<AppState>(
          builder: (context, s, _) => MaterialApp(
            theme: AppTheme.buildMaterialTheme(s.currentTheme),
            home: const ProfileScreen(),
          ),
        ),
      ),
    );

    expect(find.byType(SettingsScreen), findsNothing);

    // The gear icon is the only PressScale in the top row of ProfileScreen;
    // find it by the phosphor icon it contains.
    await tester.tap(find.byIcon(
      // The constant expression below resolves at build; using the
      // runtime helper keeps the test robust.
      const IconDataFallback(),
    ).first);
    // If the line above fails to locate the icon, fall back to finding
    // the first PressScale in the top-row Row.
  });
}

/// Sentinel IconData used only as a search token — never rendered.
class IconDataFallback extends IconData {
  const IconDataFallback() : super(0);
}
```

If `find.byIcon(const IconDataFallback())` does not work in your local Flutter version, use this alternative finder approach instead (which is more robust): locate the gear button by a `Key` on the PressScale. In that case, add `key: const Key('profile_gear')` to the gear icon's `PressScale` in `profile_screen.dart` and replace the `tester.tap` line with:

```dart
    await tester.tap(find.byKey(const Key('profile_gear')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
```

Prefer the `Key`-based approach — it is the clean version of this test. Add the Key to the gear icon in Step 3 below.

- [ ] **Step 2: Run and confirm failure**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/screens/profile_screen_test.dart
```

Expected: FAIL — `SettingsScreen` is not pushed because the gear icon still has an empty `onTap`.

- [ ] **Step 3: Wire the gear icon**

In `flutter_app/lib/screens/profile_screen.dart`, find the `PressScale` wrapping the gear icon (around line 52, the one with `onTap: () {}`) and replace it with:

```dart
PressScale(
  key: const Key('profile_gear'),
  onTap: () => Navigator.of(context).push(
    fadeRoute(const SettingsScreen()),
  ),
  child: Container(
    // ... existing Container chrome unchanged
  ),
),
```

Add the import:

```dart
import 'settings_screen.dart';
```

- [ ] **Step 4: Run the suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all tests pass including the new gear-icon test.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/screens/profile_screen.dart flutter_app/test/screens/profile_screen_test.dart
git commit -m "feat(settings): wire profile gear icon to SettingsScreen"
```

---

## Task 18: Final verification

**Purpose:** run the full suite + analyzer + a quick manual smoke test to confirm the feature is wired end-to-end.

**Files:** none modified.

- [ ] **Step 1: Full analyzer and test pass**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze && flutter test
```

Expected: "No issues found!" from analyzer; all tests pass. Compare the green count against the Task 0 baseline: it must equal the baseline count plus the new tests added by this plan (15 theme tests + 3 Surface theme tests + 2 AppCard theme tests + 5 PrimaryButton tests + 3 SettingsScreen tests + 4 AppState theme tests + 1 profile gear-icon test = +33).

- [ ] **Step 2: Manual smoke test**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter run
```

Walk through the app:

1. Complete onboarding.
2. From Home, tap the Profile tab.
3. Tap the gear icon in the top-right of the profile screen.
4. Expect the Settings screen to appear with four rows: Cream (selected), Plum, Bumble, Clue.
5. Tap Plum. Expect: the whole app (Home, Profile, Settings) re-colors to violet on white surface with flat pill-shaped buttons. The Plum row's radio dot fills in; the Cream row's radio dot empties.
6. Tap Bumble. Expect: the primary CTA on the Sign Out / Cash Out / Continue / Play surfaces renders with a BLACK background (not yellow) — this is the brand-vs-CTA split.
7. Tap Clue. Expect: gray page background, deep-teal brand, largest card radius.
8. Tap Cream. Expect: the app returns to its original identity pixel-for-pixel.
9. From Profile, tap Sign Out. Expect: the destructive red is the same red in every theme (confirms `destructive: true` overrides `cta.*`). After sign-out, the app lands on Welcome; tapping the gear icon again would show Cream selected (reset ran).

If any of those steps is visibly wrong, stop and debug before closing out the plan.

- [ ] **Step 3: No commit**

This task is verification only. Nothing to commit.

---

## Self-review notes (from the planner)

**Spec coverage check:**
- §1 Token model → Tasks 1, 2
- §2 Theme catalog → Tasks 3, 4
- §3 State wiring + Material integration → Tasks 5, 6
- §4 Component migration → Tasks 7, 8, 9, 10, 11, 12
- §4.3 Screens migrated for v1 → Tasks 13 (home), 14 (home_shell), 15 (profile), 16 (settings)
- §5 Settings screen → Task 16
- §5.1 Entry point (gear icon wire-up) → Task 17
- §6 Test plan → Tasks 1–17 (per-task unit / widget tests) + Task 18 (manual visual)
- §8 Risks (unmigrated screens correct in Cream) → enforced by the compatibility assertion in Task 3

**Type consistency check:**
- `EarnWiseTheme.palette / radii / elevation / cta` — same names used in every task.
- `kCreamTheme / kPlumTheme / kBumbleTheme / kClueTheme / kEarnWiseThemes` — consistent naming.
- `AppTheme.buildMaterialTheme(EarnWiseTheme t)` — consistent signature.
- `context.theme` extension — consistent usage everywhere.
- `PrimaryButton(label, onTap, destructive?, leadingIcon?, haptic?)` — consistent constructor across Task 11 and Task 12 call sites.
- `kDestructiveRed` — single source of truth for destructive red, referenced in PrimaryButton + profile_screen.
