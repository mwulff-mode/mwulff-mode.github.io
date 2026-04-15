import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';

void main() {
  group('AppState.currentTheme', () {
    test('defaults to Cream', () {
      final state = AppState();
      expect(state.currentTheme, kCreamTheme);
    });

    test('setTheme updates the field and notifies listeners', () {
      final state = AppState();
      var notified = 0;
      state.addListener(() => notified++);

      state.setTheme(kPlumTheme);

      expect(state.currentTheme, kPlumTheme);
      expect(notified, 1);
    });

    test('setTheme is a no-op when the theme does not change', () {
      final state = AppState();
      state.setTheme(kPlumTheme); // move off the default first
      var notified = 0;
      state.addListener(() => notified++);

      state.setTheme(kPlumTheme);

      expect(notified, 0);
    });

    test('reset returns currentTheme to Cream', () {
      final state = AppState();
      state.setTheme(kBumbleTheme);

      state.reset();

      expect(state.currentTheme, kCreamTheme);
    });
  });
}
