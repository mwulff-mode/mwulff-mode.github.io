import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Elevation knob for a theme. Each list is assignable directly to
/// `BoxDecoration.boxShadow`. Flat themes (Plum/Bumble/Clue) set every
/// layer except `none` to `const []` and lean on `AppColorPalette.hairline`
/// for visual card separation.
@immutable
class AppElevationProfile {
  final List<BoxShadow> none;
  final List<BoxShadow> card;
  final List<BoxShadow> raised;
  final List<BoxShadow> modal;

  const AppElevationProfile({
    required this.none,
    required this.card,
    required this.raised,
    required this.modal,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppElevationProfile &&
          listEquals(other.none, none) &&
          listEquals(other.card, card) &&
          listEquals(other.raised, raised) &&
          listEquals(other.modal, modal));

  @override
  int get hashCode => Object.hash(
        Object.hashAll(none),
        Object.hashAll(card),
        Object.hashAll(raised),
        Object.hashAll(modal),
      );
}
