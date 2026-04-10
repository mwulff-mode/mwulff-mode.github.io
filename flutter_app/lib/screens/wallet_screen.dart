import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../services/haptics.dart';
import '../widgets/press_scale.dart';
import '../widgets/bottom_sheet_shell.dart';
import '../widgets/reward_glow.dart';

/// First payout threshold in stars. Completing all onboarding tasks
/// (250 + 375 + 750 = 1375 task stars + 125 welcome gift) lands exactly here.
const int _kPayoutThresholdStars = 1500;

/// Dollar equivalent of the payout threshold.
const String _kPayoutDollars = '\$2.00';

/// PayPal brand blue, used for the icon badge.
const Color _kPaypalBlue = Color(0xFF0070BA);

// ──────────────────────────────────────────────────────────────
// Wallet Screen
// ──────────────────────────────────────────────────────────────

class WalletScreen extends StatefulWidget {
  final VoidCallback onNavigateHome;

  const WalletScreen({super.key, required this.onNavigateHome});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  void _showConfirmSheet(AppState state) {
    showAppBottomSheet<bool>(
      context: context,
      builder: (_) => _ConfirmRedeemContent(
        balanceStars: state.stars,
        redeemStars: _kPayoutThresholdStars,
      ),
    ).then((confirmed) {
      if (confirmed != true || !mounted) return;
      _handleRedeem();
    });
  }

  void _handleRedeem() async {
    final state = context.read<AppState>();
    Haptics.milestone();
    state.redeemPayout();

    // Switch to home tab first so it's visible when congrats dismisses
    widget.onNavigateHome();

    // Brief pause for tab switch, then show celebration
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    Navigator.of(context).push(_congratsRoute(const _PayoutCongratsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final balanceDollars = AppState.starsToDollars(state.stars);
        final thresholdDollars =
            AppState.starsToDollars(_kPayoutThresholdStars);
        final progress = (balanceDollars / thresholdDollars).clamp(0.0, 1.0);
        final isUnlocked =
            state.stars >= _kPayoutThresholdStars && !state.hasRedeemed;
        final isRedeemed = state.hasRedeemed;

        return Container(
          color: AppColors.cream,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(state),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppLayout.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        _buildBalanceSection(state, progress, isUnlocked),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Available Rewards',
                          style: AppText.listItem
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        _buildRewardCard(isUnlocked, isRedeemed, state),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isUnlocked && !isRedeemed) _buildLockedFooter(),
                        if (isRedeemed) _buildRedeemedFooter(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader(AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.gutter, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('Withdraw', style: AppText.sectionTitle),
          Positioned(
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    AppState.formatNumber(state.stars),
                    style: AppText.caption.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Balance Section ─────────────────────────────────────────

  Widget _buildBalanceSection(
      AppState state, double progress, bool isUnlocked) {
    final balanceStr = state.formatBalance();
    final remaining = _kPayoutThresholdStars - state.stars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your balance',
          style: AppText.body.copyWith(color: AppColors.inkTertiary),
        ),
        const SizedBox(height: 4),
        Text(
          '$balanceStr / $_kPayoutDollars',
          style: AppText.prompt.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: AppDurations.hero,
            curve: AppCurves.warmOut,
            builder: (context, value, _) {
              return SizedBox(
                height: 10,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.creamDeep,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (isUnlocked)
          Row(
            children: [
              Icon(PhosphorIcons.star(PhosphorIconsStyle.fill),
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                "You're ready to redeem!",
                style: AppText.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          )
        else
          Text(
            remaining > 0
                ? 'Earn \$${AppState.starsToDollars(remaining).toStringAsFixed(2)} more to unlock your first reward'
                : 'Reward redeemed',
            style: AppText.caption.copyWith(
                color: AppColors.inkTertiary, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  // ── Reward Card ─────────────────────────────────────────────

  Widget _buildRewardCard(
      bool isUnlocked, bool isRedeemed, AppState state) {
    return PressScale(
      onTap: isUnlocked ? () => _showConfirmSheet(state) : null,
      enabled: isUnlocked,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnlocked ? AppColors.primary : AppColors.creamDeep,
            width: isUnlocked ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isUnlocked ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // PayPal icon badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _kPaypalBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    PhosphorIcons.paypalLogo(PhosphorIconsStyle.fill),
                    size: 28,
                    color: _kPaypalBlue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _kPayoutDollars,
                        style: AppText.prompt
                            .copyWith(fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      Text('PayPal Gift Card',
                          style:
                              AppText.body.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (isUnlocked || isRedeemed)
                  Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                      size: 32, color: AppColors.primary)
                else
                  Icon(PhosphorIcons.lockSimple(PhosphorIconsStyle.fill),
                      size: 32, color: AppColors.accent),
              ],
            ),
            const SizedBox(height: 14),
            // Status badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isRedeemed
                    ? AppColors.primaryPale
                    : isUnlocked
                        ? AppColors.primary
                        : AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isRedeemed
                    ? 'Redeemed'
                    : isUnlocked
                        ? 'Unlocked -- Tap to redeem'
                        : 'Locked -- $_kPayoutDollars required',
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(
                  color: isRedeemed
                      ? AppColors.primary
                      : isUnlocked
                          ? Colors.white
                          : AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Locked Footer ───────────────────────────────────────────

  Widget _buildLockedFooter() {
    return Column(
      children: [
        Text(
          'Complete tasks on the Home screen to unlock rewards',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(
              color: AppColors.inkTertiary, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: AppSpacing.md),
        PressScale(
          onTap: widget.onNavigateHome,
          haptic: HapticIntensity.confirm,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Finish onboarding tasks', style: AppText.ctaLabel),
                const SizedBox(width: 6),
                Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                    size: 20, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Redeemed Footer ─────────────────────────────────────────

  Widget _buildRedeemedFooter() {
    return Center(
      child: Text(
        'Your reward is being delivered to your PayPal',
        textAlign: TextAlign.center,
        style: AppText.body.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Confirm Redeem Bottom Sheet
// ──────────────────────────────────────────────────────────────

class _ConfirmRedeemContent extends StatelessWidget {
  final int balanceStars;
  final int redeemStars;

  const _ConfirmRedeemContent({
    required this.balanceStars,
    required this.redeemStars,
  });

  String _dollars(int stars) =>
      '\$${(stars / AppState.starsPerDollar).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final afterStars = (balanceStars - redeemStars).clamp(0, balanceStars);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.paypalLogo(PhosphorIconsStyle.fill),
                size: 22, color: _kPaypalBlue),
            const SizedBox(width: 8),
            Text('$_kPayoutDollars PayPal Gift Card',
                style: AppText.listItem),
          ],
        ),
        const SizedBox(height: 20),
        Text('Confirm your withdrawal', style: AppText.sectionTitle),
        const SizedBox(height: 8),
        Text(
          '$_kPayoutDollars will be deducted from your balance',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 20),

        // Balance breakdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.creamDeep.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _detailRow('Current balance', _dollars(balanceStars)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.creamDeep, height: 1),
              ),
              _detailRow('After redemption', _dollars(afterStars)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Confirm CTA
        PressScale(
          onTap: () => Navigator.of(context).pop(true),
          haptic: HapticIntensity.confirm,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Yes, Redeem Now', style: AppText.ctaLabel),
                const SizedBox(width: 6),
                Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                    size: 20, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Later
        PressScale(
          onTap: () => Navigator.of(context).pop(false),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.creamDeep,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Later',
              textAlign: TextAlign.center,
              style:
                  AppText.bodyStrong.copyWith(color: AppColors.inkSecondary),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Reward delivered to your PayPal within 24 hours',
          style: AppText.caption.copyWith(
              fontWeight: FontWeight.w400, color: AppColors.inkTertiary),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppText.body.copyWith(fontWeight: FontWeight.w500)),
        Text(value, style: AppText.bodyStrong),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Payout Congrats (full-screen celebration)
// ──────────────────────────────────────────────────────────────

/// Fade-in route for the congrats overlay. Reverse is near-instant because
/// the screen fades itself out internally before popping.
PageRouteBuilder<void> _congratsRoute(Widget page) {
  return PageRouteBuilder<void>(
    opaque: true,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: AppDurations.medium,
    reverseTransitionDuration: const Duration(milliseconds: 1),
  );
}

class _PayoutCongratsScreen extends StatefulWidget {
  const _PayoutCongratsScreen();

  @override
  State<_PayoutCongratsScreen> createState() => _PayoutCongratsScreenState();
}

class _PayoutCongratsScreenState extends State<_PayoutCongratsScreen>
    with TickerProviderStateMixin {
  final RewardGlowController _glowCtrl = RewardGlowController();
  late final AnimationController _scaleCtrl;
  late final AnimationController _textCtrl;
  bool _fading = false;

  @override
  void initState() {
    super.initState();
    _scaleCtrl =
        AnimationController(vsync: this, duration: AppDurations.hero);
    _textCtrl =
        AnimationController(vsync: this, duration: AppDurations.long);
    _play();
  }

  Future<void> _play() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _glowCtrl.play();
    Haptics.celebrate(CelebrateMoments.payoutConfirmed);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _scaleCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textCtrl.forward();

    // Hold for a beat, then auto-dismiss
    await Future.delayed(const Duration(seconds: 3));
    _dismiss();
  }

  void _dismiss() {
    if (_fading || !mounted) return;
    setState(() => _fading = true);
    Future.delayed(AppDurations.long, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _textCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      child: AnimatedOpacity(
        opacity: _fading ? 0 : 1,
        duration: AppDurations.long,
        child: Container(
          color: AppColors.cream,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RewardGlow(
                  controller: _glowCtrl,
                  glowColor: AppColors.primary,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.tealSecondary],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                        size: 48,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ScaleTransition(
                  scale: CurvedAnimation(
                      parent: _scaleCtrl, curve: AppCurves.warmOut),
                  child: Text(_kPayoutDollars, style: AppText.heroAmount),
                ),
                ScaleTransition(
                  scale: CurvedAnimation(
                      parent: _scaleCtrl, curve: AppCurves.warmOut),
                  child: Text(
                    'Payout confirmed',
                    style: AppText.prompt.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.6),
                      letterSpacing: 1,
                      height: null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _textCtrl,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Your reward is on its way to PayPal',
                      textAlign: TextAlign.center,
                      style:
                          AppText.sectionTitle.copyWith(letterSpacing: -0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
