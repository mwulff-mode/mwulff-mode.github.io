import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Standard screen-to-screen route used across the app.
///
/// Wraps `CupertinoPageRoute` so every push gets the iOS-native slide-from-
/// right transition with parallax on the outgoing screen and the swipe-back-
/// to-pop gesture for free.
///
/// The function is still named `fadeRoute` for legacy reasons: the original
/// prototype used a fade-through helper here. The name is now a misnomer;
/// rename in a follow-up if it becomes confusing. Call sites are unchanged.
Route<T> fadeRoute<T>(Widget page) {
  return CupertinoPageRoute<T>(builder: (_) => page);
}

/// Slide-up route for modal-style screens (game detail, etc.).
Route<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final slide = Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));
      return SlideTransition(position: slide, child: child);
    },
  );
}
