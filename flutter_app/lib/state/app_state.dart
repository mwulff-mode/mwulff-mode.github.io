import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import '../services/haptics.dart';

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

  // Daily goal (post-onboarding). earnedToday is reused as the progress
  // counter; it resets at local midnight via checkDailyReset.
  int dailyGoalStars = 1500; // $2.00
  bool dailyExtensionOffered = false;
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

    // Rising-edge celebration: fires once the first time the user crosses
    // today's daily goal, regardless of which Home button they tap next.
    // This matches the Home spec: the celebration belongs to the goal-hit
    // transition, not to the extension prompt's Push/Bank actions.
    // TODO sub-project 6: route through CelebrationsService instead of
    // calling Haptics directly from state.
    if (!_dailyGoalCelebrated &&
        earnedToday >= dailyGoalStars &&
        prevEarnedToday < dailyGoalStars) {
      _dailyGoalCelebrated = true;
      Haptics.celebrate(CelebrateMoments.goalReached);
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

  /// Extend today's goal from $2 to $3. No-op if the user has already
  /// banked or pushed today.
  void pushDailyGoalToThree() {
    if (dailyExtensionOffered) return;
    dailyGoalStars = 2250; // $3.00
    dailyExtensionOffered = true;
    notifyListeners();
  }

  /// Keep today's $2 goal and stop prompting for an extension.
  void bankDailyGoal() {
    if (dailyExtensionOffered) return;
    dailyExtensionOffered = true;
    notifyListeners();
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
    dailyExtensionOffered = false;
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
    dailyExtensionOffered = false;
    _dailyResetDate = '';
    _dailyGoalCelebrated = false;
    selectedPreferences = <String>[];
    journeyLog = <JourneyEntry>[];
    convCardMsg = '';
    convCardIcon = Icons.waving_hand;
    convCardIconColor = AppColors.primary;
    convCardIconBg = AppColors.primaryPale;
    authProvider = 'Google';
    ageRange = '26-35';
    gender = 'Female';
    notifyListeners();
  }
}
