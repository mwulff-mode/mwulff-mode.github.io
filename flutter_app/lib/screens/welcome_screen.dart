import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/breathing.dart';
import '../widgets/fade_route.dart';
import '../widgets/physical_press.dart';
import '../widgets/press_scale.dart';
import '../widgets/screen_scaffold.dart';
import 'trust_carousel_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _nameController;
  late AnimationController _taglineController;
  late AnimationController _proofController;
  late AnimationController _ratingController;

  late Animation<Offset> _nameSlide;
  late Animation<double> _nameFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _taglineFade;
  late Animation<Offset> _proofSlide;
  late Animation<double> _proofFade;
  @override
  void initState() {
    super.initState();

    _nameController = AnimationController(
        vsync: this, duration: AppDurations.long);
    _taglineController = AnimationController(
        vsync: this, duration: AppDurations.long);
    _proofController = AnimationController(
        vsync: this, duration: AppDurations.long);
    _ratingController = AnimationController(
        vsync: this, duration: AppDurations.long);

    _nameSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _nameController, curve: AppCurves.warmOut));
    _nameFade = Tween(begin: 0.0, end: 1.0).animate(_nameController);

    _taglineSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _taglineController, curve: AppCurves.warmOut));
    _taglineFade = Tween(begin: 0.0, end: 1.0).animate(_taglineController);

    _proofSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _proofController, curve: AppCurves.warmOut));
    _proofFade = Tween(begin: 0.0, end: 1.0).animate(_proofController);

    _startAnimations();
  }

  void _startAnimations() async {
    // Wait for the Hero transition from SplashScreen to settle before
    // cascading the text reveals. The page transition is ~480ms; we start
    // just after it finishes so the "E" lands first, then text appears.
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _nameController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _taglineController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _proofController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _ratingController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _proofController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  void _navigate() {
    Navigator.of(context).push(fadeRoute(const TrustCarouselScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      animatedGradient: true,
      child: Column(
        children: [
          // Top area - logo + text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo: Hero-linked to the splash screen "E"
                Hero(
                  tag: 'earnwise-logo',
                  child: Breathing(
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'E',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // App name
                SlideTransition(
                  position: _nameSlide,
                  child: FadeTransition(
                    opacity: _nameFade,
                    child: Text(
                      'EarnWise',
                      style: AppText.brandMark,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Tagline
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'Turn your spare moments\ninto real dollars.',
                      textAlign: TextAlign.center,
                      style: AppText.listItem.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Social proof strip
                SlideTransition(
                  position: _proofSlide,
                  child: FadeTransition(
                    opacity: _proofFade,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stacked persona avatars
                          SizedBox(
                            width: 76,
                            height: 32,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _personaAvatar(
                                    'assets/images/personas/persona_01.png', 0),
                                _personaAvatar(
                                    'assets/images/personas/persona_02.png',
                                    22),
                                _personaAvatar(
                                    'assets/images/personas/persona_03.png',
                                    44),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              'People like you earn ~\$47/month',
                              style: AppText.caption.copyWith(
                                color: AppColors.inkSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom auth area
          Column(
            children: [
              // Google button -- prototype: PhysicalPress idiom (tactile
              // sink-into-shadow). The other 5 primary CTAs still use
              // PressScale so you can A/B the feel directly.
              PhysicalPress(
                onTap: _navigate,
                backgroundColor: AppColors.primary,
                shadowColor: AppColors.primaryDark,
                depth: 6,
                haptic: HapticIntensity.confirm,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.g_mobiledata,
                        size: 24, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Continue with Google',
                      style: AppText.ctaLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Apple button
              PhysicalPress(
                onTap: _navigate,
                backgroundColor: AppColors.white,
                shadowColor: AppColors.creamDeep,
                depth: 5,
                haptic: HapticIntensity.confirm,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIcons.appleLogo(),
                        size: 22, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Continue with Apple',
                      style: AppText.ctaLabel.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Legal
              Text(
                'By continuing you agree to our Terms & Privacy Policy',
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ],
      ),
    );
  }

  Widget _personaAvatar(String assetPath, double left) {
    return Positioned(
      left: left,
      child: Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
        ),
        child: ClipOval(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
