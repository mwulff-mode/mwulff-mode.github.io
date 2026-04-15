import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';
import 'package:earnwise_mvp/widgets/stat_bubble.dart';
import 'theme_test_harness.dart';

Widget _wrap(Widget child) => wrapWithTheme(kCreamTheme, child);

void main() {
  group('StatBubble', () {
    testWidgets('renders the value and label', (tester) async {
      await tester.pumpWidget(_wrap(
        StatBubble(
          icon: PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
          value: '\$12.40',
          label: 'Balance',
        ),
      ));
      expect(find.text('\$12.40'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
    });

    testWidgets('defaults the accent color to AppColors.brand',
        (tester) async {
      await tester.pumpWidget(_wrap(
        StatBubble(
          icon: PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
          value: '\$12.40',
          label: 'Balance',
        ),
      ));
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, AppColors.brand);
    });

    testWidgets('respects an explicit accent override', (tester) async {
      await tester.pumpWidget(_wrap(
        StatBubble(
          icon: PhosphorIcons.star(PhosphorIconsStyle.duotone),
          value: '12',
          label: 'Today',
          accentColor: AppColors.flame,
        ),
      ));
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, AppColors.flame);
    });
  });
}
