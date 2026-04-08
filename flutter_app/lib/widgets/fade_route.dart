import 'package:flutter/material.dart';
import '../theme/motion.dart';

/// Standard fade-through route used across the app.
///
/// Every screen-to-screen transition should go through this helper so the
/// timing curve is identical everywhere. Default duration is
/// `AppDurations.long`.
PageRouteBuilder<T> fadeRoute<T>(
  Widget page, {
  Duration? duration,
}) {
  final d = duration ?? AppDurations.long;
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: d,
    reverseTransitionDuration: d,
  );
}
