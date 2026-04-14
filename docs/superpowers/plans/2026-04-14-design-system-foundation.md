# Design System Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the design-system foundation for the Flutter app: a two-tier token layer (primitive + semantic), six reusable components (Surface, ListRow, VerticalTile, SectionHeader, StatBubble, CategoryIconSquare), a canonical `docs/design-system.md` reference, and a `CLAUDE.md` hook so the reference is loaded on every UI task. No screens are modified in this sub-project.

**Architecture:** All new tokens live in `lib/theme/app_theme.dart` alongside the existing `AppColors`/`AppSpacing`/`AppLayout` classes. New semantic names are added; existing names stay at their current values, with obviously-obsolete task-tint names marked `@deprecated`. Six new widget files land in `lib/widgets/`, each with its own unit test in `test/widgets/`. The spec document this plan is built from is at `docs/superpowers/specs/2026-04-14-design-system-foundation-design.md`.

**Tech Stack:** Flutter 3.x, Dart, Material 3, `google_fonts`, `phosphor_flutter`, `flutter_test`. The package name is `earnwise_mvp`; imports use `package:earnwise_mvp/…`.

---

## File Structure

**Modified:**
- `flutter_app/lib/theme/app_theme.dart`: adds private primitive consts, new semantic tokens on `AppSpacing` (`tight`, `inner`, `rowGap`, `cardPad`, `titleGap`, `sectionGap`, `pageGutter`, `blockGap`, `heroGap`, `pageTop`), new `AppRadius` and `AppElevation` classes, new semantic colors (`surface`, `surfaceRaised`, `surfaceSelected`, `surfaceSubtle`, `inkInverse`, `brand`, `brandSubtle`, `brandStrong`, `success`, six `category*` pairs). Task-tint names (`taskGame`, `taskSurvey`, etc.) get `@Deprecated` annotations forwarding to `category*`. Existing raw names like `primary`, `cream`, `creamDeep`, `white` also pick up `@Deprecated` annotations forwarding to their new semantic homes. Ambiguous old names (`tealSecondary`, `primaryLight`, `progress`, `accent`, `flame`, `gold`, `ringTrack`, etc.) stay undeprecated.
- `flutter_app/lib/theme/app_text.dart`: adds `AppText.title` (22 / 700), marks `sectionTitle` and `sheetTitle` as `@Deprecated` forwarders.
- `flutter_app/lib/widgets/app_card.dart`: swaps the hardcoded `BorderRadius.circular(18)` for `BorderRadius.circular(AppRadius.card)` (which equals 16). Only visible pixel shift in the whole sub-project.
- `CLAUDE.md`: adds a new `# Design System` section at the very top of the file (above `# Presenter`) that points to `docs/design-system.md` as a mandatory read for any Flutter UI task.

**Created:**
- `flutter_app/lib/widgets/surface.dart`: raised-card primitive.
- `flutter_app/lib/widgets/category_icon_square.dart`: the colored rounded icon tile.
- `flutter_app/lib/widgets/list_row.dart`: horizontal icon + title + subtitle + trailing list item.
- `flutter_app/lib/widgets/vertical_tile.dart`: icon-on-top tile for trio patterns.
- `flutter_app/lib/widgets/section_header.dart`: section title / optional subtitle / optional action.
- `flutter_app/lib/widgets/stat_bubble.dart`: stat indicator with icon, pre-formatted value, label.
- `flutter_app/test/theme/theme_tokens_test.dart`: invariant checks over the semantic spacing and radius scales.
- `flutter_app/test/widgets/surface_test.dart`
- `flutter_app/test/widgets/category_icon_square_test.dart`
- `flutter_app/test/widgets/list_row_test.dart`
- `flutter_app/test/widgets/vertical_tile_test.dart`
- `flutter_app/test/widgets/section_header_test.dart`
- `flutter_app/test/widgets/stat_bubble_test.dart`
- `docs/design-system.md`: canonical reference, linked from CLAUDE.md.

**Untouched:** everything else in `lib/screens/`, `lib/widgets/` (except `app_card.dart`), and `lib/theme/motion.dart`. No screen migrations happen in this sub-project.

---

## Task 0: Baseline verification

**Purpose:** confirm the test suite is green before any changes, so subsequent failures are attributable to this work.

**Files:** none modified.

- [ ] **Step 1: Run the full test suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: all tests pass (exact count will vary; the prior session reported 52 screen tests green).

- [ ] **Step 2: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze
```

Expected: "No issues found!" (or the same pre-existing info messages as before; no warnings or errors).

- [ ] **Step 3: Capture the green count**

Note the reported test count from Step 1 somewhere (e.g., a scratch note). This is the number Task 13 must match.

No commit. If either step fails, stop and debug before touching any other file.

---

## Task 1: Spacing, radius, and elevation tokens (+ invariant test)

**Purpose:** add the semantic spacing/radius/elevation tokens the components and (eventually) screens will reference. Test-first: an invariant test for the scales drives the shape of the rewrite.

**Files:**
- Create: `flutter_app/test/theme/theme_tokens_test.dart`
- Modify: `flutter_app/lib/theme/app_theme.dart`

- [ ] **Step 1: Write the failing invariant test**

Create `flutter_app/test/theme/theme_tokens_test.dart` with this exact content:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';

void main() {
  group('AppSpacing invariants', () {
    test('every semantic value is a multiple of 4 or is the tight exception',
        () {
      final entries = <String, double>{
        'tight': AppSpacing.tight,
        'xs': AppSpacing.xs,
        'sm': AppSpacing.sm,
        'inner': AppSpacing.inner,
        'rowGap': AppSpacing.rowGap,
        'cardPad': AppSpacing.cardPad,
        'titleGap': AppSpacing.titleGap,
        'sectionGap': AppSpacing.sectionGap,
        'pageGutter': AppSpacing.pageGutter,
        'blockGap': AppSpacing.blockGap,
        'heroGap': AppSpacing.heroGap,
        'pageTop': AppSpacing.pageTop,
      };
      for (final e in entries.entries) {
        final v = e.value;
        final isTight = e.key == 'tight' && v == 2;
        final isOnGrid = v % 4 == 0;
        expect(isTight || isOnGrid, isTrue,
            reason: 'AppSpacing.${e.key} = $v is off-grid');
      }
    });

    test('deprecated aliases preserve their original values', () {
      // Intentional: back-compat for existing screen code. New code
      // should use the semantic names above.
      // ignore: deprecated_member_use_from_same_package
      expect(AppSpacing.md, 16);
      // ignore: deprecated_member_use_from_same_package
      expect(AppSpacing.lg, 24);
      // ignore: deprecated_member_use_from_same_package
      expect(AppSpacing.xl, 32);
    });
  });

  group('AppRadius invariants', () {
    test('every value is in the allowed set', () {
      const allowed = {0.0, 8.0, 12.0, 16.0, 20.0, 24.0, 9999.0};
      final entries = <String, double>{
        'chip': AppRadius.chip,
        'card': AppRadius.card,
        'feature': AppRadius.feature,
        'modal': AppRadius.modal,
        'pill': AppRadius.pill,
      };
      for (final e in entries.entries) {
        expect(allowed.contains(e.value), isTrue,
            reason: 'AppRadius.${e.key} = ${e.value} is not in the '
                'allowed radius set');
      }
    });
  });

  group('AppElevation', () {
    test('card shadow is a single subtle drop', () {
      expect(AppElevation.card.length, 1);
      final shadow = AppElevation.card.single;
      expect(shadow.offset, const Offset(0, 2));
      expect(shadow.blurRadius, 8);
    });

    test('none is an empty list', () {
      expect(AppElevation.none, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails at compile**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/theme_tokens_test.dart
```

Expected: failure, since `AppSpacing.tight`, `AppSpacing.inner`, `AppRadius`, and `AppElevation` do not exist yet. The exact error will mention "undefined name" or "undefined getter" for those symbols.

- [ ] **Step 3: Rewrite `lib/theme/app_theme.dart`**

Replace the file contents with this. Note that `AppColors` is kept exactly as-is in this task (colors are Task 2). Only the spacing, radius, and elevation classes are touched here, plus the imports at the top of the file.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Design system primitives (private).
//
// These are the raw values the semantic layer below consumes. They are
// intentionally not a public class: the semantic layer is the only entry
// point screens and components should reference. Keeping these private
// also sidesteps the name collision between a hypothetical top-level
// `Radius` class and `dart:ui`'s built-in `Radius`.
// ---------------------------------------------------------------------------

const double _s2 = 2;
const double _s4 = 4;
const double _s8 = 8;
const double _s12 = 12;
const double _s16 = 16;
const double _s20 = 20;
const double _s24 = 24;
const double _s32 = 32;
const double _s40 = 40;
const double _s48 = 48;

const double _r0 = 0;
const double _r8 = 8;
const double _r12 = 12;
const double _r16 = 16;
const double _r20 = 20;
const double _r24 = 24;
const double _rFull = 9999;

// ---------------------------------------------------------------------------
// AppColors
//
// TODO(design-system): this class is rewritten to semantic tokens in the
// next task in the same sub-project. For now it ships unchanged.
// ---------------------------------------------------------------------------

class AppColors {
  static const cream = Color(0xFFFAF8F5);
  static const creamDeep = Color(0xFFF2EDE6);
  static const creamWarm = Color(0xFFF8F3EC);

  // Primary: Teal
  static const primary = Color(0xFF0D9488);
  static const primaryLight = Color(0xFFCCFBF1);
  static const primaryPale = Color(0xFFF0FDFA);
  static const primaryDark = Color(0xFF0F766E);

  // Accent: Warm gold
  static const accent = Color(0xFFF59E0B);
  static const accentLight = Color(0xFFFEF3C7);
  static const secondary = Color(0xFF14B8A6);
  static const secondaryLight = Color(0xFFCCFBF1);

  // Task colors
  static const taskVideo = Color(0xFFEC4899);
  static const taskVideoBg = Color(0xFFFDF2F8);
  static const taskSurvey = Color(0xFF6366F1);
  static const taskSurveyBg = Color(0xFFEEF2FF);
  static const taskGame = Color(0xFFF97316);
  static const taskGameBg = Color(0xFFFFF7ED);
  static const taskCheckin = Color(0xFF8B5CF6);
  static const taskCheckinBg = Color(0xFFF5F3FF);
  static const taskOffers = Color(0xFFF59E0B);
  static const taskOffersBg = Color(0xFFFFFBEB);
  static const taskReceipts = Color(0xFF10B981);
  static const taskReceiptsBg = Color(0xFFECFDF5);

  // Progress
  static const progress = Color(0xFF0D9488);
  static const progressLight = Color(0xFFCCFBF1);

  // Flame
  static const flame = Color(0xFFFF6B35);
  static const flameBg = Color(0xFFFFF4ED);

  // Teal secondary
  static const tealSecondary = Color(0xFF2BA08E);
  static const tealRing = Color(0xFF00C6B2);

  // Ink
  static const ink = Color(0xFF3B3230);
  static const inkSecondary = Color(0xFF6B5E58);
  static const inkTertiary = Color(0xFF8A7D76);
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFD4A843);

  // Ring track
  static const ringTrack = Color(0xFFE2E8F0);
}

// ---------------------------------------------------------------------------
// AppSpacing
//
// Two tiers: primitive consts above, semantic tokens here. Screens and
// components must reference the semantic names below, never raw ints.
//
// Existing `xs`, `sm`, `md`, `lg`, `xl` are retained at their current
// values so existing screens are not shifted by this sub-project. `md`,
// `lg`, and `xl` are marked `@Deprecated` because their new semantic
// homes are `cardPad`, `sectionGap`, and `blockGap` respectively.
// ---------------------------------------------------------------------------

class AppSpacing {
  AppSpacing._();

  /// 2px. Named exception to the 4px grid, reserved for tight
  /// intra-component stacks such as a title → subtitle pair inside a
  /// single tile. Do not use for anything else.
  static const double tight = _s2;

  /// 4px. Icon ↔ label gap inside a single unit.
  static const double xs = _s4;

  /// 8px. Tight horizontal gap (inside a row of small chips).
  static const double sm = _s8;

  /// 12px. Default intra-card content step (e.g., gap between an icon
  /// and its title inside a stacked tile).
  static const double inner = _s12;

  /// 12px. Gap between consecutive rows or cards in a list.
  static const double rowGap = _s12;

  /// 16px. Default card inner padding.
  static const double cardPad = _s16;

  /// 20px. Space around titles, or above a big stacked element.
  static const double titleGap = _s20;

  /// 24px. Gap between sections on a page.
  static const double sectionGap = _s24;

  /// 24px. Left/right page gutter. ScreenScaffold applies this.
  static const double pageGutter = _s24;

  /// 32px. Gap between major page blocks.
  static const double blockGap = _s32;

  /// 40px. Space around hero elements.
  static const double heroGap = _s40;

  /// 48px. Top of a scrollable page.
  static const double pageTop = _s48;

  // -------------------------------------------------------------------------
  // Deprecated aliases, kept at their original values so existing screens
  // do not shift. New code should use the semantic names above.
  // -------------------------------------------------------------------------

  @Deprecated('Use AppSpacing.cardPad instead; AppSpacing.md is retained at '
      '16 for backwards compatibility and will be removed when all screens '
      'have migrated.')
  static const double md = _s16;

  @Deprecated('Use AppSpacing.sectionGap (or pageGutter where appropriate) '
      'instead; AppSpacing.lg is retained at 24 for backwards compatibility.')
  static const double lg = _s24;

  @Deprecated('Use AppSpacing.blockGap instead; AppSpacing.xl is retained '
      'at 32 for backwards compatibility.')
  static const double xl = _s32;
}

// ---------------------------------------------------------------------------
// AppRadius, semantic border-radius scale.
// ---------------------------------------------------------------------------

class AppRadius {
  AppRadius._();

  /// 8px. Chips, small pills, icon-tile squares.
  static const double chip = _r8;

  /// 16px. Default raised card, including AppCard.
  static const double card = _r16;

  /// 20px. Feature tiles, earn tiles, stat bubbles.
  static const double feature = _r20;

  /// 24px. Modals, bottom sheets, celebration cards.
  static const double modal = _r24;

  /// 9999px. True pills and circular elements.
  static const double pill = _rFull;
}

// ---------------------------------------------------------------------------
// AppElevation, semantic shadow scale. Values are `List<BoxShadow>` so
// they plug directly into `BoxDecoration.boxShadow`.
// ---------------------------------------------------------------------------

class AppElevation {
  AppElevation._();

  static const List<BoxShadow> none = <BoxShadow>[];

  static final List<BoxShadow> card = [
    BoxShadow(
      offset: const Offset(0, 2),
      blurRadius: 8,
      color: Colors.black.withValues(alpha: 0.04),
    ),
  ];

  static final List<BoxShadow> raised = [
    BoxShadow(
      offset: const Offset(0, 4),
      blurRadius: 16,
      color: Colors.black.withValues(alpha: 0.08),
    ),
  ];

  static final List<BoxShadow> modal = [
    BoxShadow(
      offset: const Offset(0, 8),
      blurRadius: 24,
      color: Colors.black.withValues(alpha: 0.12),
    ),
  ];
}

// ---------------------------------------------------------------------------
// AppLayout, page-level layout constants.
// ---------------------------------------------------------------------------

class AppLayout {
  /// Default horizontal gutter for screen content.
  static const double gutter = 24;

  /// Maximum width for reading content on wide viewports (tablet/desktop).
  static const double maxContentWidth = 640;
}

// ---------------------------------------------------------------------------
// AppTheme
// ---------------------------------------------------------------------------

class AppTheme {
  static TextTheme get _textTheme => GoogleFonts.outfitTextTheme();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        textTheme: _textTheme.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.cream,
        ),
      );
}
```

Note the `// ignore: deprecated_member_use_from_same_package` comments in the test file are needed because the test references the deprecated `md`/`lg`/`xl` on purpose.

- [ ] **Step 4: Run the token test**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/theme/theme_tokens_test.dart
```

Expected: PASS. All three groups green.

- [ ] **Step 5: Run the whole test suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: same green count as Task 0 + the three new tests. No regressions.

- [ ] **Step 6: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze
```

Expected: "No issues found!" The `@Deprecated` annotations on `AppSpacing.md/lg/xl` will not produce warnings at their definition site; they produce info-level notices only at the call sites inside `lib/screens/`, which is expected and acceptable.

If the analyzer reports new deprecation warnings on existing call sites, that is also expected. Triage: make sure the warnings are all about `AppSpacing.md/lg/xl` and nothing else. If there is anything unexpected, stop and investigate.

- [ ] **Step 7: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/theme/app_theme.dart flutter_app/test/theme/theme_tokens_test.dart && git commit -m "$(cat <<'EOF'
feat(theme): add semantic spacing, radius, elevation tokens

Adds the new semantic layer on AppSpacing (tight, inner, rowGap,
cardPad, titleGap, sectionGap, pageGutter, blockGap, heroGap,
pageTop) alongside new AppRadius and AppElevation classes. Existing
md, lg, xl on AppSpacing are retained at their current values and
marked deprecated so no existing screen shifts. A new theme_tokens
test file enforces the 4px grid invariant on the semantic spacing
scale and the allowed radius set.

Part of sub-project 1 of the Design System initiative. See
docs/superpowers/specs/2026-04-14-design-system-foundation-design.md.
EOF
)"
```

---

## Task 2: Semantic color tokens and `task*` deprecation

**Purpose:** add the semantic color names the new components will reference and mark the `task*` tint pairs as deprecated forwarders to the new `category*` names. The `AppColors.accent` gold stays as-is because nine existing call sites use it.

**Files:**
- Modify: `flutter_app/lib/theme/app_theme.dart`

- [ ] **Step 1: Replace the `AppColors` class with the semantic version**

Find the `AppColors` class in `lib/theme/app_theme.dart` and replace it with this. Every existing raw name stays compile-compatible; new semantic names are added; `task*` names become deprecated forwarders.

```dart
class AppColors {
  AppColors._();

  // -------------------------------------------------------------------------
  // Surface (backgrounds)
  // -------------------------------------------------------------------------

  static const Color surface = Color(0xFFFAF8F5);
  static const Color surfaceRaised = Color(0xFFFFFFFF);
  static const Color surfaceSelected = Color(0xFFF0FDFA);
  static const Color surfaceSubtle = Color(0xFFF2EDE6);

  // -------------------------------------------------------------------------
  // Ink (text, icons)
  // -------------------------------------------------------------------------

  static const Color ink = Color(0xFF3B3230);
  static const Color inkSecondary = Color(0xFF6B5E58);
  static const Color inkTertiary = Color(0xFF8A7D76);

  /// Reserved for future dark surfaces. Currently identical to surface.
  static const Color inkInverse = Color(0xFFFAF8F5);

  // -------------------------------------------------------------------------
  // Brand (teal)
  // -------------------------------------------------------------------------

  static const Color brand = Color(0xFF0D9488);
  static const Color brandSubtle = Color(0xFFF0FDFA);
  static const Color brandStrong = Color(0xFF0F766E);

  // -------------------------------------------------------------------------
  // Category tints, each category has a foreground and background.
  // -------------------------------------------------------------------------

  static const Color categoryGame = Color(0xFFF97316);
  static const Color categoryGameBg = Color(0xFFFFF7ED);
  static const Color categorySurvey = Color(0xFF6366F1);
  static const Color categorySurveyBg = Color(0xFFEEF2FF);
  static const Color categoryOffers = Color(0xFFF59E0B);
  static const Color categoryOffersBg = Color(0xFFFFFBEB);
  static const Color categoryReceipts = Color(0xFF10B981);
  static const Color categoryReceiptsBg = Color(0xFFECFDF5);
  static const Color categoryVideo = Color(0xFFEC4899);
  static const Color categoryVideoBg = Color(0xFFFDF2F8);
  static const Color categoryCheckin = Color(0xFF8B5CF6);
  static const Color categoryCheckinBg = Color(0xFFF5F3FF);

  // -------------------------------------------------------------------------
  // Feedback
  // -------------------------------------------------------------------------

  /// Positive/success green. Same value as categoryReceipts but semantically
  /// distinct: reach for this one for confirmation UI, not category tints.
  static const Color success = Color(0xFF10B981);

  static const Color flame = Color(0xFFFF6B35);
  static const Color flameBg = Color(0xFFFFF4ED);

  static const Color gold = Color(0xFFD4A843);

  // -------------------------------------------------------------------------
  // Accent (warm gold). Kept as-is: nine existing call sites use it as a
  // gold highlight, not as the brand teal. Do not rename.
  // -------------------------------------------------------------------------

  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFEF3C7);

  // -------------------------------------------------------------------------
  // Ambient / utility colors retained as-is (not deprecated) because they
  // do not have a clean semantic home yet. Per-screen migrations in
  // sub-projects 2–5 will decide their fate.
  // -------------------------------------------------------------------------

  static const Color creamWarm = Color(0xFFF8F3EC);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color secondaryLight = Color(0xFFCCFBF1);
  static const Color progress = Color(0xFF0D9488);
  static const Color progressLight = Color(0xFFCCFBF1);
  static const Color tealSecondary = Color(0xFF2BA08E);
  static const Color tealRing = Color(0xFF00C6B2);
  static const Color ringTrack = Color(0xFFE2E8F0);

  // -------------------------------------------------------------------------
  // Deprecated aliases, existing raw names that forward to semantic
  // equivalents. Values unchanged, so existing screens do not shift.
  // -------------------------------------------------------------------------

  @Deprecated('Use AppColors.surface instead.')
  static const Color cream = Color(0xFFFAF8F5);

  @Deprecated('Use AppColors.surfaceSubtle instead.')
  static const Color creamDeep = Color(0xFFF2EDE6);

  @Deprecated('Use AppColors.surfaceRaised instead.')
  static const Color white = Color(0xFFFFFFFF);

  @Deprecated('Use AppColors.brand instead.')
  static const Color primary = Color(0xFF0D9488);

  @Deprecated('Use AppColors.brandSubtle (or AppColors.surfaceSelected for '
      'selected-state backgrounds) instead.')
  static const Color primaryPale = Color(0xFFF0FDFA);

  @Deprecated('Use AppColors.brandStrong instead.')
  static const Color primaryDark = Color(0xFF0F766E);

  @Deprecated('Use AppColors.categoryVideo instead.')
  static const Color taskVideo = Color(0xFFEC4899);

  @Deprecated('Use AppColors.categoryVideoBg instead.')
  static const Color taskVideoBg = Color(0xFFFDF2F8);

  @Deprecated('Use AppColors.categorySurvey instead.')
  static const Color taskSurvey = Color(0xFF6366F1);

  @Deprecated('Use AppColors.categorySurveyBg instead.')
  static const Color taskSurveyBg = Color(0xFFEEF2FF);

  @Deprecated('Use AppColors.categoryGame instead.')
  static const Color taskGame = Color(0xFFF97316);

  @Deprecated('Use AppColors.categoryGameBg instead.')
  static const Color taskGameBg = Color(0xFFFFF7ED);

  @Deprecated('Use AppColors.categoryCheckin instead.')
  static const Color taskCheckin = Color(0xFF8B5CF6);

  @Deprecated('Use AppColors.categoryCheckinBg instead.')
  static const Color taskCheckinBg = Color(0xFFF5F3FF);

  @Deprecated('Use AppColors.categoryOffers instead.')
  static const Color taskOffers = Color(0xFFF59E0B);

  @Deprecated('Use AppColors.categoryOffersBg instead.')
  static const Color taskOffersBg = Color(0xFFFFFBEB);

  @Deprecated('Use AppColors.categoryReceipts (or AppColors.success for '
      'feedback UI) instead.')
  static const Color taskReceipts = Color(0xFF10B981);

  @Deprecated('Use AppColors.categoryReceiptsBg instead.')
  static const Color taskReceiptsBg = Color(0xFFECFDF5);
}
```

- [ ] **Step 2: Run the whole test suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: green, same count as after Task 1. No existing screen changed colors, so no pixel-comparison test should fail.

- [ ] **Step 3: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze
```

Expected: deprecation info-level notices on the call sites that reference `primary`, `cream`, `creamDeep`, `white`, `primaryPale`, `primaryDark`, and the six `task*` pairs. No errors, no unexpected warnings. If a new error appears, the rewrite above has a typo, fix and re-run.

- [ ] **Step 4: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/theme/app_theme.dart && git commit -m "$(cat <<'EOF'
feat(theme): add semantic color tokens and deprecate task* aliases

Reorganizes AppColors around semantic roles (surface/ink/brand/
category/feedback) and marks task*, cream, creamDeep, white, primary,
primaryPale, primaryDark as deprecated forwarders to the new names.
Values are unchanged so no screen shifts pixels. The new teal brand
semantic is AppColors.brand, not AppColors.accent, because the
existing accent is warm gold (#F59E0B) and is still used in nine
places; it stays as-is.

Part of sub-project 1 of the Design System initiative.
EOF
)"
```

---

## Task 3: `AppText.title` and deprecation of `sectionTitle`/`sheetTitle`

**Purpose:** consolidate the two very-close heading styles into a single semantic `title`, keeping the old names as deprecated forwarders so no existing screen breaks.

**Files:**
- Modify: `flutter_app/lib/theme/app_text.dart`

- [ ] **Step 1: Edit `app_text.dart`**

Replace the block that defines `sectionTitle` and `sheetTitle` (currently lines 71–83) with this block. Add `title` first, then mark the old names as deprecated forwarders that return the same style.

```dart
  /// 22 / 700 · page and section titles. The canonical heading style
  /// for sections and bottom-sheet headers. Replaces the prior
  /// `sectionTitle` / `sheetTitle` split.
  static TextStyle get title => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  @Deprecated('Use AppText.title instead. sectionTitle and sheetTitle '
      'were consolidated, both are 22/700 now.')
  static TextStyle get sectionTitle => title;

  @Deprecated('Use AppText.title instead. sectionTitle and sheetTitle '
      'were consolidated, both are 22/700 now.')
  static TextStyle get sheetTitle => title;
```

Note: the prior `sheetTitle` was 20/700; this change promotes it to 22/700 inside the deprecated forwarder, which means any bottom-sheet header still using `sheetTitle` renders 2px larger. Per the spec (Section 1.4), this consolidation is intentional. If that shift turns out to be visually too much, the alternative is to keep `sheetTitle` as its own separate getter at 20/700, but start with the consolidation and verify in the Task 13 smoke test.

- [ ] **Step 2: Run the whole test suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: green. No test checks a specific font size, so the 20 → 22 promotion on `sheetTitle` call sites does not surface here, it is caught by the visual smoke test in Task 13.

- [ ] **Step 3: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze
```

Expected: any existing `AppText.sectionTitle` / `AppText.sheetTitle` call site now shows a deprecation info. No errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/theme/app_text.dart && git commit -m "$(cat <<'EOF'
feat(theme): add AppText.title, deprecate sectionTitle and sheetTitle

Consolidates the two very-close 22/700 and 20/700 heading styles into
a single AppText.title at 22/700. sectionTitle and sheetTitle stay as
deprecated forwarders that return the new style. Bottom-sheet headers
still using sheetTitle will render 2px larger; the Task 13 smoke test
verifies that is visually acceptable.

Part of sub-project 1 of the Design System initiative.
EOF
)"
```

---

## Task 4: `Surface` widget

**Purpose:** extract the raised-card primitive (`Container(decoration: BoxDecoration(color, borderRadius, boxShadow))`) into a reusable widget. This is the base every feature card will be built on.

**Files:**
- Create: `flutter_app/test/widgets/surface_test.dart`
- Create: `flutter_app/lib/widgets/surface.dart`

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/widgets/surface_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/widgets/surface.dart';

void main() {
  group('Surface', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Surface(child: Text('inside')),
          ),
        ),
      );
      expect(find.text('inside'), findsOneWidget);
    });

    testWidgets('applies default radius and color via BoxDecoration',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Surface(child: SizedBox(width: 100, height: 100)),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Surface),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.surfaceRaised);
      final borderRadius = decoration.borderRadius! as BorderRadius;
      expect(borderRadius.topLeft.x, AppRadius.card);
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, 1);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Surface(
              onTap: () => tapped = true,
              child: const SizedBox(
                width: 200,
                height: 100,
                child: Text('tap me'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('tap me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/surface_test.dart
```

Expected: compile failure because `surface.dart` does not exist yet.

- [ ] **Step 3: Create `lib/widgets/surface.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'press_scale.dart';

/// Raised-card primitive. The foundation every feature card in the app is
/// built on: a `Container` with a semantic background color, a semantic
/// border-radius, and a semantic elevation. Wraps in [PressScale] when
/// [onTap] is non-null.
///
/// This is **not** a selectable choice card. For the "choice card" pattern
/// (primary-pale fill when selected, primary border), use [AppCard]
/// instead. A later cleanup can rebuild AppCard on top of Surface, but
/// they are deliberately kept as separate widgets for now.
class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow> elevation;
  final Color color;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final HapticIntensity? haptic;

  Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPad),
    this.radius = AppRadius.card,
    List<BoxShadow>? elevation,
    this.color = AppColors.surfaceRaised,
    this.border,
    this.onTap,
    this.haptic,
  }) : elevation = elevation ?? AppElevation.card;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevation,
        border: border,
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

Note: the constructor is not `const` because `AppElevation.card` is a non-const `final` static (it calls `Colors.black.withValues`, which is not const-evaluable). This is a minor tradeoff for being able to express semantic shadow tokens cleanly. If we later want `const Surface(...)`, we switch `AppElevation` to expose the `BoxShadow` list as a `const` expression using `Color.fromRGBO` with pre-computed alpha.

- [ ] **Step 4: Run the test and confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/surface_test.dart
```

Expected: all three tests green.

- [ ] **Step 5: Run the whole test suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: green, no regressions.

- [ ] **Step 6: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/surface.dart flutter_app/test/widgets/surface_test.dart && git commit -m "$(cat <<'EOF'
feat(widgets): add Surface (raised-card primitive)

The base widget that every feature card in the app is built on:
semantic background color, radius, and elevation with optional tap
handling via PressScale. Kept distinct from AppCard, which is the
selectable-choice card pattern.

Part of sub-project 1 of the Design System initiative.
EOF
)"
```

---

## Task 5: `CategoryIconSquare` widget

**Purpose:** extract the repeating "colored rounded square with a category icon inside" pattern that ListRow and VerticalTile will use as their `leading`.

**Files:**
- Create: `flutter_app/test/widgets/category_icon_square_test.dart`
- Create: `flutter_app/lib/widgets/category_icon_square.dart`

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/widgets/category_icon_square_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/widgets/category_icon_square.dart';

void main() {
  group('CategoryIconSquare', () {
    testWidgets('renders the icon with the configured colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconSquare(
              icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
              foreground: AppColors.categorySurvey,
              background: AppColors.categorySurveyBg,
            ),
          ),
        ),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, AppColors.categorySurvey);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.categorySurveyBg);
    });

    testWidgets('defaults to a 48x48 square with 8px radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconSquare(
              icon: PhosphorIcons.gift(PhosphorIconsStyle.duotone),
              foreground: AppColors.categoryGame,
              background: AppColors.categoryGameBg,
            ),
          ),
        ),
      );
      final box = tester.getSize(find.byType(CategoryIconSquare));
      expect(box.width, 48);
      expect(box.height, 48);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      final br = decoration.borderRadius! as BorderRadius;
      expect(br.topLeft.x, AppRadius.chip);
    });

    testWidgets('respects an explicit size override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconSquare(
              icon: PhosphorIcons.gift(PhosphorIconsStyle.duotone),
              foreground: AppColors.categoryGame,
              background: AppColors.categoryGameBg,
              size: 44,
              iconSize: 22,
            ),
          ),
        ),
      );
      final box = tester.getSize(find.byType(CategoryIconSquare));
      expect(box.width, 44);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 22);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/category_icon_square_test.dart
```

Expected: compile failure, `category_icon_square.dart` does not exist.

- [ ] **Step 3: Create `lib/widgets/category_icon_square.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A colored rounded square with a category icon inside. Used as the
/// `leading` of [ListRow] (48x48) and [VerticalTile] (typically 44x44).
/// Small primitive, two consumers, one source of truth.
class CategoryIconSquare extends StatelessWidget {
  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;
  final double iconSize;
  final double radius;

  const CategoryIconSquare({
    super.key,
    required this.icon,
    required this.foreground,
    required this.background,
    this.size = 48,
    this.iconSize = 24,
    this.radius = AppRadius.chip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}
```

- [ ] **Step 4: Run the test and confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/category_icon_square_test.dart
```

Expected: all three tests green.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/category_icon_square.dart flutter_app/test/widgets/category_icon_square_test.dart && git commit -m "$(cat <<'EOF'
feat(widgets): add CategoryIconSquare

The repeating colored-rounded-square pattern used as the leading of
ListRow and VerticalTile. Defaults to 48x48 with an 8px radius;
VerticalTile overrides to 44x44. Single source of truth for the
category-icon tile shape.

Part of sub-project 1 of the Design System initiative.
EOF
)"
```

---

## Task 6: `ListRow` widget

**Purpose:** extract the horizontal icon + title + subtitle + trailing pattern that recurs across home, profile, wallet, and detail screens into one reusable widget.

**Files:**
- Create: `flutter_app/test/widgets/list_row_test.dart`
- Create: `flutter_app/lib/widgets/list_row.dart`

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/widgets/list_row_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/widgets/category_icon_square.dart';
import 'package:earnwise_mvp/widgets/list_row.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

CategoryIconSquare _leading() => CategoryIconSquare(
      icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
      foreground: AppColors.categorySurvey,
      background: AppColors.categorySurveyBg,
    );

void main() {
  group('ListRow', () {
    testWidgets('renders title, subtitle, and a default trailing chevron',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ListRow(
          leading: _leading(),
          title: 'Daily survey',
          subtitle: '+\$0.50 for 2 minutes',
          onTap: () {},
        ),
      ));
      expect(find.text('Daily survey'), findsOneWidget);
      expect(find.text('+\$0.50 for 2 minutes'), findsOneWidget);
      // Default trailing is a Phosphor caretRight icon.
      expect(find.byType(Icon), findsNWidgets(2)); // leading + caret
    });

    testWidgets('fires onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        ListRow(
          leading: _leading(),
          title: 'Tap target',
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.text('Tap target'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('disabled prevents onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        ListRow(
          leading: _leading(),
          title: 'Disabled row',
          onTap: () => tapped = true,
          disabled: true,
        ),
      ));
      await tester.tap(find.text('Disabled row'));
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });

    testWidgets('uses a custom trailing when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        ListRow(
          leading: _leading(),
          title: 'Custom trailing',
          trailing: const Text('NEW'),
        ),
      ));
      expect(find.text('NEW'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/list_row_test.dart
```

Expected: compile failure, `list_row.dart` does not exist.

- [ ] **Step 3: Create `lib/widgets/list_row.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'surface.dart';

/// Horizontal list item: leading icon, title with optional subtitle, and
/// trailing chrome (default: a caret-right chevron). Built on [Surface]
/// so it picks up the canonical card radius, shadow, and background.
class ListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool disabled;

  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTrailing = trailing ??
        Icon(
          PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
          size: 16,
          color: AppColors.inkTertiary,
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
                  color: AppColors.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.tight),
                Text(
                  subtitle!,
                  style: AppText.caption.copyWith(
                    color: AppColors.inkSecondary,
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
}
```

- [ ] **Step 4: Run the test and confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/list_row_test.dart
```

Expected: all four tests green.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/list_row.dart flutter_app/test/widgets/list_row_test.dart && git commit -m "$(cat <<'EOF'
feat(widgets): add ListRow

Horizontal list-item component: leading icon + title + optional
subtitle + optional trailing (defaults to a Phosphor caret-right
chevron). Built on Surface so it inherits the canonical card radius,
shadow, and background. Replaces inline _taskCard and
_buildContinueCard patterns during sub-project 2.

Part of sub-project 1 of the Design System initiative.
EOF
)"
```

---

## Task 7: `VerticalTile` widget

**Purpose:** extract the icon-on-top tile used for the "Earn More" trio in the home and onboarding screens.

**Files:**
- Create: `flutter_app/test/widgets/vertical_tile_test.dart`
- Create: `flutter_app/lib/widgets/vertical_tile.dart`

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/widgets/vertical_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/widgets/category_icon_square.dart';
import 'package:earnwise_mvp/widgets/vertical_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 120, child: child),
        ),
      ),
    );

CategoryIconSquare _leading() => CategoryIconSquare(
      icon: PhosphorIcons.tag(PhosphorIconsStyle.duotone),
      foreground: AppColors.categoryOffers,
      background: AppColors.categoryOffersBg,
      size: 44,
      iconSize: 22,
    );

void main() {
  group('VerticalTile', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(_wrap(
        VerticalTile(
          leading: _leading(),
          title: 'Offers',
          subtitle: 'Save & earn',
          onTap: () {},
        ),
      ));
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('Save & earn'), findsOneWidget);
    });

    testWidgets('fires onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        VerticalTile(
          leading: _leading(),
          title: 'Receipts',
          subtitle: 'Cashback',
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.text('Receipts'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('disabled prevents onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        VerticalTile(
          leading: _leading(),
          title: 'Games',
          subtitle: 'Play & earn',
          onTap: () => tapped = true,
          disabled: true,
        ),
      ));
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/vertical_tile_test.dart
```

Expected: compile failure, `vertical_tile.dart` does not exist.

- [ ] **Step 3: Create `lib/widgets/vertical_tile.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'surface.dart';

/// Icon-on-top tile: leading (usually a 44-size CategoryIconSquare),
/// inner gap, title, tight gap, subtitle. Used for the "Earn More"
/// trio on the home and onboarding screens.
///
/// VerticalTile does **not** wrap itself in [Expanded]. Callers are
/// responsible for sizing. Typical usage:
///
/// ```dart
/// Row(
///   children: [
///     Expanded(child: VerticalTile(...)),
///     SizedBox(width: AppSpacing.rowGap),
///     Expanded(child: VerticalTile(...)),
///     SizedBox(width: AppSpacing.rowGap),
///     Expanded(child: VerticalTile(...)),
///   ],
/// )
/// ```
///
/// This is documented as the "Tile trio" pattern in `docs/design-system.md`.
class VerticalTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool disabled;

  const VerticalTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(height: AppSpacing.inner),
        Text(
          title,
          style: AppText.bodyStrong.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.tight),
        Text(
          subtitle,
          style: AppText.caption.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );

    final surface = Surface(
      radius: AppRadius.feature,
      onTap: disabled ? null : onTap,
      child: content,
    );

    if (!disabled) return surface;
    return Opacity(opacity: 0.45, child: IgnorePointer(child: surface));
  }
}
```

- [ ] **Step 4: Run the test and confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/vertical_tile_test.dart
```

Expected: all three tests green.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/vertical_tile.dart flutter_app/test/widgets/vertical_tile_test.dart && git commit -m "$(cat <<'EOF'
feat(widgets): add VerticalTile

Icon-on-top tile built on Surface (feature radius). Used as the unit
of the Tile-trio pattern (three tiles in an Expanded row with
AppSpacing.rowGap separators). Replaces inline _earnTile during
sub-project 2.

Part of sub-project 1 of the Design System initiative.
EOF
)"
```

---

## Task 8: `SectionHeader` widget

**Purpose:** extract the section title row (title, optional subtitle, optional trailing action) that every screen re-implements inline.

**Files:**
- Create: `flutter_app/test/widgets/section_header_test.dart`
- Create: `flutter_app/lib/widgets/section_header.dart`

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/widgets/section_header_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/widgets/section_header.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SectionHeader', () {
    testWidgets('renders just a title', (tester) async {
      await tester.pumpWidget(_wrap(
        const SectionHeader(title: 'Earn More'),
      ));
      expect(find.text('Earn More'), findsOneWidget);
    });

    testWidgets('renders a subtitle when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const SectionHeader(
          title: 'Continue earning',
          subtitle: 'Pick up where you left off',
        ),
      ));
      expect(find.text('Continue earning'), findsOneWidget);
      expect(find.text('Pick up where you left off'), findsOneWidget);
    });

    testWidgets('renders a trailing action when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        SectionHeader(
          title: 'All games',
          action: TextButton(
            onPressed: () {},
            child: const Text('See all'),
          ),
        ),
      ));
      expect(find.text('All games'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/section_header_test.dart
```

Expected: compile failure, `section_header.dart` does not exist.

- [ ] **Step 3: Create `lib/widgets/section_header.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Section title row: the canonical way to introduce a section on a
/// screen. Renders the title in [AppText.title], an optional subtitle
/// in [AppText.caption], and an optional trailing action widget aligned
/// to the end of the row.
///
/// Does not add a bottom margin. The caller chooses
/// `SizedBox(height: AppSpacing.inner)` (12) or `AppSpacing.cardPad`
/// (16) below it depending on context.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(title, style: AppText.title),
            ),
            if (action != null) action!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.tight),
          Text(
            subtitle!,
            style: AppText.caption.copyWith(color: AppColors.inkSecondary),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Run the test and confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/section_header_test.dart
```

Expected: all three tests green.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/section_header.dart flutter_app/test/widgets/section_header_test.dart && git commit -m "$(cat <<'EOF'
feat(widgets): add SectionHeader

Title (AppText.title 22/700), optional subtitle (AppText.caption),
and optional trailing action aligned to the row end. No built-in
bottom margin; callers pick AppSpacing.inner or AppSpacing.cardPad
depending on context. Replaces inline section-title Text widgets
across screens during sub-projects 2–5.

Part of sub-project 1 of the Design System initiative.
EOF
)"
```

---

## Task 9: `StatBubble` widget

**Purpose:** extract the stat-indicator pattern (icon, pre-formatted value, label) used for Balance and Today bubbles flanking the ring on the home screen.

**Files:**
- Create: `flutter_app/test/widgets/stat_bubble_test.dart`
- Create: `flutter_app/lib/widgets/stat_bubble.dart`

- [ ] **Step 1: Write the failing test**

Create `flutter_app/test/widgets/stat_bubble_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/widgets/stat_bubble.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StatBubble', () {
    testWidgets('renders the value and label', (tester) async {
      await tester.pumpWidget(_wrap(
        StatBubble(
          icon: PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
          value: '\$12.40',
          label: 'Balance',
        ),
      ));
      expect(find.text('\$12.40'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
    });

    testWidgets('defaults the accent color to AppColors.brand',
        (tester) async {
      await tester.pumpWidget(_wrap(
        StatBubble(
          icon: PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
          value: '\$12.40',
          label: 'Balance',
        ),
      ));
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, AppColors.brand);
    });

    testWidgets('respects an explicit accent override', (tester) async {
      await tester.pumpWidget(_wrap(
        StatBubble(
          icon: PhosphorIcons.star(PhosphorIconsStyle.duotone),
          value: '12',
          label: 'Today',
          accentColor: AppColors.flame,
        ),
      ));
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, AppColors.flame);
    });
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/stat_bubble_test.dart
```

Expected: compile failure, `stat_bubble.dart` does not exist.

- [ ] **Step 3: Create `lib/widgets/stat_bubble.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Stat indicator: accent icon on top, pre-formatted value, caption label.
/// Decoupled from any stars / dollars helper, the caller formats
/// `value` as a string, so the widget can serve any future stat
/// (earnings, streak days, tasks completed, etc.).
class StatBubble extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;

  const StatBubble({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accentColor = AppColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(height: AppSpacing.tight),
        Text(value, style: AppText.statNumber),
        Text(
          label,
          style: AppText.caption.copyWith(color: AppColors.inkTertiary),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run the test and confirm it passes**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test test/widgets/stat_bubble_test.dart
```

Expected: all three tests green.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/stat_bubble.dart flutter_app/test/widgets/stat_bubble_test.dart && git commit -m "$(cat <<'EOF'
feat(widgets): add StatBubble

Stat indicator: accent icon, pre-formatted value string, caption
label. Decoupled from stars-to-dollars formatting so it can serve any
future stat. Defaults accent to AppColors.brand. Replaces inline
_buildStatBubble during sub-project 2.

Part of sub-project 1 of the Design System initiative.
EOF
)"
```

---

## Task 10: Migrate `AppCard` to `AppRadius.card`

**Purpose:** replace the hardcoded `BorderRadius.circular(18)` in `AppCard` with `BorderRadius.circular(AppRadius.card)` (16). This is the only visible pixel shift in the whole sub-project, approved by the user.

**Files:**
- Modify: `flutter_app/lib/widgets/app_card.dart`

- [ ] **Step 1: Swap the radius constant**

In `flutter_app/lib/widgets/app_card.dart`, change line 44 from:

```dart
        borderRadius: BorderRadius.circular(18),
```

to:

```dart
        borderRadius: BorderRadius.circular(AppRadius.card),
```

`AppRadius` is already available via the existing `import '../theme/app_theme.dart';` at the top of the file, since `AppRadius` is defined in `app_theme.dart`.

- [ ] **Step 2: Update the doc comment**

Also update the doc comment at the top of the class (currently `"white background, 18px radius, cream-deep 1.5 border, subtle shadow."`) to read `"white background, AppRadius.card (16) radius, cream-deep 1.5 border, subtle shadow."`.

- [ ] **Step 3: Run the whole test suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: green. Existing AppCard tests (if any) still pass because no widget test asserts a specific radius on AppCard.

- [ ] **Step 4: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze
```

Expected: "No issues found!" (or only pre-existing info messages). Definitely no new errors or warnings.

- [ ] **Step 5: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add flutter_app/lib/widgets/app_card.dart && git commit -m "$(cat <<'EOF'
refactor(widgets): AppCard now uses AppRadius.card (16) instead of 18

The only visible pixel shift in sub-project 1 of the Design System
initiative. Wherever AppCard is rendered (onboarding preference
picker, profile list rows, selectable choice cards), the radius drops
from 18 to 16 to match the new AppRadius.card semantic token. User
approved.
EOF
)"
```

---

## Task 11: `docs/design-system.md` reference doc

**Purpose:** publish the canonical developer reference that CLAUDE.md will point at. Optimized for Claude and developers to read while building UI.

**Files:**
- Create: `docs/design-system.md`

- [ ] **Step 1: Write the reference doc**

Create `docs/design-system.md` with this exact content:

````markdown
# EarnWise Design System

> Single source of truth for EarnWise Flutter UI. Read this file before
> building or modifying any UI in `flutter_app/`. All new UI must use the
> semantic tokens and components defined here. If a pattern does not
> exist in this system, add it to the system before using it in a screen.

## Principles

- Cream surface, warm voice.
- Generous whitespace; content breathes.
- Soft, physical pressability on every tap target.
- Animation serves comprehension, never decoration.
- Every line of copy sounds like a person spoke it. See Voice & Writing.

## Layout & Grid

- Page gutter: 24px (`AppSpacing.pageGutter`, applied by `ScreenScaffold`).
- Vertical rhythm: 4px baseline grid. The only sub-4 value is
  `AppSpacing.tight` (2px), reserved for intra-component title → subtitle
  stacks.
- Content max width: 640px (`AppLayout.maxContentWidth`), reserved for
  tablet and desktop viewports.

## Tokens

### Spacing

| Name | Value | Purpose |
|------|-------|---------|
| `AppSpacing.tight` | 2 | Title → subtitle intra-stack (named exception) |
| `AppSpacing.xs` | 4 | Icon ↔ label gap inside a single unit |
| `AppSpacing.sm` | 8 | Tight horizontal gap |
| `AppSpacing.inner` | 12 | Intra-card content step |
| `AppSpacing.rowGap` | 12 | Between consecutive rows or cards in a list |
| `AppSpacing.cardPad` | 16 | Default card inner padding |
| `AppSpacing.titleGap` | 20 | Around titles / above a big stack element |
| `AppSpacing.sectionGap` | 24 | Between sections on a page |
| `AppSpacing.pageGutter` | 24 | Page left/right gutter |
| `AppSpacing.blockGap` | 32 | Between major page blocks |
| `AppSpacing.heroGap` | 40 | Around hero elements |
| `AppSpacing.pageTop` | 48 | Top of a scrollable page |

**Do:**
- Use `AppSpacing.rowGap` between consecutive list rows or cards.
- Use `AppSpacing.sectionGap` between sections on a page.
- Use `AppSpacing.cardPad` inside a `Surface`.

**Do not:**
- Use raw ints in `SizedBox(height: N)` or `EdgeInsets.all(N)` in new code.
- Use off-grid values (`10`, `14`, `18`). Round to the nearest rung; on a
  tie, round up.
- Use the deprecated `AppSpacing.md`, `lg`, `xl` aliases in new code. Their
  new semantic homes are `cardPad`, `sectionGap` (or `pageGutter`), and
  `blockGap` respectively.

### Radius

| Name | Value | Use |
|------|-------|-----|
| `AppRadius.chip` | 8 | Chips, small pills, `CategoryIconSquare` |
| `AppRadius.card` | 16 | Default raised card, `AppCard`, `Surface` |
| `AppRadius.feature` | 20 | Feature tiles, earn tiles, stat bubbles |
| `AppRadius.modal` | 24 | Modals, bottom sheets, celebration cards |
| `AppRadius.pill` | 9999 | True pills and circular elements |

### Elevation

| Name | Shape |
|------|-------|
| `AppElevation.none` | Empty list (no shadow) |
| `AppElevation.card` | 1 drop: offset(0, 2), blur 8, `black.withAlpha(.04)` |
| `AppElevation.raised` | 1 drop: offset(0, 4), blur 16, `black.withAlpha(.08)` |
| `AppElevation.modal` | 1 drop: offset(0, 8), blur 24, `black.withAlpha(.12)` |

`AppElevation.card` matches the shadow used everywhere in the app today;
migrating to it never changes a pixel.

### Typography

See `lib/theme/app_text.dart`. The canonical styles are:

| Style | Size / weight | Use |
|-------|---------------|-----|
| `AppText.heroAmount` | 64 / 800 | Welcome gift, hero amounts |
| `AppText.display` | 48 / 800 | Name input, hero numbers |
| `AppText.brandMark` | 38 / 800 | "EarnWise" brand mark |
| `AppText.ringGoal` | 32 / 800 | Progress ring center number |
| `AppText.gameTitle` | 28 / 800 | Game detail page title |
| `AppText.slideTitle` | 26 / 800 | Trust carousel slide title |
| `AppText.prompt` | 24 / 700 | Onboarding prompt questions |
| `AppText.title` | 22 / 700 | **Section and page titles** (canonical heading) |
| `AppText.statNumber` | 20 / 800 | Stat bubble number |
| `AppText.ctaLabel` | 20 / 600 (white) | Primary button label |
| `AppText.listItem` | 17 / 600 | List row titles, tagline, primary body |
| `AppText.bodyStrong` | 16 / 600 | Emphasized body, toast title |
| `AppText.body` | 15 / 500 | Subcopy, descriptions, secondary text |
| `AppText.caption` | 14 / 600 | Meta labels, pill labels, captions |

`AppText.sectionTitle` and `AppText.sheetTitle` are deprecated forwarders
that return `AppText.title`. Use `title` directly in new code.

### Color

Grouped by role. Every semantic name has a stable meaning, do not assume
any two names with the same current value are interchangeable, since they
may diverge when dark mode lands.

**Surface (backgrounds):**
- `AppColors.surface`, cream (#FAF8F5). The default page background.
- `AppColors.surfaceRaised`, white (#FFFFFF). Default card background.
- `AppColors.surfaceSelected`, brand pale (#F0FDFA). Selected-state fill.
- `AppColors.surfaceSubtle`, cream deep (#F2EDE6). Secondary surfaces,
  dividers.

**Ink (text, icons):**
- `AppColors.ink`, primary (#3B3230)
- `AppColors.inkSecondary`, #6B5E58
- `AppColors.inkTertiary`, #8A7D76
- `AppColors.inkInverse`, cream (reserved for future dark surfaces)

**Brand (teal):**
- `AppColors.brand`, #0D9488
- `AppColors.brandSubtle`, #F0FDFA
- `AppColors.brandStrong`, #0F766E

**Category tints** (each has a foreground and background):
- `AppColors.categoryGame` / `categoryGameBg`
- `AppColors.categorySurvey` / `categorySurveyBg`
- `AppColors.categoryOffers` / `categoryOffersBg`
- `AppColors.categoryReceipts` / `categoryReceiptsBg`
- `AppColors.categoryVideo` / `categoryVideoBg`
- `AppColors.categoryCheckin` / `categoryCheckinBg`

**Feedback:**
- `AppColors.success`, #10B981 (same value as `categoryReceipts`,
  semantically distinct)
- `AppColors.flame` / `AppColors.flameBg`, streak
- `AppColors.gold`, celebration (#D4A843)

**Dark-mode note.** When dark mode lands, `AppColors` migrates to a
`ThemeExtension<AppColorPalette>` so each semantic name points at a
different primitive under `Theme.of(context).brightness == dark`. Spacing,
radius, elevation, and typography stay static because they are
brightness-invariant.

## Components

Each component follows the same mini-template:

- **Purpose:** one sentence, when to reach for it
- **Anatomy:** labeled diagram
- **Props:** link to the source file
- **Do / Don't:** three each

### Surface

**Purpose:** raised-card primitive. The foundation every feature card is
built on.

**Props:** `lib/widgets/surface.dart`. Fields: `child`, `padding`
(default `cardPad`), `radius` (default `AppRadius.card`), `elevation`
(default `AppElevation.card`), `color` (default `surfaceRaised`), `border`,
`onTap`, `haptic`.

**Do:**
- Use as the base for any new card-shaped container.
- Override `radius: AppRadius.feature` for feature tiles.
- Wire `onTap` to get PressScale feedback for free.

**Don't:**
- Use for selectable choice cards, use `AppCard` instead.
- Reach into `BoxDecoration` directly in new screen code. Let `Surface`
  own the decoration.
- Use raw shadow objects. Compose with `AppElevation.*` only.

### AppCard

**Purpose:** the selectable "choice card" pattern, with an active
`selected` state (brand-pale fill, brand border). Used in multi-select
lists like the onboarding preference picker.

**Props:** `lib/widgets/app_card.dart`. Fields: `child`, `padding`,
`onTap`, `selected`, `constraints`, `haptic`.

**Do:**
- Use for list items that have a checked state.
- Use `selected: true` to apply the active fill and border.
- Leave `haptic: null` on purely navigational choice cards.

**Don't:**
- Use as a generic card. Reach for `Surface` instead, `Surface` has no
  border and composes cleaner.
- Override the border color inline. If you need a different border, you
  likely need a different component.
- Nest `AppCard` inside `Surface` or vice versa.

### ListRow

**Purpose:** horizontal list item with leading icon, title, optional
subtitle, optional trailing (defaults to a caret-right chevron).

**Props:** `lib/widgets/list_row.dart`. Fields: `leading`, `title`,
`subtitle`, `trailing`, `onTap`, `disabled`.

**Do:**
- Use `CategoryIconSquare` as the `leading` for category rows.
- Let the default caret-right chevron show for navigational rows.
- Use `disabled: true` for rows the user cannot act on yet.

**Don't:**
- Hardcode a `Surface` around a `ListRow`, `ListRow` is already a
  `Surface` under the hood.
- Use for complex multi-control rows (toggle + text + detail link). That
  is a custom composition, not a ListRow.
- Mix a subtitle with multi-line custom `trailing`. Keep trailing simple.

### VerticalTile

**Purpose:** icon-on-top tile used as the unit of the Tile-trio pattern
(three tiles in a row).

**Props:** `lib/widgets/vertical_tile.dart`. Fields: `leading`, `title`,
`subtitle`, `onTap`, `disabled`.

**Do:**
- Wrap in `Expanded` at the call site so three tiles share a row evenly.
- Separate tiles with `SizedBox(width: AppSpacing.rowGap)`.
- Use a 44-size `CategoryIconSquare` as the `leading`.

**Don't:**
- Put four or more tiles in one row. Three is the pattern.
- Override the radius. `VerticalTile` uses `AppRadius.feature` on
  purpose.
- Let `subtitle` line-wrap more than once. Rewrite the copy.

### SectionHeader

**Purpose:** title row at the top of a section, optionally with a
subtitle and/or a trailing action (e.g., "See all").

**Props:** `lib/widgets/section_header.dart`. Fields: `title`, `subtitle`,
`action`.

**Do:**
- Use for every section on every screen.
- Pair with `SizedBox(height: AppSpacing.inner)` or `AppSpacing.cardPad`
  below it depending on how dense the section content is.
- Keep titles 1 to 3 words. Subtitles one short sentence.

**Don't:**
- Add a bottom margin inside `SectionHeader`. Let the caller decide.
- Use for the page title at the very top of a screen. That is
  `ScreenScaffold` territory.
- Put more than one trailing action. One action, one choice.

### StatBubble

**Purpose:** stat indicator: accent icon, pre-formatted value,
caption label. Used for Balance and Today bubbles flanking the ring on
the home screen.

**Props:** `lib/widgets/stat_bubble.dart`. Fields: `icon`, `value`,
`label`, `accentColor` (default `AppColors.brand`).

**Do:**
- Pre-format the `value` string at the call site. The widget is
  currency-agnostic.
- Override `accentColor` for non-earnings stats (flame for streak, for
  example).
- Keep labels one word.

**Don't:**
- Pass a number to `value`. Format it first.
- Use for the ring center number. That is `AppText.ringGoal`.
- Add a background. `StatBubble` is intentionally chrome-less.

### CategoryIconSquare

**Purpose:** colored rounded square with a category icon inside. Used as
the `leading` of `ListRow` (48x48) and `VerticalTile` (typically 44x44).

**Props:** `lib/widgets/category_icon_square.dart`. Fields: `icon`,
`foreground`, `background`, `size` (default 48), `iconSize` (default 24),
`radius` (default `AppRadius.chip`).

**Do:**
- Pair `foreground` and `background` from the same category (e.g.,
  `categorySurvey` and `categorySurveyBg`).
- Override `size: 44, iconSize: 22` for `VerticalTile`.
- Reuse across screens, this is a pure primitive with no state.

**Don't:**
- Pass mismatched foreground and background (e.g., survey foreground on
  game background). Pick one category.
- Use for a circular badge. That is a different widget.
- Override radius unless you are building a new variant with a good
  reason.

## Patterns

### Section + card list

```dart
SectionHeader(title: 'Today\'s tasks'),
const SizedBox(height: AppSpacing.inner),
ListRow(leading: ..., title: 'Daily survey', subtitle: '+\$0.50', onTap: ...),
const SizedBox(height: AppSpacing.rowGap),
ListRow(leading: ..., title: 'Quick video', subtitle: '+\$0.25', onTap: ...),
```

### Hero stat row

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    StatBubble(icon: ..., value: '\$12.40', label: 'Balance'),
    const DailyGoalRing(...),
    StatBubble(icon: ..., value: '4', label: 'Today'),
  ],
),
```

### Tile trio (Earn More)

```dart
Row(
  children: [
    Expanded(child: VerticalTile(leading: ..., title: 'Offers', subtitle: 'Save & earn', onTap: ...)),
    const SizedBox(width: AppSpacing.rowGap),
    Expanded(child: VerticalTile(leading: ..., title: 'Receipts', subtitle: 'Cashback', onTap: ...)),
    const SizedBox(width: AppSpacing.rowGap),
    Expanded(child: VerticalTile(leading: ..., title: 'Games', subtitle: 'Play & earn', onTap: ...)),
  ],
),
```

## Voice & Writing

- No em-dashes (`—`). Use commas, periods, or semicolons. This is a hard
  rule in the EarnWise project.
- Every line of copy reads like a person spoke it. No telegraphic
  fragments ("Not eligible.", "Coming soon.").
- Never minimize earnings. No "a little", "pocket money", or "spare
  change". Frame earnings straight or cumulative.

## Migration notes (sub-projects 2–6)

- Replace inline `Container(decoration: BoxDecoration(...))` raised cards
  with `Surface`.
- Replace inline `_taskCard`, `_earnTile`, `_buildContinueCard`, and
  `_buildSectionCard` helpers with `ListRow` / `VerticalTile`.
- Replace raw `SizedBox(height: N)` and `EdgeInsets.all(N)` with
  `AppSpacing.*`. Round off-grid values per the rules above.
- Migrate call sites away from `AppSpacing.md`, `lg`, `xl` (deprecated)
  onto `cardPad`, `sectionGap`, `blockGap`.
- Migrate call sites away from `AppColors.task*`, `primary`, `cream`,
  `creamDeep`, `white`, `primaryPale`, `primaryDark` (all deprecated)
  onto the semantic names.
- When dark mode lands, `AppColors` migrates to
  `ThemeExtension<AppColorPalette>`; `AppSpacing`, `AppRadius`,
  `AppElevation`, and `AppText` stay static.
````

- [ ] **Step 2: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add docs/design-system.md && git commit -m "$(cat <<'EOF'
docs(design-system): publish canonical reference doc

The single source of truth for EarnWise Flutter UI: principles,
layout, full token tables (spacing/radius/elevation/typography/
color), the six components landed in this sub-project plus AppCard,
three canonical composition patterns (section + card list, hero stat
row, tile trio), voice & writing rules, and migration notes for
sub-projects 2 through 6. Linked into CLAUDE.md in the next task so
it loads on every Flutter UI task.

Part of sub-project 1 of the Design System initiative.
EOF
)"
```

---

## Task 12: `CLAUDE.md` Design System hook

**Purpose:** add a new `# Design System` section at the top of `CLAUDE.md` so the reference doc is loaded on every UI task.

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Insert the new section**

Edit `CLAUDE.md`. The current file starts with `# Presenter`. Insert a new top-level section **above** it. The final top of the file should read:

```markdown
# Design System

When building or modifying UI in `flutter_app/`, read `docs/design-system.md`
before writing code. It defines the grid, spacing scale, typography, colors,
and reusable components for the Flutter app. All new UI must use the
semantic tokens and components defined there.

If a pattern does not exist in the system, add it to the system before
using it in a screen. This is non-negotiable.

# Presenter

Generate self-contained HTML presentations from concept documents.

...rest of the file unchanged...
```

Do not touch anything below the original `# Presenter` line, just insert the new section and a blank line above it.

- [ ] **Step 2: Commit**

```bash
cd /Users/markus/Dev/earnapp && git add CLAUDE.md && git commit -m "$(cat <<'EOF'
docs(claude-md): add Design System section pointing at design-system.md

CLAUDE.md is loaded as project instructions on every session, so a
top-level Design System section here means docs/design-system.md
becomes a mandatory second read whenever Claude is asked to build or
modify Flutter UI.

Part of sub-project 1 of the Design System initiative.
EOF
)"
```

---

## Task 13: Final verification

**Purpose:** confirm the whole sub-project is green before handing off. Analyzer clean, all tests pass, visual smoke test confirms no unexpected pixel changes.

**Files:** none modified.

- [ ] **Step 1: Run the analyzer**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter analyze
```

Expected: "No issues found!", or only info-level deprecation notices on call sites in `lib/screens/` referencing `AppSpacing.md/lg/xl`, `AppColors.task*`, `AppColors.primary/cream/creamDeep/white/primaryPale/primaryDark`, and `AppText.sectionTitle/sheetTitle`. No errors, no unexpected warnings.

- [ ] **Step 2: Run the full test suite**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter test
```

Expected: green. The total count should be the Task 0 baseline plus the new theme-tokens test and the six new widget test files (approximately 20 new tests).

- [ ] **Step 3: Visual smoke test in Chrome**

```bash
cd /Users/markus/Dev/earnapp/flutter_app && flutter run -d chrome
```

Once the app loads:

- Click through the onboarding flow (welcome → trust carousel → onboarding preference picker). Confirm the preference cards render correctly with the new 16px radius (was 18). The difference is subtle but visible if you compare against the committed pre-change screenshot.
- Skip into the post-onboarding home screen. Confirm the Balance + Today stat bubbles, the daily-goal ring, Continue earning cards, Earn More tile trio, and section headers all render identically to before.
- Open the Wallet screen. Confirm it renders identically.
- Open the Profile screen. Confirm `AppCard` items in the settings list use the new 16 radius, otherwise identical.
- Open the Game detail screen for any installed game. Confirm it renders identically.

If any screen shifts pixels anywhere other than AppCard corners, stop and investigate. The token rewrite preserves all original spacing and color values; an unexpected shift means a typo or a missed deprecation target.

- [ ] **Step 4: Close the Chrome dev server**

Terminate the `flutter run` process cleanly (Ctrl-C in the terminal running it, or kill the background task).

No commit. Task 13 is a verification gate; no files change.

---

## Summary

After all thirteen tasks:

- Tokens: `AppSpacing` grows to twelve semantic names plus three deprecated aliases. `AppRadius`, `AppElevation` are new. `AppColors` grows to forty-plus semantic names with twelve deprecated aliases. `AppText.title` replaces `sectionTitle`/`sheetTitle`.
- Components: six new widgets (`Surface`, `ListRow`, `VerticalTile`, `SectionHeader`, `StatBubble`, `CategoryIconSquare`) each with a unit test.
- Existing `AppCard` picks up `AppRadius.card` (16 instead of 18). This is the only visible pixel shift in the sub-project.
- Documentation: `docs/design-system.md` is published. `CLAUDE.md` has a new `# Design System` section at the top that forces the reference doc to be loaded on every UI task.
- No file in `lib/screens/` is modified. No screen behavior changes except the AppCard radius.

Subsequent sub-projects (2 through 6) migrate one screen at a time onto the new token and component names. Each is independent and gets its own spec + plan.
