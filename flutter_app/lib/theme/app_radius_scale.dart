import 'package:flutter/foundation.dart';

/// Radius knob for a theme. The `button` field is new in this sub-project
/// — static `AppRadius` does not define one. Pill (9999) is a constant
/// and lives on the class, not on instances, because every theme's
/// full-pill elements are full-pill.
@immutable
class AppRadiusScale {
  final double chip;
  final double card;
  final double feature;
  final double modal;
  final double button;

  const AppRadiusScale({
    required this.chip,
    required this.card,
    required this.feature,
    required this.modal,
    required this.button,
  });

  /// 9999 — theme-invariant full-pill radius.
  static const double pill = 9999;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppRadiusScale &&
          other.chip == chip &&
          other.card == card &&
          other.feature == feature &&
          other.modal == modal &&
          other.button == button);

  @override
  int get hashCode => Object.hash(chip, card, feature, modal, button);
}
