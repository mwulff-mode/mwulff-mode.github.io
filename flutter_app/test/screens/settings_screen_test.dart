import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:earnwise_mvp/screens/settings_screen.dart';
import 'package:earnwise_mvp/state/app_state.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';

Widget _boot(AppState state) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: Consumer<AppState>(
      builder: (context, s, _) => MaterialApp(
        theme: AppTheme.buildMaterialTheme(s.currentTheme),
        home: const SettingsScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders four rows in Cream, Plum, Bumble, Clue order',
      (tester) async {
    final state = AppState();
    await tester.pumpWidget(_boot(state));

    expect(find.text('Cream'), findsOneWidget);
    expect(find.text('Plum'), findsOneWidget);
    expect(find.text('Bumble'), findsOneWidget);
    expect(find.text('Clue'), findsOneWidget);

    // Row order: find the SettingsScreen descendant Text widgets in render order
    final titles = tester
        .widgetList<Text>(find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Text),
        ))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    final creamIdx = titles.indexOf('Cream');
    final plumIdx = titles.indexOf('Plum');
    final bumbleIdx = titles.indexOf('Bumble');
    final clueIdx = titles.indexOf('Clue');
    expect(creamIdx, lessThan(plumIdx));
    expect(plumIdx, lessThan(bumbleIdx));
    expect(bumbleIdx, lessThan(clueIdx));
  });

  testWidgets('tapping Plum row calls setTheme(kPlumTheme)', (tester) async {
    final state = AppState();
    await tester.pumpWidget(_boot(state));

    expect(state.currentTheme, kCreamTheme);

    await tester.tap(find.text('Plum'));
    await tester.pumpAndSettle();

    expect(state.currentTheme, kPlumTheme);
  });

  testWidgets('after tap, Scaffold.backgroundColor reflects the new theme',
      (tester) async {
    final state = AppState();
    await tester.pumpWidget(_boot(state));

    await tester.tap(find.text('Plum'));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, kPlumTheme.palette.surface);
  });
}
