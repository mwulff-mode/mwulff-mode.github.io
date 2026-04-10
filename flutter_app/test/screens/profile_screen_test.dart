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
      state.userName = 'Lisa';
      await pumpProfile(tester, state: state);
      expect(find.text('L'), findsOneWidget);
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
  });
}
