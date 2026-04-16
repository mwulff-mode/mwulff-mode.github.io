import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';
import 'package:earnwise_mvp/widgets/app_card.dart';
import 'theme_test_harness.dart';

BoxDecoration _decorationOf(WidgetTester tester, Key key) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byKey(key),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  const k = Key('card-under-test');

  testWidgets('Plum AppCard unselected uses surfaceRaised + hairline border',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kPlumTheme,
        AppCard(key: k, child: const SizedBox(width: 80, height: 40)),
      ),
    );

    final d = _decorationOf(tester, k);
    expect(d.color, kPlumTheme.palette.surfaceRaised);
    final border = d.border as Border;
    expect(border.top.color, kPlumTheme.palette.hairline);
    expect(border.top.width, 1.5);
  });

  testWidgets('Plum AppCard selected uses surfaceSelected + brand border',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kPlumTheme,
        AppCard(
          key: k,
          selected: true,
          child: const SizedBox(width: 80, height: 40),
        ),
      ),
    );

    final d = _decorationOf(tester, k);
    expect(d.color, kPlumTheme.palette.surfaceSelected);
    final border = d.border as Border;
    expect(border.top.color, kPlumTheme.palette.brand);
  });
}
