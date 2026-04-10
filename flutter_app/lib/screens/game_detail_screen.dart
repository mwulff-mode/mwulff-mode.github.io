import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../data/games.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_gradient_bg.dart';
import '../widgets/physical_press.dart';
import '../widgets/press_scale.dart';

const double _kHeroBandHeight = 220.0;
const double _kSectionHeadingLetterSpacing = 1.6;
const double _kStepCardWidth = 180.0;
const double _kStepCardHeight = 160.0;

/// Full-page detail view for a single game. Opens after the user picks a
/// game from the home screen game picker. The X button in the hero band
/// pops the screen without committing. The sticky Install CTA at the
/// bottom (added in a later task) commits via [onInstall] and then pops.
class GameDetailScreen extends StatelessWidget {
  final Game game;
  final VoidCallback onInstall;

  const GameDetailScreen({
    super.key,
    required this.game,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final heroHeight = _kHeroBandHeight + topPadding;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AnimatedGradientBg(
        child: Stack(
        children: [
          // Hero band, full width, gradient with centered icon.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Container(
              padding: EdgeInsets.only(top: topPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: game.heroGradient,
                ),
              ),
              child: Center(
                child: _GameIcon(game: game),
              ),
            ),
          ),
          // Scrolling content begins under the hero.
          Positioned.fill(
            top: heroHeight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: AppLayout.gutter,
                right: AppLayout.gutter,
                top: AppSpacing.lg,
                bottom: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleRow(game: game),
                  const SizedBox(height: AppSpacing.lg),
                  _HowItWorksSection(game: game),
                  const SizedBox(height: AppSpacing.xl),
                  _RegularStepsSection(game: game),
                  const SizedBox(height: AppSpacing.xl),
                  _AboutSection(game: game),
                  const SizedBox(height: AppSpacing.xl),
                  _DisclaimerSection(game: game),
                ],
              ),
            ),
          ),
          // X close button, top right, inside safe area.
          Positioned(
            top: topPadding + 12,
            right: 20,
            child: PressScale(
              key: const Key('game_detail_close'),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creamDeep,
                ),
                child: Icon(
                  PhosphorIcons.x(PhosphorIconsStyle.bold),
                  size: 18,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppLayout.gutter,
          AppSpacing.md,
          AppLayout.gutter,
          AppSpacing.md,
        ),
        child: PhysicalPress(
          key: const Key('game_detail_install'),
          onTap: () {
            // Fire onInstall before pop so the caller's state update runs
            // while this route is still mounted.
            onInstall();
            Navigator.of(context).pop();
          },
          backgroundColor: AppColors.primary,
          shadowColor: AppColors.primaryDark,
          depth: 6,
          height: 68,
          haptic: HapticIntensity.confirm,
          child: Text('Install Game', style: AppText.ctaLabel),
        ),
      ),
    );
  }
}

/// Game name on the left, max-earning badge on the right. A second line
/// shows the rating (Phosphor star plus number) and the category, separated
/// by a centered dot.
class _TitleRow extends StatelessWidget {
  final Game game;

  const _TitleRow({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                game.name,
                style: AppText.gameTitle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _EarningBadge(amount: game.maxEarning),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              PhosphorIcons.star(PhosphorIconsStyle.fill),
              size: 16,
              color: AppColors.gold,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              game.rating.toStringAsFixed(1),
              style: AppText.caption.copyWith(color: AppColors.inkSecondary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '·',
              style: AppText.caption.copyWith(color: AppColors.inkTertiary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              game.category,
              style: AppText.caption.copyWith(color: AppColors.inkSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pill-shaped earning badge. Primary-pale background, primary text,
/// shows a dollar amount.
class _EarningBadge extends StatelessWidget {
  final double amount;

  const _EarningBadge({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Text(
        '\$${amount.toStringAsFixed(2)}',
        style: AppText.bodyStrong.copyWith(color: AppColors.primary),
      ),
    );
  }
}

/// Top progress bar. Cream-deep track, primary fill, label row above.
/// `earned` is hardcoded to $0.00 in v1 because no steps complete in-session.
/// `total` is the maximum dollars earnable across all regular steps for
/// the current game.
class _TopProgressBar extends StatelessWidget {
  final double total;

  const _TopProgressBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\$0.00 earned of \$${total.toStringAsFixed(2)}',
          style: AppText.caption.copyWith(color: AppColors.inkSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.creamDeep,
            borderRadius: BorderRadius.circular(4),
          ),
          // Foreground fill is rendered as a 0-width container in v1.
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Displays the square game icon at 120 pt, with a colored letter-square
/// fallback when the asset cannot be loaded. Used inside the hero band so
/// the screen never crashes when art is missing.
class _GameIcon extends StatelessWidget {
  final Game game;

  const _GameIcon({required this.game});

  static const double _size = 120;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_size * 0.22),
      child: Image.asset(
        game.iconPath,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: _size,
            height: _size,
            color: game.heroGradient.isNotEmpty
                ? game.heroGradient.first
                : AppColors.creamDeep,
            alignment: Alignment.center,
            child: Text(
              game.name.isEmpty ? '?' : game.name[0].toUpperCase(),
              style: AppText.display.copyWith(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

/// The eyebrow heading style used by every section. Optional trailing
/// widget slot for a counter or icon.
class _SectionHeading extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionHeading({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.listItem.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// HOW IT WORKS section: heading plus a short paragraph.
class _HowItWorksSection extends StatelessWidget {
  final Game game;

  const _HowItWorksSection({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(label: 'How It Works'),
        Text(
          game.howItWorks,
          style: AppText.body.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

/// "ABOUT {game name}" section: heading plus a short blurb.
class _AboutSection extends StatelessWidget {
  final Game game;

  const _AboutSection({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(label: 'About ${game.name}'),
        Text(
          game.about,
          style: AppText.body.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

/// DISCLAIMER section: heading plus fine print.
class _DisclaimerSection extends StatelessWidget {
  final Game game;

  const _DisclaimerSection({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(label: 'Disclaimer'),
        // Fine print is intentionally lighter than the default caption weight
        // (w600) so it reads as legal copy rather than as an active label.
        Text(
          game.disclaimer,
          style: AppText.caption.copyWith(
            color: AppColors.inkTertiary,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Visual state of a regular step. v1 only ever uses [notStarted] and
/// [upNext]; [completed] is included so the same widget can render the
/// future "in progress" state without a follow-up refactor.
enum _StepState { notStarted, upNext, completed }

/// REGULAR STEPS section: heading with a counter trailing widget plus
/// a horizontal scroll list of [_StepCard]s.
class _RegularStepsSection extends StatelessWidget {
  final Game game;

  const _RegularStepsSection({required this.game});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          label: 'Reward Steps',
          trailing: Text(
            '0 / ${game.regularSteps.length}',
            style: AppText.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ),
        SizedBox(
          height: _kStepCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: game.regularSteps.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final step = game.regularSteps[index];
              final state =
                  index == 0 ? _StepState.upNext : _StepState.notStarted;
              return _StepCard(step: step, state: state);
            },
          ),
        ),
      ],
    );
  }
}

/// One step card. Replicates the AppCard visual recipe inline because
/// AppCard does not support a fixed width. White background, 18 radius,
/// cream-deep border, soft shadow. State pill at the top, label in the
/// middle, reward at the bottom.
class _StepCard extends StatelessWidget {
  final GameStep step;
  final _StepState state;

  const _StepCard({required this.step, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kStepCardWidth,
      padding: const EdgeInsets.all(AppSpacing.md),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatePill(state: state),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              step.label,
              style: AppText.listItem,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${step.reward.toStringAsFixed(2)}',
            style: AppText.bodyStrong.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// The state pill shown at the top of each step card. Three states map
/// to three color treatments. The pill text is taken from the enum.
class _StatePill extends StatelessWidget {
  final _StepState state;

  const _StatePill({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (state) {
      _StepState.notStarted => (
          'NOT STARTED',
          AppColors.creamDeep,
          AppColors.inkTertiary
        ),
      _StepState.upNext => (
          'UP NEXT',
          AppColors.primaryPale,
          AppColors.primary
        ),
      _StepState.completed => (
          'COMPLETED',
          AppColors.primaryLight,
          AppColors.primaryDark
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: fg,
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
