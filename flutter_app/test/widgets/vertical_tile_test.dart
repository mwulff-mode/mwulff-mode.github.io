import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/widgets/category_icon_square.dart';
import 'package:earnwise_mvp/widgets/vertical_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 120, child: child),
        ),
      ),
    );

CategoryIconSquare _leading() => CategoryIconSquare(
      icon: PhosphorIcons.tag(PhosphorIconsStyle.duotone),
      foreground: AppColors.categoryOffers,
      background: AppColors.categoryOffersBg,
      size: 44,
      iconSize: 22,
    );

void main() {
  group('VerticalTile', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(_wrap(
        VerticalTile(
          leading: _leading(),
          title: 'Offers',
          subtitle: 'Save & earn',
          onTap: () {},
        ),
      ));
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('Save & earn'), findsOneWidget);
    });

    testWidgets('fires onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        VerticalTile(
          leading: _leading(),
          title: 'Receipts',
          subtitle: 'Cashback',
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.text('Receipts'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('disabled prevents onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(
        VerticalTile(
          leading: _leading(),
          title: 'Games',
          subtitle: 'Play & earn',
          onTap: () => tapped = true,
          disabled: true,
        ),
      ));
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
    });
  });
}
