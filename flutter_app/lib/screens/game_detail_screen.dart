import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../data/games.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/press_scale.dart';

const double _kHeroBandHeight = 220.0;

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
      body: Stack(
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
                  const _TopProgressBar(),
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
                style: AppText.brandMark.copyWith(fontSize: 28),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const _EarningBadge(amount: 1.00),
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
            const SizedBox(width: 4),
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
/// Progress is always 0 in v1 because no steps complete in-session.
class _TopProgressBar extends StatelessWidget {
  const _TopProgressBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\$0.00 earned of \$1.00',
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
