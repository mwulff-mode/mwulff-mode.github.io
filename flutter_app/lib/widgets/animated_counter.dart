import 'package:flutter/material.dart';
import '../theme/motion.dart';

/// Animates a numeric value from its previous state to a new one whenever
/// [value] changes. The format function maps the interpolated integer to
/// a display string so the counter works for both Stars and dollar amounts.
///
/// On first build the counter snaps to [value] with no animation so there
/// is no distracting count-up on screen entry.
class AnimatedCounter extends StatefulWidget {
  final int value;
  final String Function(int) format;
  final TextStyle style;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.format,
    required this.style,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  int _from = 0;
  int _to = 0;

  @override
  void initState() {
    super.initState();
    _to = widget.value;
    _from = widget.value; // snap on first build
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.hero,
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: AppCurves.warmOut,
    );
    // Start at 1.0 so the first render shows the final value immediately.
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      // Capture where the counter visually is right now as the new start point.
      _from = (_from + (_to - _from) * _curved.value).round();
      _to = widget.value;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) {
        final display = (_from + (_to - _from) * _curved.value).round();
        return Text(widget.format(display), style: widget.style);
      },
    );
  }
}
