import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';
import 'package:earnwise_mvp/widgets/surface.dart';
import 'theme_test_harness.dart';

BoxDecoration _decorationOf(WidgetTester tester, Key key) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byKey(key), matching: find.byType(Container)),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  const k = Key('surface-under-test');

  testWidgets('Cream Surface uses raised surface color + elevation.card',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kCreamTheme,
        Surface(key: k, child: const SizedBox(width: 80, height: 40)),
      ),
    );

    final d = _decorationOf(tester, k);
    expect(d.color, kCreamTheme.palette.surfaceRaised);
    expect(d.boxShadow, isNotEmpty);
    expect(d.border, isNull); // Cream has shadows, no auto-hairline
  });

  testWidgets('Plum Surface is flat and auto-draws the hairline border',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kPlumTheme,
        Surface(key: k, child: const SizedBox(width: 80, height: 40)),
      ),
    );

    final d = _decorationOf(tester, k);
    expect(d.color, kPlumTheme.palette.surfaceRaised);
    expect(d.boxShadow, isEmpty);
    // Auto-hairline fired because elevation.card is empty and no
    // explicit border was passed.
    final border = d.border as Border;
    expect(border.top.color, kPlumTheme.palette.hairline);
    expect(border.top.width, 1);
  });

  testWidgets('An explicit border suppresses the auto-hairline', (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kPlumTheme,
        Surface(
          key: k,
          border: Border.all(color: const Color(0xFF123456), width: 2),
          child: const SizedBox(width: 80, height: 40),
        ),
      ),
    );

    final d = _decorationOf(tester, k);
    final border = d.border as Border;
    expect(border.top.color, const Color(0xFF123456));
    expect(border.top.width, 2);
  });
}
