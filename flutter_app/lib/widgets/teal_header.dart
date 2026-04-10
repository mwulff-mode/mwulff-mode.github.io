import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Teal header band with a gentle downward arc at the bottom edge.
/// Wraps arbitrary content (greeting row, ring, balance, avatar, etc.).
class TealHeader extends StatelessWidget {
  final Widget child;
  final double arcHeight;

  const TealHeader({
    super.key,
    required this.child,
    this.arcHeight = 25,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ArcClipper(arcHeight: arcHeight),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.primary,
        ),
        foregroundDecoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.6, -0.8),
            radius: 1.2,
            colors: [
              Colors.white.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _ArcClipper extends CustomClipper<Path> {
  final double arcHeight;

  _ArcClipper({required this.arcHeight});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - arcHeight);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + arcHeight,
      size.width,
      size.height - arcHeight,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_ArcClipper oldClipper) =>
      oldClipper.arcHeight != arcHeight;
}
