import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';
import 'package:earnwise_mvp/widgets/primary_button.dart';
import 'theme_test_harness.dart';

BoxDecoration _decorationOf(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(PrimaryButton),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('Cream CTA renders brand background with full card radius',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kCreamTheme,
        PrimaryButton(label: 'Continue', onTap: () {}),
      ),
    );
    final d = _decorationOf(tester);
    expect(d.color, kCreamTheme.cta.background);
    expect(
      (d.borderRadius as BorderRadius).topLeft.x,
      kCreamTheme.radii.button,
    );
  });

  testWidgets('Plum CTA renders violet background with full pill radius',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kPlumTheme,
        PrimaryButton(label: 'Continue', onTap: () {}),
      ),
    );
    final d = _decorationOf(tester);
    expect(d.color, kPlumTheme.cta.background);
    expect(
      (d.borderRadius as BorderRadius).topLeft.x,
      kPlumTheme.radii.button,
    );
  });

  testWidgets('Bumble CTA uses ink background, NOT brand', (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kBumbleTheme,
        PrimaryButton(label: 'Continue', onTap: () {}),
      ),
    );
    final d = _decorationOf(tester);
    // The brand-vs-CTA split: yellow brand but black CTA.
    expect(d.color, kBumbleTheme.palette.ink);
    expect(d.color, isNot(kBumbleTheme.palette.brand));
  });

  testWidgets('destructive=true overrides theme with Sign Out red',
      (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kBumbleTheme,
        PrimaryButton(
          label: 'Sign Out',
          onTap: () {},
          destructive: true,
        ),
      ),
    );
    final d = _decorationOf(tester);
    expect(d.color, kDestructiveRed);
  });

  testWidgets('onTap fires when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrapWithTheme(
        kCreamTheme,
        PrimaryButton(label: 'Continue', onTap: () => taps++),
      ),
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('onTap=null does not throw when tapped', (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kCreamTheme,
        const PrimaryButton(label: 'Loading', onTap: null),
      ),
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    // No exception thrown. Animation completes cleanly.
  });

  testWidgets(
      'outlined variant renders transparent fill + accent border', (tester) async {
    await tester.pumpWidget(
      wrapWithTheme(
        kCreamTheme,
        PrimaryButton(
          label: 'Finish onboarding tasks',
          onTap: () {},
          outlined: true,
        ),
      ),
    );
    final d = _decorationOf(tester);
    expect(d.color, Colors.transparent);
    // Border is painted in the base cta.background color (the accent),
    // so the outlined pill inherits the same hue that a filled one would.
    final border = d.border as Border;
    expect(border.top.color, kCreamTheme.cta.background);
    expect(border.top.width, 1.5);
  });

  testWidgets('trailingIcon renders after the label with the accent color',
      (tester) async {
    const trailing = Icons.arrow_forward;
    await tester.pumpWidget(
      wrapWithTheme(
        kCreamTheme,
        PrimaryButton(
          label: 'Finish onboarding tasks',
          onTap: () {},
          outlined: true,
          trailingIcon: trailing,
        ),
      ),
    );
    // Icon is painted in the accent color (cta.background for outlined).
    final iconWidget = tester.widget<Icon>(find.byIcon(trailing));
    expect(iconWidget.color, kCreamTheme.cta.background);
  });
}
