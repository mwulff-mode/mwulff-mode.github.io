import 'package:flutter/material.dart';

/// Primary-button color pair. Deliberately a separate object (not part of
/// `AppColorPalette`) because Bumble forces `background = ink` instead of
/// `background = brand` — yellow on white has no contrast for a CTA.
/// `PrimaryButton` reads `radii.button` for its radius directly, so the
/// button-shape knob lives in one place only.
@immutable
class AppCtaTokens {
  final Color background;
  final Color foreground;

  const AppCtaTokens({
    required this.background,
    required this.foreground,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppCtaTokens &&
          other.background == background &&
          other.foreground == foreground);

  @override
  int get hashCode => Object.hash(background, foreground);
}
