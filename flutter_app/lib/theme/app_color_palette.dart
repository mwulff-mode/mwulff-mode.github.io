import 'package:flutter/material.dart';

/// Every color that varies between EarnWise themes. Category tints,
/// feedback colors (success/flame/gold), and the destructive Sign Out red
/// are deliberately NOT in this palette — they stay static in `AppColors`.
///
/// See `docs/superpowers/specs/2026-04-15-app-theming-design.md` §1.1.
@immutable
class AppColorPalette {
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSubtle;
  final Color surfaceSelected;
  final Color ink;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color brand;
  final Color brandStrong;
  final Color brandSubtle;
  final Color heroBackground;
  final Color heroForeground;
  final Color hairline;

  const AppColorPalette({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSubtle,
    required this.surfaceSelected,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.brand,
    required this.brandStrong,
    required this.brandSubtle,
    required this.heroBackground,
    required this.heroForeground,
    required this.hairline,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppColorPalette &&
          other.surface == surface &&
          other.surfaceRaised == surfaceRaised &&
          other.surfaceSubtle == surfaceSubtle &&
          other.surfaceSelected == surfaceSelected &&
          other.ink == ink &&
          other.inkSecondary == inkSecondary &&
          other.inkTertiary == inkTertiary &&
          other.brand == brand &&
          other.brandStrong == brandStrong &&
          other.brandSubtle == brandSubtle &&
          other.heroBackground == heroBackground &&
          other.heroForeground == heroForeground &&
          other.hairline == hairline);

  @override
  int get hashCode => Object.hash(
        surface,
        surfaceRaised,
        surfaceSubtle,
        surfaceSelected,
        ink,
        inkSecondary,
        inkTertiary,
        brand,
        brandStrong,
        brandSubtle,
        heroBackground,
        heroForeground,
        hairline,
      );
}
