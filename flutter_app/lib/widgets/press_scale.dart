import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../services/haptics.dart';
import '../theme/motion.dart';

/// Haptic intensity to fire on press-in. Maps 1:1 to the [Haptics] service.
/// Use `null` (the default) when no haptic is wanted.
///
/// Note: there is no `celebrate` variant. Celebrate haptics are reserved
/// for hero moments triggered manually by screen code (e.g. gift reveal,
/// legend reached) and require a `momentId` for the per-session guard, which
/// the enum cannot carry. PressScale call sites that need a celebrate
/// haptic should fire it separately via `Haptics.celebrate(momentId)`.
enum HapticIntensity { tick, reward, milestone }

/// Wraps any tappable child with spring-driven press feedback and an optional
/// haptic on press-in.
///
/// On press-in: scales `child` to [pressedScale] via the `pressSettle` spring.
/// On press-out: scales back to `1.0` via the same spring.
/// On release inside bounds: fires [onTap].
///
/// When [enabled] is false, the widget renders the child but does not respond
/// to taps and does not animate.
///
/// When `MediaQuery.disableAnimations` is true, the spring is skipped — but
/// the haptic and `onTap` callback still fire (motion is hidden, not feedback).
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final HapticIntensity? haptic;
  final bool enabled;

  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.haptic,
    this.enabled = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(
      vsync: this,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disable) {
      _controller.value = target;
      return;
    }
    final simulation = SpringSimulation(
      AppSprings.pressSettle,
      _controller.value,
      target,
      0,
    );
    _controller.animateWith(simulation);
  }

  void _fireHaptic() {
    switch (widget.haptic) {
      case null:
        return;
      case HapticIntensity.tick:
        Haptics.tick();
      case HapticIntensity.reward:
        Haptics.reward();
      case HapticIntensity.milestone:
        Haptics.milestone();
    }
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    _fireHaptic();
    _animateTo(widget.pressedScale);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    _animateTo(1.0);
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    _animateTo(1.0);
  }

  void _handleTap() {
    if (!widget.enabled) return;
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _controller.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
