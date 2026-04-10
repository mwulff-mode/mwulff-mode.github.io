import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/home_shell.dart';
import 'package:earnwise_mvp/state/app_state.dart';

/// Pumps [HomeShell] inside a Provider + MaterialApp harness.
///
/// screen5Played is the gate that suppresses the welcome-gift animation
/// chain in HomeScreen._playGiftAnimation. Skipping it avoids the 5.5 s
/// of Future.delayed timers that would otherwise run during the test.
/// AnimatedGradientBg still runs its infinite repeat loop in the
/// background, but no assertion depends on it, so we never need to
/// pumpAndSettle.
Future<void> pumpShell(WidgetTester tester) async {
  final state = AppState()..screen5Played = true;
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: HomeShell()),
    ),
  );
  await tester.pump(); // one frame to build the tree
}

void main() {
  group('HomeShell', () {
    testWidgets('renders without throwing', (tester) async {
      await pumpShell(tester);
      expect(find.byType(HomeShell), findsOneWidget);
    });

    testWidgets('tapping the Wallet tab shows the Wallet screen',
        (tester) async {
      await pumpShell(tester);
      expect(find.text('Withdraw'), findsNothing);

      await tester.tap(find.byKey(const Key('shell_nav_wallet')));
      await tester.pump(); // setState and rebuild
      await tester.pump(const Duration(
          milliseconds: 320)); // AnimatedContainer frame (AppDurations.medium)

      expect(find.text('Withdraw'), findsOneWidget);
    });

    testWidgets('tapping the Profile tab shows the profile screen',
        (tester) async {
      await pumpShell(tester);
      expect(find.byKey(const Key('profile_screen_root')), findsNothing);

      await tester.tap(find.byKey(const Key('shell_nav_profile')));
      await tester.pump(); // setState and rebuild
      await tester.pump(const Duration(
          milliseconds: 320)); // AnimatedContainer frame (AppDurations.medium)

      expect(find.byKey(const Key('profile_screen_root')), findsOneWidget);
    });
  });
}
