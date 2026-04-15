import 'package:flutter/material.dart';
import 'app_color_palette.dart';
import 'app_cta_tokens.dart';
import 'app_elevation_profile.dart';
import 'app_radius_scale.dart';
import 'app_theme.dart';
import 'earnwise_theme.dart';

/// The four named EarnWise themes plus the `kEarnWiseThemes` catalog list.
/// See `docs/superpowers/specs/2026-04-15-app-theming-design.md` §2.

/// Cream — the existing EarnWise identity. Every palette/radii/elevation
/// field equals its static `AppColors`/`AppRadius`/`AppElevation`
/// counterpart so unmigrated screens stay pixel-correct when Cream is
/// active. Enforced by a unit test in `earnwise_theme_test.dart`.
final EarnWiseTheme kCreamTheme = EarnWiseTheme(
  palette: const AppColorPalette(
    surface: Color(0xFFFAF8F5),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF2EDE6),
    surfaceSelected: Color(0xFFF0FDFA),
    ink: Color(0xFF3B3230),
    inkSecondary: Color(0xFF6B5E58),
    inkTertiary: Color(0xFF8A7D76),
    brand: Color(0xFF0D9488),
    brandStrong: Color(0xFF0F766E),
    brandSubtle: Color(0xFFF0FDFA),
    heroBackground: Color(0xFFFFFFFF),
    heroForeground: Color(0xFF3B3230),
    // Unused in Cream — cards are shadow-elevated — but populated for
    // forward-compat with the `AppColorPalette` contract.
    hairline: Color(0xFFF2EDE6),
  ),
  radii: const AppRadiusScale(
    chip: 8,
    card: 16,
    feature: 20,
    modal: 24,
    button: 16,
  ),
  elevation: AppElevationProfile(
    none: AppElevation.none,
    card: AppElevation.card,
    raised: AppElevation.raised,
    modal: AppElevation.modal,
  ),
  cta: const AppCtaTokens(
    background: Color(0xFF0D9488),
    foreground: Colors.white,
  ),
);
