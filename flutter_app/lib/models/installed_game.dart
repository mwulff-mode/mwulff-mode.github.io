/// A minimal per-game state record used by the Post-Onboarding Home
/// "Continue earning" section. This is a v1 placeholder. Sub-project 3
/// (Tasks list screen) may replace this with a richer model.
class InstalledGame {
  final String id;
  final String name;
  final String iconPath;
  final String nextMilestoneLabel;
  final double nextMilestoneReward;
  final DateTime lastPlayedAt;

  const InstalledGame({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.nextMilestoneLabel,
    required this.nextMilestoneReward,
    required this.lastPlayedAt,
  });

  /// True when the user still has at least one milestone to complete.
  /// v1 assumes any seeded game with a positive reward is in progress.
  bool get hasRemainingMilestones => nextMilestoneReward > 0;
}
