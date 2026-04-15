import 'package:flutter/material.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/earnwise_theme.dart';

/// Stat indicator: accent icon on top, pre-formatted value, caption label.
/// Decoupled from any stars / dollars helper, the caller formats
/// `value` as a string, so the widget can serve any future stat
/// (earnings, streak days, tasks completed, etc.).
class StatBubble extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? accentColor;

  const StatBubble({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? context.theme.palette.brand;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: AppSpacing.tight),
        Text(value, style: AppText.statNumber),
        Text(label, style: AppText.caption),
      ],
    );
  }
}
