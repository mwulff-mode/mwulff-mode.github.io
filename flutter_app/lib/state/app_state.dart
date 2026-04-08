import 'package:flutter/material.dart';

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
      goalStars: 5000,
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
  String userName = 'Lisa';
  int stars = 125; // welcome gift
  int goalIndex = 0;
  int tasksCompleted = 0;
  bool screen5Played = false;
  int streakCount = 0;
  bool showDollars = false;
  bool isLegend = false;
  Set<String> completedTasks = {};
  List<String> selectedPreferences = [];
  List<JourneyEntry> journeyLog = [];

  // Conversational card state
  String convCardMsg = '';
  IconData convCardIcon = Icons.waving_hand;
  Color convCardIconColor = const Color(0xFF0D9488);
  Color convCardIconBg = const Color(0xFFF0FDFA);

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

  double starsToDollars(int s) => s / starsPerDollar;

  String formatBalance() {
    if (showDollars) {
      return '\$${starsToDollars(stars).toStringAsFixed(2)}';
    }
    return formatNumber(stars);
  }

  String formatRingProgress() {
    if (isLegend) return '';
    return '${formatNumber(stars)} / ${formatNumber(currentGoal.goalStars)}';
  }

  String formatToday() {
    if (showDollars) {
      return '\$${starsToDollars(stars).toStringAsFixed(2)} today';
    }
    return '${formatNumber(stars)} today';
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

  void toggleCurrency() {
    showDollars = !showDollars;
    notifyListeners();
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
    // Goal 1 (onboarding)
    'profile': 250,
    'survey': 375,
    'game': 750,
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
    final prevStars = stars;
    stars += taskStars[task] ?? 0;
    tasksCompleted++;
    notifyListeners();

    // Check if we crossed a goal threshold
    if (!isLegend &&
        stars >= currentGoal.goalStars &&
        prevStars < currentGoal.goalStars) {
      return true;
    }
    return false;
  }

  void advanceGoal() {
    if (isLastGoal) {
      isLegend = true;
    } else {
      goalIndex++;
    }
    notifyListeners();
  }

  bool get allTasksCompleted => tasksCompleted >= 3;
}
