import 'package:flutter/material.dart';
import 'app_color_palette.dart';
import 'app_cta_tokens.dart';
import 'app_elevation_profile.dart';
import 'app_radius_scale.dart';

/// Single `ThemeExtension` that wraps the four "knobs" EarnWise themes vary
/// across: color palette, radius scale, elevation profile, CTA colors.
///
/// Registered on `ThemeData.extensions` so any widget can read it via
/// `Theme.of(context).extension<EarnWiseTheme>()!` — or, more ergonomically,
/// via the `context.theme` extension below.
///
/// `lerp` returns `this` in v1: theme swaps are instant. Animated
/// interpolation can be added later by tweening each field inside `lerp`
/// without touching any consumer.
@immutable
class EarnWiseTheme extends ThemeExtension<EarnWiseTheme> {
  final AppColorPalette palette;
  final AppRadiusScale radii;
  final AppElevationProfile elevation;
  final AppCtaTokens cta;

  const EarnWiseTheme({
    required this.palette,
    required this.radii,
    required this.elevation,
    required this.cta,
  });

  @override
  EarnWiseTheme copyWith({
    AppColorPalette? palette,
    AppRadiusScale? radii,
    AppElevationProfile? elevation,
    AppCtaTokens? cta,
  }) =>
      EarnWiseTheme(
        palette: palette ?? this.palette,
        radii: radii ?? this.radii,
        elevation: elevation ?? this.elevation,
        cta: cta ?? this.cta,
      );

  @override
  EarnWiseTheme lerp(covariant ThemeExtension<EarnWiseTheme>? other, double t) =>
      this;
}

/// Ergonomic `Theme.of(context).extension<EarnWiseTheme>()!` shortcut.
///
/// Use `context.theme.palette.ink` instead of
/// `Theme.of(context).extension<EarnWiseTheme>()!.palette.ink`.
///
/// The bang is intentional: if a test wraps a widget in a `MaterialApp`
/// without `AppTheme.buildMaterialTheme(...)`, failure should be loud and
/// immediate so the test harness is fixed, not papered over.
extension EarnWiseThemeContext on BuildContext {
  EarnWiseTheme get theme => Theme.of(this).extension<EarnWiseTheme>()!;
}
