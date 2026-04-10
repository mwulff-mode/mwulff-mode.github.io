import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/profile_screen.dart';
import 'package:earnwise_mvp/state/app_state.dart';

/// Pumps [ProfileScreen] inside a minimal Provider + MaterialApp harness.
/// Optionally accepts a pre-built [AppState] so tests can set userName
/// or other fields before the screen reads them.
Future<void> pumpProfile(
  WidgetTester tester, {
  AppState? state,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state ?? AppState(),
      child: const MaterialApp(
        home: Scaffold(body: ProfileScreen()),
      ),
    ),
  );
  // Safe to pumpAndSettle here: ProfileScreen has no infinite-repeat
  // animations. HomeShell's test has to skip pumpAndSettle because of
  // AnimatedGradientBg, but ProfileScreen renders static content only.
  await tester.pumpAndSettle();
}

void main() {
  group('ProfileScreen', () {
    testWidgets('renders without throwing', (tester) async {
      await pumpProfile(tester);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('renders the avatar initial from userName', (tester) async {
      final state = AppState();
      state.userName = 'Alice';
      await pumpProfile(tester, state: state);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('renders the email from AppState', (tester) async {
      await pumpProfile(tester);
      expect(find.text('lisa@earnwise.demo'), findsWidgets);
    });

    testWidgets('renders the provider badge "via Google"', (tester) async {
      await pumpProfile(tester);
      expect(find.text('via'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('renders the PERSONAL INFO section heading', (tester) async {
      await pumpProfile(tester);
      expect(find.text('PERSONAL INFO'), findsOneWidget);
    });

    testWidgets('renders the Full Name row with label and value',
        (tester) async {
      final state = AppState();
      state.userName = 'Lisa';
      await pumpProfile(tester, state: state);
      expect(find.text('Full Name'), findsOneWidget);
      // The hero shows the initial 'L' and the info row shows the full name 'Lisa'.
      expect(find.text('Lisa'), findsOneWidget);
    });

    testWidgets('renders the Age Range row with label and value',
        (tester) async {
      await pumpProfile(tester);
      expect(find.text('Age Range'), findsOneWidget);
      expect(find.text('26-35'), findsOneWidget);
    });

    testWidgets('renders the Gender row with label and value', (tester) async {
      await pumpProfile(tester);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
    });

    testWidgets('renders the ACCOUNT section heading', (tester) async {
      await pumpProfile(tester);
      expect(find.text('ACCOUNT'), findsOneWidget);
    });

    testWidgets('renders the Connected Account row with the email',
        (tester) async {
      await pumpProfile(tester);
      expect(find.text('Connected Account'), findsOneWidget);
      // Email now appears twice: once in the hero and once in the account row.
      expect(find.text('lisa@earnwise.demo'), findsNWidgets(2));
    });
  });
}
