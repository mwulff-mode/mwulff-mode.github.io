import 'package:flutter/cupertino.dart';

/// Standard screen-to-screen route used across the app.
///
/// Wraps `CupertinoPageRoute` so every push gets the iOS-native slide-from-
/// right transition with parallax on the outgoing screen and the swipe-back-
/// to-pop gesture for free.
///
/// The function is still named `fadeRoute` for legacy reasons — the original
/// prototype used a fade-through helper here. The name is now a misnomer;
/// rename in a follow-up if it becomes confusing. Call sites are unchanged.
Route<T> fadeRoute<T>(Widget page) {
  return CupertinoPageRoute<T>(builder: (_) => page);
}
