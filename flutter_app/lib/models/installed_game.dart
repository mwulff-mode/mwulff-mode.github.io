import '../data/games.dart';

/// A minimal per-game state record used by the Post-Onboarding Home
/// "Continue earning" section and the Game Detail screen's milestone
/// strip.
class InstalledGame {
  final String id;
  final String name;
  final String iconPath;
  final String nextMilestoneLabel;
  final double nextMilestoneReward;
  final DateTime lastPlayedAt;

  /// Which milestone indices the user has already finished for this game.
  /// Indices refer to [Game.regularSteps]. Populated when the game was
  /// installed through onboarding (milestone 0 = "Install the app"). The
  /// Game Detail screen reads this to render completed / upNext states.
  final Set<int> completedMilestoneIndices;

  const InstalledGame({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.nextMilestoneLabel,
    required this.nextMilestoneReward,
    required this.lastPlayedAt,
    this.completedMilestoneIndices = const {},
  });

  /// Builds an [InstalledGame] from a catalog [Game]. Use this when the
  /// user installs a game through the onboarding picker. Milestone 0
  /// (the install step) is marked completed by default, so the next
  /// visible milestone is index 1.
  factory InstalledGame.fromCatalog(
    Game catalog, {
    Set<int> completed = const {0},
    DateTime? lastPlayedAt,
  }) {
    final nextIndex = _firstIncompleteIndex(catalog, completed);
    final nextStep = catalog.regularSteps[nextIndex];
    return InstalledGame(
      id: catalog.key,
      name: catalog.name,
      iconPath: catalog.iconPath,
      nextMilestoneLabel: nextStep.label,
      nextMilestoneReward: nextStep.reward,
      lastPlayedAt: lastPlayedAt ?? DateTime.now(),
      completedMilestoneIndices: completed,
    );
  }

  static int _firstIncompleteIndex(Game catalog, Set<int> completed) {
    for (var i = 0; i < catalog.regularSteps.length; i++) {
      if (!completed.contains(i)) return i;
    }
    // All done: fall back to the last index so callers that read
    // nextMilestoneLabel still see something sensible.
    return catalog.regularSteps.length - 1;
  }

  /// True when the user still has at least one milestone to complete.
  /// v1 assumes any game with a positive reward is in progress.
  bool get hasRemainingMilestones => nextMilestoneReward > 0;
}
