import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Bottom padding reserved inside the scroll view so the last element
/// sits above the floating nav pill that HomeShell overlays above
/// every tab. Matches the pill height plus breathing room.
const double _kNavClearance = 140.0;

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
                bottom: _kNavClearance,
              ),
              child: Column(
                children: [
                  _ProfileHero(state: state),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeading(label: 'PERSONAL INFO'),
                  _InfoCard(state: state),
                  // Account and Sign Out are added in subsequent tasks.
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
          // Glow layer: slightly larger soft circle behind the avatar face.
          Container(
            width: 140,
            height: 140,
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
            child: Center(
              child: Text(
                initials,
                style: AppText.display.copyWith(color: Colors.white),
              ),
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

/// The eyebrow heading style used by every section on the profile.
/// Uppercase, letter-spaced, ink-tertiary, weight 700. Matches the same
/// recipe used by the game detail screen's _SectionHeading.
class _SectionHeading extends StatelessWidget {
  final String label;

  const _SectionHeading({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.inkTertiary,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Outer card wrapping three _InfoRow children with thin dividers.
/// Replicates the AppCard visual recipe inline (white, 18 radius,
/// cream-deep border, soft shadow) because the profile info card is
/// a fixed three-row layout that does not need the AppCard widget's
/// tap-target behavior.
class _InfoCard extends StatelessWidget {
  final AppState state;

  const _InfoCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.creamDeep, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
            label: 'Full Name',
            value: state.userName,
          ),
          const _RowDivider(),
          _InfoRow(
            icon: PhosphorIcons.calendar(PhosphorIconsStyle.regular),
            label: 'Age Range',
            value: state.ageRange,
          ),
          const _RowDivider(),
          _InfoRow(
            icon: PhosphorIcons.usersThree(PhosphorIconsStyle.regular),
            label: 'Gender',
            value: state.gender,
          ),
        ],
      ),
    );
  }
}

/// One row inside _InfoCard. Circular icon tile on the left, label
/// above value in the middle, decorative pencil icon on the right.
/// The pencil icon has no tap handler in v1.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      AppText.caption.copyWith(color: AppColors.inkSecondary),
                ),
                const SizedBox(height: 2),
                Text(value, style: AppText.listItem),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            PhosphorIcons.pencilSimpleLine(PhosphorIconsStyle.regular),
            size: 20,
            color: AppColors.inkTertiary,
          ),
        ],
      ),
    );
  }
}

/// 1 px cream-deep divider inset from both sides by AppSpacing.md so it
/// does not touch the card border.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.creamDeep,
      ),
    );
  }
}
