import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/widgets/daily_goal_card.dart';

Future<void> pumpCard(WidgetTester tester, AppState state) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(
        home: Scaffold(body: DailyGoalCard()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('DailyGoalCard', () {
    testWidgets('default state shows "\$X of \$2.00"', (tester) async {
      final state = AppState()..earnedToday = 750; // \$1.00
      await pumpCard(tester, state);
      expect(find.textContaining('\$1.00'), findsOneWidget);
      expect(find.textContaining('\$2.00'), findsOneWidget);
      expect(find.text('Push to \$3'), findsNothing);
    });

    testWidgets('goal-hit state shows the extension prompt', (tester) async {
      final state = AppState()..earnedToday = 1500;
      await pumpCard(tester, state);
      expect(find.textContaining("you hit today's \$2"), findsOneWidget);
      expect(find.text('Push to \$3'), findsOneWidget);
      expect(find.text('Bank it'), findsOneWidget);
    });

    testWidgets('tapping "Push to \$3" raises target and hides the prompt',
        (tester) async {
      final state = AppState()..earnedToday = 1500;
      await pumpCard(tester, state);
      await tester.tap(find.text('Push to \$3'));
      await tester.pump();
      expect(state.dailyGoalStars, 2250);
      expect(state.dailyExtensionOffered, isTrue);
      expect(find.text('Push to \$3'), findsNothing);
      // Progress bar should now show target \$3.00.
      expect(find.textContaining('\$3.00'), findsOneWidget);
    });

    testWidgets('tapping "Bank it" keeps \$2 target and hides the prompt',
        (tester) async {
      final state = AppState()..earnedToday = 1500;
      await pumpCard(tester, state);
      await tester.tap(find.text('Bank it'));
      await tester.pump();
      expect(state.dailyGoalStars, 1500);
      expect(state.dailyExtensionOffered, isTrue);
      expect(find.text('Push to \$3'), findsNothing);
      expect(find.textContaining('\$2.00'), findsOneWidget);
    });

    testWidgets('extended state after push shows "\$X of \$3.00"',
        (tester) async {
      final state = AppState()
        ..earnedToday = 1800
        ..dailyGoalStars = 2250
        ..dailyExtensionOffered = true;
      await pumpCard(tester, state);
      expect(find.textContaining('\$2.40'), findsOneWidget); // 1800/750
      expect(find.textContaining('\$3.00'), findsOneWidget);
      expect(find.text('Push to \$3'), findsNothing);
    });
  });
}
