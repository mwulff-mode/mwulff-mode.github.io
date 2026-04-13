import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/home_shell.dart';
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
  });
}
