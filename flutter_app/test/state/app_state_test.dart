import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/services/haptics.dart';
import 'package:earnwise_mvp/models/installed_game.dart';

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

    test('dailyGoalExtended defaults to false', () {
      final state = AppState();
      expect(state.dailyGoalExtended, isFalse);
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

    test('crossing the \$2 tier auto-extends the goal to \$5', () {
      // The user climbs from just under $2 up to the threshold in a
      // single task completion. completeTask fires the rising-edge
      // celebration, then immediately flips the goal up to $5 so the
      // ring "levels up" without prompting the user.
      final state = AppState();
      state.earnedToday = state.dailyGoalStars - 100; // 1400
      state.completeTask('game_milestone'); // +600, crosses 1500
      expect(state.dailyGoalStars, 3750, reason: '\$5 target in stars');
      expect(state.dailyGoalExtended, isTrue);
    });

    test('auto-extend leaves earnedToday as locked-in progress on the \$5 ring', () {
      // The crossed $2 should register as progress on the $5 ring, not
      // get wiped or double-counted. After crossing, dailyGoalProgress
      // should be around 40% (1500/3750 after the reward is applied).
      final state = AppState();
      state.earnedToday = 1450;
      state.completeTask('daily_offer'); // +350 → 1800
      expect(state.earnedToday, 1800,
          reason: 'auto-extend must not touch earnedToday');
      expect(state.dailyGoalStars, 3750);
      // 1800 / 3750 = 48%
      expect(state.dailyGoalProgress, closeTo(48, 0.5));
    });

    test('auto-extend only fires once per day even if earnedToday is massaged', () {
      // If the day's counters ever walk below and back over the starter
      // target, the one-time guard must still prevent a second
      // auto-extension. This guards against test-harness mutations and
      // any future code paths that could roll earnedToday backward.
      final state = AppState();
      state.earnedToday = 1400;
      state.completeTask('game_milestone'); // crosses to 2000, extends to 3750
      expect(state.dailyGoalStars, 3750);

      // Hand-roll a second "cross $2" scenario. The goal must stay at $5.
      state.dailyGoalStars = 1500;
      state.earnedToday = 1400;
      state.completeTask('daily_offer'); // +350 → 1750
      expect(state.dailyGoalStars, 1500,
          reason: 'once extended, never re-extends in the same day');
    });

    test('checkDailyReset resets earnedToday, target, and extended flag when date changes', () {
      final state = AppState();
      state.earnedToday = 2000;
      state.dailyGoalStars = 3750;
      state.dailyGoalExtended = true;
      // Force last reset date to yesterday.
      state.debugSetDailyResetDate('2000-01-01');
      state.checkDailyReset();
      expect(state.earnedToday, 0);
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyGoalExtended, isFalse);
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
      expect(state.dailyGoalExtended, isFalse);
    });

    test('reset() restores daily goal fields to defaults', () {
      final state = AppState();
      state.dailyGoalStars = 3750;
      state.dailyGoalExtended = true;
      state.reset();
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyGoalExtended, isFalse);
    });

    test('completeTask does not crash when haptic fires on goal crossing', () {
      // The celebration lives inside completeTask. We exercise the exact
      // rising edge (crossing dailyGoalStars for the first time) to make
      // sure the Haptics call compiles and does not throw under flutter
      // test. Haptics.celebrate is per-run guarded, so repeats are safe.
      // Assert on dailyGoalExtended rather than dailyGoalHit because the
      // same crossing auto-extends the goal, so earnedToday is now below
      // the new $5 threshold.
      final state = AppState();
      state.earnedToday = state.dailyGoalStars - 100;
      state.completeTask('game_milestone'); // +600 stars, crosses 1500
      expect(state.dailyGoalExtended, isTrue);
    });

    test('crossing \$2 disarms the guard so the \$5 tier can celebrate again', () {
      // First crossing arms the guard and then auto-extends the goal,
      // which disarms the guard on purpose: the $5 tier is a fresh
      // celebration opportunity, not a re-fire of the same one.
      final state = AppState();
      state.earnedToday = state.dailyGoalStars - 100; // 1400
      state.completeTask('game_milestone'); // crosses 1500, extends to 3750
      expect(state.dailyGoalStars, 3750);
      expect(state.debugDailyGoalCelebrated, isFalse,
          reason: 'auto-extend re-arms the guard for the \$5 tier');
    });

    test('crossing the extended \$5 tier re-fires the celebration once', () {
      final state = AppState();
      // Load earnedToday a hair under $5 on the already-extended ring.
      state.dailyGoalStars = 3750;
      state.dailyGoalExtended = true;
      state.earnedToday = 3700;
      state.completeTask('daily_offer'); // +350 → 4050
      expect(state.debugDailyGoalCelebrated, isTrue,
          reason: 'hitting the \$5 tier must arm the guard once');
      expect(state.dailyGoalStars, 3750,
          reason: 'already-extended ring must not re-extend');
    });
  });

  // ---------------------------------------------------------------------------
  // In-progress games
  // ---------------------------------------------------------------------------

  group('in-progress games', () {
    test('installedGames defaults to an empty list on a fresh AppState', () {
      // A fresh AppState must ship empty so onboarding Game Detail never
      // flips into "Continue playing" mode for a game the user hasn't
      // actually installed yet. Population happens via
      // installGameFromOnboarding when the user picks a game.
      final state = AppState();
      expect(state.installedGames, isEmpty);
    });

    test('inProgressGames returns only games with remaining milestones', () {
      final state = AppState();
      // Seed a mix of in-progress and fully-cleared games so the filter
      // actually has something to reject. Default installedGames is
      // empty, so the pre-fix version of this test trivially passed.
      state.installedGames = [
        InstalledGame(
          id: 'in_progress',
          name: 'In Progress',
          iconPath: 'assets/app_icons/Candy_Crush_Saga.png',
          nextMilestoneLabel: 'L1',
          nextMilestoneReward: 1.00,
          lastPlayedAt: DateTime(2026, 4, 13),
        ),
        InstalledGame(
          id: 'cleared',
          name: 'Cleared',
          iconPath: 'assets/app_icons/Candy_Crush_Saga.png',
          nextMilestoneLabel: 'done',
          nextMilestoneReward: 0,
          lastPlayedAt: DateTime(2026, 4, 13),
        ),
      ];
      final filtered = state.inProgressGames;
      expect(filtered.map((g) => g.id).toList(), ['in_progress']);
    });

    test('inProgressGames is ordered by lastPlayedAt, most recent first', () {
      // The test injects three out-of-order games so an accidentally
      // ascending sort would surface as a failed assertion. The seeded
      // pair alone is too short to catch direction flips.
      final state = AppState();
      final older = DateTime(2026, 4, 10, 8, 0);
      final newest = DateTime(2026, 4, 13, 22, 0);
      final middle = DateTime(2026, 4, 12, 15, 0);
      state.installedGames = [
        InstalledGame(
          id: 'older',
          name: 'Older',
          iconPath: 'assets/app_icons/Candy_Crush_Saga.png',
          nextMilestoneLabel: 'L1',
          nextMilestoneReward: 1.00,
          lastPlayedAt: older,
        ),
        InstalledGame(
          id: 'newest',
          name: 'Newest',
          iconPath: 'assets/app_icons/Candy_Crush_Saga.png',
          nextMilestoneLabel: 'L1',
          nextMilestoneReward: 1.00,
          lastPlayedAt: newest,
        ),
        InstalledGame(
          id: 'middle',
          name: 'Middle',
          iconPath: 'assets/app_icons/Candy_Crush_Saga.png',
          nextMilestoneLabel: 'L1',
          nextMilestoneReward: 1.00,
          lastPlayedAt: middle,
        ),
      ];

      final list = state.inProgressGames;
      expect(list.map((g) => g.id).toList(), ['newest', 'middle', 'older']);
    });
  });
}
