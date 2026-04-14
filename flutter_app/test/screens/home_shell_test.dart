import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/home_shell.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/widgets/press_scale.dart';

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

    testWidgets('tapping the Wallet tab activates the Wallet index',
        (tester) async {
      // HomeShell uses an IndexedStack, which keeps every tab mounted at
      // all times. Tab visibility is controlled by IndexedStack.index, so
      // the test asserts the active index instead of looking for
      // tab-specific text that would be in the tree on every pump.
      //
      // The nav pill is wrapped in a ClipRRect + BackdropFilter, which
      // makes real gesture-based taps unreliable in the test harness
      // (the hit test lands on the clipped background rather than on the
      // inner PressScale). Invoking the PressScale.onTap directly
      // exercises the same code path setState uses without depending on
      // the render-level hit testing.
      await pumpShell(tester);
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        0,
      );

      final walletTab = tester
          .widget<PressScale>(find.byKey(const Key('shell_nav_wallet')));
      walletTab.onTap!();
      await tester.pump(); // setState and rebuild
      await tester.pump(const Duration(
          milliseconds: 320)); // AnimatedContainer frame (AppDurations.medium)

      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        1,
      );
    });

    testWidgets('tapping the Profile tab activates the Profile index',
        (tester) async {
      // Same IndexedStack reasoning as the Wallet test above, and same
      // BackdropFilter hit-test workaround: invoke onTap directly on the
      // PressScale instead of routing through the gesture pipeline.
      await pumpShell(tester);
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        0,
      );

      final profileTab = tester
          .widget<PressScale>(find.byKey(const Key('shell_nav_profile')));
      profileTab.onTap!();
      await tester.pump(); // setState and rebuild
      await tester.pump(const Duration(
          milliseconds: 320)); // AnimatedContainer frame (AppDurations.medium)

      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        2,
      );
      // profile_screen_root is in the tree on every pump (IndexedStack
      // keeps tabs mounted), so this just double-checks the ProfileScreen
      // actually built without throwing.
      expect(find.byKey(const Key('profile_screen_root')), findsOneWidget);
    });
  });
}
