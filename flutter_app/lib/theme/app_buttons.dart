import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Button style constants for EarnWise. Use these instead of inlining
/// `ElevatedButton.styleFrom(...)` so the primary CTA stays identical
/// across screens.
class AppButtonStyles {
  AppButtonStyles._();

  /// Filled teal CTA, 68px height, full-round corners, 0 elevation.
  /// Used on welcome, trust, onboarding, and the game picker sheet.
  static ButtonStyle get primary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        minimumSize: const Size(double.infinity, 68),
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: const StadiumBorder(),
        elevation: 0,
      );

  /// Outlined teal CTA, 66px height, full-round corners. Used as the
  /// secondary auth button ("Continue with Apple") on the welcome screen.
  static ButtonStyle get primaryOutline => OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 66),
        padding: const EdgeInsets.symmetric(vertical: 22),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        shape: const StadiumBorder(),
      );
}
