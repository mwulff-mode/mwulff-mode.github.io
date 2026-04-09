import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/home_shell.dart';
import 'package:earnwise_mvp/state/app_state.dart';

/// Pumps [HomeShell] inside a Provider + MaterialApp harness.
/// Uses pump() with a fixed duration rather than pumpAndSettle() because
/// AnimatedGradientBg contains a repeat() animation controller that never
/// settles, which would cause pumpAndSettle() to time out.
Future<void> pumpShell(WidgetTester tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>(
      create: (_) => AppState(),
      child: const MaterialApp(
        home: HomeShell(),
      ),
    ),
  );
  // Advance past all gift animation timers. The chain in _playGiftAnimation
  // accumulates to ~3080 ms before hiding the gift, then fires a final
  // 2500 ms journey-entry timer. Pumping 6 s drains every pending timer
  // without requiring pumpAndSettle (AnimatedGradientBg uses repeat() and
  // never settles).
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  group('HomeShell', () {
    testWidgets('renders without throwing', (tester) async {
      await pumpShell(tester);
      expect(find.byType(HomeShell), findsOneWidget);
    });

    testWidgets('tapping the Wallet tab shows the Wallet stub',
        (tester) async {
      await pumpShell(tester);
      expect(find.text('Wallet coming soon'), findsNothing);

      await tester.tap(find.byKey(const Key('shell_nav_wallet')));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Wallet coming soon'), findsOneWidget);
    });

    testWidgets('tapping the Profile tab shows the profile screen',
        (tester) async {
      await pumpShell(tester);
      expect(find.byKey(const Key('profile_screen_root')), findsNothing);

      await tester.tap(find.byKey(const Key('shell_nav_profile')));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('profile_screen_root')), findsOneWidget);
    });
  });
}
