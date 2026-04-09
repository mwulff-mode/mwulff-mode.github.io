import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/data/games.dart';
import 'package:earnwise_mvp/screens/game_detail_screen.dart';

void main() {
  /// Helper that pushes [GameDetailScreen] onto a real Navigator so the
  /// X button can pop it like in the real app.
  Future<void> pumpDetail(
    WidgetTester tester, {
    required Game game,
    VoidCallback? onInstall,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
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
  });
}
