import 'dart:math';
import 'package:flutter/material.dart';

class ProgressRing extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  ProgressRing({
    required this.percentage,
    required this.trackColor,
    required this.fillColor,
    this.strokeWidth = 18,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * (percentage / 100).clamp(0, 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRing oldDelegate) =>
      oldDelegate.percentage != percentage;
}
