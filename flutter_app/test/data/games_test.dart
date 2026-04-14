import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/data/games.dart';

void main() {
  group('gamesByName', () {
    test('contains exactly 3 entries keyed by display name', () {
      expect(gamesByName.keys.toSet(),
          {'Candy Crush', 'Solitaire', 'Word Search'});
    });

    test('every game has 6 regular steps with positive rewards', () {
      for (final game in gamesByName.values) {
        expect(game.regularSteps.length, 6,
            reason: '${game.name} should have exactly 6 steps');
        for (final step in game.regularSteps) {
          expect(step.reward, greaterThan(0),
              reason: '${game.name} step "${step.label}" should reward > 0');
        }
      }
    });

    test('every game has non-empty howItWorks, about, disclaimer', () {
      for (final game in gamesByName.values) {
        expect(game.howItWorks, isNotEmpty);
        expect(game.about, isNotEmpty);
        expect(game.disclaimer, isNotEmpty);
      }
    });

    test('every game has a non-empty iconPath under assets/app_icons/', () {
      for (final game in gamesByName.values) {
        expect(game.iconPath, startsWith('assets/app_icons/'));
        expect(game.iconPath, endsWith('.png'));
      }
    });

    test('every game has a 2-stop hero gradient', () {
      for (final game in gamesByName.values) {
        expect(game.heroGradient.length, 2,
            reason: '${game.name} should have 2 gradient stops');
      }
    });
  });
}
