import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/app_color_palette.dart';
import 'package:earnwise_mvp/theme/app_radius_scale.dart';
import 'package:earnwise_mvp/theme/app_elevation_profile.dart';
import 'package:earnwise_mvp/theme/app_cta_tokens.dart';

void main() {
  group('AppColorPalette', () {
    test('exposes every required semantic slot', () {
      const p = AppColorPalette(
        surface: Color(0xFF000001),
        surfaceRaised: Color(0xFF000002),
        surfaceSubtle: Color(0xFF000003),
        surfaceSelected: Color(0xFF000004),
        ink: Color(0xFF000005),
        inkSecondary: Color(0xFF000006),
        inkTertiary: Color(0xFF000007),
        brand: Color(0xFF000008),
        brandStrong: Color(0xFF000009),
        brandSubtle: Color(0xFF00000A),
        heroBackground: Color(0xFF00000B),
        heroForeground: Color(0xFF00000C),
        hairline: Color(0xFF00000D),
      );
      expect(p.surface, const Color(0xFF000001));
      expect(p.hairline, const Color(0xFF00000D));
    });
  });

  group('AppRadiusScale', () {
    test('stores every radius knob and `pill` is 9999 by convention', () {
      const r = AppRadiusScale(
        chip: 8,
        card: 16,
        feature: 20,
        modal: 24,
        button: 16,
      );
      expect(r.chip, 8);
      expect(r.card, 16);
      expect(r.feature, 20);
      expect(r.modal, 24);
      expect(r.button, 16);
      expect(AppRadiusScale.pill, 9999.0);
    });
  });

  group('AppElevationProfile', () {
    test('allows all-flat profiles and rich drop-shadow profiles', () {
      const flat = AppElevationProfile(
        none: [],
        card: [],
        raised: [],
        modal: [],
      );
      final rich = AppElevationProfile(
        none: const [],
        card: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
        raised: const [],
        modal: const [],
      );
      expect(flat.card, isEmpty);
      expect(rich.card.single.blurRadius, 8);
    });
  });

  group('AppCtaTokens', () {
    test('stores background and foreground', () {
      const cta = AppCtaTokens(
        background: Color(0xFF111111),
        foreground: Color(0xFFFFFFFF),
      );
      expect(cta.background, const Color(0xFF111111));
      expect(cta.foreground, const Color(0xFFFFFFFF));
    });
  });
}
