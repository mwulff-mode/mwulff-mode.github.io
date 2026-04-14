import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';

void main() {
  group('AppSpacing invariants', () {
    test('every semantic value is a multiple of 4 or is the tight exception',
        () {
      final entries = <String, double>{
        'tight': AppSpacing.tight,
        'xs': AppSpacing.xs,
        'sm': AppSpacing.sm,
        'inner': AppSpacing.inner,
        'rowGap': AppSpacing.rowGap,
        'cardPad': AppSpacing.cardPad,
        'titleGap': AppSpacing.titleGap,
        'sectionGap': AppSpacing.sectionGap,
        'pageGutter': AppSpacing.pageGutter,
        'blockGap': AppSpacing.blockGap,
        'heroGap': AppSpacing.heroGap,
        'pageTop': AppSpacing.pageTop,
      };
      for (final e in entries.entries) {
        final v = e.value;
        final isTight = e.key == 'tight' && v == 2;
        final isOnGrid = v % 4 == 0;
        expect(isTight || isOnGrid, isTrue,
            reason: 'AppSpacing.${e.key} = $v is off-grid');
      }
    });

    test('deprecated aliases preserve their original values', () {
      // Intentional: back-compat for existing screen code. New code
      // should use the semantic names above.
      // ignore: deprecated_member_use_from_same_package
      expect(AppSpacing.md, 16);
      // ignore: deprecated_member_use_from_same_package
      expect(AppSpacing.lg, 24);
      // ignore: deprecated_member_use_from_same_package
      expect(AppSpacing.xl, 32);
    });
  });

  group('AppRadius invariants', () {
    test('every value is in the allowed set', () {
      // Exactly the rungs exposed by AppRadius. Any future addition
      // outside this set should fail the test until it is added here
      // deliberately.
      final allowed = {8.0, 16.0, 20.0, 24.0, 9999.0};
      final entries = <String, double>{
        'chip': AppRadius.chip,
        'card': AppRadius.card,
        'feature': AppRadius.feature,
        'modal': AppRadius.modal,
        'pill': AppRadius.pill,
      };
      for (final e in entries.entries) {
        expect(allowed.contains(e.value), isTrue,
            reason: 'AppRadius.${e.key} = ${e.value} is not in the '
                'allowed radius set');
      }
    });
  });

  group('AppElevation', () {
    test('card shadow is a single subtle drop', () {
      expect(AppElevation.card.length, 1);
      final shadow = AppElevation.card.single;
      expect(shadow.offset, const Offset(0, 2));
      expect(shadow.blurRadius, 8);
    });

    test('none is an empty list', () {
      expect(AppElevation.none, isEmpty);
    });
  });
}
