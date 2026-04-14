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
// ---------------------------------------------------------------------------

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
  // sub-projects 2-5 will decide their fate.
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
