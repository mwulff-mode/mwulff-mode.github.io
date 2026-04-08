import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';

void main() {
  runApp(const RingPlaygroundApp());
}

class RingPlaygroundApp extends StatelessWidget {
  const RingPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const RingPlayground(),
    );
  }
}

class Tier {
  final int level;
  final String name;
  final int goalStars;
  final Color ringColor;
  final Color trackColor;
  final String unlockLabel;
  final IconData icon;

  const Tier({
    required this.level,
    required this.name,
    required this.goalStars,
    required this.ringColor,
    required this.trackColor,
    required this.unlockLabel,
    required this.icon,
  });
}

const tiers = [
  Tier(
      level: 1,
      name: 'Starter',
      goalStars: 1500,
      ringColor: Color(0xFF0D9488),
      trackColor: Color(0xFFE2E8F0),
      unlockLabel: '',
      icon: IconData(0)),
  Tier(
      level: 2,
      name: 'Explorer',
      goalStars: 5000,
      ringColor: Color(0xFF0D9488),
      trackColor: Color(0xFFE2E8F0),
      unlockLabel: '',
      icon: IconData(0)),
  Tier(
      level: 3,
      name: 'Achiever',
      goalStars: 10000,
      ringColor: Color(0xFF6366F1),
      trackColor: Color(0xFFE8E5FF),
      unlockLabel: '',
      icon: IconData(0)),
  Tier(
      level: 4,
      name: 'Expert',
      goalStars: 25000,
      ringColor: Color(0xFF6366F1),
      trackColor: Color(0xFFE8E5FF),
      unlockLabel: '',
      icon: IconData(0)),
  Tier(
      level: 5,
      name: 'Master',
      goalStars: 50000,
      ringColor: Color(0xFFF59E0B),
      trackColor: Color(0xFFFEF3C7),
      unlockLabel: '',
      icon: IconData(0)),
  Tier(
      level: 6,
      name: 'Legend',
      goalStars: 100000,
      ringColor: Color(0xFFF59E0B),
      trackColor: Color(0xFFFEF3C7),
      unlockLabel: '',
      icon: IconData(0)),
];

class RingPlayground extends StatefulWidget {
  const RingPlayground({super.key});

  @override
  State<RingPlayground> createState() => _RingPlaygroundState();
}

class _RingPlaygroundState extends State<RingPlayground>
    with TickerProviderStateMixin {
  int _stars = 125;
  int _tierIndex = 0;

  // Animation phases: normal → filling → complete → transition → normal (next tier)
  // "complete" means ring is full and center is solid
  bool _isComplete = false;
  bool _isTransitioning = false;
  bool _isLegend = false; // final golden state
  double _displayProgress = 0; // 0-100, animated smoothly

  late AnimationController _fillController; // animates ring fill + solid center
  late AnimationController _centerFadeController; // fades center content in/out

  Tier get _currentTier => tiers[_tierIndex];
  int get _tierStartStars =>
      _tierIndex == 0 ? 0 : tiers[_tierIndex - 1].goalStars;
  double get _rawProgress =>
      ((_stars - _tierStartStars) / (_currentTier.goalStars - _tierStartStars))
          .clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _fillController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _centerFadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300), value: 1.0);
    _displayProgress = _rawProgress * 100;
  }

  @override
  void dispose() {
    _fillController.dispose();
    _centerFadeController.dispose();
    super.dispose();
  }

  void _addStars(int amount) {
    if (_isLegend || _isComplete || _isTransitioning) return;
    _stars += amount;
    final newProgress = _rawProgress;

    if (newProgress >= 1.0 && !_isComplete) {
      _animateToComplete();
    } else {
      setState(() {
        _displayProgress = newProgress * 100;
      });
    }
  }

  bool get _isLastTier => _tierIndex >= tiers.length - 1;

  Future<void> _animateToComplete() async {
    // Phase 1: Animate ring to 100%
    final startProgress = _displayProgress;
    _fillController.reset();
    _fillController.addListener(() {
      setState(() {
        _displayProgress = startProgress +
            (100 - startProgress) *
                Curves.easeOutCubic.transform(_fillController.value);
      });
    });
    _fillController.duration = const Duration(milliseconds: 800);
    await _fillController.forward();

    // Phase 2: Fade out center text, show completion
    await _centerFadeController.animateTo(0,
        duration: const Duration(milliseconds: 200));
    setState(() => _isComplete = true);
    await _centerFadeController.animateTo(1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic);

    // If this is the last goal, stay in the golden legend state forever
    if (_isLastTier) {
      await Future.delayed(const Duration(milliseconds: 2000));
      await _centerFadeController.animateTo(0,
          duration: const Duration(milliseconds: 300));
      setState(() {
        _isComplete = false;
        _isLegend = true;
      });
      await _centerFadeController.animateTo(1,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic);
      _fillController.removeListener(() {});
      return;
    }

    // Phase 3: Hold for a moment
    await Future.delayed(const Duration(milliseconds: 1800));

    // Phase 4: Transition to next tier
    setState(() => _isTransitioning = true);
    await _centerFadeController.animateTo(0,
        duration: const Duration(milliseconds: 300));

    setState(() {
      _tierIndex++;
      _isComplete = false;
      _isTransitioning = false;
      _displayProgress = _rawProgress * 100;
    });
    await _centerFadeController.animateTo(1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic);

    _fillController.removeListener(() {});
  }

  void _reset() {
    _fillController.stop();
    setState(() {
      _stars = 125;
      _tierIndex = 0;
      _isComplete = false;
      _isTransitioning = false;
      _isLegend = false;
      _displayProgress = (125 / 1500) * 100;
      _centerFadeController.value = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The Ring
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ring painter
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: (_isComplete || _isLegend)
                            ? [
                                BoxShadow(
                                  color: (_isLegend
                                          ? const Color(0xFFF59E0B)
                                          : _currentTier.ringColor)
                                      .withValues(alpha: _isLegend ? 0.4 : 0.3),
                                  blurRadius: _isLegend ? 40 : 30,
                                  spreadRadius: _isLegend ? 8 : 4,
                                )
                              ]
                            : [],
                      ),
                      child: CustomPaint(
                        size: const Size(170, 170),
                        painter: _TierRingPainter(
                          percentage: _isLegend ? 100 : _displayProgress,
                          trackColor: _isLegend
                              ? const Color(0xFFFEF3C7)
                              : _currentTier.trackColor,
                          fillColor: _isLegend
                              ? const Color(0xFFF59E0B)
                              : _currentTier.ringColor,
                          solidFill: _isComplete || _isLegend,
                        ),
                      ),
                    ),

                    // Center content
                    FadeTransition(
                      opacity: _centerFadeController,
                      child: _isLegend
                          ? _buildLegendCenter()
                          : _isComplete
                              ? _buildCompleteCenter()
                              : _buildNormalCenter(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Controls
              Text('Add Stars to test',
                  style: GoogleFonts.outfit(
                      fontSize: 14, color: const Color(0xFF8A7D76))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _controlBtn('+250', 250),
                  const SizedBox(width: AppSpacing.sm),
                  _controlBtn('+500', 500),
                  const SizedBox(width: AppSpacing.sm),
                  _controlBtn('+1000', 1000),
                  const SizedBox(width: AppSpacing.sm),
                  _controlBtn('Fill',
                      (_currentTier.goalStars - _stars + 1).clamp(1, 99999)),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _reset,
                child: Text('Reset',
                    style: GoogleFonts.outfit(
                        fontSize: 14, color: const Color(0xFF8A7D76))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalCenter() {
    return Column(
      key: ValueKey('normal-$_tierIndex'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_displayProgress.round()}%',
          style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF3B3230),
              letterSpacing: -1),
        ),
        const SizedBox(height: 2),
        Text(
          '${_formatNumber(_stars)} / ${_formatNumber(_currentTier.goalStars)}',
          style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8A7D76)),
        ),
      ],
    );
  }

  Widget _buildCompleteCenter() {
    return Column(
      key: const ValueKey('complete'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
            size: 32, color: Colors.white),
        const SizedBox(height: 6),
        Text(
          'Goal ${_tierIndex + 1}',
          style: GoogleFonts.outfit(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        Text(
          'Complete!',
          style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85)),
        ),
      ],
    );
  }

  Widget _buildLegendCenter() {
    return Column(
      key: const ValueKey('legend'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(PhosphorIcons.crown(PhosphorIconsStyle.fill),
            size: 28, color: Colors.white),
        const SizedBox(height: 6),
        Text(
          "You've earned",
          style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85)),
        ),
        Text(
          'it all.',
          style: GoogleFonts.outfit(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ],
    );
  }

  Widget _controlBtn(String label, int amount) {
    return ElevatedButton(
      onPressed: (_isComplete || _isTransitioning || _isLegend)
          ? null
          : () => _addStars(amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: _currentTier.ringColor,
        disabledBackgroundColor: _currentTier.ringColor.withValues(alpha: 0.4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final remainder = n % 1000;
      if (remainder == 0) return '$thousands,000';
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return '$n';
  }
}

class _TierRingPainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color fillColor;
  final bool solidFill;

  _TierRingPainter({
    required this.percentage,
    required this.trackColor,
    required this.fillColor,
    required this.solidFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 28) / 2;
    final pct = (percentage / 100).clamp(0.0, 1.0);

    // Inner fill — grows with progress, solid when complete
    final fillOpacity = solidFill ? 1.0 : (pct * 0.08);
    final innerRadius = solidFill ? radius + 11 : radius - 12;
    final centerFill = Paint()
      ..color = fillColor.withValues(alpha: fillOpacity);
    canvas.drawCircle(center, innerRadius, centerFill);

    if (!solidFill) {
      // Track
      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radius, trackPaint);

      // Progress arc
      final arcPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * pct;
      if (sweepAngle > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          sweepAngle,
          false,
          arcPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TierRingPainter old) =>
      old.percentage != percentage ||
      old.solidFill != solidFill ||
      old.fillColor != fillColor;
}
