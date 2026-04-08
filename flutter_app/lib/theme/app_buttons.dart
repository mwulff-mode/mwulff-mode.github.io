import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Button style constants for EarnWise. Use these instead of inlining
/// `ElevatedButton.styleFrom(...)` so the primary CTA stays identical
/// across screens.
class AppButtonStyles {
  AppButtonStyles._();

  /// Filled teal CTA, 60px height, 16px radius, 0 elevation.
  /// Used on welcome, trust, onboarding, and the game picker sheet.
  static ButtonStyle get primary => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        minimumSize: const Size(double.infinity, 60),
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      );

  /// Outlined teal CTA, 58px height. Used as the secondary auth button
  /// ("Continue with Apple") on the welcome screen.
  static ButtonStyle get primaryOutline => OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 58),
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
}
