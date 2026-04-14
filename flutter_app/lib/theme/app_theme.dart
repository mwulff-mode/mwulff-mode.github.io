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
