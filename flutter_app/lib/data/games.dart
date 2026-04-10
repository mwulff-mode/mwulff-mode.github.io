import 'dart:ui' show Color;
import 'package:flutter/foundation.dart' show immutable;
import '../theme/app_theme.dart';

/// One step in a game's reward ladder.
@immutable
class GameStep {
  final String label;
  final double reward;

  const GameStep({required this.label, required this.reward});
}

/// All the data needed to render a game detail page.
@immutable
class Game {
  /// Stable internal id, lowercase snake_case. Matches the filename of the
  /// icon asset.
  final String key;

  /// Display name. Used as the lookup key in [gamesByName] and as the title
  /// shown on the detail screen.
  final String name;

  /// Short category label like 'Puzzle' or 'Card'.
  final String category;

  /// 0.0 to 5.0 star rating. Hardcoded per game.
  final double rating;

  /// Asset path under `assets/images/games/`. The detail screen uses an
  /// `errorBuilder` fallback so a missing file does not crash the build.
  final String iconPath;

  /// Two color stops used by the hero band gradient.
  final List<Color> heroGradient;

  /// Ordered reward steps shown on the detail screen ladder.
  final List<GameStep> regularSteps;

  /// Short paragraph for the HOW IT WORKS section.
  final String howItWorks;

  /// 2 to 3 sentence game blurb for the ABOUT section.
  final String about;

  /// Fine print for the DISCLAIMER section.
  final String disclaimer;

  const Game({
    required this.key,
    required this.name,
    required this.category,
    required this.rating,
    required this.iconPath,
    required this.heroGradient,
    required this.regularSteps,
    required this.howItWorks,
    required this.about,
    required this.disclaimer,
  });

  /// Total dollar amount earnable across all regular steps. Computed from
  /// [regularSteps] so it stays in sync with the data instead of being a
  /// duplicate literal that can drift.
  double get maxEarning =>
      regularSteps.fold<double>(0.0, (sum, step) => sum + step.reward);
}

/// All games shown in the picker, keyed by display name. The picker sheet
/// pops with the display name as its result, so the home screen can look
/// the matching `Game` up directly with `gamesByName[picked]`.
const Map<String, Game> gamesByName = {
  'Candy Crush': Game(
    key: 'candy_crush',
    name: 'Candy Crush',
    category: 'Puzzle',
    rating: 4.7,
    iconPath: 'assets/app_icons/Candy_Crush_Saga.png',
    heroGradient: [AppColors.taskVideo, AppColors.accent],
    regularSteps: [
      GameStep(label: 'Install the app', reward: 0.10),
      GameStep(label: 'Reach Level 15', reward: 0.90),
      GameStep(label: 'Reach Level 50', reward: 2.00),
      GameStep(label: 'Reach Level 100', reward: 4.00),
      GameStep(label: 'Reach Level 200', reward: 8.00),
      GameStep(label: 'Reach Level 350', reward: 12.00),
    ],
    howItWorks:
        'Download the app for free, swap candies to clear the puzzles, and earn dollars when you hit each milestone. The further you get, the more you earn.',
    about:
        'A bright, casual matching game where you swap and chain colored candies to clear the board. Great for short sessions while you wait for the bus.',
    disclaimer:
        'Rewards credit to your EarnWise balance after each milestone is verified. Some milestones can take a few hours to confirm.',
  ),
  'Solitaire': Game(
    key: 'solitaire',
    name: 'Solitaire',
    category: 'Card',
    rating: 4.6,
    iconPath: 'assets/app_icons/Solitaire_Classic.png',
    heroGradient: [AppColors.primary, AppColors.creamDeep],
    regularSteps: [
      GameStep(label: 'Install the app', reward: 0.10),
      GameStep(label: 'Win 25 games', reward: 0.90),
      GameStep(label: 'Win 75 games', reward: 2.50),
      GameStep(label: 'Win 150 games', reward: 5.00),
      GameStep(label: 'Win 300 games', reward: 9.00),
      GameStep(label: 'Win 500 games', reward: 8.50),
    ],
    howItWorks:
        'Download the app for free, sort cards into the four foundation piles, and earn dollars when you hit each milestone. The further you get, the more you earn.',
    about:
        'The classic single-player card game. Stack cards in descending order, build the foundations, and finish a hand in a few quiet minutes.',
    disclaimer:
        'Rewards credit to your EarnWise balance after each milestone is verified. Some milestones can take a few hours to confirm.',
  ),
  'Word Search': Game(
    key: 'word_search',
    name: 'Word Search',
    category: 'Word',
    rating: 4.5,
    iconPath: 'assets/app_icons/Word_Search.png',
    heroGradient: [AppColors.taskCheckin, AppColors.creamWarm],
    regularSteps: [
      GameStep(label: 'Install the app', reward: 0.10),
      GameStep(label: 'Complete 20 puzzles', reward: 0.90),
      GameStep(label: 'Complete 60 puzzles', reward: 2.00),
      GameStep(label: 'Complete 120 puzzles', reward: 4.50),
      GameStep(label: 'Complete 250 puzzles', reward: 7.50),
      GameStep(label: 'Complete 400 puzzles', reward: 10.00),
    ],
    howItWorks:
        'Download the app for free, find every word hidden in the grid, and earn dollars when you hit each milestone. The further you get, the more you earn.',
    about:
        'A relaxing puzzle game where you trace hidden words in a grid of letters. New themes and word lists are added every week.',
    disclaimer:
        'Rewards credit to your EarnWise balance after each milestone is verified. Some milestones can take a few hours to confirm.',
  ),
};
