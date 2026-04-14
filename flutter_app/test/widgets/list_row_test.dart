import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/widgets/category_icon_square.dart';
import 'package:earnwise_mvp/widgets/list_row.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

CategoryIconSquare _leading() => CategoryIconSquare(
      icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
      foreground: AppColors.categorySurvey,
      background: AppColors.categorySurveyBg,
    );

void main() {
  group('ListRow', () {
    testWidgets('renders title, subtitle, and a default trailing chevron',
        (tester) async {
      await tester.pumpWidget(_wrap(
        ListRow(
          leading: _leading(),
          title: 'Daily survey',
          subtitle: '+\$0.50 for 2 minutes',
          onTap: () {},
        ),
      ));
      expect(find.text('Daily survey'), findsOneWidget);
      expect(find.text('+\$0.50 for 2 minutes'), findsOneWidget);
      // Default trailing is a Phosphor caretRight icon.
      expect(find.byType(Icon), findsNWidgets(2)); // leading + caret
    });

    testWidgets('fires onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        ListRow(
          leading: _leading(),
          title: 'Tap target',
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.text('Tap target'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('disabled prevents onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        ListRow(
          leading: _leading(),
          title: 'Disabled row',
          onTap: () => tapped = true,
          disabled: true,
        ),
      ));
      // warnIfMissed: false because the IgnorePointer inside the disabled
      // row is exactly what we are asserting. The tap is expected to miss.
      await tester.tap(find.text('Disabled row'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });

    testWidgets('uses a custom trailing when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        ListRow(
          leading: _leading(),
          title: 'Custom trailing',
          trailing: const Text('NEW'),
        ),
      ));
      expect(find.text('NEW'), findsOneWidget);
    });
  });
}
