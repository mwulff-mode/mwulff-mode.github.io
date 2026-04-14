import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/widgets/section_header.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SectionHeader', () {
    testWidgets('renders just a title', (tester) async {
      await tester.pumpWidget(_wrap(
        const SectionHeader(title: 'Earn More'),
      ));
      expect(find.text('Earn More'), findsOneWidget);
    });

    testWidgets('renders a subtitle when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const SectionHeader(
          title: 'Continue earning',
          subtitle: 'Pick up where you left off',
        ),
      ));
      expect(find.text('Continue earning'), findsOneWidget);
      expect(find.text('Pick up where you left off'), findsOneWidget);
    });

    testWidgets('renders a trailing action when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        SectionHeader(
          title: 'All games',
          action: TextButton(
            onPressed: () {},
            child: const Text('See all'),
          ),
        ),
      ));
      expect(find.text('All games'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
    });
  });
}
