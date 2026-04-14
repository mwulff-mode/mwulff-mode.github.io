import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A colored rounded square with a category icon inside. Used as the
/// `leading` of [ListRow] (48x48) and [VerticalTile] (typically 44x44).
/// Small primitive, two consumers, one source of truth.
class CategoryIconSquare extends StatelessWidget {
  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;
  final double iconSize;
  final double radius;

  const CategoryIconSquare({
    super.key,
    required this.icon,
    required this.foreground,
    required this.background,
    this.size = 48,
    this.iconSize = 24,
    this.radius = AppRadius.chip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}
