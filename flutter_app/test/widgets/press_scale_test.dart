import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/widgets/press_scale.dart';

void main() {
  group('PressScale', () {
    testWidgets('calls onTap on release', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressScale(
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('tap me'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressScale(
                enabled: false,
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('tap me'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });

    testWidgets('does not crash when disableAnimations is true',
        (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: PressScale(
                  onTap: () => tapped = true,
                  child: const SizedBox(
                    width: 100,
                    height: 100,
                    child: Text('tap me'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
