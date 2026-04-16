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

/// Plum — bold violet brand on white surface, flat cards with hairline
/// borders, full-pill buttons.
const EarnWiseTheme kPlumTheme = EarnWiseTheme(
  palette: AppColorPalette(
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF4F2F7),
    surfaceSelected: Color(0xFFEFE9FE),
    ink: Color(0xFF0F1B2B),
    inkSecondary: Color(0xFF5B6470),
    inkTertiary: Color(0xFF8B92A0),
    brand: Color(0xFF5F2EE5),
    brandStrong: Color(0xFF4A1FB8),
    brandSubtle: Color(0xFFEFE9FE),
    heroBackground: Color(0xFF5F2EE5),
    heroForeground: Color(0xFFFFFFFF),
    hairline: Color(0xFFECE9F2),
  ),
  radii: AppRadiusScale(
    chip: 8,
    card: 14,
    feature: 16,
    modal: 22,
    button: AppRadiusScale.pill,
  ),
  elevation: AppElevationProfile(
    none: [],
    card: [],
    raised: [],
    modal: [],
  ),
  cta: AppCtaTokens(
    background: Color(0xFF5F2EE5),
    foreground: Color(0xFFFFFFFF),
  ),
);

/// Bumble — honey yellow brand, BLACK CTA background. This theme is the
/// reason `AppCtaTokens` is a separate object: yellow on white has no
/// contrast for a primary button, so `cta.background == ink`, not
/// `cta.background == brand`. Future contributors, please leave this
/// asymmetry in place.
const EarnWiseTheme kBumbleTheme = EarnWiseTheme(
  palette: AppColorPalette(
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF7F7F7),
    surfaceSubtle: Color(0xFFF2F2F2),
    surfaceSelected: Color(0xFFFFF6C2),
    ink: Color(0xFF1A1A1A),
    inkSecondary: Color(0xFF5C5C5C),
    inkTertiary: Color(0xFF909090),
    brand: Color(0xFFFEDA01),
    brandStrong: Color(0xFFE5C300),
    brandSubtle: Color(0xFFFFF6C2),
    heroBackground: Color(0xFFFEDA01),
    heroForeground: Color(0xFF1A1A1A),
    hairline: Color(0xFFEAEAEA),
  ),
  radii: AppRadiusScale(
    chip: 12,
    card: 18,
    feature: 20,
    modal: 24,
    button: AppRadiusScale.pill,
  ),
  elevation: AppElevationProfile(
    none: [],
    card: [],
    raised: [],
    modal: [],
  ),
  // INTENTIONAL: cta.background == palette.ink (not brand) so the CTA
  // reads as black-on-white. Yellow-on-white would be invisible.
  cta: AppCtaTokens(
    background: Color(0xFF1A1A1A),
    foreground: Color(0xFFFFFFFF),
  ),
);

/// Clue — cool gray surface with deep teal brand. Largest card radius of
/// the four themes (22); full-pill buttons.
const EarnWiseTheme kClueTheme = EarnWiseTheme(
  palette: AppColorPalette(
    surface: Color(0xFFECECEC),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFE0E0E0),
    surfaceSelected: Color(0xFFD6EFFC),
    ink: Color(0xFF0E1B2A),
    inkSecondary: Color(0xFF5B6470),
    inkTertiary: Color(0xFF8B92A0),
    brand: Color(0xFF0E7889),
    brandStrong: Color(0xFF075560),
    brandSubtle: Color(0xFFD6EFFC),
    heroBackground: Color(0xFFFFFFFF),
    heroForeground: Color(0xFF0E1B2A),
    hairline: Color(0xFFDDDDDD),
  ),
  radii: AppRadiusScale(
    chip: 12,
    card: 22,
    feature: 24,
    modal: 28,
    button: AppRadiusScale.pill,
  ),
  elevation: AppElevationProfile(
    none: [],
    card: [],
    raised: [],
    modal: [],
  ),
  cta: AppCtaTokens(
    background: Color(0xFF0E7889),
    foreground: Color(0xFFFFFFFF),
  ),
);

/// Catalog list in the order the Settings picker displays:
/// Cream (default) first, then the three in conversation order.
final List<EarnWiseTheme> kEarnWiseThemes = [
  kCreamTheme,
  kPlumTheme,
  kBumbleTheme,
  kClueTheme,
];
