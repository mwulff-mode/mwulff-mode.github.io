import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/data/games.dart';
import 'package:earnwise_mvp/models/installed_game.dart';
import 'package:earnwise_mvp/screens/game_detail_screen.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';

void main() {
  /// Helper that pushes [GameDetailScreen] onto a real Navigator so the
  /// X button can pop it like in the real app. The screen reads
  /// [AppState.installedGames] to drive the "Reward Steps" strip, so the
  /// pump wraps the whole tree in a real [ChangeNotifierProvider].
  Future<void> pumpDetail(
    WidgetTester tester, {
    required Game game,
    VoidCallback? onInstall,
    AppState? state,
  }) async {
    final appState = state ?? AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameDetailScreen(
                        game: game,
                        onInstall: onInstall ?? () {},
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('GameDetailScreen', () {
    testWidgets('renders the game name in the title', (tester) async {
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('Candy Crush'), findsWidgets);
    });

    testWidgets('X button pops the screen', (tester) async {
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('Candy Crush'), findsWidgets);

      await tester.tap(find.byKey(const Key('game_detail_close')));
      await tester.pumpAndSettle();

      expect(find.text('Candy Crush'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('renders the game category and rating', (tester) async {
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('Puzzle'), findsOneWidget);
      expect(find.text('4.7'), findsOneWidget);
    });

    testWidgets(
        'earnings summary shows the total reward and fresh earned amount',
        (tester) async {
      // Candy Crush steps sum to $27.00 (0.10 + 0.90 + 2.00 + 4.00 + 8.00
      // + 12.00). On a fresh AppState nothing is completed for Candy Crush,
      // so the earned amount reads $0.00. Both dollar amounts render inside
      // a single Text.rich sentence, so the finders pass findRichText.
      final state = AppState()..installedGames = [];
      await pumpDetail(
        tester,
        game: gamesByName['Candy Crush']!,
        state: state,
      );
      expect(
        find.textContaining('\$27.00', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('\$0.00', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining("You've earned", findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets(
        'earnings summary adds up rewards for completed milestones',
        (tester) async {
      // Marking the first two Candy Crush steps completed means the user
      // has earned $0.10 + $0.90 = $1.00 out of $27.00.
      final catalog = gamesByName['Candy Crush']!;
      final state = AppState()
        ..installedGames = [
          InstalledGame.fromCatalog(catalog, completed: const {0, 1}),
        ];
      await pumpDetail(tester, game: catalog, state: state);
      expect(
        find.textContaining('\$1.00', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('\$27.00', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders the How It Works section', (tester) async {
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('How It Works'), findsOneWidget);
      expect(
        find.text(gamesByName['Candy Crush']!.howItWorks),
        findsOneWidget,
      );
    });

    testWidgets('renders the About section with the game name in the heading',
        (tester) async {
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('About Candy Crush'), findsOneWidget);
      expect(find.text(gamesByName['Candy Crush']!.about), findsOneWidget);
    });

    testWidgets('renders the Disclaimer section', (tester) async {
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('Disclaimer'), findsOneWidget);
      expect(
        find.text(gamesByName['Candy Crush']!.disclaimer),
        findsOneWidget,
      );
    });

    testWidgets('renders the Reward Steps heading with a 0/6 counter',
        (tester) async {
      // Each catalog game now ships 6 reward steps, and no steps are
      // completed on a fresh AppState.
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('Reward Steps'), findsOneWidget);
      expect(find.text('0 / 6'), findsOneWidget);
    });

    testWidgets('renders both step labels and rewards', (tester) async {
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('Install the app'), findsOneWidget);
      expect(find.text('Reach Level 15'), findsOneWidget);
      expect(find.text('\$0.10'), findsOneWidget);
      expect(find.text('\$0.90'), findsOneWidget);
    });

    testWidgets('first step shows UP NEXT, later steps show NOT STARTED',
        (tester) async {
      // With nothing completed, step 0 is the only "up next" card and
      // the remaining visible cards render the "not started" pill. The
      // Reward Steps ListView lazily builds only the cards that fit in
      // the horizontal viewport (about 3-4 at 800 px wide), so the
      // assertion is framed around the presence of the pill rather
      // than an exact count.
      await pumpDetail(tester, game: gamesByName['Candy Crush']!);
      expect(find.text('UP NEXT'), findsOneWidget);
      expect(find.text('NOT STARTED'), findsAtLeastNWidgets(1));
    });

    testWidgets('Install Game button calls onInstall and pops the screen',
        (tester) async {
      int installCount = 0;
      // AppState seeds Candy Crush as already installed, which would flip
      // the CTA into "Continue playing" mode and skip onInstall. Clear
      // installedGames so this test exercises the fresh-install path.
      final state = AppState()..installedGames = [];
      await pumpDetail(
        tester,
        game: gamesByName['Candy Crush']!,
        state: state,
        onInstall: () => installCount++,
      );
      expect(find.text('Candy Crush'), findsWidgets);

      await tester.tap(find.byKey(const Key('game_detail_install')));
      await tester.pumpAndSettle();

      expect(installCount, 1);
      expect(find.text('Candy Crush'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets(
      'falls back to a colored letter square when the icon asset is missing',
      (tester) async {
        const fakeGame = Game(
          key: 'fake',
          name: 'Fake Game',
          category: 'Puzzle',
          rating: 4.0,
          iconPath: 'assets/images/games/does_not_exist.png',
          heroGradient: [AppColors.primary, AppColors.creamDeep],
          regularSteps: [
            GameStep(label: 'Install the app', reward: 0.10),
            GameStep(label: 'Reach Level 1', reward: 0.90),
          ],
          howItWorks: 'How it works copy.',
          about: 'About copy.',
          disclaimer: 'Disclaimer copy.',
        );
        await pumpDetail(tester, game: fakeGame);
        // Settle any residual frames from the failed image decode so the
        // errorBuilder fallback widget is committed to the tree.
        await tester.pumpAndSettle();
        // Fallback shows the first letter of the game name.
        expect(find.text('F'), findsOneWidget);
      },
    );
  });
}
