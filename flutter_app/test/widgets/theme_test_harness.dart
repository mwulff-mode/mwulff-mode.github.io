import 'package:flutter/material.dart';
import 'package:earnwise_mvp/theme/app_theme.dart';
import 'package:earnwise_mvp/theme/earnwise_theme.dart';

/// Wraps [child] in a minimal `MaterialApp` built with
/// `AppTheme.buildMaterialTheme(theme)` so widget tests can assert how a
/// widget reads from a specific `EarnWiseTheme`.
Widget wrapWithTheme(EarnWiseTheme theme, Widget child) {
  return MaterialApp(
    theme: AppTheme.buildMaterialTheme(theme),
    home: Scaffold(body: Center(child: child)),
  );
}
