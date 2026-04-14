import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/widgets/category_icon_square.dart';

void main() {
  group('CategoryIconSquare', () {
    testWidgets('renders the icon with the configured colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconSquare(
              icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
              foreground: AppColors.categorySurvey,
              background: AppColors.categorySurveyBg,
            ),
          ),
        ),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, AppColors.categorySurvey);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.categorySurveyBg);
    });

    testWidgets('defaults to a 48x48 square with 8px radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconSquare(
              icon: PhosphorIcons.gift(PhosphorIconsStyle.duotone),
              foreground: AppColors.categoryGame,
              background: AppColors.categoryGameBg,
            ),
          ),
        ),
      );
      final box = tester.getSize(find.byType(CategoryIconSquare));
      expect(box.width, 48);
      expect(box.height, 48);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      final br = decoration.borderRadius! as BorderRadius;
      expect(br.topLeft.x, AppRadius.chip);
    });

    testWidgets('respects an explicit size override', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryIconSquare(
              icon: PhosphorIcons.gift(PhosphorIconsStyle.duotone),
              foreground: AppColors.categoryGame,
              background: AppColors.categoryGameBg,
              size: 44,
              iconSize: 22,
            ),
          ),
        ),
      );
      final box = tester.getSize(find.byType(CategoryIconSquare));
      expect(box.width, 44);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 22);
    });
  });
}
