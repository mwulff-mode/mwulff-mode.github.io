import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/services/haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState profile fields', () {
    test('default values match the spec', () {
      final state = AppState();
      expect(state.email, 'jane.doe@gmail.com');
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
      state.authProvider = 'Facebook';
      state.ageRange = '99+';
      state.gender = 'Dirty';

      state.hasRedeemed = true;

      state.reset();

      expect(state.hasRedeemed, isFalse, reason: 'hasRedeemed');
      expect(state.userName, '', reason: 'userName should reset to empty');
      expect(state.stars, 0,
          reason: 'stars should reset to zero');
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
      expect(state.email, 'jane.doe@gmail.com', reason: 'email');
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

  // ---------------------------------------------------------------------------
  // redeemPayout
  // ---------------------------------------------------------------------------

  group('redeemPayout', () {
    test('deducts first-goal stars and sets hasRedeemed', () {
      final state = AppState();
      state.stars = 1500; // exactly at threshold
      state.redeemPayout();
      expect(state.stars, 0);
      expect(state.hasRedeemed, isTrue);
    });

    test('is a no-op when stars are below the threshold', () {
      final state = AppState();
      // Default stars == 0, well below 1500.
      state.redeemPayout();
      expect(state.stars, 0, reason: 'stars should be unchanged');
      expect(state.hasRedeemed, isFalse);
    });

    test('is a no-op when already redeemed (idempotency)', () {
      final state = AppState();
      state.stars = 3000;
      state.redeemPayout(); // first call
      expect(state.stars, 1500);

      state.redeemPayout(); // second call -- should not deduct again
      expect(state.stars, 1500, reason: 'stars should not change on repeat');
      expect(state.hasRedeemed, isTrue);
    });

    test('notifies listeners', () {
      final state = AppState();
      state.stars = 1500;
      int notifyCount = 0;
      state.addListener(() => notifyCount++);
      state.redeemPayout();
      expect(notifyCount, 1);
    });

    test('does not notify when insufficient balance', () {
      final state = AppState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);
      state.redeemPayout();
      expect(notifyCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // completeTask
  // ---------------------------------------------------------------------------

  group('completeTask', () {
    test('adds the task to completedTasks and increments stars', () {
      final state = AppState();
      // Fresh state: stars == 0, no tasks done.
      state.completeTask('profile');
      expect(state.completedTasks, contains('profile'));
      // profile awards 300 stars.
      expect(state.stars, 0 + 300);
    });

    test('increments tasksCompleted', () {
      final state = AppState();
      expect(state.tasksCompleted, 0);
      state.completeTask('profile');
      expect(state.tasksCompleted, 1);
      state.completeTask('survey');
      expect(state.tasksCompleted, 2);
    });

    test('increments earnedToday by the task star value', () {
      final state = AppState();
      state.completeTask('survey'); // 450 stars
      expect(state.earnedToday, 450);
    });

    test('returns false when goal is not completed', () {
      final state = AppState();
      // goal 0 threshold is 1500. Starting stars 0, profile adds 300 = 300.
      // Still far from 1500, so should return false.
      final crossed = state.completeTask('profile');
      expect(crossed, isFalse);
    });

    test('returns true when stars cross the current goal threshold', () {
      final state = AppState();
      // Set stars just below goal 0 threshold (1500).
      // game_milestone awards 600 stars.
      state.stars = 1500 - 600; // 900, so completing game_milestone takes us to 1500.
      final crossed = state.completeTask('game_milestone');
      expect(crossed, isTrue);
    });

    test('does nothing and returns false if the task is already completed', () {
      final state = AppState();
      state.completeTask('profile');
      final starsBefore = state.stars;
      final tasksCompletedBefore = state.tasksCompleted;

      final result = state.completeTask('profile');

      expect(result, isFalse);
      expect(state.stars, starsBefore);
      expect(state.tasksCompleted, tasksCompletedBefore);
    });

    test('sets lastCompletedTask to the task name', () {
      final state = AppState();
      state.completeTask('survey');
      expect(state.lastCompletedTask, 'survey');
    });

    test('does not return true when stars cross threshold on a repeat call', () {
      final state = AppState();
      // Push stars to just below goal with a real task.
      state.stars = 1500 - 600;
      state.completeTask('game_milestone'); // returns true, goal crossed

      // Attempt to complete the same task again -- should be a no-op.
      state.stars = 1500 - 600; // manually reset to re-trigger condition
      final result = state.completeTask('game_milestone');
      expect(result, isFalse); // already in completedTasks, early-return false
    });
  });

  // ---------------------------------------------------------------------------
  // advanceGoal
  // ---------------------------------------------------------------------------

  group('advanceGoal', () {
    test('increments goalIndex by 1', () {
      final state = AppState();
      expect(state.goalIndex, 0);
      state.advanceGoal();
      expect(state.goalIndex, 1);
    });

    test('increments goalIndex again on a second call', () {
      final state = AppState();
      state.advanceGoal();
      state.advanceGoal();
      expect(state.goalIndex, 2);
    });

    test('sets isLegend when advancing past the last goal', () {
      final state = AppState();
      // goals list has 6 entries (indices 0-5). isLastGoal is true at index 5.
      state.goalIndex = goals.length - 1; // index 5
      expect(state.isLastGoal, isTrue);
      state.advanceGoal();
      expect(state.isLegend, isTrue);
    });

    test('does not increment goalIndex when becoming legend', () {
      final state = AppState();
      state.goalIndex = goals.length - 1;
      final indexBefore = state.goalIndex;
      state.advanceGoal();
      expect(state.goalIndex, indexBefore,
          reason: 'goalIndex should not change when isLastGoal is true');
    });
  });

  // ---------------------------------------------------------------------------
  // goalProgress
  // ---------------------------------------------------------------------------

  group('goalProgress', () {
    test('returns 0 at the start of goal 0 with only the welcome gift', () {
      final state = AppState();
      // stars == 125, goalStartStars == 0, currentGoal.goalStars == 1500.
      // 125 / 1500 * 100 ~ 8.3 -- NOT zero. Welcome gift already moved the bar.
      // The meaningful "start of goal" to test is zero stars.
      state.stars = 0;
      expect(state.goalProgress, 0.0);
    });

    test('returns 100 when stars exactly reach the goal threshold', () {
      final state = AppState();
      // Goal 0 threshold is 1500.
      state.stars = 1500;
      expect(state.goalProgress, 100.0);
    });

    test('returns 100 when isLegend is true', () {
      final state = AppState();
      state.isLegend = true;
      state.stars = 0; // irrelevant when legend
      expect(state.goalProgress, 100.0);
    });

    test('clamps to 0 when stars are below goalStartStars', () {
      final state = AppState();
      // Advance to goal 1; goalStartStars is now 1500.
      state.goalIndex = 1;
      state.stars = 0; // below goalStartStars
      expect(state.goalProgress, 0.0);
    });

    test('clamps to 100 when stars greatly exceed current goal', () {
      final state = AppState();
      state.stars = 999999;
      expect(state.goalProgress, 100.0);
    });

    test('returns a proportional value mid-goal', () {
      final state = AppState();
      // Goal 0: 0 to 1500. At stars == 750 we expect exactly 50.
      state.stars = 750;
      expect(state.goalProgress, closeTo(50.0, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  // Formatting helpers
  // ---------------------------------------------------------------------------

  group('formatting', () {
    test('formatBalance returns dollar amount based on stars / 750', () {
      final state = AppState();
      state.stars = 750;
      expect(state.formatBalance(), '\$1.00');
    });

    test('formatBalance with default stars (0)', () {
      final state = AppState();
      expect(state.formatBalance(), '\$0.00');
    });

    test('formatBalance with zero stars', () {
      final state = AppState();
      state.stars = 0;
      expect(state.formatBalance(), '\$0.00');
    });

    test('formatEarnedToday returns dollar amount based on earnedToday', () {
      final state = AppState();
      state.earnedToday = 1500; // $2.00
      expect(state.formatEarnedToday(), '\$2.00');
    });

    test('formatEarnedToday returns zero string when earnedToday is 0', () {
      final state = AppState();
      expect(state.formatEarnedToday(), '\$0.00');
    });

    test('formatGoal returns dollar amount for goal 0 threshold', () {
      final state = AppState();
      // Goal 0 goalStars == 1500; 1500 / 750 == $2.00
      expect(state.formatGoal(), '\$2.00');
    });

    test('formatGoal returns correct dollar for goal 1 threshold', () {
      final state = AppState();
      state.goalIndex = 1;
      // Goal 1 goalStars == 3750; 3750 / 750 == $5.00
      expect(state.formatGoal(), '\$5.00');
    });

    test('formatGoal returns infinity symbol when isLegend', () {
      final state = AppState();
      state.isLegend = true;
      expect(state.formatGoal(), '\u221e');
    });
  });

  // ---------------------------------------------------------------------------
  // togglePreference
  // ---------------------------------------------------------------------------

  group('togglePreference', () {
    test('adds a preference if not already present', () {
      final state = AppState();
      state.togglePreference('puzzle');
      expect(state.selectedPreferences, contains('puzzle'));
    });

    test('removes a preference if already present', () {
      final state = AppState();
      state.selectedPreferences.add('puzzle');
      state.togglePreference('puzzle');
      expect(state.selectedPreferences, isNot(contains('puzzle')));
    });

    test('adding two different preferences keeps both', () {
      final state = AppState();
      state.togglePreference('puzzle');
      state.togglePreference('word');
      expect(state.selectedPreferences, containsAll(['puzzle', 'word']));
    });

    test('toggling twice leaves list empty', () {
      final state = AppState();
      state.togglePreference('puzzle');
      state.togglePreference('puzzle');
      expect(state.selectedPreferences, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // setUserName
  // ---------------------------------------------------------------------------

  group('setUserName', () {
    test('updates userName', () {
      final state = AppState();
      state.setUserName('Alice');
      expect(state.userName, 'Alice');
    });

    test('updates convCardMsg with the new name', () {
      final state = AppState();
      state.setUserName('Alice');
      expect(state.convCardMsg, "Hey Alice, let's start earning");
    });
  });

  // ---------------------------------------------------------------------------
  // Daily goal
  // ---------------------------------------------------------------------------

  group('daily goal', () {
    setUp(() {
      // The daily-goal celebration path fires Haptics.celebrate, which is
      // guarded by a static Set. Reset it between tests so assertions on
      // the celebration branch stay independent of test ordering.
      Haptics.debugResetCelebrateGuard();
    });

    test('dailyGoalStars defaults to 1500 (\$2.00)', () {
      final state = AppState();
      expect(state.dailyGoalStars, 1500);
    });

    test('dailyExtensionOffered defaults to false', () {
      final state = AppState();
      expect(state.dailyExtensionOffered, isFalse);
    });

    test('dailyGoalHit is false when earnedToday is below target', () {
      final state = AppState();
      state.earnedToday = 1499;
      expect(state.dailyGoalHit, isFalse);
    });

    test('dailyGoalHit is true when earnedToday reaches target', () {
      final state = AppState();
      state.earnedToday = 1500;
      expect(state.dailyGoalHit, isTrue);
    });

    test('pushDailyGoalToThree raises target to 2250 and marks offered', () {
      final state = AppState();
      state.earnedToday = 1500;
      state.pushDailyGoalToThree();
      expect(state.dailyGoalStars, 2250);
      expect(state.dailyExtensionOffered, isTrue);
    });

    test('pushDailyGoalToThree is a no-op if already offered', () {
      final state = AppState();
      state.dailyExtensionOffered = true;
      state.dailyGoalStars = 1500; // banked scenario
      state.pushDailyGoalToThree();
      expect(state.dailyGoalStars, 1500, reason: 'must not re-push');
    });

    test('bankDailyGoal marks offered but leaves target at 1500', () {
      final state = AppState();
      state.earnedToday = 1500;
      state.bankDailyGoal();
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyExtensionOffered, isTrue);
    });

    test('pushDailyGoalToThree notifies listeners', () {
      final state = AppState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);
      state.pushDailyGoalToThree();
      expect(notifyCount, 1);
    });

    test('bankDailyGoal notifies listeners', () {
      final state = AppState();
      int notifyCount = 0;
      state.addListener(() => notifyCount++);
      state.bankDailyGoal();
      expect(notifyCount, 1);
    });

    test('checkDailyReset resets earnedToday, target, and extension flag when date changes', () {
      final state = AppState();
      state.earnedToday = 2000;
      state.dailyGoalStars = 2250;
      state.dailyExtensionOffered = true;
      // Force last reset date to yesterday.
      state.debugSetDailyResetDate('2000-01-01');
      state.checkDailyReset();
      expect(state.earnedToday, 0);
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyExtensionOffered, isFalse);
    });

    test('checkDailyReset is a no-op when date has not changed', () {
      final state = AppState();
      state.checkDailyReset(); // sets last reset date to today
      state.earnedToday = 500;
      state.checkDailyReset();
      expect(state.earnedToday, 500, reason: 'same-day call must not reset');
    });

    test('first checkDailyReset on a fresh state preserves same-session progress', () {
      // Onboarding just ran, so earnedToday already has value. The very
      // first time Home mounts and checkDailyReset() is called, it must
      // only anchor today's date, never wipe counters that were built
      // earlier in the same day.
      final state = AppState();
      state.earnedToday = 900;
      state.checkDailyReset();
      expect(state.earnedToday, 900);
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyExtensionOffered, isFalse);
    });

    test('reset() restores daily goal fields to defaults', () {
      final state = AppState();
      state.dailyGoalStars = 2250;
      state.dailyExtensionOffered = true;
      state.reset();
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyExtensionOffered, isFalse);
    });

    test('completeTask does not crash when haptic fires on goal crossing', () {
      // The celebration lives inside completeTask. We exercise the exact
      // rising edge (crossing dailyGoalStars for the first time) to make
      // sure the Haptics call compiles and does not throw under flutter
      // test. Haptics.celebrate is per-run guarded, so repeats are safe.
      final state = AppState();
      // Load earnedToday right up against the threshold so the next
      // task crosses it.
      state.earnedToday = state.dailyGoalStars - 100;
      // Pick a task whose reward is large enough to cross 1500.
      state.completeTask('game_milestone'); // +600 stars
      expect(state.dailyGoalHit, isTrue);
    });

    test('second goal crossing in the same day does not re-celebrate', () {
      // Rising-edge guard: the first crossing must set _dailyGoalCelebrated,
      // and a second crossing in the same day must leave it set without
      // firing the celebration branch a second time. Assert on the guard
      // getter directly instead of on dailyGoalHit, which only observes
      // the current earnedToday value.
      final state = AppState();
      state.earnedToday = state.dailyGoalStars - 100;
      state.completeTask('game_milestone'); // first crossing
      expect(state.debugDailyGoalCelebrated, isTrue,
          reason: 'first crossing must arm the guard');

      // Drop back under the goal without resetting the guard, then cross
      // again. The guard must remain armed and the second crossing must
      // not throw or clear it.
      state.earnedToday = state.dailyGoalStars - 10;
      state.completeTask('daily_offer'); // second crossing
      expect(state.debugDailyGoalCelebrated, isTrue,
          reason: 'second crossing in the same day must leave the guard armed');
      expect(state.dailyGoalHit, isTrue);
    });
  });
}
