import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Named text styles for EarnWise. Use these instead of inlining
/// `GoogleFonts.outfit(fontSize: …, fontWeight: …)` so size/weight pairings
/// stay consistent across screens.
///
/// Each style ships a sensible default color; use `.copyWith(color: …)` (or
/// any other field) for minor per-site variations.
class AppText {
  AppText._();

  /// 64 / 800 · gift overlay hero amount (welcome gift "$0.17")
  static TextStyle get heroAmount => GoogleFonts.outfit(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        letterSpacing: -3,
        color: AppColors.primary,
      );

  /// 48 / 800 · name input, hero numbers
  static TextStyle get display => GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: AppColors.ink,
      );

  /// 38 / 800 · brand mark ("EarnWise")
  static TextStyle get brandMark => GoogleFonts.outfit(
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: AppColors.ink,
      );

  /// 32 / 800 · progress ring goal number
  static TextStyle get ringGoal => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: Colors.white,
      );

  /// 28 / 800 · game detail page title (game name on the detail screen)
  static TextStyle get gameTitle => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.ink,
      );

  /// 26 / 800 · trust carousel slide title
  static TextStyle get slideTitle => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: AppColors.ink,
      );

  /// 24 / 700 · onboarding prompt questions
  static TextStyle get prompt => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.3,
        color: AppColors.ink,
      );

  /// 22 / 700 · page and section titles. The canonical heading style
  /// for sections and bottom-sheet headers. Replaces the prior
  /// `sectionTitle` / `sheetTitle` split.
  static TextStyle get title => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  @Deprecated('Use AppText.title instead. sectionTitle is 22/700, '
      'identical to the new title style.')
  static TextStyle get sectionTitle => title;

  /// 20 / 700 · legacy bottom sheet title. Kept as a real style (not a
  /// forwarder to `title`) so the one existing call site in
  /// `home_screen.dart` renders identically until sub-project 2 migrates
  /// the "Choose your game" sheet onto `AppText.title` (22/700) on purpose.
  @Deprecated('Use AppText.title instead. sheetTitle is 20/700 and will be '
      'retired when the bottom sheet header is migrated in sub-project 2.')
  static TextStyle get sheetTitle => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  /// 20 / 800 · stat bubble number (earnings/tasks counters)
  static TextStyle get statNumber => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.ink,
      );

  /// 20 / 600 / white · primary button label
  static TextStyle get ctaLabel => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  /// 17 / 600 · list row titles, tagline, primary body
  static TextStyle get listItem => GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  /// 16 / 600 · toast title, emphasized body
  static TextStyle get bodyStrong => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  /// 15 / 500 · subcopy, descriptions, secondary text
  static TextStyle get body => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.inkSecondary,
      );

  /// 14 / 600 · meta labels, pill labels, captions
  static TextStyle get caption => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.inkTertiary,
      );
}
