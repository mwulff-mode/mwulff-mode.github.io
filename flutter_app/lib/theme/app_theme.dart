import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const cream = Color(0xFFFAF8F5);
  static const creamDeep = Color(0xFFF2EDE6);
  static const creamWarm = Color(0xFFF8F3EC);

  // Primary: Teal
  static const primary = Color(0xFF0D9488);
  static const primaryLight = Color(0xFFCCFBF1);
  static const primaryPale = Color(0xFFF0FDFA);
  static const primaryDark = Color(0xFF0F766E);

  // Accent: Warm gold (from Indigo variant)
  static const accent = Color(0xFFF59E0B);
  static const accentLight = Color(0xFFFEF3C7);
  static const secondary = Color(0xFF14B8A6);
  static const secondaryLight = Color(0xFFCCFBF1);

  // Task colors: Indigo variant (vibrant, game-adjacent)
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

  // Progress: Teal
  static const progress = Color(0xFF0D9488);
  static const progressLight = Color(0xFFCCFBF1);

  // Flame (streak, daily tasks)
  static const flame = Color(0xFFFF6B35);
  static const flameBg = Color(0xFFFFF4ED);

  // Teal secondary (gift gradient endpoint)
  static const tealSecondary = Color(0xFF2BA08E);

  // Ink
  static const ink = Color(0xFF3B3230);
  static const inkSecondary = Color(0xFF6B5E58);
  static const inkTertiary = Color(0xFF8A7D76);
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFD4A843);

  // Ring track (lighter for teal/indigo)
  static const ringTrack = Color(0xFFE2E8F0);
}

/// Vertical/horizontal spacing scale. Use these instead of raw pixel values
/// so rhythm stays consistent across screens.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Page-level layout constants (gutters, content width caps).
class AppLayout {
  /// Default horizontal gutter for screen content.
  static const double gutter = 24;

  /// Maximum width for reading content on wide viewports (tablet/desktop).
  static const double maxContentWidth = 640;
}

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
