import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/home_shell.dart';
import 'package:earnwise_mvp/screens/placeholder_list_screen.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/widgets/daily_goal_card.dart';
import 'package:earnwise_mvp/models/installed_game.dart';

Future<void> pumpPostOnboardingHome(
  WidgetTester tester, {
  void Function(AppState)? setup,
}) async {
  final state = AppState()
    ..screen5Played = true
    ..welcomeModalShown = true
    ..goalIndex = 1 // Post-onboarding: past first goal.
    ..userName = 'Sarah';
  if (setup != null) setup(state);
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: HomeShell()),
    ),
  );
  await tester.pump();
}

void main() {
  group('Post-Onboarding Home', () {
    testWidgets('renders the DailyGoalCard instead of Today\'s Tasks',
        (tester) async {
      await pumpPostOnboardingHome(tester);
      expect(find.byType(DailyGoalCard), findsOneWidget);
      expect(find.text("Today's Tasks"), findsNothing);
    });

    testWidgets('shows Continue earning cards for in-progress games',
        (tester) async {
      await pumpPostOnboardingHome(tester);
      expect(find.text('Continue earning'), findsOneWidget);
      expect(find.text('Candy Crush'), findsOneWidget);
      expect(find.text('Solitaire'), findsOneWidget);
    });

    testWidgets('hides the Continue earning section when no in-progress games',
        (tester) async {
      await pumpPostOnboardingHome(tester, setup: (s) {
        s.installedGames = [];
      });
      expect(find.text('Continue earning'), findsNothing);
    });

    testWidgets('caps Continue earning at 3 cards', (tester) async {
      await pumpPostOnboardingHome(tester, setup: (s) {
        s.installedGames = List.generate(
          5,
          (i) => InstalledGame(
            id: 'game_$i',
            name: 'Game $i',
            iconPath: 'assets/logos/unknown.png',
            nextMilestoneLabel: 'Level ${i + 1}',
            nextMilestoneReward: 1.0,
            lastPlayedAt: DateTime(2026, 4, 13, 10, i),
          ),
        );
      });
      expect(find.text('Game 4'), findsOneWidget); // most recent
      expect(find.text('Game 3'), findsOneWidget);
      expect(find.text('Game 2'), findsOneWidget);
      expect(find.text('Game 1'), findsNothing); // dropped
      expect(find.text('Game 0'), findsNothing); // dropped
    });

    testWidgets('shows three Earn more section cards', (tester) async {
      await pumpPostOnboardingHome(tester);
      expect(find.text('Earn more'), findsOneWidget);
      expect(find.text('Surveys'), findsOneWidget);
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      // Blurb assertions guard against future copy regressions.
      expect(find.textContaining('\$0.50 to \$2.00'), findsOneWidget);
      expect(find.textContaining('Complete an offer'), findsOneWidget);
      expect(find.textContaining('Play games'), findsOneWidget);
    });

    testWidgets('tapping the Surveys card pushes PlaceholderListScreen',
        (tester) async {
      await pumpPostOnboardingHome(tester);
      await tester.scrollUntilVisible(find.text('Surveys'), 100);
      await tester.tap(find.text('Surveys'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceholderListScreen), findsOneWidget);
      expect(find.text('Surveys'), findsWidgets);
      expect(find.textContaining('coming soon'), findsOneWidget);
    });

    testWidgets('end-to-end: progress increment to goal-hit flows through UI',
        (tester) async {
      await pumpPostOnboardingHome(tester, setup: (s) {
        s.earnedToday = 1450; // just under $2 target (1500 stars)
      });
      // Exact-string matches on 'Push to $3' below are intentional.
      // textContaining('$3') would also match the $3.00 progress text
      // after the push, making findsNothing unreliable.
      expect(find.text('Push to \$3'), findsNothing);

      // Bypass completeTask and set earnedToday directly to trigger
      // the goal-hit UI state. This exercises the DailyGoalCard
      // transitions, not the earning pipeline.
      final state = Provider.of<AppState>(
        tester.element(find.byType(DailyGoalCard)),
        listen: false,
      );
      state.earnedToday = 1500;
      // ignore: invalid_use_of_protected_member
      state.notifyListeners();
      await tester.pump();

      expect(find.text('Push to \$3'), findsOneWidget);

      // Tap Push to $3.
      await tester.tap(find.text('Push to \$3'));
      await tester.pump();
      expect(state.dailyGoalStars, 2250);
      expect(state.dailyExtensionOffered, isTrue);
      expect(find.text('Push to \$3'), findsNothing);
      // Progress card should now target $3.00.
      expect(find.textContaining('\$3.00'), findsOneWidget);
    });
  });
}
