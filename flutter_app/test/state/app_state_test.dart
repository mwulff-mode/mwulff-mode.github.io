import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';

void main() {
  group('AppState profile fields', () {
    test('default values match the spec', () {
      final state = AppState();
      expect(state.email, 'lisa@earnwise.demo');
      expect(state.authProvider, 'Google');
      expect(state.ageRange, '26-35');
      expect(state.gender, 'Female');
    });
  });

  group('AppState.reset()', () {
    test('restores every in-session field to its default value', () {
      final state = AppState();

      // Mutate everything a real session might touch.
      state.userName = 'Dirty';
      state.stars = 9999;
      state.earnedToday = 500;
      state.goalIndex = 3;
      state.tasksCompleted = 7;
      state.screen5Played = true;
      state.streakCount = 12;
      state.isLegend = true;
      state.completedTasks.addAll({'profile', 'survey', 'game'});
      state.lastCompletedTask = 'game';
      state.selectedPreferences.addAll(['puzzle', 'word']);
      state.journeyLog.add(JourneyEntry(
        msg: 'Dirty',
        icon: Icons.bug_report,
        iconColor: Colors.red,
        iconBg: Colors.pink,
        time: '12:00 PM',
      ));
      state.convCardMsg = 'Dirty message';
      state.convCardIcon = Icons.bug_report;
      state.convCardIconColor = Colors.red;
      state.convCardIconBg = Colors.pink;
      state.email = 'hacked@example.com';
      state.authProvider = 'Facebook';
      state.ageRange = '99+';
      state.gender = 'Dirty';

      state.reset();

      expect(state.userName, 'Lisa', reason: 'userName should reset to Lisa');
      expect(state.stars, 125,
          reason: 'stars should reset to welcome-gift starting balance');
      expect(state.earnedToday, 0, reason: 'earnedToday');
      expect(state.goalIndex, 0, reason: 'goalIndex');
      expect(state.tasksCompleted, 0, reason: 'tasksCompleted');
      expect(state.screen5Played, isFalse, reason: 'screen5Played');
      expect(state.streakCount, 0, reason: 'streakCount');
      expect(state.isLegend, isFalse, reason: 'isLegend');
      expect(state.completedTasks, isEmpty,
          reason: 'completedTasks should be a new empty set');
      expect(state.lastCompletedTask, isNull, reason: 'lastCompletedTask');
      expect(state.selectedPreferences, isEmpty,
          reason: 'selectedPreferences should be a new empty list');
      expect(state.journeyLog, isEmpty,
          reason: 'journeyLog should be a new empty list');
      expect(state.convCardMsg, '', reason: 'convCardMsg');
      expect(state.convCardIcon, Icons.waving_hand, reason: 'convCardIcon');
      expect(state.convCardIconColor, AppColors.primary,
          reason: 'convCardIconColor');
      expect(state.convCardIconBg, AppColors.primaryPale,
          reason: 'convCardIconBg');
      expect(state.email, 'lisa@earnwise.demo', reason: 'email');
      expect(state.authProvider, 'Google', reason: 'authProvider');
      expect(state.ageRange, '26-35', reason: 'ageRange');
      expect(state.gender, 'Female', reason: 'gender');
    });

    test('notifies listeners when called', () {
      final state = AppState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);

      state.reset();

      expect(notifyCount, 1);
    });
  });
}
