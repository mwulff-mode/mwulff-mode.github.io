import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Controller for [RewardGlow]. Call [play] to trigger the celebration
/// flourish. Safe to call multiple times: re-plays the animation from the
/// start.
class RewardGlowController extends ChangeNotifier {
  int _playCount = 0;
  int get playCount => _playCount;

  void play() {
    _playCount++;
    notifyListeners();
  }

  /// Test-only: reset the play counter without notifying listeners.
  void debugReset() {
    _playCount = 0;
  }
}

/// A celebration pulse for multi-stage reward moments. Wraps a [child] and,
/// when the [controller] fires `play()`, plays a three-beat flourish:
///
/// 1. 0–300ms: child scales 1.0 → 1.06 (`AppCurves.pop`)
/// 2. 100–700ms: radial glow behind child fades 0 → 0.5 → 0 alpha,
///    expanding from 160px to 280px (a 200px base, scaled 0.8× → 1.4×)
/// 3. 300–900ms: child scales 1.06 → 1.0 (`AppCurves.warmOut`)
///
/// Total duration: `AppDurations.hero` (900ms).
///
/// The glow is rendered behind the child via `Stack` with `clipBehavior:
/// Clip.none`, so it does not affect layout and may visually overflow the
/// parent. Intentional for the radiance effect.
class RewardGlow extends StatefulWidget {
  final Widget child;
  final RewardGlowController controller;
  final Color glowColor;

  const RewardGlow({
    super.key,
    required this.child,
    required this.controller,
    this.glowColor = AppColors.accent,
  });

  @override
  State<RewardGlow> createState() => _RewardGlowState();
}

class _RewardGlowState extends State<RewardGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _lastPlayCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.hero,
    );
    widget.controller.addListener(_onPlay);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlay);
    _controller.dispose();
    super.dispose();
  }

  void _onPlay() {
    if (widget.controller.playCount == _lastPlayCount) return;
    _lastPlayCount = widget.controller.playCount;
    final disable = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disable) return;
    _controller.forward(from: 0);
  }

  // 0–300ms: 1.0 → 1.06 with pop
  // 300–900ms: 1.06 → 1.0 with warmOut
  double _scaleAt(double t) {
    if (t < 0.333) {
      final localT = AppCurves.pop.transform(t / 0.333);
      return 1.0 + 0.06 * localT;
    }
    final localT = AppCurves.warmOut.transform((t - 0.333) / 0.667);
    return 1.06 - 0.06 * localT;
  }

  // 100–700ms: alpha 0 → 0.5 → 0
  double _glowAlphaAt(double t) {
    if (t < 0.111 || t > 0.778) return 0;
    final localT = (t - 0.111) / 0.667;
    final triangle =
        localT < 0.5 ? localT * 2 : (1 - localT) * 2;
    return 0.5 * triangle;
  }

  // 100–700ms: scale 0.8 → 1.4
  double _glowScaleAt(double t) {
    if (t < 0.111 || t > 0.778) return 0.8;
    final localT = (t - 0.111) / 0.667;
    return 0.8 + 0.6 * localT;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Glow layer (behind)
            IgnorePointer(
              child: Opacity(
                opacity: _glowAlphaAt(t),
                child: Transform.scale(
                  scale: _glowScaleAt(t),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.glowColor.withValues(alpha: 0.6),
                          widget.glowColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 200,
                      minHeight: 200,
                    ),
                  ),
                ),
              ),
            ),
            // Child layer (front)
            Transform.scale(
              scale: _scaleAt(t),
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
