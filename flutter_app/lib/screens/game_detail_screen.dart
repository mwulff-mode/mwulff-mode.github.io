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

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Hero band, partial in this task: gradient + close button only.
          // Title, icon, and the rest of the page are added in later tasks.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _kHeroBandHeight + topPadding,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: game.heroGradient,
                ),
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
          // Below the hero, a positioned Text holds the game name so the
          // first widget test can find it. The real title row is added in
          // a later task and replaces this stub.
          Positioned(
            top: _kHeroBandHeight + topPadding + 24,
            left: 24,
            child: Text(game.name, style: AppText.sectionTitle),
          ),
        ],
      ),
    );
  }
}
