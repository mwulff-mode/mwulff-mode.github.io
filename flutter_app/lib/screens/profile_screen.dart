import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
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
      key: const Key('profile_screen_root'),
      color: AppColors.cream,
      child: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: AppLayout.gutter,
                right: AppLayout.gutter,
                top: AppSpacing.xl,
                // Extra bottom padding so the last element sits above the
                // floating nav pill overlay that HomeShell renders above
                // every tab.
                bottom: 140,
              ),
              child: Column(
                children: [
                  _ProfileHero(state: state),
                  // Personal Info, Account, and Sign Out are added in
                  // subsequent tasks.
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Hero block: avatar circle with initials on top, email and provider
/// badge below.
class _ProfileHero extends StatelessWidget {
  final AppState state;

  const _ProfileHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final initials = state.userName.isEmpty
        ? '?'
        : state.userName[0].toUpperCase();
    return Column(
      children: [
        _AvatarCircle(initials: initials),
        const SizedBox(height: AppSpacing.lg),
        Text(
          state.email,
          style: AppText.body.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        _ProviderBadge(provider: state.authProvider),
      ],
    );
  }
}

/// Teal circle with white initials centered and a soft primary-alpha
/// glow layer behind it.
class _AvatarCircle extends StatelessWidget {
  final String initials;

  const _AvatarCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow layer: slightly larger soft circle behind the avatar.
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          // Avatar face.
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppText.display.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// "via [G] Google" row shown under the email.
class _ProviderBadge extends StatelessWidget {
  final String provider;

  const _ProviderBadge({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'via',
          style: AppText.caption.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(width: 6),
        const _GoogleLogo(size: 20),
        const SizedBox(width: 6),
        Text(
          provider,
          style: AppText.caption.copyWith(color: AppColors.ink),
        ),
      ],
    );
  }
}

/// Google G logo asset with a letter fallback for when the asset is
/// missing. Same pattern as the game detail screen's game icon.
class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/google_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Text(
              'G',
              style: AppText.caption.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.62,
              ),
            ),
          );
        },
      ),
    );
  }
}
