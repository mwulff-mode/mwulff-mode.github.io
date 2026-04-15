import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';
import '../widgets/fade_route.dart';
import '../widgets/press_scale.dart';
import '../widgets/primary_button.dart';
import 'welcome_screen.dart';

/// Bottom padding reserved inside the scroll view so the last element
/// sits above the floating nav pill that HomeShell overlays above
/// every tab. Matches the pill height plus breathing room.
const double _kNavClearance = 140.0;

/// Letter spacing applied to section headings. Matches the same value
/// used by game_detail_screen.dart so the two screens render identical
/// eyebrow headings. A future task extracts both into a shared widget.
const double _kSectionHeadingLetterSpacing = 1.6;

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
    return SafeArea(
      key: const Key('profile_screen_root'),
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final t = context.theme;
            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: AppLayout.gutter,
                right: AppLayout.gutter,
                top: 32,
                bottom: _kNavClearance,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Profile', style: AppText.sectionTitle),
                      ),
                      PressScale(
                        onTap: () {},
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.gear(PhosphorIconsStyle.fill),
                            size: 20,
                            color: t.palette.inkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ProfileHero(state: state),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionHeading(label: 'PERSONAL INFO'),
                  _InfoCard(state: state),
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionHeading(label: 'ACCOUNT'),
                  _AccountCard(state: state),
                  const SizedBox(height: AppSpacing.xl),
                  const _SignOutButton(),
                ],
              ),
            );
          },
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
    final initials =
        state.displayName[0].toUpperCase();
    return _AvatarCircle(initials: initials);
  }
}

/// Teal circle with white initials centered and a soft primary-alpha
/// glow layer behind it.
class _AvatarCircle extends StatelessWidget {
  final String initials;

  const _AvatarCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
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
                  t.palette.brand.withValues(alpha: 0.3),
                  t.palette.brand.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          // Avatar face.
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.palette.brand,
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
    final t = context.theme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'via',
          style: AppText.caption.copyWith(color: t.palette.inkTertiary),
        ),
        const SizedBox(width: 6),
        const _GoogleLogo(size: 20),
        const SizedBox(width: 6),
        Text(
          provider,
          style: AppText.caption.copyWith(color: t.palette.ink),
        ),
      ],
    );
  }
}

/// Google G logo from SVG asset.
class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logos/svg/Google_Logo.svg',
      width: size,
      height: size,
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
    final t = context.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: t.palette.inkTertiary,
            letterSpacing: _kSectionHeadingLetterSpacing,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Outer card wrapping three _InfoRow children with thin dividers.
/// Replicates the AppCard visual recipe inline (surfaceRaised,
/// radii.card, hairline border, elevation.card) because the profile
/// info card is a fixed three-row layout that does not need the
/// AppCard widget's tap-target behavior.
class _InfoCard extends StatelessWidget {
  final AppState state;

  const _InfoCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Container(
      decoration: BoxDecoration(
        color: t.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(t.radii.card),
        border: Border.all(color: t.palette.hairline, width: 1.5),
        boxShadow: t.elevation.card,
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
            label: 'Full Name',
            value: state.displayName,
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
    final t = context.theme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.palette.brand.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Icon(icon, size: 22, color: t.palette.brand),
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
                      AppText.caption.copyWith(color: t.palette.inkSecondary),
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
            color: t.palette.inkTertiary,
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
    final t = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Divider(
        height: 1,
        thickness: 1,
        color: t.palette.hairline,
      ),
    );
  }
}

/// Outer card for the connected account row. Same AppCard visual
/// recipe as _InfoCard (surfaceRaised, radii.card, hairline border,
/// elevation.card) but holds only one row because there is only one
/// connected account in v1.
class _AccountCard extends StatelessWidget {
  final AppState state;

  const _AccountCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Container(
      decoration: BoxDecoration(
        color: t.palette.surfaceRaised,
        borderRadius: BorderRadius.circular(t.radii.card),
        border: Border.all(color: t.palette.hairline, width: 1.5),
        boxShadow: t.elevation.card,
      ),
      child: _AccountRow(state: state),
    );
  }
}

/// Connected Account row: Google logo on the left, label above the
/// email in the middle, lock icon on the right. The lock icon signals
/// that this row is not editable (unlike the decorative pencil icons
/// on _InfoRow).
class _AccountRow extends StatelessWidget {
  final AppState state;

  const _AccountRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const _GoogleLogo(size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Account',
                  style:
                      AppText.caption.copyWith(color: t.palette.inkSecondary),
                ),
                const SizedBox(height: 2),
                Text(state.email, style: AppText.listItem),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            PhosphorIcons.lock(PhosphorIconsStyle.regular),
            size: 20,
            color: t.palette.inkTertiary,
          ),
        ],
      ),
    );
  }
}

/// Destructive pill button. Full width. Tap calls AppState.reset()
/// and then pushes the welcome screen onto a cleared navigation stack.
/// Uses the destructive variant of PrimaryButton so the haptic feedback
/// and color treatment both signal a destructive action.
class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      key: const Key('profile_sign_out'),
      label: 'Sign Out',
      destructive: true,
      haptic: HapticIntensity.warning,
      onTap: () {
        context.read<AppState>().reset();
        Navigator.of(context).pushAndRemoveUntil(
          fadeRoute(const WelcomeScreen()),
          (route) => false,
        );
      },
    );
  }
}
