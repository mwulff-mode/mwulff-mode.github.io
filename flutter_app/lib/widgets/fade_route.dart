import 'package:flutter/material.dart';

/// Standard fade-through route used across the app.
///
/// Every screen-to-screen transition should go through this helper so the
/// timing curve is identical everywhere.
PageRouteBuilder<T> fadeRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 400),
}) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: duration,
    reverseTransitionDuration: duration,
  );
}
