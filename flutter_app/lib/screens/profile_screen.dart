import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-page profile surface shown as the third tab inside [HomeShell].
/// Displays the user's avatar, email, fictional personal info fields,
/// a connected-account row, and a Sign Out button.
///
/// v1 is intentionally a demo surface: the edit icons are decorative,
/// the auth provider is hardcoded, and Sign Out just calls
/// [AppState.reset] and sends the user back to welcome.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      // Content is added in subsequent tasks.
    );
  }
}
