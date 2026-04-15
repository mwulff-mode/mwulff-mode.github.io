import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/games.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';
import '../theme/theme_catalog.dart';
import '../services/haptics.dart';
import '../models/installed_game.dart';

class JourneyEntry {
  final String msg;
  final String? context;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String time;
  final String date;

  JourneyEntry({
    required this.msg,
    this.context,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.time,
    this.date = 'Today',
  });
}

class Goal {
  final int level;
  final int goalStars;
  final Color ringColor;
  final Color trackColor;

  const Goal({
    required this.level,
    required this.goalStars,
    required this.ringColor,
    required this.trackColor,
  });
}

const goals = [
  Goal(
      level: 1,
      goalStars: 1500,
      ringColor: Color(0xFF0D9488),
      trackColor: Color(0xFFE2E8F0)),
  Goal(
      level: 2,
      goalStars: 3750,
      ringColor: Color(0xFF0D9488),
      trackColor: Color(0xFFE2E8F0)),
  Goal(
      level: 3,
      goalStars: 10000,
      ringColor: Color(0xFF6366F1),
      trackColor: Color(0xFFE8E5FF)),
  Goal(
      level: 4,
      goalStars: 25000,
      ringColor: Color(0xFF6366F1),
      trackColor: Color(0xFFE8E5FF)),
  Goal(
      level: 5,
      goalStars: 50000,
      ringColor: Color(0xFFF59E0B),
      trackColor: Color(0xFFFEF3C7)),
  Goal(
      level: 6,
      goalStars: 100000,
      ringColor: Color(0xFFF59E0B),
      trackColor: Color(0xFFFEF3C7)),
];

const legendColor = Color(0xFFF59E0B);
const legendTrackColor = Color(0xFFFEF3C7);

class AppState extends ChangeNotifier {
  String userName = '';
  int stars = 0;
  int earnedToday = 0;
  int goalIndex = 0;
  int tasksCompleted = 0;
  bool screen5Played = false;
  bool welcomeModalShown = false;
  int streakCount = 0;
  bool isLegend = false;
  Set<String> completedTasks = {};
  String? lastCompletedTask;
  bool hasRedeemed = false;
  List<String> selectedPreferences = [];
  List<JourneyEntry> journeyLog = [];

  /// Active theme. Session-only; reset by [reset]. Default is Cream so a
  /// fresh install / sign-out always lands in the original identity.
  EarnWiseTheme currentTheme = kCreamTheme;

  /// Swaps the active theme and rebuilds the app through the `Consumer`
  /// in `main.dart`. No-op when the requested theme is already active, to
  /// avoid a needless `notifyListeners()` traversal.
  void setTheme(EarnWiseTheme theme) {
    if (currentTheme == theme) return;
    currentTheme = theme;
    notifyListeners();
  }

  // Daily goal (post-onboarding). earnedToday is reused as the progress
  // counter; it resets at local midnight via checkDailyReset.
  // The ring auto-extends from $2 to $5 the first time the user crosses
  // today's goal, so [dailyGoalStars] flips from 1500 to 3750 mid-session
  // while [earnedToday] stays put (the crossed amount becomes locked-in
  // progress on the bigger ring). [dailyGoalExtended] is the one-time
  // guard that prevents a second auto-extension and resets at midnight.
  int dailyGoalStars = 1500; // $2.00
  bool dailyGoalExtended = false;

  // In-progress games for the Post-Onboarding Home "Continue earning"
  // section. Populated when the user installs a game through the
  // onboarding picker (see [installGameFromOnboarding]); stays empty
  // before that so Game Detail never shows "Continue playing" for a
  // game the user has not actually installed yet.
  List<InstalledGame> installedGames = [];

  List<InstalledGame> get inProgressGames {
    final filtered =
        installedGames.where((g) => g.hasRemainingMilestones).toList();
    filtered.sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    return filtered;
  }

  String _dailyResetDate = ''; // yyyy-MM-dd of last reset, empty until first check
  bool _dailyGoalCelebrated = false; // rising-edge guard for the goal-hit celebration

  // Conversational card state
  String convCardMsg = '';
  IconData convCardIcon = Icons.waving_hand;
  Color convCardIconColor = AppColors.primary;
  Color convCardIconBg = AppColors.primaryPale;

  // Profile fields (fictional demo values, surfaced on ProfileScreen)
  String get displayName => userName.isEmpty ? 'Jane Doe' : userName;

  String get email {
    final name = displayName.toLowerCase().replaceAll(' ', '.');
    return '$name@gmail.com';
  }
  String authProvider = 'Google'; // 'Google' | 'Apple'
  String ageRange = '26-35';
  String gender = 'Female';

  // Conversion: 750 stars = $1.00
  static const double starsPerDollar = 750;

  Goal get currentGoal => goals[goalIndex];
  int get goalStartStars => goalIndex == 0 ? 0 : goals[goalIndex - 1].goalStars;
  bool get isLastGoal => goalIndex >= goals.length - 1;

  double get goalProgress {
    if (isLegend) return 100;
    return ((stars - goalStartStars) /
            (currentGoal.goalStars - goalStartStars) *
            100)
        .clamp(0, 100);
  }

  Color get ringColor => isLegend ? legendColor : currentGoal.ringColor;
  Color get trackColor => isLegend ? legendTrackColor : currentGoal.trackColor;

  /// Ring color used by the post-onboarding Home ring. Flips to a cool
  /// violet once today's goal has auto-extended past $2, so the "level up"
  /// moment is visually distinct from the starting teal tier.
  Color get dailyRingColor =>
      dailyGoalExtended ? AppColors.categoryCheckin : ringColor;
  Color get dailyTrackColor =>
      dailyGoalExtended ? AppColors.categoryCheckinBg : trackColor;

  /// Progress-arc color overlaid on the daily ring disc. Matches the
  /// lighter-variant treatment of the starter teal tier: brand teal disc
  /// plus brighter [AppColors.tealRing] arc, so after the level-up flip
  /// the violet disc gets its own brighter [AppColors.violetRing] arc.
  Color get dailyArcColor =>
      dailyGoalExtended ? AppColors.violetRing : AppColors.tealRing;

  String get currentTimeFormatted {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${now.minute.toString().padLeft(2, '0')} $period';
  }

  static double starsToDollars(int s) => s / starsPerDollar;

  String formatBalance() {
    return '\$${starsToDollars(stars).toStringAsFixed(2)}';
  }

  String formatRingProgress() {
    if (isLegend) return '';
    return '${formatNumber(stars)} / ${formatNumber(currentGoal.goalStars)}';
  }

  String formatToday() {
    return '\$${starsToDollars(stars).toStringAsFixed(2)} today';
  }

  /// Dollars earned from tasks this session (excludes welcome gift).
  String formatEarnedToday() {
    return '\$${starsToDollars(earnedToday).toStringAsFixed(2)}';
  }

  /// The current goal target formatted as dollars.
  String formatGoal() {
    if (isLegend) return '∞';
    return '\$${starsToDollars(currentGoal.goalStars).toStringAsFixed(2)}';
  }

  /// Today's daily goal target formatted as dollars ($2.00 default,
  /// $3.00 after a Push). Used as the label inside the ring post-onboarding.
  String formatDailyGoal() {
    return '\$${starsToDollars(dailyGoalStars).toStringAsFixed(2)}';
  }

  /// Progress toward today's daily goal as a percentage 0..100. Used by
  /// the ring post-onboarding, where the ring tracks the daily goal rather
  /// than the lifetime goal.
  double get dailyGoalProgress =>
      ((earnedToday / dailyGoalStars) * 100).clamp(0, 100);

  static String formatNumber(int n) {
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final remainder = n % 1000;
      if (remainder == 0) return '$thousands,000';
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return '$n';
  }

  void setUserName(String name) {
    userName = name;
    convCardMsg = 'Hey $userName, let\'s start earning';
    notifyListeners();
  }

  void togglePreference(String pref) {
    if (selectedPreferences.contains(pref)) {
      selectedPreferences.remove(pref);
    } else {
      selectedPreferences.add(pref);
    }
    notifyListeners();
  }

  void addJourneyEntry(
      String msg, String? context, IconData icon, Color color, Color bg) {
    journeyLog.insert(
        0,
        JourneyEntry(
          msg: msg,
          context: context,
          icon: icon,
          iconColor: color,
          iconBg: bg,
          time: currentTimeFormatted,
        ));
    convCardMsg = msg.replaceAll(RegExp(r'<[^>]*>'), '');
    convCardIcon = icon;
    convCardIconColor = color;
    convCardIconBg = bg;
    notifyListeners();
  }

  // Task sets per goal phase
  static const taskStars = {
    // Goal 1 (onboarding) — must total 1500 ($2.00)
    'profile': 300,        // $0.40
    'survey': 450,         // $0.60
    'game_install': 150,   // $0.20
    'game_milestone': 600, // $0.80
    // Goal 2+ (daily)
    'daily_survey': 500,
    'daily_play': 650,
    'daily_offer': 350,
  };

  int get taskSetIndex => goalIndex == 0 ? 0 : 1;
  int get dailyTasksCompleted =>
      completedTasks.where((t) => t.startsWith('daily_')).length;
  bool get allDailyTasksCompleted => dailyTasksCompleted >= 3;

  /// Returns true if a goal was just completed
  bool completeTask(String task) {
    if (completedTasks.contains(task)) return false;
    completedTasks.add(task);
    lastCompletedTask = task;
    final prevStars = stars;
    final prevEarnedToday = earnedToday;
    final earned = taskStars[task] ?? 0;
    stars += earned;
    earnedToday += earned;
    tasksCompleted++;

    // Onboarding "Reach first milestone" task → mark the just-installed
    // game's first post-install milestone (index 1) as completed, so the
    // Game Detail screen's earnings summary and Reward Steps strip match
    // what the user was just credited for in starter tasks.
    if (task == 'game_milestone') {
      _advanceInstalledGameToFirstMilestone();
    }

    // Rising-edge celebration: fires once the first time the user crosses
    // the active daily goal tier. When crossing the $2 starter tier, the
    // goal auto-extends to $5 right after the haptic so the ring levels up
    // to a bigger target without prompting the user. earnedToday stays
    // put, so the crossed amount becomes locked-in progress on the new
    // ring (1500/3750 = 40%). Re-arming _dailyGoalCelebrated lets the
    // user earn a second celebration when they later reach $5.
    // TODO sub-project 6: route through CelebrationsService instead of
    // calling Haptics directly from state.
    if (!_dailyGoalCelebrated &&
        earnedToday >= dailyGoalStars &&
        prevEarnedToday < dailyGoalStars) {
      _dailyGoalCelebrated = true;
      Haptics.celebrate(CelebrateMoments.goalReached);

      if (!dailyGoalExtended && dailyGoalStars == 1500) {
        dailyGoalStars = 3750; // $5.00
        dailyGoalExtended = true;
        _dailyGoalCelebrated = false;
      }
    }

    notifyListeners();

    // Check if we crossed a lifetime goal threshold
    if (!isLegend &&
        stars >= currentGoal.goalStars &&
        prevStars < currentGoal.goalStars) {
      return true;
    }
    return false;
  }

  bool get dailyGoalHit => earnedToday >= dailyGoalStars;

  @visibleForTesting
  bool get debugDailyGoalCelebrated => _dailyGoalCelebrated;

  /// Replaces [installedGames] with a single entry derived from the
  /// catalog [Game] the user picked during onboarding. Marks the install
  /// step (milestone index 0) as completed so the Continue earning row
  /// and the Game Detail milestone strip both reflect "you already
  /// installed it, here's what's next".
  void installGameFromOnboarding(Game catalog) {
    final game = InstalledGame.fromCatalog(catalog);
    installedGames = [game];
    notifyListeners();
  }

  /// Adds milestone index 1 (the first real milestone after install) to
  /// the onboarding-installed game's completed set. No-op when no game is
  /// installed yet or when the catalog lookup fails. Called from
  /// [completeTask] when the onboarding "Reach first milestone" task
  /// fires, so the Game Detail earnings summary, the Reward Steps strip,
  /// and the Continue earning card all advance past Level 15 (or the
  /// equivalent first real milestone on the picked game) in lockstep.
  void _advanceInstalledGameToFirstMilestone() {
    if (installedGames.isEmpty) return;
    final current = installedGames.first;
    final catalog = gamesByName[current.name];
    if (catalog == null) return;
    if (catalog.regularSteps.length < 2) return;
    if (current.completedMilestoneIndices.contains(1)) return;
    final nextCompleted =
        Set<int>.from(current.completedMilestoneIndices)..add(1);
    installedGames = [
      InstalledGame.fromCatalog(
        catalog,
        completed: nextCompleted,
        lastPlayedAt: current.lastPlayedAt,
      ),
      ...installedGames.skip(1),
    ];
  }

  /// Call once on Home mount and again when the app resumes. Resets the
  /// daily counters when the local date has actually rolled over.
  ///
  /// The first call on a fresh AppState must be a no-op on the counters,
  /// it only records today's date as the reset anchor. Otherwise same-day
  /// progress that was just built up (e.g. from onboarding tasks earlier
  /// in the same session) would be wiped the first time Home mounts.
  void checkDailyReset() {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_dailyResetDate == today) return;
    final isFirstInit = _dailyResetDate.isEmpty;
    _dailyResetDate = today;
    if (isFirstInit) return;
    earnedToday = 0;
    dailyGoalStars = 1500;
    dailyGoalExtended = false;
    _dailyGoalCelebrated = false;
    notifyListeners();
  }

  /// Test-only helper so unit tests can force a date-rollover scenario
  /// without mocking DateTime.now.
  @visibleForTesting
  void debugSetDailyResetDate(String isoDate) {
    _dailyResetDate = isoDate;
  }

  /// Mock payout: deducts the first-goal threshold (1 500 stars = $2.00)
  /// and marks the reward as redeemed.
  void redeemPayout() {
    if (hasRedeemed) return;
    if (stars < goals[0].goalStars) return;
    stars -= goals[0].goalStars;
    hasRedeemed = true;
    notifyListeners();
  }

  void advanceGoal() {
    if (isLastGoal) {
      isLegend = true;
    } else {
      goalIndex++;
    }
    notifyListeners();
  }

  bool get allTasksCompleted => tasksCompleted >= 4;

  /// Resets every in-session field to the same initial value the field
  /// declaration uses today. Called by the Sign Out button on
  /// [ProfileScreen]. After reset the next onboarding run sees the
  /// welcome gift animation again because [stars] goes back to 125.
  void reset() {
    userName = '';
    stars = 0;
    earnedToday = 0;
    goalIndex = 0;
    tasksCompleted = 0;
    screen5Played = false;
    welcomeModalShown = false;
    streakCount = 0;
    isLegend = false;
    completedTasks = <String>{};
    lastCompletedTask = null;
    hasRedeemed = false;
    dailyGoalStars = 1500;
    dailyGoalExtended = false;
    _dailyResetDate = '';
    _dailyGoalCelebrated = false;
    installedGames = [];
    selectedPreferences = <String>[];
    journeyLog = <JourneyEntry>[];
    convCardMsg = '';
    convCardIcon = Icons.waving_hand;
    convCardIconColor = AppColors.primary;
    convCardIconBg = AppColors.primaryPale;
    authProvider = 'Google';
    ageRange = '26-35';
    gender = 'Female';
    currentTheme = kCreamTheme;
    notifyListeners();
  }
}
