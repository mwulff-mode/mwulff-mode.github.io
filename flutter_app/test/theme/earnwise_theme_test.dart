import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earnwise_mvp/theme/app_color_palette.dart';
import 'package:earnwise_mvp/theme/app_radius_scale.dart';
import 'package:earnwise_mvp/theme/app_elevation_profile.dart';
import 'package:earnwise_mvp/theme/app_cta_tokens.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/theme/earnwise_theme.dart';
import 'package:earnwise_mvp/theme/theme_catalog.dart';

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

  group('EarnWiseTheme', () {
    AppColorPalette palette() => const AppColorPalette(
          surface: Color(0xFFFFFFFF),
          surfaceRaised: Color(0xFFFFFFFF),
          surfaceSubtle: Color(0xFFEEEEEE),
          surfaceSelected: Color(0xFFDDDDDD),
          ink: Color(0xFF000000),
          inkSecondary: Color(0xFF444444),
          inkTertiary: Color(0xFF888888),
          brand: Color(0xFF00AAAA),
          brandStrong: Color(0xFF007777),
          brandSubtle: Color(0xFFCCFFFF),
          heroBackground: Color(0xFFFFFFFF),
          heroForeground: Color(0xFF000000),
          hairline: Color(0xFFDDDDDD),
        );

    EarnWiseTheme make() => EarnWiseTheme(
          palette: palette(),
          radii: const AppRadiusScale(
            chip: 8,
            card: 16,
            feature: 20,
            modal: 24,
            button: 16,
          ),
          elevation: const AppElevationProfile(
            none: [],
            card: [],
            raised: [],
            modal: [],
          ),
          cta: const AppCtaTokens(
            background: Color(0xFF00AAAA),
            foreground: Color(0xFFFFFFFF),
          ),
        );

    test('is a ThemeExtension<EarnWiseTheme>', () {
      expect(make(), isA<ThemeExtension<EarnWiseTheme>>());
    });

    test('copyWith swaps only the provided slot', () {
      final base = make();
      final swapped = base.copyWith(
        cta: const AppCtaTokens(
          background: Color(0xFF111111),
          foreground: Color(0xFFFFFFFF),
        ),
      );
      expect(swapped.palette, base.palette);
      expect(swapped.radii, base.radii);
      expect(swapped.elevation, base.elevation);
      expect(swapped.cta.background, const Color(0xFF111111));
    });

    test('lerp is instant (returns `this`) in v1', () {
      final base = make();
      final other = base.copyWith(
        cta: const AppCtaTokens(
          background: Color(0xFF222222),
          foreground: Color(0xFFFFFFFF),
        ),
      );
      // Instant swap is deliberate; animated lerp is deferred.
      expect(identical(base.lerp(other, 0.5), base), isTrue);
    });
  });

  group('kCreamTheme compatibility with static AppColors/AppRadius/AppElevation',
      () {
    test('palette equals the static AppColors semantic fields', () {
      final p = kCreamTheme.palette;
      expect(p.surface, AppColors.surface);
      expect(p.surfaceRaised, AppColors.surfaceRaised);
      expect(p.surfaceSubtle, AppColors.surfaceSubtle);
      expect(p.surfaceSelected, AppColors.surfaceSelected);
      expect(p.ink, AppColors.ink);
      expect(p.inkSecondary, AppColors.inkSecondary);
      expect(p.inkTertiary, AppColors.inkTertiary);
      expect(p.brand, AppColors.brand);
      expect(p.brandStrong, AppColors.brandStrong);
      expect(p.brandSubtle, AppColors.brandSubtle);
    });

    test('radii equal the static AppRadius fields (excluding new `button`)',
        () {
      final r = kCreamTheme.radii;
      expect(r.chip, AppRadius.chip);
      expect(r.card, AppRadius.card);
      expect(r.feature, AppRadius.feature);
      expect(r.modal, AppRadius.modal);
      // `button` is new; it matches the existing card radius for Cream.
      expect(r.button, AppRadius.card);
    });

    test('elevation equals the static AppElevation lists', () {
      final e = kCreamTheme.elevation;
      expect(e.none, AppElevation.none);
      expect(e.card, AppElevation.card);
      expect(e.raised, AppElevation.raised);
      expect(e.modal, AppElevation.modal);
    });

    test('cta uses brand background and white foreground', () {
      expect(kCreamTheme.cta.background, AppColors.brand);
      expect(kCreamTheme.cta.foreground, Colors.white);
    });
  });

  group('non-Cream themes', () {
    test('Plum palette uses violet brand and white surface', () {
      expect(kPlumTheme.palette.brand, const Color(0xFF5F2EE5));
      expect(kPlumTheme.palette.surface, const Color(0xFFFFFFFF));
      expect(kPlumTheme.radii.button, AppRadiusScale.pill);
      expect(kPlumTheme.elevation.card, isEmpty);
    });

    test('Bumble forces brand ≠ CTA (yellow brand, black CTA)', () {
      expect(kBumbleTheme.palette.brand, const Color(0xFFFEDA01));
      expect(kBumbleTheme.cta.background, kBumbleTheme.palette.ink);
      expect(kBumbleTheme.cta.foreground, const Color(0xFFFFFFFF));
      expect(kBumbleTheme.radii.button, AppRadiusScale.pill);
      expect(kBumbleTheme.elevation.card, isEmpty);
    });

    test('Clue uses cool gray surface with deep teal brand', () {
      expect(kClueTheme.palette.surface, const Color(0xFFECECEC));
      expect(kClueTheme.palette.brand, const Color(0xFF0E7889));
      expect(kClueTheme.radii.card, 22);
      expect(kClueTheme.elevation.card, isEmpty);
    });
  });

  group('kEarnWiseThemes catalog', () {
    test('contains four themes in the order Cream, Plum, Bumble, Clue', () {
      expect(kEarnWiseThemes, hasLength(4));
      expect(kEarnWiseThemes[0], kCreamTheme);
      expect(kEarnWiseThemes[1], kPlumTheme);
      expect(kEarnWiseThemes[2], kBumbleTheme);
      expect(kEarnWiseThemes[3], kClueTheme);
    });
  });
}
