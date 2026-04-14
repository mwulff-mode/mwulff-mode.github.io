import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/widgets/surface.dart';

void main() {
  group('Surface', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Surface(child: const Text('inside')),
          ),
        ),
      );
      expect(find.text('inside'), findsOneWidget);
    });

    testWidgets('applies default radius and color via BoxDecoration',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Surface(child: const SizedBox(width: 100, height: 100)),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Surface),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.surfaceRaised);
      final borderRadius = decoration.borderRadius! as BorderRadius;
      expect(borderRadius.topLeft.x, AppRadius.card);
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, 1);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Surface(
              onTap: () => tapped = true,
              child: const SizedBox(
                width: 200,
                height: 100,
                child: Text('tap me'),
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
