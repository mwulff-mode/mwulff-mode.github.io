import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/fade_route.dart';
import '../widgets/physical_press.dart';
import '../widgets/press_scale.dart';
import '../widgets/screen_scaffold.dart';
import 'onboarding_screen.dart';

class TrustCarouselScreen extends StatefulWidget {
  const TrustCarouselScreen({super.key});

  @override
  State<TrustCarouselScreen> createState() => _TrustCarouselScreenState();
}

class _TrustCarouselScreenState extends State<TrustCarouselScreen>
    with TickerProviderStateMixin {
  int _currentSlide = 0;
  Timer? _autoTimer;
  late AnimationController _progressController;

  final _slides = [
    _SlideData(
      assetPath: 'assets/icons/graphics/play.png',
      title: 'Play, Earn, Cash Out!',
    ),
    _SlideData(
      assetPath: 'assets/icons/graphics/fast.png',
      title: 'Same-day cash to PayPal',
    ),
    _SlideData(
      assetPath: 'assets/icons/graphics/trusted.png',
      title: 'No tricks, just real money',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _startCarousel();
  }

  void _startCarousel() {
    _progressController.forward(from: 0);
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      _advanceSlide();
    });
  }

  void _advanceSlide() {
    setState(() {
      _currentSlide = (_currentSlide + 1) % _slides.length;
    });
    _progressController.forward(from: 0);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _navigate() {
    _autoTimer?.cancel();
    Navigator.of(context).push(fadeRoute(const OnboardingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      animatedGradient: true,
      child: Column(
        children: [
          const SizedBox(height: 56),

          // Progress ring pill
          _buildProgressPill(),
          const SizedBox(height: AppSpacing.md),

          // Carousel area
          Expanded(
            child: PressScale(
              onTap: _advanceSlide,
              haptic: null,
              pressedScale: 0.99, // large surface: subtler shrink
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: _buildSlide(_slides[_currentSlide]),
                ),
              ),
            ),
          ),

          // Trust quote
          _buildTrustQuote(),
          const SizedBox(height: AppSpacing.md),

          // CTA
          PhysicalPress(
            onTap: _navigate,
            backgroundColor: AppColors.primary,
            shadowColor: AppColors.primaryDark,
            depth: 6,
            haptic: HapticIntensity.confirm,
            child: Text("Let's get started", style: AppText.ctaLabel),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildProgressPill() {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(64, 64),
                painter: _RingPainter(
                  progress: _progressController.value,
                  bgColor: AppColors.creamDeep,
                  fgColor: AppColors.primary,
                ),
              );
            },
          ),
          Text(
            '${_currentSlide + 1}/3',
            style: AppText.bodyStrong.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_SlideData slide) {
    return Column(
      key: ValueKey(slide.title),
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          slide.assetPath,
          width: 280,
          height: 280,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: AppText.slideTitle,
        ),
      ],
    );
  }

  Widget _buildTrustQuote() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars
          Row(
            children: List.generate(
                5,
                (_) => Icon(
                      PhosphorIcons.star(PhosphorIconsStyle.fill),
                      size: 14,
                      color: AppColors.gold,
                    )),
          ),
          const SizedBox(height: 10),
          Text(
            '\$47 last month just from my couch. I play Candy Crush, now I earn while I do it.',
            style: AppText.bodyStrong.copyWith(
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.inkSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Diane, Ohio · cashed out 3 times',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String assetPath;
  final String title;
  const _SlideData({required this.assetPath, required this.title});
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;

  _RingPainter(
      {required this.progress, required this.bgColor, required this.fgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final fgPaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
