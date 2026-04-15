import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/home_shell.dart';
import 'package:earnwise_mvp/screens/placeholder_list_screen.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/models/installed_game.dart';

Future<void> pumpPostOnboardingHome(
  WidgetTester tester, {
  void Function(AppState)? setup,
}) async {
  final state = AppState()
    ..screen5Played = true
    ..welcomeModalShown = true
    ..goalIndex = 1 // Post-onboarding: past first goal.
    ..userName = 'Sarah'
    // Seed two demo in-progress games so the default pump exercises the
    // Continue earning section. AppState itself ships empty so onboarding
    // Game Detail never shows "Continue playing" for a game the user has
    // not actually installed yet; tests that want the populated list have
    // to set it here (or override via `setup`).
    ..installedGames = [
      InstalledGame(
        id: 'candy_crush',
        name: 'Candy Crush',
        iconPath: 'assets/app_icons/Candy_Crush_Saga.png',
        nextMilestoneLabel: 'Reach Level 50',
        nextMilestoneReward: 2.00,
        lastPlayedAt: DateTime(2026, 4, 13, 9, 15),
      ),
      InstalledGame(
        id: 'solitaire',
        name: 'Solitaire',
        iconPath: 'assets/app_icons/Solitaire_Classic.png',
        nextMilestoneLabel: 'Win 75 games',
        nextMilestoneReward: 2.50,
        lastPlayedAt: DateTime(2026, 4, 12, 20, 40),
      ),
    ];
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
    testWidgets('renders the daily-goal ring instead of Today\'s Tasks',
        (tester) async {
      await pumpPostOnboardingHome(tester);
      // The ring center renders the daily target. Default state is the
      // $2 starter tier, and the Balance + Today stat bubbles still
      // flank the ring post-onboarding just like they did during
      // onboarding.
      expect(find.text('\$2.00'), findsWidgets);
      expect(find.text('Daily Goal'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
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

    testWidgets('shows three Earn More tiles matching onboarding',
        (tester) async {
      await pumpPostOnboardingHome(tester);
      expect(find.text('Earn More'), findsOneWidget);
      // Post-onboarding mirrors the onboarding tile trio so the "unlock
      // all modes" promise resolves to the same three categories.
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('Surveys'), findsOneWidget);
      expect(find.text('Games'), findsOneWidget);
      // Subtitle assertions guard against future copy regressions.
      expect(find.text('Save & earn'), findsOneWidget);
      expect(find.text('Share & earn'), findsOneWidget);
      expect(find.text('Play & earn'), findsOneWidget);
    });

    testWidgets('tapping the Offers tile pushes PlaceholderListScreen',
        (tester) async {
      await pumpPostOnboardingHome(tester);
      await tester.scrollUntilVisible(find.text('Offers'), 100);
      await tester.tap(find.text('Offers'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceholderListScreen), findsOneWidget);
      expect(find.text('Offers'), findsWidgets);
      expect(find.textContaining('coming soon'), findsOneWidget);
    });

    testWidgets('end-to-end: crossing \$2 auto-extends the ring to \$5',
        (tester) async {
      await pumpPostOnboardingHome(tester, setup: (s) {
        s.earnedToday = 1450; // just under $2 target
      });
      // Starter tier: ring reads $2.00 and is not yet extended.
      expect(find.text('\$2.00'), findsWidgets);

      // Anchor the Provider lookup on HomeShell, which is always in the
      // tree. Drive the state through completeTask so the rising-edge
      // detector and the auto-extend branch both run.
      final state = Provider.of<AppState>(
        tester.element(find.byType(HomeShell)),
        listen: false,
      );
      state.completeTask('daily_survey'); // +500 stars, crosses 1500
      await tester.pump();

      // The ring has levelled up: target jumps to $5, extended flag is
      // true, and the previous $2 of progress is locked in on the bigger
      // ring (no prompt card appears, no user input required).
      expect(state.dailyGoalExtended, isTrue);
      expect(state.dailyGoalStars, 3750);
      expect(find.text('\$5.00'), findsWidgets);
      expect(find.text('Daily Goal'), findsOneWidget);
      // Balance + Today bubbles remain on either side of the ring.
      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });
  });
}
