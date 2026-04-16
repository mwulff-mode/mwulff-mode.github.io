import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_text.dart';
import '../theme/earnwise_theme.dart';
import '../theme/motion.dart';
import '../widgets/animated_gradient_bg.dart';
import '../widgets/press_scale.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

/// Frosted glass pill fill and border alpha values. Coordinated so the
/// glass effect stays consistent if the colors need to change later.
const double _kGlassFillAlpha = 0.55;
const double _kGlassBorderAlpha = 0.70;

/// Corner radius for the floating nav pill. The inner nav item radius
/// (32) is intentionally smaller so the active tab highlight floats
/// inside the pill.
const double _kNavPillRadius = 40.0;

/// Top-level tab shell that sits between onboarding and the tab content.
/// Owns the floating glass nav pill that overlays every tab with a
/// surface-to-transparent gradient fade above it. Children are swapped via
/// [IndexedStack] so each tab's state survives tab switches.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.theme;
    return Scaffold(
      backgroundColor: t.palette.surface,
      body: AnimatedGradientBg(
        child: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _navIndex,
              children: [
                HomeScreen(
                  onNavigateToWallet: () => setState(() => _navIndex = 1),
                ),
                WalletScreen(
                  onNavigateHome: () => setState(() => _navIndex = 0),
                ),
                const ProfileScreen(),
              ],
            ),
          ),
          // Floating glass nav pill with surface-to-transparent gradient fade
          // above it, matching the pattern the home screen used to own.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 50,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0, -0.1),
                  colors: [
                    t.palette.surface.withValues(alpha: 0),
                    t.palette.surface,
                  ],
                ),
              ),
              child: Center(child: _buildBottomNav()),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kNavPillRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(_kNavPillRadius),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navItem(
                0,
                PhosphorIcons.house(PhosphorIconsStyle.fill),
                'Home',
                key: const Key('shell_nav_home'),
              ),
              _navItem(
                1,
                PhosphorIcons.wallet(PhosphorIconsStyle.fill),
                'Wallet',
                key: const Key('shell_nav_wallet'),
              ),
              _navItem(
                2,
                PhosphorIcons.user(PhosphorIconsStyle.fill),
                'Profile',
                key: const Key('shell_nav_profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {required Key key}) {
    final t = context.theme;
    final isActive = _navIndex == index;
    return PressScale(
      key: key,
      onTap: () => setState(() => _navIndex = index),
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: AppCurves.warmOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? t.palette.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive ? Colors.white : t.palette.inkSecondary,
            ),
            AnimatedSize(
              duration: AppDurations.medium,
              curve: AppCurves.warmOut,
              child: isActive
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        // Override font size: the nav pill label is
                        // intentionally one step smaller than the base
                        // bodyStrong (16 -> 15). Weight (w600) is unchanged.
                        Text(
                          label,
                          style: AppText.bodyStrong.copyWith(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

