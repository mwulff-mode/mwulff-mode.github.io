import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/home_shell.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/widgets/daily_goal_card.dart';

Future<void> pumpPostOnboardingHome(
  WidgetTester tester, {
  void Function(AppState)? setup,
}) async {
  final state = AppState()
    ..screen5Played = true
    ..welcomeModalShown = true
    ..goalIndex = 1 // Post-onboarding: past first goal.
    ..userName = 'Sarah';
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
    testWidgets('renders the DailyGoalCard instead of Today\'s Tasks',
        (tester) async {
      await pumpPostOnboardingHome(tester);
      expect(find.byType(DailyGoalCard), findsOneWidget);
      expect(find.text("Today's Tasks"), findsNothing);
    });
  });
}
