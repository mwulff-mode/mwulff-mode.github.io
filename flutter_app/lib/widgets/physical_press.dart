import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../services/haptics.dart';
import '../theme/motion.dart';
import 'press_scale.dart' show HapticIntensity;

/// A physical-button press effect. The child sits on top of a solid offset
/// shadow, and on press translates down into the shadow so the button looks
/// like it sinks into the page. Mirrors the "pushable card" idiom from Cash
/// App, Pinterest, and Duolingo.
///
/// At rest the bottom [depth] pixels of the shadow are visible below the
/// button face. On press-in the button face translates down by [depth],
/// fully covering the shadow; on release the button springs back up using
/// the `pressSettle` spring from `AppSprings`.
///
/// Unlike [PressScale] this is a fully-rendered button: the child is just
/// its content (Row, Text, Icon). [PhysicalPress] draws the background fill,
/// shadow, and pill shape itself.
class PhysicalPress extends StatefulWidget {
  /// Button content (typically a Row with Icon + Text). Centered inside the
  /// button face.
  final Widget child;

  /// Tap callback. Fires on release inside bounds.
  final VoidCallback? onTap;

  /// Fill color of the button face.
  final Color backgroundColor;

  /// Fill color of the offset shadow below the button. Typically a darker
  /// shade of [backgroundColor] (e.g. `AppColors.primaryDark` for a teal
  /// button).
  final Color shadowColor;

  /// Vertical pixels of shadow visible below the button face at rest.
  /// 6-8px is the sweet spot for feeling tactile without being cartoonish.
  final double depth;

  /// Total button face height. The pill radius is half this.
  final double height;

  /// Haptic to fire on press-in.
  final HapticIntensity? haptic;

  /// When false, taps do nothing and no animation plays.
  final bool enabled;

  const PhysicalPress({
    super.key,
    required this.child,
    required this.onTap,
    required this.backgroundColor,
    required this.shadowColor,
    this.depth = 6,
    this.height = 68,
    this.haptic,
    this.enabled = true,
  });

  @override
  State<PhysicalPress> createState() => _PhysicalPressState();
}

class _PhysicalPressState extends State<PhysicalPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this, value: 0);
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
      case HapticIntensity.confirm:
        Haptics.confirm();
      case HapticIntensity.reward:
        Haptics.reward();
      case HapticIntensity.milestone:
        Haptics.milestone();
      case HapticIntensity.warning:
        Haptics.warning();
    }
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    _fireHaptic();
    _animateTo(1.0);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    _animateTo(0);
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    _animateTo(0);
  }

  void _handleTap() {
    if (!widget.enabled) return;
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.height / 2);
    return AnimatedOpacity(
      opacity: widget.enabled ? 1.0 : 0.45,
      duration: AppDurations.short,
      child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value.clamp(0.0, 1.0);
          final translateY = widget.depth * t;
          return SizedBox(
            width: double.infinity,
            height: widget.height + widget.depth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: widget.height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.shadowColor,
                      borderRadius: radius,
                    ),
                  ),
                ),
                Positioned(
                  top: translateY,
                  left: 0,
                  right: 0,
                  height: widget.height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: radius,
                    ),
                    child: Center(child: child),
                  ),
                ),
              ],
            ),
          );
        },
        child: widget.child,
      ),
    ),   // GestureDetector
    );   // AnimatedOpacity
  }
}
